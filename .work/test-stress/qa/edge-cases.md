# Edge Cases (7)

| # | Edge Case | Ожидаемое поведение |
|---|---|---|
| EC-01 | Title с XSS (`<script>alert('xss')</script>`) | Escaped при отображении |
| EC-02 | Unicode/special chars в title | Корректное хранение |
| EC-03 | Empty description | Опционально, сохраняется как null |
| EC-04 | 1000+ задач в списке | Pagination или virtual scroll |
| EC-05 | Offline queue > 100 items | Warning, sync по batch |
| EC-06 | Network timeout при sync | Retry 3 раза, затем offline |
| EC-07 | Два merge одновременно на одну задачу | Один 200, второй 409 |
