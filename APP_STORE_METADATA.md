# Milli — App Store Metadata

Copy-paste ready for App Store Connect submission.

---

## App Information

| Field | Value |
|---|---|
| **App name** | Milli — Tax Autopilot |
| **Bundle display name** | Milli |
| **Bundle ID** | `app.milli.tax` |
| **SKU** | `milli-ios-001` |
| **Primary language** | English (U.S.) |
| **Category** | Finance |
| **Secondary category** | Business |
| **Age rating** | 4+ (no objectionable content) |
| **Version** | 1.0.0 |
| **Build** | 1 |
| **Minimum iOS** | 16.0 |

## Subtitle (30 char max)

> **Earn freely. Milli handles the tax side.**

## Promotional Text (170 char max, editable without new build)

> Your tax autopilot for the gig economy. Track miles, set aside taxes automatically, and stay ready — every payout, every quarter, every mile.

## Keywords (100 char max, comma-separated, no spaces)

```
tax,mileage,deductions,gig,driver,freelancer,1099,quarterly,autopilot,self-employed,uber,doordash
```

## Description (long-form, 4000 char max)

```
Milli is the tax and mileage autopilot for anyone earning 1099 income.

If you drive for Uber, deliver for DoorDash, freelance on Upwork, sell on
Etsy, or run any kind of self-employed side income — the government still
expects taxes four times a year. Milli takes that anxiety off your plate.

Milli Autopilot™ — every payout, on autopilot.
Every time you get paid, Milli:
• Detects the payout automatically
• Calculates your federal, state, and self-employment tax reserve
• Moves the right amount into your Milli Tax Vault™
• Updates your Available to Spend so you always know what's yours
• Optionally allocates a percentage to retirement, investing, and savings
• Files an immutable, hash-verified Autopilot Receipt™ for your records
• Tells you exactly what happened in plain English

Never again wonder if you've set aside enough for taxes.

Milli Tax Vault™
A dedicated tax reserve, always separate from your everyday cash.
Watch your Tax Ready Score™ climb as Milli protects each payout —
100% means you're fully funded for the next quarterly estimate.

Automatic Mileage Tracking
Milli logs every business drive in the background, using GPS the way
Waze uses it — accurate, low-battery, and always on when you're on a
gig. Classify trips as Business, Medical, Charitable, Personal, or
Commuting and Milli computes your IRS deduction at the current
$0.70/mile business rate.

Quarterly Tax Estimates
Milli projects your annual tax bill using real 2025 IRS brackets,
your filing status, your state, and your business type — then splits
it into the four quarterly estimates and countdowns to each due date
(April 15, June 15, September 15, and January 15).

Expense & Receipt Tracking
Snap a photo of any receipt. AI reads the vendor, amount, and
category, and Milli files it against your Schedule C for tax season.

Milli AI
A financial coach in your pocket. Ask questions, get plain-English
answers, and receive proactive nudges when trips need review, taxes
are underfunded, or a quarter is coming due.

Reports Built for Tax Season
Export your Schedule C summary, mileage log, and expense report as
PDF or CSV — hand them to your accountant or drop them into your
tax software.

Plans:
• Milli Core — Autopilot, Tax Vault, Mileage, Expenses, Reports, Milli AI
• Milli Pro — Everything in Core plus Retirement + Investing automation
• Milli Elite — Everything in Pro plus guided tax preparation and
  approved-partner filing when you're ready to submit

Milli is designed for the way self-employed people actually earn:
irregular, cross-platform, always in motion. We do the paperwork so
you keep driving, delivering, designing, and building.

Start your 3-day free trial. No card required. Cancel anytime.

Milli is not a bank. Banking and tax filing services, when activated,
are provided by approved third-party partners.
```

## Support Text

- **Support URL:** https://milli.tax/support *(placeholder — replace with live URL before submission)*
- **Marketing URL:** https://milli.tax
- **Privacy Policy URL:** https://milli.tax/privacy *(placeholder — required for App Store review)*

## Apple Developer Account

