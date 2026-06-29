---
description: 빌드 검증 후 git commit + push를 한 번에 수행합니다. 사용법: /tc "커밋 메시지"
---

아래 순서로 수행하세요.

1. **빌드 검증** — 다음 명령을 실행합니다. 실패하면 즉시 멈추고 오류를 보고합니다.

```bash
xcodebuild \
  -project Avis.xcodeproj \
  -scheme Avis \
  -destination 'platform=iOS Simulator,name=iPhone 16e' \
  -configuration Debug \
  build 2>&1 | tail -5
```

빌드 결과 마지막 줄이 `** BUILD SUCCEEDED **`가 아니면 커밋하지 않고 중단합니다.

2. **스테이징** — 변경된 소스 파일만 추가합니다 (`.env`, `*.xcuserstate`, `DerivedData` 제외).

```bash
git add -A
git status
```

스테이지된 변경사항이 없으면 "커밋할 변경사항이 없습니다"라고 알리고 종료합니다.

3. **커밋** — 사용자가 `/tc` 뒤에 전달한 텍스트를 커밋 메시지로 사용합니다. 메시지가 없으면 묻지 말고 변경 내용을 요약해서 자동 작성합니다.

4. **푸시** — `git push` 를 실행하고 결과를 보고합니다.
