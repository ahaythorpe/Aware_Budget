## Paywall — Product IDs & IAP Setup

App Store Connect IAP configuration for GoldMind. **Product IDs use `goldmind_` prefix** (legacy from setup, do not rename — Apple Product IDs are immutable once submitted).

### Subscription Group

- **Group name:** GoldMind Pro
- **Group ID:** 22065055
- **App display name (en-AU):** GoldMind

### Products

| Type | Product ID | Apple ID | Reference Name | Duration | Price (AUD) | Trial |
|---|---|---|---|---|---|---|
| Auto-renew sub | `goldmind_monthly` | 6765996248 | GoldMind Monthly | 1 month | $11.89 | 14-day free intro |
| Auto-renew sub | `goldmind_annual_plan` | — | GoldMind Annual | 1 year | $119 | 14-day free intro |
| Non-consumable | `goldmind_lifetime` | 6765997197 | Gold Mind Life Time | — | $149 | n/a |

### RevenueCat

- **Entitlement:** `pro` — attached to all 3 products
- **API key:** stored in `Services/Paywall.swift` (Apple public key, starts `appl_…`) — pasted at integration time

### Status (as of 2026-05-03)

All 3 products show "Missing Metadata" — needs:
- 1024×1024 promo image (per product)
- Localized display name + description (en-AU)
- Review screenshot
- Pricing confirmed in all regions
- First sub must be submitted alongside a new app version (not standalone)

### Code touchpoints

- `Services/Paywall.swift` — RevenueCat config, `PaywallStore` (`@Observable`), entitlement check
- `Views/PaywallView.swift` — three SKU cards, "Start 14-day free trial" CTA, restore button
- `AwareBudgetApp.swift` — gate: onboarding complete && no `pro` → PaywallView; else HomeView
- Settings → "Manage subscription" deep-link to App Store sub management
