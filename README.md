# Avis — English Vocabulary Flashcard App

An iOS/iPadOS flashcard app for learning English vocabulary. Import words from Excel files, practice with typed quizzes, and track your learning progress.

## Features

- **Excel Import** — Import words from `.xlsx` files (auto-detects TOEIC format or 2-column simple format)
- **Typed Quizzes** — Three modes: English→Korean, Korean→English, and random mixed
- **Flexible Answer Matching** — For compound definitions like `"(명) 경영진, 임원 / (형) 경영의"`, any single segment is accepted as correct
- **Learned Word Promotion** — A word is marked learned (`isLearned = true`) after 3 consecutive correct answers; any wrong answer resets it
- **Word List Management** — Search, filter (unlearned / most-missed first), swipe to delete
- **Statistics Dashboard** — Cumulative accuracy, high score, and top 3 most-missed words

## Tech Stack

| Item | Detail |
|---|---|
| Platform | iOS 17.0+, iPhone + iPad |
| Language | Swift 5.0 |
| UI | SwiftUI |
| Architecture | MVVM |
| Persistence | UserDefaults |
| External Dependencies | None (pure Xcode project) |

## Project Structure

```
Avis/
├── Avis.swift                   # App entry point (@main)
├── Models/
│   └── Word.swift               # Word, QuizMode, QuizQuestion, QuizResult, QuizStats
├── ViewModels/
│   ├── WordListViewModel.swift  # Word CRUD, import, search
│   ├── QuizViewModel.swift      # Quiz state machine (idle → active → answered → finished)
│   └── StatsViewModel.swift     # Cumulative stats load/save
├── Views/
│   ├── ContentView.swift        # TabView root (Home / Words / Quiz / Stats)
│   ├── HomeView.swift           # Learning summary card, quick start, Excel import
│   ├── WordListView.swift       # Word list, search, filter
│   ├── QuizSetupView.swift      # Quiz options setup
│   ├── QuizView.swift           # Active quiz screen
│   ├── ResultView.swift         # Quiz results and retry
│   ├── StatsView.swift          # Learning statistics
│   └── FlowLayout.swift         # Flow layout for answer tags
└── Services/
    ├── WordStore.swift          # UserDefaults read/write (static methods)
    └── ExcelService.swift       # .xlsx parsing (ZipArchive + direct XML handling)
```

## Architecture

Three `@StateObject` ViewModels are created in `ContentView` and shared to child views via `@EnvironmentObject`.

```
ContentView (TabView)
  ├── WordListViewModel   — owns [Word], handles import & CRUD
  ├── QuizViewModel       — state machine for the active quiz session
  └── StatsViewModel      — wraps QuizStats from UserDefaults
```

### Data Flow

```
.xlsx file
  └─▶ ExcelService.parse()
        └─▶ WordListViewModel.importExcel()
              └─▶ WordStore.save()  ──▶  UserDefaults("saved_words")

Quiz session
  └─▶ QuizViewModel.submitAnswer()
        ├─▶ WordListViewModel.updateWordResult()  →  updates isLearned
        └─▶ StatsViewModel  →  WordStore.saveStats()  ──▶  UserDefaults("quiz_stats")
```

### Excel Import Formats

| Format | Columns |
|---|---|
| 6-column TOEIC | `No.(A)` / `English(B)` / `PoS1(C)` / `Meaning1(D)` / `PoS2(E)` / `Meaning2(F)` |
| 2-column simple | `English(A)` / `Korean(B)` |

Duplicate words are merged by `english.lowercased()`; when the existing word list is non-empty, the user chooses between adding or replacing.

## Build & Run

```bash
tuist install         # Install dependencies
tuist generate        # Generate Xcode project and open in Xcode
# Cmd+B          Build
# Cmd+R          Run on simulator
# Cmd+Shift+K    Clean build folder
```

There are no test targets; build success is the verification criterion.
