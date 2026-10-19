class_name DataTable
extends RefCounted
## One pipe table out of a hand-edited data file (data/*.md; the browser game's pool/poolFile.ts readTables): its
## heading, its headers and its rows, each with the file line it came from, so a problem is reported as
## "stats.md:57: …". Never throws: what it can't read is listed in `problems`.


## One body row: each cell by its column's header, trimmed.
class Row:
	extends RefCounted
	## The first column's cell (a Key or an ID).
	var key: String = ""
	var cells: Dictionary[String, String] = {}
	## Its line in the file (1-based).
	var line: int = 0

	## The cell under `header`, or "" if the table has no such column.
	func cell(header: String) -> String:
		return cells.get(header, "")


## The nearest `#` heading above the table, without its #s.
var heading: String = ""
var headers: PackedStringArray = PackedStringArray()
var rows: Array[Row] = []
## The line of its header row, and the file's name for messages.
var line: int = 0
var file_name: String = ""
## What is wrong with its layout (a header twice, a row with more cells than the header, rows cut off by a blank line),
## each as "file:line: …".
var problems: Array[String] = []


## Every table in `text`, in file order. A table is a header row, a separator row (`|---|:--:|`) and its body rows, all
## starting with `|`; any other line ends it. Fenced code blocks are skipped. A short row leaves the rest of its cells
## empty; extra cells are dropped and reported. Rows cut off from the table above by blank lines aren't read and are
## reported once (a blank line once dropped every name after it, unsaid).
static func read_all(text: String, file: String) -> Array[DataTable]:
	var tables: Array[DataTable] = []
	var lines := text.split("\n")
	var heading_now := ""
	var fenced := false
	var table: DataTable = null
	var ended: DataTable = null
	var orphans := false
	var i := 0
	while i < lines.size():
		var trimmed := lines[i].strip_edges()
		var line_no := i + 1
		i += 1
		if trimmed.begins_with("```"):
			fenced = not fenced
			table = null
			ended = null
			continue
		if fenced:
			continue
		var head := _heading_of(trimmed)
		if head != "":
			heading_now = head
			table = null
			ended = null
			continue
		if not trimmed.begins_with("|"):
			# Rows after blank lines still look like the table's to whoever edits the file; after prose they don't.
			if table != null:
				ended = table if trimmed == "" else null
			elif trimmed != "":
				ended = null
			table = null
			orphans = false
			continue
		if table != null:
			table._add_row(_cells_of(trimmed), line_no)
		elif i < lines.size() and _is_separator(lines[i].strip_edges()):
			table = DataTable.new()
			table.heading = heading_now
			table.headers = _cells_of(trimmed)
			table.line = line_no
			table.file_name = file
			for c in table.headers.size():
				if table.headers.find(table.headers[c]) != c:
					table.problem(line_no, "column \"%s\" appears twice" % table.headers[c])
			tables.append(table)
			ended = null
			i += 1 # the separator
		elif ended != null and not orphans:
			ended.problem(line_no, "row outside its table, so it and the rows after it are not read: a blank line ends a table")
			orphans = true
	return tables


## The first of `tables` under `heading`, or null.
static func find(tables: Array[DataTable], heading_text: String) -> DataTable:
	for t in tables:
		if t.heading == heading_text:
			return t
	return null


## A number typed in a cell, or NAN if it isn't one. A minus sign typed as − or – reads as -, and a trailing % is
## allowed (the caller decides what it means).
static func parse_number(raw: String) -> float:
	var text := raw.strip_edges()
	if text.begins_with("−") or text.begins_with("–"):
		text = "-" + text.substr(1)
	if text.ends_with("%"):
		text = text.left(-1).strip_edges()
	if text == "" or not text.is_valid_float():
		return NAN
	return text.to_float()


## A comma-separated cell's names, trimmed, empty ones dropped.
static func names(cell: String) -> PackedStringArray:
	var out := PackedStringArray()
	for n in cell.split(","):
		if n.strip_edges() != "":
			out.append(n.strip_edges())
	return out


## The first row whose first column is `row_key`, or null.
func row(row_key: String) -> Row:
	for r in rows:
		if r.key == row_key:
			return r
	return null


func has_column(header: String) -> bool:
	return headers.has(header)


## "file:line" for messages.
func where(line_no: int) -> String:
	return "%s:%d" % [file_name, line_no]


## Records `message` at `line_no` in `problems`.
func problem(line_no: int, message: String) -> void:
	problems.append("%s: %s" % [where(line_no), message])


func _add_row(cells_in: PackedStringArray, line_no: int) -> void:
	var r := Row.new()
	r.line = line_no
	for c in headers.size():
		r.cells[headers[c]] = cells_in[c] if c < cells_in.size() else ""
	r.key = cells_in[0] if cells_in.size() > 0 else ""
	if cells_in.size() > headers.size():
		problem(line_no, "row has %d cells, the header %d" % [cells_in.size(), headers.size()])
	rows.append(r)


## A heading line's text (`## Replicas` → "Replicas"), or "" for any other line.
static func _heading_of(trimmed: String) -> String:
	var hashes := 0
	while hashes < trimmed.length() and trimmed[hashes] == "#":
		hashes += 1
	if hashes == 0 or hashes > 6 or hashes >= trimmed.length() or not (trimmed[hashes] in [" ", "\t"]):
		return ""
	return trimmed.substr(hashes).strip_edges()


## The cells of a `| a | b |` line, trimmed; the outer pipes are optional and an escaped `\|` is a pipe inside a cell, as
## GitHub reads them.
static func _cells_of(trimmed: String) -> PackedStringArray:
	const ESCAPED := "\u0001"
	var body := trimmed.strip_edges().replace("\\|", ESCAPED)
	if body.begins_with("|"):
		body = body.substr(1)
	if body.ends_with("|"):
		body = body.left(-1)
	var out := PackedStringArray()
	for c in body.split("|"):
		out.append(c.replace(ESCAPED, "|").strip_edges())
	return out


## A header's separator line: every cell `---`, `:--`, `--:` or `:-:` (three dashes or more).
static func _is_separator(trimmed: String) -> bool:
	if not trimmed.begins_with("|"):
		return false
	for c in _cells_of(trimmed):
		var dashes := c.trim_prefix(":").trim_suffix(":")
		if dashes.length() < 3 or dashes.replace("-", "") != "":
			return false
	return true
