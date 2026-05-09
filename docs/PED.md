# Product Execution Document (PED)
## StockManager Mobile App (Flutter)

## 1) Product Vision
Build a cross-platform mobile application (Android + iOS) for SMEs and retail stores to manage inventory, sales, audits, and profitability with an offline-first design. The app should work fully with local storage for free, while paid plans unlock cloud backup/sync and multi-user collaboration for a single store.

## 2) Target Users
- **Store owner**: needs complete control of stock, reporting, and profit/loss.
- **Cashier / POS operator**: records customer orders quickly and accurately.
- **Inventory manager**: handles stock intake, audits, barcode workflows.
- **Account assistant**: reviews P&L and reconciles daily/weekly/monthly performance.

## 3) Core Outcomes
- Reduce stock mismatches and out-of-stock events.
- Speed up intake and checkout operations.
- Improve financial visibility (margin, profit/loss, shrinkage).
- Support growth from a single-device local setup to multi-user cloud sync.

## 4) Scope Overview
### 4.1 MVP (Free Local-Only)
1. Item type/category management.
2. Item/SKU registration with barcode support.
3. Stock addition:
   - Individual scan + quantity.
   - Bulk add by quantity + addition date.
4. POS / kiosk sales order capture.
5. Automatic stock deduction on completed sales.
6. Stock audit workflows (cycle count and adjustment).
7. Daily/weekly/monthly P&L summaries.
8. Fully local database and local backups.

### 4.2 Phase 2 (Paid Add-on)
1. Cloud backup and cross-device sync.
2. Multi-user under same store (roles + permissions).
3. Conflict handling for offline edits.
4. Advanced analytics dashboards.
5. Optional integrations (printer, accounting export, e-commerce sync).

## 5) Functional Requirements
### 5.1 Store Setup & Authentication
- Create store profile (name, address, currency, timezone, tax settings).
- Free tier: local PIN/biometric lock.
- Paid tier: email/phone auth + role-based user accounts.

### 5.2 Catalog & Item Management
- Create item types/categories and optional subcategories.
- Create items with fields:
  - SKU, barcode, name, description.
  - Cost price, selling price, tax class.
  - Reorder threshold, supplier, unit type (piece, box, kg, etc.).
  - Expiry/batch support (optional at create time).
- Attach multiple barcodes per item where needed.

### 5.3 Stock Intake
- **Single intake mode**: scan barcode, enter qty, choose purchase/addition date.
- **Bulk intake mode**: select item, enter large quantity, set date and optional notes.
- Optional purchase record fields:
  - Supplier, invoice number, unit cost, tax, discounts.
- Stock ledger entries created for every intake transaction.

### 5.4 POS / Sales (Kiosk Mode)
- Fast item lookup (scan barcode, search by name/SKU).
- Cart with quantity controls, discount, tax handling.
- Support multiple payment methods (cash, card, mixed, wallet placeholders).
- Complete sale updates stock atomically.
- Return/refund flow with stock reversion and reason capture.

### 5.5 Audits & Adjustments
- Scheduled cycle count by category/location.
- Full physical count mode.
- Difference calculation between expected and counted stock.
- Adjustment requires reason codes (damage, theft, expiry, correction).
- Audit history with user + timestamp trail.

### 5.6 Reporting & P&L
- Daily, weekly, monthly summaries:
  - Revenue, COGS, gross profit, net estimate.
  - Stock added value, stock sold value, adjustments/shrinkage.
- Filter by date range, category, and user.
- Export to CSV/PDF.

### 5.7 Notifications & Alerts (Useful Added Feature)
- Low-stock alerts.
- Expiry alerts (if expiry tracking enabled).
- Daily close reminder for end-of-day reconciliation.

### 5.8 Backups & Sync
- Free tier: local encrypted backup/restore (file export/import).
- Paid tier: encrypted cloud sync, background sync, version history.
- Merge/conflict policy: latest timestamp + manual resolve screen for critical fields.

