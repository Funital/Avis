import SwiftUI

/// 여러 개의 View(예: 태그, 칩)를 가로 방향으로 배치하다가
/// 화면 너비를 초과하면 자동으로 다음 줄로 내려주는 Flow Layout
struct FlowLayout<Item: Hashable, Content: View>: View {
    
    /// 표시할 데이터 목록
    let items: [Item]
    
    /// 각 Item을 어떤 View로 표현할지 결정하는 클로저
    let content: (Item) -> Content
    
    /// FlowLayout의 최종 높이
    /// 줄바꿈이 발생하면 높이가 늘어나므로 동적으로 계산
    @State private var totalHeight: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            // 부모 View의 크기를 이용하여 레이아웃 생성
            self.generateContent(in: geo)
        }
        // 계산된 높이를 적용
        .frame(height: totalHeight)
    }
    
    /// 실제 Flow Layout을 생성하는 함수
    private func generateContent(in geo: GeometryProxy) -> some View {
        
        /// 현재 행에서 사용 중인 가로 위치
        var width: CGFloat = 0
        
        /// 현재 행의 세로 위치
        var height: CGFloat = 0
        
        /// 현재 행에서 가장 높은 View의 높이
        /// 줄바꿈 시 다음 줄 위치를 계산하기 위해 사용
        var rowHeight: CGFloat = 0
        
        /// 아이템 간 간격
        let spacing: CGFloat = 6
        
        return ZStack(alignment: .topLeading) {
            ForEach(items, id: \.self) { item in
                content(item)
                    .padding(.all, 2)
                
                    // 가로 위치 계산
                    .alignmentGuide(.leading) { d in
                        
                        // 현재 아이템을 배치했을 때 화면 너비를 넘는다면 줄바꿈
                        if abs(width - d.width - spacing) > geo.size.width {
                            width = 0
                            height -= rowHeight + spacing
                            rowHeight = 0
                        }
                        
                        // 현재 아이템의 x 좌표
                        let result = width
                        
                        // 마지막 아이템이면 다음 계산을 위해 초기화
                        if item == items.last {
                            width = 0
                        } else {
                            // 다음 아이템의 위치 계산
                            width -= d.width + spacing
                        }
                        
                        // 현재 줄에서 가장 큰 높이 저장
                        rowHeight = max(rowHeight, d.height)
                        
                        return result
                    }
                
                    // 세로 위치 계산
                    .alignmentGuide(.top) { _ in
                        let result = height
                        
                        // 마지막 아이템이면 초기화
                        if item == items.last {
                            height = 0
                        }
                        
                        return result
                    }
            }
        }
        // 실제 ZStack의 높이를 측정하여 FlowLayout 높이 갱신
        .background(
            GeometryReader { geo in
                Color.clear.onAppear {
                    totalHeight = geo.size.height
                }
            }
        )
    }
}
