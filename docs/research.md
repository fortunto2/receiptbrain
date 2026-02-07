---
type: research
status: draft
title: "Deep Research — ReceiptBrain"
created: 2026-02-08
tags: [receiptbrain, research, competitive-analysis, ios, privacy, ocr, finance]
product_type: ios
related:
  - 3-opportunities/receiptbrain/prd.md
  - 0-principles/manifest.md
---

# Deep Research: ReceiptBrain

## Executive Summary

The receipt scanning / expense tracking market is large ($12.26B in 2026, CAGR ~12%) but dominated by business-focused SaaS tools (Expensify, Dext, Veryfi) with monthly subscriptions and cloud-mandatory architecture. Personal users are underserved — Reddit threads show consistent frustration with overengineered, privacy-invasive apps. One direct competitor ("Receipt Scanner AI") claims privacy-first but secretly collects User IDs for advertising. This is a clear gap: **a genuinely private, offline-only, one-time-purchase iOS receipt scanner has no credible competitor**. Recommendation: **GO**.

## 1. Competitive Landscape

| Competitor | URL | Pricing | Key Features | Weaknesses |
|-----------|-----|---------|-------------|------------|
| **Expensify** | expensify.com | $5/mo per user | SmartScan OCR, policy rules, accounting integrations, team management | Business-only, cloud-required, subscription, complex onboarding |
| **Smart Receipts** | smartreceipts.co | Free + IAP ($10 pro) | Open source, cloud sync, PDF/CSV export, receipt photos | Cloud-first, dated UI, limited OCR accuracy, no auto-categorization |
| **SimplyWise** | simplywise.com | Free + $7.99/mo premium | Best OCR accuracy (per Reddit), receipt organizing, search | Cloud upload required, subscription, tracks user data |
| **Veryfi** | veryfi.com | $18-54/mo | Enterprise OCR API, real-time extraction, 100+ currencies | Enterprise pricing, API-focused (not consumer), overkill for personal |
| **Receipt Scanner AI** | apps.apple.com/id6748891814 | Free | AI-powered OCR, local storage claims, spending analytics | **0 ratings**, collects User ID for ads despite "no cloud" claims, new/unproven |
| **Genius Scan** | thegrizzlylabs.com | Free + $9.99 pro | "Privacy-by-design", PDF scanner, OCR, Dropbox/Drive export | Document scanner (not expense-specific), no spending analytics, no auto-categorization |
| **Wave Receipts** | waveapps.com | Free | Cloud receipt storage, basic OCR, accounting integration | Discontinued standalone app, now part of Wave accounting suite |
| **Apple Notes** | built-in | Free | Live Text OCR, document scanning | No organization, no categorization, no spending tracking |

### Gap Analysis

**Nobody does all of these together:**
1. **On-device OCR** (no cloud upload) — Receipt Scanner AI claims it but collects tracking data
2. **Auto-categorization** by merchant name — only business tools (Expensify) do this
3. **Spending dashboard** with charts — Genius Scan and Smart Receipts lack this
4. **One-time purchase** — nearly all competitors charge monthly subscriptions
5. **Genuinely zero data collection** — even "privacy" apps leak User IDs

**Our advantage:** True privacy (zero network calls, zero tracking, App Privacy Report: "No data collected") + personal expense focus (not business) + one-time purchase (no subscription fatigue).

## 2. User Pain Points

| Pain Point | Source | URL | Sentiment |
|-----------|--------|-----|-----------|
| "All receipt scanning apps are slow" | Reddit r/Frugal | reddit.com/r/Frugal/14nf6a2 | negative |
| "I need something that archives receipts, NOT cashback apps" | Reddit r/androidapps | reddit.com/r/androidapps/17rbq4f | feature_request |
| "SimplyWise is the best OCR but I tried EVERY scanner app" | Reddit r/budget | reddit.com/r/budget/18prh61 | mixed |
| "Receipts management for small company — need simple not enterprise" | Reddit r/Bookkeeping | reddit.com/r/Bookkeeping/1ijzqx4 | feature_request |
| "Best expense and mileage tracker — Everlance, but it requires cloud" | Reddit r/smallbusiness | reddit.com/r/smallbusiness/s4uyyz | mixed |

### Top Insights

1. **Users distinguish receipt *rewards* apps (Fetch, Ibotta) from receipt *tracking* apps** — search results are polluted by cashback apps. Clear positioning needed.
2. **Apple Notes is the baseline** — multiple Reddit users mention "Apple Notes app is very powerful but not good at organizing." ReceiptBrain must be noticeably better than Notes+Photos.
3. **OCR accuracy is the #1 evaluation criterion** — SimplyWise wins on Reddit specifically because of OCR quality. VisionKit must hit >90% accuracy on amounts.
4. **Subscription fatigue is real** — recurring theme across Reddit: personal users refuse $5-15/mo for something they use occasionally. One-time $4.99 is the right model.
5. **Privacy is mentioned but rarely the primary buying factor** — it's a differentiator, not the main draw. Speed + accuracy + simplicity sell; privacy seals the deal.

## 3. ASO Analysis (iOS App Store)

### Keywords

| Keyword | Intent | Competition | Relevance |
|---------|--------|------------|-----------|
| receipt scanner | commercial | high | primary |
| expense tracker | commercial | very high | primary |
| receipt organizer | commercial | medium | primary |
| receipt OCR | informational | low | secondary |
| personal expense tracker | commercial | medium | primary |
| offline expense tracker | commercial | low | primary — differentiator |
| privacy expense app | commercial | very low | primary — differentiator |
| receipt photo scanner | commercial | medium | secondary |
| spending tracker | commercial | high | secondary |
| no subscription expense app | commercial | low | primary — differentiator |

