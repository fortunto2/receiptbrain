# ReceiptBrain — Features v2 Plan

Created: 2026-02-08

## Quick Wins (easy, high impact)

### 1. VNDocumentCameraViewController
Replace UIImagePickerController with document scanner. Auto-crop, perspective correction, multi-page receipts. OCR quality jumps significantly.
- **Files:** CameraView.swift (rewrite), ScannerView.swift
- **Effort:** 30 min

### 2. Widgets (WidgetKit)
Home screen widget showing "spent this week/month" summary. Family can see without opening the app.
- **Files:** NEW ReceiptBrainWidget/ target
- **Effort:** 2-3 hours

### 3. Spotlight Search (CSSearchableItem)
Receipts indexed in system Spotlight. Search "Migros" from home screen → jump to receipt.
- **Files:** ScannerViewModel.swift (index on save), ReceiptBrainApp.swift (handle activity)
- **Effort:** 1 hour

### 4. App Intents / Siri
"How much did I spend today?" via Siri. iOS 17+ App Intents.
- **Files:** NEW Intents/SpendingIntent.swift
- **Effort:** 1-2 hours

## Medium (day of work, strong improvement)

### 5. Local Merchant Database
JSON with ~500 merchants (name → category, logo URL). Fuzzy match on OCR result. Category accuracy 95%+.
- **Files:** NEW merchants.json, MerchantDatabase.swift service
- **Effort:** 3-4 hours

### 6. CreateML Text Classifier
Train model on ~1000 receipts: "receipt text → category". CoreML, offline, faster than regex. Can bootstrap from own receipts.
- **Files:** NEW ReceiptClassifier.mlmodel, CategoryClassifier.swift
- **Effort:** 4-6 hours (including data collection)

### 7. Natural Language Framework
NLTagger for Named Entity Recognition. Better merchant names, addresses, amounts extraction than regex.
- **Files:** ReceiptParser.swift (enhance with NL framework)
- **Effort:** 2-3 hours

## Advanced (complex, powerful)

### 8. Foundation Models (iOS 18.4+)
Apple's on-device LLM. Feed full OCR text → extract merchant, amount, items. Kills entire regex parser, 99% accuracy. Requires min iOS 18.4.
- **Files:** NEW LLMParser.swift, ReceiptParser.swift (fallback for older iOS)
- **Effort:** 4-6 hours

### 9. Export PDF
Monthly report with charts, receipt list, totals by category. PDFKit generation.
- **Files:** NEW PDFExportService.swift, ExportView.swift
- **Effort:** 3-4 hours

## Implementation Status

- [x] 1. VNDocumentCameraViewController — CameraView.swift rewritten
- [x] 2. Natural Language framework — NER in ReceiptParser.swift
- [x] 3. Spotlight Search — CoreSpotlight in ScannerViewModel.swift
- [x] 4. App Intents / Siri — SpendingIntents.swift
- [x] 5. Widgets — ReceiptBrainWidget/ target with small+medium views
- [x] 6. Merchant Database — merchants.json + MerchantDatabase.swift (150+ merchants, fuzzy match)
- [x] 7. Export PDF — PDFExportService.swift + ExportView.swift
- [ ] 8. CreateML Classifier (needs training data)
- [ ] 9. Foundation Models (when iOS 18.4 is min target)

## From PRD (still TODO)

- [ ] StoreKit 2 IAP (Pro tier)
- [ ] PostHog analytics
- [x] Tests (parser + merchant DB tests)
- [ ] App Store assets
- [ ] TestFlight
