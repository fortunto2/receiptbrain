# CLAUDE.md — ReceiptBrain

## Overview

Privacy-first receipt scanner for iOS. Snap a photo, on-device OCR extracts merchant/amount/date/category. All data stays local in SwiftData. No cloud, no account, no subscription for core features.

## Tech Stack

- **Language:** Swift 6
- **UI:** SwiftUI
- **Persistence:** SwiftData (local SQLite)
- **OCR:** Vision framework (VNRecognizeTextRequest)
- **Charts:** Swift Charts (SectorMark, BarMark)
- **Camera:** UIImagePickerController (wrapped in SwiftUI)
- **IAP:** StoreKit 2 (Pro upgrade)
- **Analytics:** PostHog iOS SDK (EU hosting)
- **Linter:** SwiftLint
- **Testing:** Swift Testing + XCTest
- **Min iOS:** 17.0

## Architecture

MVVM pattern:

```
ReceiptBrain/
  ReceiptBrainApp.swift     # @main, ModelContainer
  ContentView.swift          # TabView (Scanner, Dashboard, History)
  Models/
    Receipt.swift            # @Model + ExpenseCategory + PaymentMethod enums
  Views/
    ScannerView.swift        # Camera/photo capture + review form
    CameraView.swift         # UIImagePickerController wrapper
    DashboardView.swift      # Charts (pie + bar) + spending summary
    HistoryView.swift        # Searchable receipt list with category filters
  ViewModels/
    ScannerViewModel.swift   # OCR pipeline orchestration
  Services/
    VisionService.swift      # VNRecognizeTextRequest actor
    ReceiptParser.swift      # OCR text → structured receipt data
ReceiptBrainTests/
  ReceiptParserTests.swift   # Parser unit tests (Swift Testing)
```

## Commands

```bash
# Build (Xcode)
open Package.swift  # Opens in Xcode
# Or: xcodebuild -scheme ReceiptBrain -destination 'platform=iOS Simulator,name=iPhone 16'

# Test
xcodebuild test -scheme ReceiptBrain -destination 'platform=iOS Simulator,name=iPhone 16'

# Lint
swiftlint lint
```

## SGR — Schemas First

This project follows Schema-Guided Reasoning: **domain models are the source of truth**.

**Read `Models/Receipt.swift` BEFORE any other code.** It defines:
- `Receipt` (@Model) — core aggregate: merchant, amount, date, category, payment method, OCR text
- `ExpenseCategory` (enum) — groceries, dining, transport, shopping, utilities, health, entertainment, education, travel, other
- `PaymentMethod` (enum) — cash, creditCard, debitCard, other
- `ParsedReceipt` (struct in ReceiptParser.swift) — intermediate OCR result before user review

**Rules:**
- New features start with schema changes in `Models/`
- Enums are the ubiquitous language — add new categories to `ExpenseCategory`, not ad-hoc strings
- Services accept and return typed models, never raw strings/dicts
- VisionService → ParsedReceipt → Receipt is a typed pipeline, keep it that way

## Key Patterns

- **OCR Pipeline:** Camera → VisionService (actor) → ReceiptParser → ParsedReceipt → user review → Receipt (@Model) → SwiftData
- **VisionService** is an `actor` for thread safety
- **ReceiptParser** uses regex for amount extraction, keyword matching for categorization
- **@Query** for reactive SwiftData lists in SwiftUI
- **@Observable** ViewModel pattern (not ObservableObject)

## Do

- Define schemas/models BEFORE writing logic or views
- Keep all data local (SwiftData, no network calls)
- Use Swift 6 concurrency (async/await, actors)
- Use Swift Testing (@Test) for new tests
- Add AICODE- comments where OCR logic is non-obvious
- Use enums for categories and types, never raw strings

## Don't

- Don't add cloud sync or network calls
- Don't use UIKit directly (wrap in UIViewControllerRepresentable)
- Don't use ObservableObject (use @Observable instead)
- Don't hardcode currency (use receipt.currency field)
- Don't work with untyped data — always go through schemas

## PRD

Full requirements: `docs/prd.md`
