# StockManager (Flutter)

Offline-first stock management mobile app for Android and iOS, designed for first-time store owners who need simple item setup, stock entry, sales, counting, and backups.

## Included
- Category and item type management.
- Guided home screen with beginner-friendly next steps.
- Item registration (name, SKU, barcode, cost, price) with one or more photos.
- Stock intake (single or bulk quantity with date/note) with bill or delivery photos.
- POS checkout with atomic stock deduction.
- Stock audit with count adjustments, reason, and count photos.
- Daily/weekly/monthly P&L cards.
- Local SQLite persistence.
- Settings screen with storage options for device backups or Google Drive/other apps through the platform share sheet.
- App information menu with version, build, database schema, and storage model details.
- JSON backup export that can be saved locally or shared to Drive, email, WhatsApp, files, and similar apps.

## Tech
- Flutter + Material 3
- SQLite (`sqflite`)
- `intl` for date formatting
- `image_picker` for camera/gallery photos
- `path_provider` for app-local backup/photo storage
- `share_plus` for backup sharing

## Run
```bash
flutter pub get
flutter run
```
