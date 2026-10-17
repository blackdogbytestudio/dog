@tool
class_name DogApiMerge
extends RefCounted
## Pure text merge behind the `api` command: no file or editor access here.
##
## `blocks` is an Array of Dictionaries {"kind", "name", "text"}:
## - "func" (default when "kind" is missing): `text` is the full func, no trailing newline.
## - "var" / "signal": `text` is the one-line declaration.
## - "ready_line": `text` is one indented line that must exist inside `_ready`
##   (`_ready` is created when missing). `name` is only used in the report.
##
## Modes:
## - ADD (default): add what is missing, matching by name only.
## - UPDATE (-u): ADD, plus replace existing func/var/signal whose text differs.
##   If a func that would be replaced looks cut in the middle, nothing changes and
##   `error` says which func and "line N" (1-based line of its `func`).
## - FORCE (-f): keep the header and rewrite everything below it.
##
## New items are appended: signals, vars, `_ready`, funcs.
## Returns {"source": String, "report": Array[String], "error": String}.

enum Mode { ADD, UPDATE, FORCE }

## A top-level line that starts a new declaration (so it can't be part of a body).
const DECLARATION := "^(@|##|(static\\s+func|func|var|const|signal|enum|class_name|class|extends)\\b)"
## Lines that belong to the top of the file, above the members.
const HEADER_LINE := "^(@tool|@icon|@static_unload|class_name|extends)\\b"
const APPEND_ORDER := ["signal", "var", "ready", "func"]


static func merge(source: String, blocks: Array, mode := Mode.ADD) -> Dictionary:
	var lines := source.split("\n")
	if mode == Mode.FORCE:
		lines = _trim_blank_tail(lines.slice(0, _header_end(lines)))
		if not lines.is_empty():
			lines.append("")
		mode = Mode.ADD

	var report := []
	var buckets := {"signal": [], "var": [], "ready": [], "func": []}
	var to_replace: Array = []
	var connects_to_insert := PackedStringArray()
	var ready_lines_to_create := PackedStringArray()
	var ready_start := _find(lines, "func", "_ready")

	# Pass 1 only reads: classify every block and validate before touching anything.
	for block in blocks:
		var kind: String = block.get("kind", "func")
		var block_name: String = block["name"]
		var text: String = block["text"]
		var label := "%s %s" % [_word(kind), block_name]

		if kind == "ready_line":
			if ready_start == -1:
				if ready_lines_to_create.is_empty():
					report.append("add func _ready")
				ready_lines_to_create.append(text)
				report.append("add " + label)
				continue
			if not lines[ready_start].strip_edges().ends_with(":"):
				return _error(source, "func _ready (line %d) has its body on the same line: can't add lines under it" % (ready_start + 1))
			if _has_line(lines, ready_start, text):
				report.append("skip " + label)
			else:
				connects_to_insert.append(text)
				report.append("add " + label)
			continue

		var start := _find(lines, kind, block_name)
		if start == -1:
			buckets[kind].append(block)
			report.append("add " + label)
			continue

		if mode == Mode.UPDATE:
			var span := _span_for(kind, lines, start)
			var bad_line: int = span["bad_line"]
			if bad_line != -1:
				return _error(source, "func %s (line %d) looks cut in the middle: line %d is neither a declaration nor part of its body" % [block_name, start + 1, bad_line + 1])
			var end: int = span["end"]
			if "\n".join(lines.slice(start, end + 1)) != text:
				to_replace.append(block)
				report.append("update " + label)
				continue
		report.append("skip " + label)

	# Pass 2 writes. Replace first (positions shift, so find again every time).
	for block in to_replace:
		var kind: String = block.get("kind", "func")
		var text: String = block["text"]
		var start := _find(lines, kind, block["name"])
		var end: int = _span_for(kind, lines, start)["end"]
		lines = lines.slice(0, start) + text.split("\n") + lines.slice(end + 1)

	if not connects_to_insert.is_empty():
		var at := _find(lines, "func", "_ready") + 1
		lines = lines.slice(0, at) + connects_to_insert + lines.slice(at)

	if not ready_lines_to_create.is_empty():
		buckets["ready"].append({
			"kind": "func",
			"name": "_ready",
			"text": "func _ready() -> void:\n" + "\n".join(ready_lines_to_create),
		})

	var ordered: Array = []
	for rank in APPEND_ORDER:
		ordered.append_array(buckets[rank])
	if not ordered.is_empty():
		lines = _append_blocks(lines, ordered)

	return {"source": "\n".join(lines), "report": report, "error": ""}


