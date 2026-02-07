# ReceiptBrain

Privacy-first receipt scanner for iOS. Snap a photo of any receipt — on-device OCR extracts merchant, amount, date, and category. All data stays on your iPhone. No cloud, no account, no subscription.

## Features

- Camera receipt scanning with Apple Vision OCR
- Auto-categorization (groceries, dining, transport, etc.)
- Monthly spending dashboard with charts
- Search and filter receipt history
- 100% offline — zero network calls
- SwiftData local persistence

## Requirements

- iOS 17.0+
- Xcode 16+
- iPhone with camera (for scanning)

## Setup

```bash
# Open in Xcode
open Package.swift

# Build & Run
# Cmd+R in Xcode (select iOS Simulator or device)
```

## Test

```bash
xcodebuild test -scheme ReceiptBrain \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Language | Swift 6 |
| UI | SwiftUI |
| Persistence | SwiftData |
| OCR | Vision (VNRecognizeTextRequest) |
| Charts | Swift Charts |
| IAP | StoreKit 2 |
| Analytics | PostHog iOS |
| Linter | SwiftLint |
| Testing | Swift Testing |

## Architecture

MVVM — Models, Views, ViewModels, Services

## Privacy

All data is processed and stored on-device. No data leaves your iPhone. No account required. No analytics on your financial data — PostHog tracks only app usage events (screen views, feature usage), never receipt content.

## License

Proprietary. All rights reserved.
