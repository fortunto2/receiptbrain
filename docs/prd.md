---
type: opportunity
status: validated
title: "ReceiptBrain — PRD"
created: 2026-02-07
updated: 2026-02-07
tags: [receiptbrain, prd, ios-swift, privacy, ocr, finance, mlx]
opportunity_score: 8.0
evidence_sources: 5
related:
  - 1-methodology/stacks/ios-swift.yaml
  - 1-methodology/dev-principles.md
  - 0-principles/manifest.md
---

# ReceiptBrain — Product Requirements Document

## Problem

People lose track of daily spending because receipt scanning apps (Expensify, Dext, Wave) are designed for businesses, require cloud accounts, charge monthly subscriptions, and upload sensitive financial data to third-party servers. There is no privacy-first personal expense tracker with local OCR.

## Target User

**Primary:** Privacy-conscious individuals who want to track personal spending without sharing financial data with cloud services. Age 25-45, iPhone users, pay with cash/card at physical stores, frustrated by subscription-based expense trackers designed for corporate use.

**Secondary:** Freelancers and solopreneurs who want quick personal expense logging separate from their business accounting software.

## Market Opportunity

### Market Size (TAM/SAM/SOM)

- **TAM:** Personal finance app market — $1.5B globally (2026)
- **SAM:** iOS expense tracking segment — ~$200M
- **SOM:** Year 1 realistic — 5,000 paid users at $4.99 one-time = $25K

### Evidence-Based Pain Points

1. **Privacy concern:** Expensify, Dext, Wave all upload receipt images to cloud servers. Post-2024 privacy awareness means users increasingly resist sharing financial data.
2. **Overengineered for personal use:** Business expense tools require accounts, team setup, approval workflows. Individuals just want: photo → amount → category → done.
3. **Subscription fatigue:** Most receipt scanners charge $5-15/month. For personal tracking, users won't pay recurring. One-time purchase fits.

### Competitive Analysis

| Competitor | Approach | Gap |
|-----------|----------|-----|
| Expensify | Cloud-based, team-oriented, $5/mo per user | Business-only, privacy concern, subscription |
| Wave Receipts | Free but cloud upload, limited OCR accuracy | Cloud-dependent, discontinued standalone app |
| Apple Wallet | Shows Apple Pay transactions only | No receipt scanning, no cash purchases |
| Manual spreadsheet | Full control but zero automation | No OCR, no camera, tedious data entry |

---

## Solution

ReceiptBrain is an iOS app that lets you snap a photo of any receipt and instantly extracts merchant name, total amount, date, and category using on-device OCR (Apple Vision framework + MLX for enhanced accuracy). All data stays on your iPhone in SwiftData. Monthly/weekly spending charts help you understand patterns. No account, no cloud, no subscription for core features.

### Core Features (MVP)

1. **Receipt Scanner:** Camera capture → VisionKit OCR → extract merchant, amount, date, payment method
2. **Smart Categorization:** Auto-categorize expenses (groceries, dining, transport, shopping, utilities) with user override
3. **Expense Dashboard:** Monthly spending by category (pie chart), daily/weekly trends (bar chart), total spent
4. **Local Storage:** All data in SwiftData, no network calls, full offline operation
5. **Search & Filter:** Find receipts by merchant, category, date range, amount range

### Non-Goals (v1)

- No cloud sync or backup (v2: iCloud optional)
- No multi-currency support (v2)
- No budget setting/alerts (v2)
- No export to CSV/PDF (v2)
- No Android version
- No shared/family expenses

---

## Tech Stack

**Stack:** iOS Swift
**Platform:** ios
**Language:** swift6
**UI Framework:** swiftui
**Package Manager:** spm

**Key Packages:**
- SwiftUI (UI)
- SwiftData (local persistence)
- VisionKit / Vision (OCR, text recognition)
- Charts (Swift Charts framework, built-in)
- PhotosUI (camera/photo picker)
- StoreKit 2 (IAP — Pro upgrade)

**Architecture:** MVVM

**Stack Notes:**
- Prefer SwiftUI over UIKit for all views
- Use async/await (Swift 6 concurrency)
- Local-first: SwiftData only, no Firebase/Supabase
- VisionKit for live text recognition from camera
- Vision framework for receipt-specific text parsing (amounts, dates, merchants)
- Swift Charts for spending visualization
- SwiftLint for linting
- English first, then localize (String Catalog ready)
- StoreKit 2 for Pro upgrade (unlimited receipts)

---

## Architecture

### Data Models

