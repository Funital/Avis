import Foundation
import UniformTypeIdentifiers

/// ExcelService: .xlsx 파일에서 단어를 파싱합니다.
/// 지원 형식:
///   - 2열: [영어(A), 한글(B)]
///   - 6열: [번호(A), 영어(B), 품사1(C), 뜻1(D), 품사2(E), 뜻2(F)] ← 토익 단어장 형식
class ExcelService {

    static func parseWords(from url: URL) throws -> [Word] {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempDir) }

        let accessed = url.startAccessingSecurityScopedResource()
        defer { if accessed { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        guard let archive = ZipArchive(data: data) else { throw ExcelError.invalidFormat }

        var sharedStrings: [String] = []
        if let ssData = archive.extract("xl/sharedStrings.xml"),
           let ssXml = String(data: ssData, encoding: .utf8) {
            sharedStrings = parseSharedStrings(from: ssXml)
        }

        guard let sheetData = archive.extract("xl/worksheets/sheet1.xml"),
              let sheetXml = String(data: sheetData, encoding: .utf8) else {
            throw ExcelError.sheetNotFound
        }

        return try parseSheet(xml: sheetXml, sharedStrings: sharedStrings)
    }

    private static func parseSharedStrings(from xml: String) -> [String] {
        var strings: [String] = []
        let pattern = "<t[^>]*>([^<]*)</t>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
        for match in matches {
            if let r = Range(match.range(at: 1), in: xml) {
                strings.append(String(xml[r]).xmlDecoded)
            }
        }
        return strings
    }

    private static func parseSheet(xml: String, sharedStrings: [String]) throws -> [Word] {
        let rowPattern  = "<row[^>]*>(.*?)</row>"
        let cellPattern = "<c r=\"([A-Z]+\\d+)\"[^>]*(?:t=\"([^\"]*)\")?>(?:<v>([^<]*)</v>)?(?:<is><t>([^<]*)</t></is>)?"

        guard let rowRegex  = try? NSRegularExpression(pattern: rowPattern, options: .dotMatchesLineSeparators),
              let cellRegex = try? NSRegularExpression(pattern: cellPattern) else {
            throw ExcelError.parseError
        }

        var allRows: [[String: String]] = []
        rowRegex.enumerateMatches(in: xml, range: NSRange(xml.startIndex..., in: xml)) { match, _, _ in
            guard let match = match, let rowRange = Range(match.range(at: 1), in: xml) else { return }
            let rowContent = String(xml[rowRange])
            var rowData: [String: String] = [:]
            cellRegex.enumerateMatches(in: rowContent, range: NSRange(rowContent.startIndex..., in: rowContent)) { cm, _, _ in
                guard let cm = cm,
                      let refRange = Range(cm.range(at: 1), in: rowContent) else { return }
                let col = String(String(rowContent[refRange]).prefix(while: { $0.isLetter }))
                let typeStr = (Range(cm.range(at: 2), in: rowContent)).map { String(rowContent[$0]) } ?? ""
                var value = ""
                if let vRange = Range(cm.range(at: 3), in: rowContent) {
                    let raw = String(rowContent[vRange])
                    value = (typeStr == "s" && Int(raw).map { $0 < sharedStrings.count } == true)
                        ? sharedStrings[Int(raw)!] : raw
                } else if let isRange = Range(cm.range(at: 4), in: rowContent) {
                    value = String(rowContent[isRange]).xmlDecoded
                }
                rowData[col] = value
            }
            allRows.append(rowData)
        }

        guard !allRows.isEmpty else { return [] }

        // 열 수로 포맷 자동 감지
        let hasSixCols = allRows.prefix(5).contains { $0["D"] != nil }
        return hasSixCols ? parseToeicFormat(rows: allRows) : parseSimpleFormat(rows: allRows)
    }

    // 6열 토익 형식: 번호(A) / 영어(B) / 품사1(C) / 뜻1(D) / 품사2(E) / 뜻2(F)
    private static func parseToeicFormat(rows: [[String: String]]) -> [Word] {
        var words: [Word] = []
        for row in rows {
            let english  = (row["B"] ?? "").trimmingCharacters(in: .whitespaces)
            let pos1     = (row["C"] ?? "").trimmingCharacters(in: .whitespaces)
            let meaning1 = (row["D"] ?? "").trimmingCharacters(in: .whitespaces)
            let pos2     = (row["E"] ?? "").trimmingCharacters(in: .whitespaces)
            let meaning2 = (row["F"] ?? "").trimmingCharacters(in: .whitespaces)
            guard !english.isEmpty, !meaning1.isEmpty, Double(english) == nil else { continue }
            var korean = "\(pos1) \(meaning1)".trimmingCharacters(in: .whitespaces)
            if !pos2.isEmpty && !meaning2.isEmpty && meaning2 != meaning1 {
                korean += " / \(pos2) \(meaning2)"
            }
            words.append(Word(english: english, korean: korean))
        }
        return words
    }

    // 2열 기본 형식: 영어(A) / 한글(B)
    private static func parseSimpleFormat(rows: [[String: String]]) -> [Word] {
        var words: [Word] = []
        for (i, row) in rows.enumerated() {
            let english = (row["A"] ?? "").trimmingCharacters(in: .whitespaces)
            let korean  = (row["B"] ?? "").trimmingCharacters(in: .whitespaces)
            if i == 0 && (english.lowercased() == "english" || korean == "한글" || korean == "Korean") { continue }
            if !english.isEmpty && !korean.isEmpty { words.append(Word(english: english, korean: korean)) }
        }
        return words
    }

    enum ExcelError: LocalizedError {
        case invalidFormat, sheetNotFound, parseError
        var errorDescription: String? {
            switch self {
            case .invalidFormat: return "유효하지 않은 Excel 파일입니다."
            case .sheetNotFound: return "시트를 찾을 수 없습니다."
            case .parseError:    return "파싱 중 오류가 발생했습니다."
            }
        }
    }
}

