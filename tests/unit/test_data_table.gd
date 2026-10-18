extends GutTest
## The data/*.md table reader (game/config/data_table.gd), ported from the browser game's pool/poolFile.ts cases: rows by
## first column, cells by header, line numbers kept, layout problems reported, never failing.

const TEXT := """# A file

Some prose | with a pipe.

## Replicas

| Key | Name | Energy (J) |
|---|:---:|---:|
| aeg | AEG Rifle | 0.97 |
| pistol | GBB \\| Pistol |
| cyber | Cyber | 1.0 | extra |

| orphan | row | 1 |

```
| Key | Name |
|---|---|
| fenced | no |
```

### Site limits
| Class | Class |
|---|---|
| rifle | 1.2 |
"""


func test_reads_rows_by_key_and_cells_by_header_with_their_lines() -> void:
	var tables := DataTable.read_all(TEXT, "stats.md")
	assert_eq(tables.size(), 2, "the fenced example isn't a table")
	var t := DataTable.find(tables, "Replicas")
	assert_eq(t.line, 7)
	assert_eq(t.headers, PackedStringArray(["Key", "Name", "Energy (J)"]))
	assert_eq(t.rows.size(), 3)
	var aeg := t.row("aeg")
	assert_eq(aeg.line, 9)
	assert_eq(aeg.cell("Energy (J)"), "0.97")
	assert_eq(aeg.cell("No such column"), "")
	assert_eq(t.row("pistol").cell("Name"), "GBB | Pistol", "an escaped pipe is a pipe in the cell")
	assert_eq(t.row("pistol").cell("Energy (J)"), "", "a short row leaves the rest empty")
	assert_null(t.row("orphan"))
	assert_eq(t.where(10), "stats.md:10")
	assert_null(DataTable.find(tables, "Optics"))


func test_reports_layout_problems_with_their_lines() -> void:
	var tables := DataTable.read_all(TEXT, "stats.md")
	var replicas := DataTable.find(tables, "Replicas")
	assert_eq(replicas.problems, ["stats.md:11: row has 4 cells, the header 3",
			"stats.md:13: row outside its table, so it and the rows after it are not read: a blank line ends a table"] as Array[String])
	var limits := DataTable.find(tables, "Site limits")
	assert_eq(limits.problems, ["stats.md:22: column \"Class\" appears twice"] as Array[String])


func test_never_fails_on_odd_text() -> void:
	assert_eq(DataTable.read_all("", "x.md").size(), 0)
	assert_eq(DataTable.read_all("|", "x.md").size(), 0)
	assert_eq(DataTable.read_all("| a |\n| b |\n#", "x.md").size(), 0, "no separator, no table")
	var crlf := DataTable.read_all("## T\r\n| A | B |\r\n|---|---|\r\n| x | 1 |\r\n", "x.md")
	assert_eq(crlf[0].row("x").cell("B"), "1", "Windows line ends")


func test_reads_numbers_as_typed() -> void:
	assert_eq(DataTable.parse_number(" 13 "), 13.0)
	assert_eq(DataTable.parse_number("0.45"), 0.45)
	assert_eq(DataTable.parse_number("−2"), -2.0, "a typed minus sign")
	assert_eq(DataTable.parse_number("–5 %"), -5.0, "a dash and a percent sign")
	for bad: String in ["", "lots", "1,5", "%"]:
		assert_true(is_nan(DataTable.parse_number(bad)), bad)