static func _append_blocks(lines: PackedStringArray, ordered: Array) -> PackedStringArray:
	lines = _trim_blank_tail(lines)
	var previous := ""
	for block in ordered:
		var kind: String = block.get("kind", "func")
		var text: String = block["text"]
		var gap := 0
		if previous.is_empty():
			if not lines.is_empty():
				gap = 2 if kind == "func" else 1
		elif kind != previous or kind == "func":
			gap = 2 if kind == "func" else 1
		for _i in gap:
			lines.append("")
		lines.append_array(text.split("\n"))
		previous = kind
	lines.append("")
	return lines


static func _error(source: String, message: String) -> Dictionary:
	return {"source": source, "report": [], "error": message}


static func _word(kind: String) -> String:
	return "connect" if kind == "ready_line" else kind


## Index of the line that declares `block_name`, or -1. Whole-name match:
## `jump` never matches `jump_high`, and a commented-out line doesn't start with
## the keyword.
static func _find(lines: PackedStringArray, kind: String, block_name: String) -> int:
	if kind == "func":
		var prefix := "func %s(" % block_name
		for i in lines.size():
			if lines[i].begins_with(prefix):
				return i
		return -1
	if not block_name.is_valid_identifier():
		return -1
	var pattern := "^signal\\s+%s\\b" % block_name
	if kind == "var":
		pattern = "^(@\\w+(\\([^)]*\\))?\\s+)*var\\s+%s\\b" % block_name
	var re := RegEx.new()
	re.compile(pattern)
	for i in lines.size():
		if re.search(lines[i]) != null:
			return i
	return -1


static func _span_for(kind: String, lines: PackedStringArray, start: int) -> Dictionary:
	if kind == "func":
		return _span(lines, start)
	return {"end": start, "bad_line": -1}


## Is `text` (compared without surrounding whitespace) in the body of the func at `start`?
static func _has_line(lines: PackedStringArray, start: int, text: String) -> bool:
	var wanted := text.strip_edges()
	var end: int = _span(lines, start)["end"]
	for i in range(start + 1, end + 1):
		if lines[i].strip_edges() == wanted:
			return true
	return false


## Where the func starting at `start` ends: the last indented line before the
## first non-blank line without indentation. Blank lines never end it.
## `bad_line` is the line that proves the func was cut in the middle, or -1.
static func _span(lines: PackedStringArray, start: int) -> Dictionary:
	var end := start
	var i := start + 1
	while i < lines.size():
		var line := lines[i]
		if line.strip_edges().is_empty():
			i += 1
			continue
		if line.begins_with("\t") or line.begins_with(" "):
			end = i
			i += 1
			continue
		break

	if i >= lines.size() or _matches(DECLARATION, lines[i]):
		return {"end": end, "bad_line": -1}

	if lines[i].begins_with("#"):
		# A plain column-0 comment is fine between members, but not in the middle
		# of a body: if the next real line is indented, the body went on.
		var j := i + 1
		while j < lines.size() and (lines[j].strip_edges().is_empty() or lines[j].begins_with("#")):
			j += 1
		if j >= lines.size() or not (lines[j].begins_with("\t") or lines[j].begins_with(" ")):
			return {"end": end, "bad_line": -1}

	return {"end": end, "bad_line": i}


## Number of lines that make up the header: everything before the first member.
## A comment counts only when it is detached from the member that follows it.
static func _header_end(lines: PackedStringArray) -> int:
	var end := 0
	for i in lines.size():
		var line := lines[i]
		if line.strip_edges().is_empty():
			continue
		if _matches(HEADER_LINE, line):
			end = i + 1
			continue
		if line.begins_with("#") and _comment_is_detached(lines, i):
			end = i + 1
			continue
		break
	return end


static func _comment_is_detached(lines: PackedStringArray, index: int) -> bool:
	var j := index + 1
	while j < lines.size() and lines[j].begins_with("#"):
		j += 1
	return j >= lines.size() or lines[j].strip_edges().is_empty() or _matches(HEADER_LINE, lines[j])


static func _trim_blank_tail(lines: PackedStringArray) -> PackedStringArray:
	var n := lines.size()
	while n > 0 and lines[n - 1].strip_edges().is_empty():
		n -= 1
	return lines.slice(0, n)


static func _matches(pattern: String, line: String) -> bool:
	var re := RegEx.new()
	re.compile(pattern)
	return re.search(line) != null
