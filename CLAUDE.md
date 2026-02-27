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

## Project Structure

```
receiptbrain/
├── Package.swift              # Swift Package (Xcode project)
├── ReceiptBrain/              # App source
│   ├── ReceiptBrainApp.swift  # @main, ModelContainer
│   ├── ContentView.swift      # TabView (Scanner, Dashboard, History)
│   ├── Models/                # Domain models (read first — SGR)
│   ├── Views/                 # SwiftUI views
│   ├── ViewModels/            # @Observable view models
│   └── Services/              # VisionService, ReceiptParser
├── ReceiptBrainTests/         # Swift Testing tests
└── docs/                      # PRD and specs
```

## Architecture

MVVM pattern:

```
ReceiptBrain/
  ReceiptBrainApp.swift     # @main, ModelContainer
  ContentView.swift          # TabView (Scanner, Dashboard, History)
  Models/                    # ← READ FIRST (SGR: schemas are source of truth)
    Receipt.swift            # @Model — core aggregate (merchant, amount, date, category)
    OCRResult.swift          # Value object — typed Vision output (replaces raw [String])
    ParsedReceipt.swift      # Domain struct — intermediate OCR result + toReceipt() converter
    ReceiptError.swift       # Domain errors — consolidated error types for pipeline
  Views/
    ScannerView.swift        # Camera/photo capture + review form
    CameraView.swift         # UIImagePickerController wrapper
    DashboardView.swift      # Charts (pie + bar) + spending summary
    HistoryView.swift        # Searchable receipt list with category filters
  ViewModels/
    ScannerViewModel.swift   # OCR pipeline orchestration (typed: OCRResult → ParsedReceipt)
  Services/
    VisionService.swift      # VNRecognizeTextRequest actor → returns OCRResult
    ReceiptParser.swift      # OCRResult → ParsedReceipt (no domain types defined here)
ReceiptBrainTests/
  ReceiptParserTests.swift   # Parser + domain model tests (Swift Testing)
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

**Read `Models/` BEFORE any other code.** It defines the entire domain:

| File | Type | Purpose |
|------|------|---------|
| `Receipt.swift` | `@Model` | Core aggregate: merchant, amount, date, category, payment method, OCR text |
| `Receipt.swift` | `ExpenseCategory` enum | Ubiquitous language: groceries, dining, transport, shopping, etc. |
| `Receipt.swift` | `PaymentMethod` enum | cash, creditCard, debitCard, other |
| `OCRResult.swift` | `struct` (value object) | Typed Vision output — wraps `[String]` lines, provides `fullText`, `isEmpty` |
| `ParsedReceipt.swift` | `struct` (domain) | Intermediate OCR result with `toReceipt()` schema-driven converter |
| `ReceiptError.swift` | `enum` (domain errors) | All pipeline errors: invalidImage, emptyOCRResult, noAmountFound |

### Typed Pipeline

```
UIImage → VisionService → OCRResult → ReceiptParser → ParsedReceipt → user review → Receipt (@Model) → SwiftData
```

**No raw strings or untyped data cross service boundaries.** Every step accepts and returns a typed domain model.

### Rules

- New features start with schema changes in `Models/`
- Enums are the ubiquitous language — add new categories to `ExpenseCategory`, not ad-hoc strings
- Services accept and return typed models, never raw strings/dicts
- Domain types live ONLY in `Models/` — services contain logic, not type definitions
- Errors are domain types in `ReceiptError` — don't scatter error enums across services

## Key Patterns

- **VisionService** is an `actor` → returns `OCRResult` (typed)
- **ReceiptParser** takes `OCRResult` → returns `ParsedReceipt` (typed)
- **ParsedReceipt.toReceipt()** converts intermediate → persisted model (schema-driven)
- **@Query** for reactive SwiftData lists in SwiftUI
- **@Observable** ViewModel pattern (not ObservableObject)

## Do

- Read `Models/` BEFORE writing any code
- Define schemas/models BEFORE writing logic or views
- Keep all data local (SwiftData, no network calls)
- Use Swift 6 concurrency (async/await, actors)
- Use Swift Testing (@Test) for new tests
- Add AI-NOTE/AI-TODO comments where OCR logic is non-obvious
- Use enums for categories and types, never raw strings
- Put ALL domain types in `Models/`, not in service files

## Don't

- Don't add cloud sync or network calls
- Don't use UIKit directly (wrap in UIViewControllerRepresentable)
- Don't use ObservableObject (use @Observable instead)
- Don't hardcode currency (use receipt.currency field)
- Don't work with untyped data — always go through schemas
- Don't define domain types outside `Models/` — services only contain logic
- Don't pass raw `[String]` between components — use `OCRResult`

## PRD

Full requirements: `docs/prd.md`
