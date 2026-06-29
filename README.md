# Avis — 영어 단어 암기장

iOS/iPadOS용 영어 단어 플래시카드 앱입니다. 엑셀 파일로 단어를 불러오고, 타이핑 퀴즈로 학습하며, 학습 진행 상황을 추적합니다.

## 주요 기능

- **엑셀 임포트** — `.xlsx` 파일에서 단어 가져오기 (TOEIC 형식 / 2열 단순 형식 자동 감지)
- **타이핑 퀴즈** — 영어→한글, 한글→영어, 랜덤 혼합 3가지 모드
- **유연한 정답 처리** — `"(명) 경영진, 임원 / (형) 경영의"` 같은 복합 뜻에서 어느 한 단어만 입력해도 정답 인정
- **학습 완료 판정** — 정답 3회 이상 누적 시 완료(`isLearned = true`), 오답 시 초기화
- **단어장 관리** — 검색, 필터(미학습/오답 우선), 스와이프 삭제
- **통계 대시보드** — 누적 정확도, 최고 점수, 자주 틀리는 단어 TOP 3

## 기술 스택

| 항목 | 내용 |
|---|---|
| 플랫폼 | iOS 17.0+, iPhone + iPad |
| 언어 | Swift 5.0 |
| UI | SwiftUI |
| 아키텍처 | MVVM |
| 저장소 | UserDefaults |
| 외부 의존성 | 없음 (순수 Xcode 프로젝트) |

## 프로젝트 구조

```
Avis/
├── Avis.swift                   # 앱 진입점 (@main)
├── Models/
│   └── Word.swift               # Word, QuizMode, QuizQuestion, QuizResult, QuizStats
├── ViewModels/
│   ├── WordListViewModel.swift  # 단어 CRUD, 임포트, 검색
│   ├── QuizViewModel.swift      # 퀴즈 상태 머신 (idle → active → answered → finished)
│   └── StatsViewModel.swift     # 누적 통계 로드/저장
├── Views/
│   ├── ContentView.swift        # TabView 루트 (홈/단어장/퀴즈/통계)
│   ├── HomeView.swift           # 학습 현황 카드, 빠른 시작, 엑셀 임포트
│   ├── WordListView.swift       # 단어 목록, 검색, 필터
│   ├── QuizSetupView.swift      # 퀴즈 옵션 설정
│   ├── QuizView.swift           # 퀴즈 진행 화면
│   ├── ResultView.swift         # 퀴즈 결과 및 재도전
│   ├── StatsView.swift          # 학습 통계
│   └── FlowLayout.swift         # 정답 태그 흐름 레이아웃
└── Services/
    ├── WordStore.swift          # UserDefaults 읽기/쓰기 (정적 메서드)
    └── ExcelService.swift       # .xlsx 파싱 (ZipArchive + XML 직접 처리)
```

## 아키텍처

`ContentView`에서 세 개의 `@StateObject` ViewModel을 생성하고 `@EnvironmentObject`로 하위 뷰에 공유합니다.

```
ContentView (TabView)
  ├── WordListViewModel   — [Word] 보유, 임포트·CRUD 처리
  ├── QuizViewModel       — 진행 중인 퀴즈 세션 상태 머신
  └── StatsViewModel      — UserDefaults의 QuizStats 래퍼
```

### 데이터 흐름

```
.xlsx 파일
  └─▶ ExcelService.parse()
        └─▶ WordListViewModel.importExcel()
              └─▶ WordStore.save()  ──▶  UserDefaults("saved_words")

퀴즈 세션
  └─▶ QuizViewModel.submitAnswer()
        ├─▶ WordListViewModel.updateWordResult()  →  isLearned 갱신
        └─▶ StatsViewModel  →  WordStore.saveStats()  ──▶  UserDefaults("quiz_stats")
```

### Excel 임포트 형식

| 형식 | 열 구성 |
|---|---|
| 6열 TOEIC | `번호(A)` / `영어(B)` / `품사1(C)` / `뜻1(D)` / `품사2(E)` / `뜻2(F)` |
| 2열 단순 | `영어(A)` / `한글(B)` |

중복 단어는 `english.lowercased()` 기준으로 병합하며, 기존 단어장이 있을 경우 추가/교체 중 선택합니다.

## 빌드 및 실행

```bash
open Avis.xcodeproj   # Xcode에서 열기
# Cmd+B   빌드
# Cmd+R   시뮬레이터 실행
# Cmd+Shift+K   빌드 폴더 정리
```

테스트 타겟은 없으며, 빌드 성공이 검증 기준입니다.