// MARK: - ZIP Archive (외부 라이브러리 없이 구현)
class ZipArchive {
    private let data: Data
    init?(data: Data) {
        guard data.count > 22 else { return nil }
        self.data = data
    }

    func extract(_ path: String) -> Data? {
        var offset = 0
        while offset + 30 < data.count {
            guard data.readUInt32(at: offset) == 0x04034b50 else { break }
            let fnLen  = Int(data.readUInt16(at: offset + 26))
            let exLen  = Int(data.readUInt16(at: offset + 28))
            let cmSize = Int(data.readUInt32(at: offset + 18))
            let method = Int(data.readUInt16(at: offset + 8))
            let fnStart = offset + 30, fnEnd = fnStart + fnLen
            guard fnEnd <= data.count else { break }
            if let fn = String(data: data[fnStart..<fnEnd], encoding: .utf8), fn == path {
                let cs = fnEnd + exLen, ce = cs + cmSize
                guard ce <= data.count else { return nil }
                let compressed = data[cs..<ce]
                if method == 0 { return Data(compressed) }
                if method == 8 { return try? (compressed as NSData).decompressed(using: .zlib) as Data }
            }
            offset = fnEnd + exLen + cmSize
        }
        return searchCentralDirectory(for: path)
    }

    private func searchCentralDirectory(for targetPath: String) -> Data? {
        var eocd = data.count - 22
        while eocd >= 0 { if data.readUInt32(at: eocd) == 0x06054b50 { break }; eocd -= 1 }
        guard eocd >= 0 else { return nil }
        let cdOffset = Int(data.readUInt32(at: eocd + 16))
        let cdSize   = Int(data.readUInt32(at: eocd + 12))
        var pos = cdOffset
        while pos < cdOffset + cdSize && pos + 46 < data.count {
            guard data.readUInt32(at: pos) == 0x02014b50 else { break }
            let fnLen = Int(data.readUInt16(at: pos + 28))
            let exLen = Int(data.readUInt16(at: pos + 30))
            let cmLen = Int(data.readUInt16(at: pos + 32))
            let lhOff = Int(data.readUInt32(at: pos + 42))
            let fnStart = pos + 46, fnEnd = fnStart + fnLen
            if fnEnd <= data.count,
               let fn = String(data: data[fnStart..<fnEnd], encoding: .utf8), fn == targetPath {
                let lhFnLen = Int(data.readUInt16(at: lhOff + 26))
                let lhExLen = Int(data.readUInt16(at: lhOff + 28))
                let cmSize  = Int(data.readUInt32(at: lhOff + 18))
                let method  = Int(data.readUInt16(at: lhOff + 8))
                let cs = lhOff + 30 + lhFnLen + lhExLen, ce = cs + cmSize
                guard ce <= data.count else { return nil }
                let compressed = data[cs..<ce]
                if method == 0 { return Data(compressed) }
                if method == 8 { return try? (compressed as NSData).decompressed(using: .zlib) as Data }
            }
            pos += 46 + fnLen + exLen + cmLen
        }
        return nil
    }
}

extension Data {
    func readUInt32(at offset: Int) -> UInt32 {
        guard offset + 4 <= count else { return 0 }
        return self[offset..<offset+4].withUnsafeBytes { $0.load(as: UInt32.self) }
    }
    func readUInt16(at offset: Int) -> UInt16 {
        guard offset + 2 <= count else { return 0 }
        return self[offset..<offset+2].withUnsafeBytes { $0.load(as: UInt16.self) }
    }
}

extension String {
    var xmlDecoded: String {
        self
            .replacingOccurrences(of: "&amp;",  with: "&")
            .replacingOccurrences(of: "&lt;",   with: "<")
            .replacingOccurrences(of: "&gt;",   with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&apos;", with: "'")
    }
}
