# Rewrite ReportsTable using TableView (two_dimensional_scrollables)

This plan outlines the complete replacement of the current `ReportsTable` architecture (split-scroll with synchronized controllers) with a modern, virtualized 2D table using the `two_dimensional_scrollables` package.

## User Review Required

> [!IMPORTANT]
> The `ReportsTable` API will change: `leftController` and `rightController` will be removed as `TableView` manages scrolling internally. Any parent widgets providing these controllers will need to be updated.

> [!NOTE]
> The category separator logic (horizontal line between categories) will be integrated into the row's styling and height calculation within the `TableView`.

## Proposed Changes

### Reports Module

#### [MODIFY] [reports_table.dart](file:///D:/Flutter_Projects/inventry_management/lib/Home_Page/Reports_Page/reports_table.dart)

- **Remove Old Architecture**: Delete `_FrozenProductColumn`, `_ScrollableDataArea`, `_DataHeader`, `_DataBody`, and manual scroll synchronization logic.
- **Implement `TableView.builder`**:
    - **Row 0**: Header row (Pinned).
    - **Columns 0-2**: Frozen columns (Product, Unit Price, Total Value).
    - **Columns 3+**: Date columns followed by the "Current" stock column.
- **Dynamic Span Builders**:
    - `rowSpanBuilder`: Fixed height for header; fixed height + optional separator offset for data rows.
    - `columnSpanBuilder`: Fixed widths based on `ReportsConstants`.
- **Virtualized `cellBuilder`**:
    - Lazily build cells based on `TableVicinity`.
    - Port existing styling (borders, fonts, colors) and interactive behaviors (taps, mouse cursors).
    - Maintain category change detection for visual separation.
- **Cleanup API**: Simplify `ReportsTable` constructor to only take necessary data.

## Verification Plan

### Automated Tests
- N/A (Manual UI verification is preferred for layout changes).

### Manual Verification
- **Vertical Scrolling**: Verify that the header row remains sticky at the top.
- **Horizontal Scrolling**: Verify that the first 3 columns (Product, Unit Price, Total Value) remain sticky on the left.
- **2D Scrolling**: Verify smooth simultaneous horizontal and vertical scrolling.
- **Data Integrity**: Ensure all product names, prices, values, and daily stock numbers match the source data.
- **Interactions**:
    - Clicking a daily stock cell opens `StockMovements`.
    - Clicking the "Current" stock cell opens `UpdateProductStock`.
    - Mouse cursor changes to pointer on clickable cells.
- **Visuals**:
    - Category separators appear correctly.
    - Borders and background colors match the original design.
    - Grand total value is correctly displayed in the header.