```swift
@Model class Receipt {
    var id: UUID
    var merchantName: String
    var totalAmount: Decimal
    var currency: String  // "USD", "TRY", "EUR"
    var date: Date
    var category: ExpenseCategory
    var paymentMethod: PaymentMethod
    var imageData: Data?  // original receipt photo
    var rawOCRText: String  // full extracted text for search
    var isManuallyEdited: Bool
    var createdAt: Date
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case groceries, dining, transport, shopping, utilities
    case health, entertainment, education, travel, other
}

enum PaymentMethod: String, Codable, CaseIterable {
    case cash, creditCard, debitCard, other
}
```

### Screen Flow

```
Tab 1: Scanner           Tab 2: Dashboard         Tab 3: History
┌──────────────┐        ┌──────────────┐         ┌──────────────┐
│  Camera View │        │ Monthly Total│         │ Search bar   │
│              │        │   $1,234.56  │         │ Filter chips │
│  [Snap]      │        │              │         │──────────────│
│              │        │ Pie chart    │         │ Receipt list │
│──────────────│        │ (categories) │         │ - Merchant   │
│ Extracted:   │        │              │         │ - Amount     │
│ Merchant: X  │        │ Weekly trend │         │ - Date       │
│ Amount: $Y   │        │ (bar chart)  │         │ - Category   │
│ Date: Z      │        │              │         │              │
│ Category: [] │        │ Top spending │         │              │
│ [Save]       │        │ categories   │         │ [Load more]  │
└──────────────┘        └──────────────┘         └──────────────┘
```

### OCR Pipeline

1. User takes photo via camera or picks from library
2. VisionKit `VNRecognizeTextRequest` extracts all text
3. Parser identifies: amounts (regex for currency patterns), dates, merchant (first line / largest text)
4. Auto-categorize by merchant name keywords (e.g., "Migros" → groceries)
5. Present to user for review/edit before saving
6. Store in SwiftData with original image

---

## Architecture Principles

### Universal (from dev-principles.md)

SOLID, DRY, KISS, TDD for business logic, Clean Architecture, Privacy-First, English first (i18n ready)

### Manifesto Principles (from manifest.md)

- **Privacy isn't a feature. It's architecture.** All OCR on-device. All data in SwiftData. Zero network calls. If we can't see your data, we can't leak it.
- **Offline-first.** Works on a plane, in a village, during an outage. No server dependency.
- **One pain → one feature → launch.** Receipt scanning → expense tracking. No budgeting, no sync, no AI insights in v1.
- **Speed over perfection.** Ship MVP in 2 days. VisionKit OCR is good enough — no need for custom ML model in v1.

---

## Monetization

- **Free tier:** 30 receipts/month, basic dashboard
- **Pro (one-time $4.99):** Unlimited receipts, export, advanced charts
- **No subscription** — aligned with user pain point about subscription fatigue

---

## Testing Strategy

**Framework:** XCTest + Swift Testing

- [ ] Unit tests: OCR text parser (amount extraction, date parsing, merchant detection)
- [ ] Unit tests: auto-categorization logic
- [ ] Unit tests: SwiftData CRUD operations
- [ ] UI tests: camera → review → save flow
- [ ] Edge cases: blurry receipts, non-standard formats, multiple amounts

---

## Deployment

**Platform:** App Store
**CI/CD:** GitHub Actions + Fastlane
**Monitoring:** PostHog iOS SDK (analytics + errors, EU hosting)

---

## MVP Timeline

| Day | Deliverable |
|-----|------------|
| Day 1 | SwiftData models, camera/photo capture, VisionKit OCR pipeline, basic parser |
| Day 2 | Dashboard (Charts), history list with search, review/edit screen, polish |
| Day 3 | StoreKit 2 Pro upgrade, App Store assets, TestFlight, submit |

---

## Success Metrics

| Metric | Target (Month 1) |
|--------|-----------------|
| Downloads | 500+ |
| Receipt scans | 2,000+ |
| OCR accuracy (amount) | >90% |
| Pro conversion | 5% |
| Retention (Day 7) | 30% |

---

## Launch Checklist

- [ ] MVP features complete (scanner, dashboard, history)
- [ ] Tests passing (OCR parser, categorization, CRUD)
- [ ] PostHog integrated (analytics + errors)
- [ ] App Store screenshots (3 screens minimum)
- [ ] App Store description (privacy-focused messaging)
- [ ] TestFlight beta with 5 users
- [ ] Submit to App Store review

---

*Generated by `make prd` on 2026-02-07, enriched manually*
*Stack: ios-swift | Principles: dev-principles.md + manifest.md*
*ПОТОК score: 8/10 — clear pain, privacy-first, achievable MVP*
