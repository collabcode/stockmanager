# StockManager (Flutter)

Phase 1 implementation of an offline-first stock management mobile app for Android and iOS.

## Included in Phase 1 (Free Local Storage)
- Category and item type management.
- Item registration (name, SKU, barcode, cost, price).
- Stock intake (single or bulk quantity with date/note).
- POS checkout with atomic stock deduction.
- Stock audit with count adjustments.
- Daily/weekly/monthly P&L cards.
- Local SQLite persistence only.

## Tech
- Flutter + Material 3
- SQLite (`sqflite`)
- `intl` for date formatting

## Run
```bash
flutter pub get
flutter run
```