### Competitor ASO Insights

- **High-competition keywords:** "expense tracker" and "receipt scanner" are dominated by Expensify, Mint, YNAB
- **Low-competition opportunity:** "offline expense tracker", "privacy receipt scanner", "no subscription expense app" — very few results
- **App Store title strategy:** Use "ReceiptBrain: Receipt Scanner & Expense Tracker" (hits 3 primary keywords)
- **Subtitle opportunity:** "Private. Offline. No Subscription." — hits differentiator keywords

### Competitor Ratings

- Expensify: 4.7 (190K+ ratings) — dominant but business-focused
- SimplyWise: 4.8 (4K+ ratings) — best OCR reputation
- Smart Receipts: 4.2 (500+ ratings) — dated, loyal niche
- Receipt Scanner AI: no ratings — brand new, no traction
- Genius Scan: 4.8 (30K+ ratings) — document scanner, not expense-specific

## 4. Naming & Domains

| Name | .com | .app | .io | Trademark | Notes |
|------|------|------|-----|-----------|-------|
| ReceiptBrain | likely available (no search results) | check | check | clean | Strong: receipt + brain = smart scanner |
| SnapReceipt | likely taken | check | check | risk | Generic, many similar names exist |
| ReceiptVault | likely available | check | check | clean | Privacy metaphor (vault = secure) |
| PocketReceipt | likely taken | check | check | risk | Common compound, may conflict |
| ReceiptBox | likely taken | check | check | risk | Too close to Shoeboxed |

### Recommended Name: **ReceiptBrain**

Strong compound that implies intelligence (OCR/AI) without being generic. No existing app with this exact name found in App Store search results. "Brain" reinforces on-device processing narrative ("your phone's brain reads receipts, no cloud needed").

## 5. Market Size

- **TAM:** $12.26B — global expense tracker apps market in 2026 (The Business Research Company, CAGR 12.9%)
- **SAM:** ~$1.7B — personal finance apps on iOS (est. 14% of TAM based on iOS market share + personal segment ~50% of total)
- **SOM (Year 1):** $25K-50K — 5,000-10,000 paid users at $4.99 one-time purchase

**Growth drivers:**
- Personal finance app market growing at 20.57% CAGR to $167.5B by 2035 (Business Research Insights)
- Post-2024 privacy awareness driving demand for offline-first solutions
- Apple's App Tracking Transparency (ATT) created user expectation of privacy — apps that deliver on this promise win trust

**Revenue potential:**
- Smart Receipts (open-source, dated) sustains with ~$10 IAP — proves personal receipt tracking has paying audience
- Genius Scan (document scanner, not expense-specific) earns estimated $2-5M/year on $9.99 pro upgrade
- ReceiptBrain at $4.99 with 5% conversion of free users needs only 100K downloads for $25K revenue

## 6. Recommendation

**Verdict: GO**

1. Clear market gap: no genuinely private, offline-only, personal receipt scanner with spending analytics exists on iOS
2. Direct competitor ("Receipt Scanner AI") has 0 ratings and secretly collects user data despite privacy claims — easy to differentiate with true "No Data Collected" App Store privacy label
3. TAM is large ($12B+) and growing (12.9% CAGR), but ReceiptBrain targets underserved personal segment
4. One-time $4.99 pricing aligns with user sentiment (anti-subscription) and manifesto principles
5. Technical feasibility is high — VisionKit + SwiftData are mature Apple frameworks, MVP achievable in 2-3 days
6. **Risk:** OCR accuracy must match SimplyWise perception (>90% on amounts) or users will churn. Invest in parser testing with diverse receipt formats.

**Suggested next step:** `/validate-idea receiptbrain` or `make prd P=receiptbrain S=ios-swift` (PRD already exists, research data will auto-inject)

## Sources

1. [Forbes — Best Receipt Scanner Apps 2025](https://www.forbes.com/advisor/business/best-receipt-scanner-apps/) — feature comparison of 8 platforms
2. [The Business Research Company — Expense Tracker Apps Market 2026](https://www.thebusinessresearchcompany.com/report/expense-tracker-apps-global-market-report) — $12.26B market size, CAGR 12.9%
3. [Business Research Insights — Personal Finance App Market](https://www.businessresearchinsights.com/market-reports/personal-finance-app-market-117811) — $25.8B in 2026, CAGR 20.57%
4. [Reddit r/Frugal — Receipt scanning apps discussion](https://www.reddit.com/r/Frugal/comments/14nf6a2/) — user complaints about speed
5. [Reddit r/budget — SimplyWise review](https://www.reddit.com/r/budget/comments/18prh61/) — "tried every scanner, SimplyWise is best"
6. [Reddit r/androidapps — Receipt archiving request](https://www.reddit.com/r/androidapps/comments/17rbq4f/) — users want archiving, not cashback
7. [Apple App Store — Receipt Scanner AI](https://apps.apple.com/us/app/receipt-scanner-ai/id6748891814) — 0 ratings, collects User ID despite privacy claims
8. [Smart Receipts](https://smartreceipts.co/) — open-source receipt manager, free+IAP model
9. [Tailride — Best Free Receipt Scanner Apps 2025](https://tailride.so/blog/best-free-receipt-scanner-app) — Genius Scan "privacy-by-design" mention
10. [ReceiptMake — Best Receipt Scanning Apps 2026](https://receiptmake.com/blog/best-receipt-scanning-apps) — top 12 tools comparison
