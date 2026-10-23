class_name ReportScrub
extends RefCounted
## Takes what names the player or their machine out of a report's lines (SV4), since a report may go into a public
## issue: the save folder's path becomes "<save folder>", the home folder "~", the account name "<you>" (as a whole word,
## min_name_chars or more; in any user folder too, whoever's), the machine's name "<machine>", and network and e-mail
## addresses "<address>". Paths match with either slash and in any case (Windows' and Linux' alike, and log lines name
## them both ways). Built once with its names (`for_this_machine`, or injected by tests); `line` per line.

const SAVE_FOLDER := "<save folder>"
const HOME := "~"
const YOU := "<you>"
const MACHINE := "<machine>"
const ADDRESS := "<address>"
## Unicode letters for \w and case-insensitive, so "Jöe" and "JÖE" are one name.
const UNICODE := "(*UCP)(?i)"
## A user folder on Windows (C:\Users\name) or Linux and macOS (/home/name, /Users/name): its name is someone's account.
## The name may hold spaces ("Jo Bloggs") when a separator follows it, else it ends at the first space.
const USER_FOLDER := "(*UCP)(?i)((?:\\b[a-z]:)?[\\\\/]+(?:users|home|documents and settings)[\\\\/]+)" \
		+ "(?:[^\\\\/:*?\"<>|\\r\\n]+(?=[\\\\/])|[^\\\\/\\s:*?\"<>|]+)"
const IPV4 := "(?<![\\d.])(?:(?:25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)\\.){3}(?:25[0-5]|2[0-4]\\d|1\\d\\d|[1-9]?\\d)(?![\\d.])"
const IPV6 := "(?i)(?<![0-9a-f:])(?:[0-9a-f]{1,4}:){7}[0-9a-f]{1,4}(?![0-9a-f:])"
const MAC := "(?i)(?<![0-9a-f:-])(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}(?![0-9a-f:-])"
const EMAIL := "(*UCP)[\\w.+-]+@[\\w-]+(?:\\.[\\w-]+)+"
## The characters a regular expression gives a meaning to, escaped in a name or path.
const SPECIAL := "\\^$.|?*+()[]{}"

var _paths: Array[RegEx] = []
var _path_words: PackedStringArray = []
var _names: Array[RegEx] = []
var _name_words: PackedStringArray = []
var _user_folder := RegEx.create_from_string(USER_FOLDER)
var _addresses: Array[RegEx] = [RegEx.create_from_string(IPV4), RegEx.create_from_string(IPV6),
		RegEx.create_from_string(MAC), RegEx.create_from_string(EMAIL)]


## `save_folder` (OS.get_user_data_dir), `home`, `account` and `machine` as this machine gives them ("" for one not
## known); names shorter than `min_chars` are taken out of paths only.
func _init(save_folder: String = "", home: String = "", account: String = "", machine: String = "",
		min_chars: int = 3) -> void:
	_add_path(save_folder, SAVE_FOLDER)
	_add_path(home, HOME)
	# The longer name first, so a machine named after its owner ("zandra-laptop") goes whole.
	if machine.length() > account.length():
		_add_name(machine, MACHINE, min_chars)
		_add_name(account, YOU, min_chars)
	else:
		_add_name(account, YOU, min_chars)
		_add_name(machine, MACHINE, min_chars)


## This machine's: the save folder, the home folder (USERPROFILE or HOME), the account (USERNAME or USER, else the home
## folder's name) and the machine's name (COMPUTERNAME, HOSTNAME or /etc/hostname).
static func for_this_machine(config: ReportConfig = null) -> ReportScrub:
	var home := _env(["USERPROFILE", "HOME"])
	var account := _env(["USERNAME", "USER", "LOGNAME"])
	if account == "" and home != "":
		account = home.replace("\\", "/").trim_suffix("/").get_file()
	var machine := _env(["COMPUTERNAME", "HOSTNAME"])
	if machine == "" and FileAccess.file_exists("/etc/hostname"):
		machine = FileAccess.get_file_as_string("/etc/hostname").strip_edges()
	var min_chars := config.min_name_chars if config != null else ReportConfig.new().min_name_chars
	return ReportScrub.new(OS.get_user_data_dir(), home, account, machine, min_chars)


## `text` with the folders, names and addresses taken out.
func line(text: String) -> String:
	var out := text
	for i in _paths.size():
		out = _paths[i].sub(out, _path_words[i], true)
	out = _user_folder.sub(out, "$1" + YOU, true)
	for i in _names.size():
		out = _names[i].sub(out, _name_words[i], true)
	for r in _addresses:
		out = r.sub(out, ADDRESS, true)
	return out


## Every line of `texts`, scrubbed.
func lines(texts: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	out.resize(texts.size())
	for i in texts.size():
		out[i] = line(texts[i])
	return out


## A folder: matched with either slash between its parts and in any case, with or without a slash after it.
func _add_path(path: String, word: String) -> void:
	var parts := PackedStringArray()
	for part in path.replace("\\", "/").split("/", false):
		parts.append(_escaped(part))
	if parts.is_empty():
		return
	var lead := "[\\\\/]+" if path.begins_with("/") or path.begins_with("\\") else ""
	_paths.append(RegEx.create_from_string("%s%s%s(?![^\\\\/\\s\"'),:;])" % [UNICODE, lead, "[\\\\/]+".join(parts)]))
	_path_words.append(word)


## A name, as a whole word in any case; none shorter than `min_chars`.
func _add_name(name: String, word: String, min_chars: int) -> void:
	if name.length() < min_chars:
		return
	_names.append(RegEx.create_from_string("%s(?<!\\w)%s(?!\\w)" % [UNICODE, _escaped(name)]))
	_name_words.append(word)


static func _escaped(text: String) -> String:
	var out := ""
	for c in text:
		out += "\\" + c if SPECIAL.contains(c) else c
	return out


static func _env(names: PackedStringArray) -> String:
	for n in names:
		var v := OS.get_environment(n).strip_edges()
		if v != "":
			return v
	return ""
