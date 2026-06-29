# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Avis is an iOS/iPadOS English vocabulary flashcard app (영어 단어 암기장). It supports typed quizzes, Excel import, and learning progress tracking.

- **Platform**: iOS 17.0+, iPhone + iPad (`TARGETED_DEVICE_FAMILY = "1,2"`)
- **Language**: Swift 5.0, SwiftUI
- **Dependencies**: None (no CocoaPods, no SPM packages — pure Xcode project)
- **Bundle ID**: `com.avis.app`

## Build & Run

Open `Avis.xcodeproj` in Xcode, then:

- **Build**: `Cmd+B`
- **Run on simulator**: `Cmd+R`
- **Clean build folder**: `Cmd+Shift+K`

There are no test targets in this project. Build success is used as the verification step in the `/tc` command.

## Trigger Keywords

These are shorthand phrases Claude Code recognizes in this repo:

| 키워드 | 동작 |
|---|---|
| `/tc "메시지"` | 빌드 검증 → 성공 시 `git commit` + `git push` (`.claude/commands/tc.md` 참조) |
| `빌드해` / `빌드 확인` | `xcodebuild build` 실행 후 결과 보고 |
| `시뮬레이터로 실행해` | 시뮬레이터 부팅 → 앱 빌드·설치·실행 → 스크린샷 |

## Architecture

MVVM with SwiftUI. Three `@MainActor ObservableObject` ViewModels are created at the root (`ContentView`) and shared downward via `@EnvironmentObject`.

```
ContentView (TabView: 홈 / 단어장 / 퀴즈 / 통계)
  ├── WordListViewModel   — owns [Word], drives imports and CRUD
  ├── QuizViewModel       — state machine for an active quiz session
  └── StatsViewModel      — wraps QuizStats from UserDefaults
```

### Data layer

All persistence is `UserDefaults` via `WordStore` (static methods only):
- `WordStore.save/load` — `[Word]` array, key `"saved_words"`
- `WordStore.saveStats/loadStats` — `QuizStats`, key `"quiz_stats"`

There is no Core Data, no network layer, and no iCloud sync.

### Key models (`Models/Word.swift`)

| Type | Purpose |
|---|---|
| `Word` | Single vocabulary entry: `english`, `korean`, `isLearned`, `correctCount`, `wrongCount` |
| `QuizMode` | `.englishToKorean`, `.koreanToEnglish`, `.mixed` |
| `QuizQuestion` | Wraps a `Word` + `QuizMode`; exposes `acceptableAnswers` |
| `QuizResult` | Aggregates a finished session (score, wrong words) |
| `QuizStats` | Lifetime totals persisted across sessions |

**`isLearned` promotion rule**: `WordListViewModel.updateWordResult` sets `isLearned = true` once `correctCount >= 3`; any wrong answer resets it to `false`.

### Answer matching (`QuizQuestion.acceptableAnswers`)

Korean answers in `Word.korean` follow the pattern `"(명) 경영진, 임원 / (형) 경영의"`. The parser strips part-of-speech tags (`(명)`, `(동)`, etc.), splits on `/`, then on `,`, and trims whitespace — any one segment is accepted as correct. English answers are compared case-insensitively.

### Excel import (`Services/ExcelService.swift`)

Parses `.xlsx` without third-party libraries: unzips the file manually (custom `ZipArchive`), then regex-parses `xl/sharedStrings.xml` and `xl/worksheets/sheet1.xml`.

Two supported formats, auto-detected by whether column D is present:
- **6-column TOEIC format**: `번호(A) / 영어(B) / 품사1(C) / 뜻1(D) / 품사2(E) / 뜻2(F)`
- **2-column simple format**: `영어(A) / 한글(B)`

Imported words are merged by `english.lowercased()` deduplication; users choose add vs. replace when the word list is non-empty.