## 6) Non-Functional Requirements
- **Offline-first**: all critical actions must work without internet.
- **Performance**: scan-to-result < 500ms on mid-tier devices.
- **Reliability**: ACID-compliant local transaction handling.
- **Security**: encrypted sensitive data, secure auth, audit logs.
- **Scalability target**: up to 100k SKU records per store.
- **Usability**: touchscreen-optimized POS UI.

## 7) Suggested Technical Architecture (Flutter)
### 7.1 Client App
- Flutter (Android + iOS).
- State management: Riverpod or Bloc.
- Local DB: Drift (SQLite) or Isar (fast object DB).
- Barcode scanning: camera-based plugin (e.g., mobile_scanner).
- Local auth: biometrics + PIN.

### 7.2 Data Model (High Level)
- `stores`
- `users`
- `roles_permissions`
- `categories`
- `items`
- `barcodes`
- `stock_ledger`
- `purchases`
- `sales`
- `sale_items`
- `audit_sessions`
- `audit_lines`
- `adjustments`
- `expenses` (added for better net P&L)
- `sync_events`

### 7.3 Cloud Layer (Paid)
- Backend options: Firebase/Supabase/custom API.
- Sync strategy: delta sync with change timestamps + device IDs.
- Store-tenant data partitioning.

## 8) Roles & Permissions (Paid Multi-User)
- **Owner/Admin**: full control.
- **Manager**: inventory + reporting + audit, limited billing settings.
- **Cashier**: POS and basic sale history only.
- **Auditor**: audit and adjustment entry without pricing edits.

## 9) Screens / UX Map
1. Onboarding & store setup.
2. Dashboard (today’s sales, low stock, quick actions).
3. Categories / item management.
4. Add stock (single + bulk).
5. POS kiosk screen.
6. Sales history & returns.
7. Audit sessions and discrepancy review.
8. Reports (daily/weekly/monthly P&L).
9. Settings (backup, users, subscription, integrations).

## 10) Pricing Model (Proposed)
- **Free**:
  - Single device.
  - Local storage only.
  - Core inventory + POS + basic reports.
- **Nominal Paid Plan (monthly/yearly)**:
  - Cloud backup/sync.
  - Multi-user access for one store.
  - Advanced reports and exports.
  - Priority support.

## 11) Analytics & KPIs
- Daily active stores.
- Sales transactions/day.
- Inventory accuracy % (post-audit).
- Stockout incidents.
- Gross margin trend.
- Sync success/failure rates (paid tier).

## 12) Edge Cases to Cover
- Duplicate barcodes.
- Negative stock prevention (configurable override for admin).
- Interrupted sale transaction recovery.
- Timezone/date boundary effects in daily reports.
- Concurrent edits in multi-user sync.
- Device change / app reinstall restore flow.

## 13) Milestone Plan
### Milestone 1 (2–3 weeks)
- Project setup, DB schema, item/category CRUD, local auth.

### Milestone 2 (2–3 weeks)
- Stock intake (single/bulk), barcode workflows, stock ledger.

### Milestone 3 (2–3 weeks)
- POS/kiosk cart, checkout, stock deduction, sale history.

### Milestone 4 (2 weeks)
- Audits, adjustments, reason codes, audit trail.

### Milestone 5 (2 weeks)
- P&L reporting, CSV/PDF export, low-stock alerts.

### Milestone 6 (3–4 weeks, paid tier)
- Cloud sync, multi-user roles, subscription gating.

## 14) QA & Test Strategy
- Unit tests for pricing, stock arithmetic, and P&L calculations.
- Integration tests for sale completion and stock deduction integrity.
- Offline/online sync tests and conflict scenarios.
- Device tests on low-end Android + iPhone models.
- UAT scripts for cashier and owner personas.

## 15) Future Enhancements
- Multi-store support for chain businesses.
- AI demand forecasting and reorder suggestions.
- Supplier purchase order generation.
- WhatsApp/SMS receipt sharing.
- Hardware integrations: thermal printer, barcode scanner gun.

---
This PED can be used as the baseline for backlog creation (epics, user stories, acceptance criteria) and sprint planning.
