# PixelSpark Design System

## Design Philosophy
Three principles: **Clarity**, **Power**, **Delight**.
- Every feature must be discoverable within 2 taps.
- Every action shows immediate feedback.
- Processing never blocks the UI.

## Color System
- **Primary Navy**: `#1E3A5F`
- **Dark Navy**: `#0D2137`
- **Highlight Cyan**: `#00BCD4`
- **AI Purple**: `#7C3AED`
- **AI Indigo**: `#4F46E5`

## Typography
- **Primary Font**: `Inter` (via google_fonts)
- **Headings**: `Inter 800/700`, Dark Navy / White
- **Body**: `Inter 400/500`, Dark Grey / White70

## Spacing & Layout
- **Grid System**: 8px baseline
- **Padding**: Standard 16px horizontal, 24px for distinct sections.

## Component Library
- **ToolButton**: 4 styles (Primary, Secondary, Ghost, Danger)
- **AdjustmentSlider**: Includes reset option, debounce logic, visual feedback.
- **BeforeAfterSlider**: Interactive touch controls to compare changes.
- **LoadingOverlay**: Custom spinner + shimmering text for AI context.

## HCI Principles Applied
1. **Visibility of system status**: Continuous feedback (LoadingOverlay, SnackBar).
2. **User control**: Undo/Redo readily available.
3. **Consistency**: Uniform `AppTheme` and button styles.
4. **Error prevention**: Dialogs confirm destructive actions.
5. **Recognition over recall**: Icons and visual thumbnails over pure text.
6. **Flexibility**: Prebuilt filters + manual slider controls.
7. **Aesthetic & minimalist**: Clean layouts, high contrast margins.
8. **Help users recover**: Non-destructive edits with `EditHistory`.

## Screen Flows
1. `Splash` -> `Home`
2. `Home` -> `Editor` (Gallery/Camera pick)
3. `Editor` -> `Save Dialog` -> `Home` (after save)

## Accessibility
- Contrast ratios optimized via `AppTheme`.
- Tap targets minimum `44x44`.
- Legible scaling fonts.
