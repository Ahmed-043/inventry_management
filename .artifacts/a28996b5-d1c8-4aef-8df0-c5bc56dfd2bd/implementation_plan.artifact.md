# Dashboard Data Consistency Fix

Ensure that both Dashboard Chips and the Sales/Purchase Trend graphs reflect the same data by including transactions that are either fully paid or partially paid (including overdue partially paid ones).

## Proposed Changes

### Database Layer

#### [MODIFY] [dashboard_info.dart](file:///D:/Flutter_Projects/inventry_management/lib/Database/dashboard_info.dart)

- Update `loadDashboardChipData` to filter for transactions that have any payment activity (`payment_status = 'Paid'` or `paid_amount != 0`).
- Update `getDailyPayments` to remove the strict `payment_status = 'Paid'` requirement and include partially paid transactions.
- Update `getMonthlyPayments` to remove the strict `payment_status = 'Paid'` requirement and include partially paid transactions.

## Verification Plan

### Manual Verification
- Verify that the "Total Spending" chip value for "from last month" matches the peak/sum shown in the "Monthly Purchase Trend" graph for that same month.
- Check that purely "Pending" transactions with `paid_amount = 0` are excluded from both to maintain financial accuracy.
