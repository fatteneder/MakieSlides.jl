using MakieSlides
using Markdown
using GLMakie

f = Figure()

md = md"""
| Region  | Rep      | Item   | Units  | Unit Cost | Total     |
|:--------|:---------|:-------|-------:|----------:|----------:|
| East    | Jones    | Pencil |      95|  1.99     |    189.05 |
| Central | Kivell   | Binder |      50|  19.99    |    999.50 |
| Central | Jardine  | Pencil |      36|  4.99     |    179.64 |
| Central | Gill     | Pen    |      27|  19.99    |    539.73 |
| West    | Sorvino  | Pencil |      56|  2.99     |    167.44 |
| East    | Jones    | Binder |      60|  4.99     |    299.40 |
| Central | Andrews  | Pencil |      75|  1.99     |    149.25 |
| Central | Jardine  | Pencil |      90|  4.99     |    449.10 |
| West    | Thompson | Pencil |      32|  1.99     |     63.68 |
| East    | Jones    | Binder |      60|  8.99     |    539.40 |
| Central | Morgan   | Pencil |      90|  4.99     |    449.10 |
| East    | Howard   | Binder |      29|  1.99     |     57.71 |
| East    | Parent   | Binder |      81|  19.99    |  1,619.19 |
| East    | Jones    | Pencil |      35|  4.99     |    174.65 |
| Central | Smith    | Desk   |       2|  125.00   |    250.00 |
| East    | Jones    | Pen Set|      16|  15.99    |    255.84 |
| Central | Morgan   | Binder |      28|  8.99     |    251.72 |
| East    | Jones    | Pen    |      64|  8.99     |    575.36 |
| East    | Parent   | Pen    |      15|  19.99    |    299.85 |
| Central | Kivell   | Pen Set|      96|  4.99     |    479.04 |
| Central | Smith    | Pencil |      67|  1.29     |     86.43 |
| East    | Parent   | Pen Set|      74|  15.99    |  1,183.26 |
| Central | Gill     | Binder |      46|  8.99     |    413.54 |
| Central | Smith    | Binder |      87|  15.00    |  1,305.00 |
| East    | Jones    | Binder |       4|  4.99     |     19.96 |
| West    | Sorvino  | Binder |       7|  19.99    |    139.93 |
| Central | Jardine  | Pen Set|      50|  4.99     |    249.50 |
| Central | Andrews  | Pencil |      66|  1.99     |    131.34 |
| East    | Howard   | Pen    |      96|  4.99     |    479.04 |
| Central | Gill     | Pencil |      53|  1.29     |     68.37 |
| Central | Gill     | Binder |      80|  8.99     |    719.20 |
| Central | Kivell   | Desk   |       5|  125.00   |    625.00 |
"""

@time fmttbl = FormattedTable(f[1,1], md)

f