| Field | Value |
|---|---|
| **Apple Developer Team ID** | `W5Q42XNM9V` |
| **Primary Apple ID** | `iwoodby90@gmail.com` |
| **App Store Connect account** | `iwoodby90@gmail.com` |
| **Main app Bundle ID** | `app.milli.tax` |
| **Watch app Bundle ID** | `app.milli.tax.watchkitapp` |
| **Watch complication Bundle ID** | `app.milli.tax.watchkitapp.complication` |
| **Signing style** | Automatic (managed by Xcode) |

These credentials are already injected into
`/app/frontend/ios/App/App.xcodeproj/project.pbxproj` and
`/app/frontend/ios/App/ExportOptions.plist`. When you open the
workspace in Xcode, the correct team will be pre-selected.

## App Review Information

- **Contact first name:** *(fill in)*
- **Contact last name:** *(fill in)*
- **Contact phone:** *(fill in)*
- **Contact email:** iwoodby90@gmail.com
- **Demo account:**
  - Username: `jordan@milli.demo` *(or hit `POST /api/demo/seed` to generate a live one)*
  - Password: `MilliDemo!2026`
- **Review notes** (paste verbatim into the "Notes" field):

> Milli is a tax and mileage autopilot for self-employed workers. Please
> tap "Try demo account" on the sign-in screen to auto-populate a
> pre-seeded user with 40 sample payouts, 28 sample trips, and a fully
> populated Milli Tax Vault™ so you can exercise every feature.
>
> Background location: required for the flagship "auto mileage
> tracking" feature. Trip data is only collected while the user has
> tapped "Start Trip" or has enabled Auto-Detect in Settings, is stored
> exclusively on Milli's own servers, and is never sold or shared.
>
> Milli does not itself hold user funds. The "Tax Vault" is an internal
> ledger view; real ACH banking will be enabled through Stripe Treasury
> in a future submission (currently gated as "coming soon" in the UI).
>
> Real tax filing is not performed by Milli itself. When activated for
> Elite users, filing is executed by an approved third-party e-file
> partner and clearly disclosed to the user before authorization.

## What's New (for updates — leave blank for 1.0.0)

## Data Types Collected (App Privacy)

Fill out App Store Connect > App Privacy > Data Collection:

| Category | Type | Linked to user | Used for tracking | Purpose |
|---|---|:-:|:-:|---|
| Financial Info | Payment Info | ✅ | ❌ | App functionality |
| Financial Info | Other Financial Info | ✅ | ❌ | App functionality |
| Location | Precise Location | ✅ | ❌ | App functionality |
| Contact Info | Email Address | ✅ | ❌ | App functionality |
| Contact Info | Name | ✅ | ❌ | App functionality |
| Identifiers | User ID | ✅ | ❌ | App functionality |
| Usage Data | Product Interaction | ✅ | ❌ | Analytics |
| Diagnostics | Crash Data | ✅ | ❌ | App functionality |

## Encryption Compliance (ITSAppUsesNonExemptEncryption)

Set to `NO` in Info.plist. Milli only uses HTTPS + standard iOS APIs
(no custom cryptography), which qualifies for the export-compliance
exemption. No annual self-classification report needed.

## Screenshots Required

You'll need to upload screenshots for the following device sets:
- **iPhone 6.9"** (15/16/17 Pro Max) — 1290×2796 or 1320×2868 (required)
- **iPhone 6.7"** (14/15 Plus, 15 Pro Max) — 1290×2796 (required)
- **iPad 13"** (iPad Pro M4) — 2064×2752 (only if you support iPad)

Minimum: 3 screenshots per set, maximum 10.

Suggested screenshots (see `/app/marketing_videos/` for reference frames):
1. Dashboard hero — Available to Spend + Tax Ready Score ring
2. Milli Tax Vault™ balance with "Autopilot ✓ Taxes Protected" badge
3. Mileage tracking — live trip + trip list
4. Autopilot Receipt — "$186.24 from Amazon Flex → $42.81 protected"
5. Quarterly Tax Center — next payment + countdown

## In-App Purchase / Subscription (for Pro / Elite)

*(Not required for 1.0.0 — web Stripe handles billing.)* When adding
IAP:
- Product IDs: `milli.core.monthly`, `milli.pro.monthly`, `milli.elite.monthly`
- All auto-renewing subscriptions in a single **Subscription Group**
- Provide privacy policy + terms links on the subscription page
