class_name ReportScrub
extends RefCounted
## Takes what names the player or their machine out of a report's lines (SV4), since a report may go into a public
## issue: the save folder's path becomes "<save folder>", the home folder "~", the account name "<you>" (as a whole word,
## min_name_chars or more; in any user folder too, whoever's), the machine's name "<machine>" (a full name and its
## first part), a OneDrive for Business folder's organisation "<organisation>", and network and e-mail addresses
## "<address>" (IPv4, IPv6 in any of its forms, MAC, e-mail). Paths match with either slash and in any case (Windows' and
## Linux' alike, and log lines name them both ways). Built once with its names (`for_this_machine`, or injected by
## tests); `line` per line. Over-scrubs rather than leaks.

const SAVE_FOLDER := "<save folder>"
const HOME := "~"
const YOU := "<you>"
const MACHINE := "<machine>"
const ORGANISATION := "<organisation>"
const ADDRESS := "<address>"
## Unicode letters for \w and case-insensitive, so "Jöe" and "JÖE" are one name.
const UNICODE := "(*UCP)(?i)"
## A path starts where no word, dot or dash runs into it ("/var/home/bob" is not "/home/bob").
const PATH_START := r"(?<![\w.\-])"
## A path ends at a separator, a space, a quote or bracket, a comma or colon, or a full stop that ends a sentence.
const PATH_END := r"(?![^\\/\s\"'()\[\],:;.]|\.\w)"
## A user folder on Windows (C:\Users\name) or Linux and macOS (/home/name, /Users/name): its name is someone's account.
## The name may hold spaces ("Jo Bloggs") when a separator follows it; else it ends at a space, a bracket or a comma,
## and never on a full stop.
const USER_FOLDER := r"(*UCP)(?i)(?<![\w.\-])((?:\b[a-z]:)?[\\/]+(?:users|home|documents and settings)[\\/]+)" \
		+ r"(?:[^\\/:*?\"<>|\[\]()\r\n]+(?=[\\/])|[^\\/\s:*?\"<>|\[\](),;]*[^\\/\s:*?\"<>|\[\](),;.])"
## A OneDrive for Business folder is named after the employer: "OneDrive - Contoso Ltd".
const ONEDRIVE := r"(?i)(OneDrive - )[^\\/:*?\"<>|\r\n]+"
const OCTET := r"(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)"
const HEX := r"[0-9a-f]{1,4}"
## A full stop may follow an address (the end of a sentence), never another number.
const IPV4 := r"(?<![\d.])(?:" + OCTET + r"\.){3}" + OCTET + r"(?!\d|\.\d)"
## Every IPv6 form: full, compressed ("2001:db8::1", "fe80::1ff:fe23:4567:890a", "::ffff:c0a8:105") and with an IPv4
## tail ("::ffff:1.2.3.4"). It holds a digit, so a C++ name ("Face::bad") isn't one; clocks have no "::" and too few
## groups.
const IPV6 := r"(?i)(?<![\w:.])(?=[0-9a-f:.]*\d)(?:" \
		+ r"(?:[0-9a-f]{0,4}:){2,6}" + OCTET + r"(?:\." + OCTET + r"){3}(?!\d|\.\d)" \
		+ r"|(?:" + HEX + r":){7}" + HEX \
		+ r"|(?:" + HEX + r":){1,6}:" + HEX \
		+ r"|(?:" + HEX + r":){1,5}(?::" + HEX + r"){1,2}" \
		+ r"|(?:" + HEX + r":){1,4}(?::" + HEX + r"){1,3}" \
		+ r"|(?:" + HEX + r":){1,3}(?::" + HEX + r"){1,4}" \
		+ r"|(?:" + HEX + r":){1,2}(?::" + HEX + r"){1,5}" \
		+ r"|" + HEX + r":(?::" + HEX + r"){1,6}" \
		+ r"|:(?::" + HEX + r"){1,7}" \
		+ r"|(?:" + HEX + r":){1,7}:" \
		+ r")(?![\w:])"
const MAC := r"(?i)(?<![0-9a-f:-])(?:[0-9a-f]{2}[:-]){5}[0-9a-f]{2}(?![0-9a-f:-])"
const EMAIL := r"(*UCP)[\w.+-]+@[\w-]+(?:\.[\w-]+)+"
## The characters a regular expression gives a meaning to, escaped in a name or path.
const SPECIAL := "\\^$.|?*+()[]{}"

var _paths: Array[RegEx] = []
var _path_words: PackedStringArray = []
var _names: Array[RegEx] = []
var _name_words: PackedStringArray = []
var _user_folder := RegEx.create_from_string(USER_FOLDER)
var _onedrive := RegEx.create_from_string(ONEDRIVE)
var _email := RegEx.create_from_string(EMAIL)
## IPv6 before IPv4, so an IPv4 tail goes with its address.
var _addresses: Array[RegEx] = [RegEx.create_from_string(IPV6), RegEx.create_from_string(IPV4),
		RegEx.create_from_string(MAC)]


## `save_folder` (OS.get_user_data_dir), `home`, `account` and `machine` as this machine gives them ("" for one not
## known); names shorter than `min_chars` are taken out of paths only. A machine's full name ("box.corp.example") goes
## and so does its first part ("box").
func _init(save_folder: String = "", home: String = "", account: String = "", machine: String = "",
		min_chars: int = 3) -> void:
	_add_path(save_folder, SAVE_FOLDER)
	_add_path(home, HOME)
	var names: Array[PackedStringArray] = [PackedStringArray([account, YOU]), PackedStringArray([machine, MACHINE])]
	var short := machine.get_slice(".", 0)
	if short != machine:
		names.append(PackedStringArray([short, MACHINE]))
	# The longer name first, so a machine named after its owner ("zandra-laptop") goes whole.
	names.sort_custom(func(a: PackedStringArray, b: PackedStringArray) -> bool: return a[0].length() > b[0].length())
	for n in names:
		_add_name(n[0], n[1], min_chars)


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


## `text` with the folders, names and addresses taken out. E-mail addresses go before the names, so "<you>@domain"
## never stays behind.
func line(text: String) -> String:
	var out := text
	for i in _paths.size():
		out = _paths[i].sub(out, _path_words[i], true)
	out = _user_folder.sub(out, "$1" + YOU, true)
	out = _onedrive.sub(out, "$1" + ORGANISATION, true)
	out = _email.sub(out, ADDRESS, true)
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


## A folder: matched with either slash between its parts and in any case, with or without a slash after it, never as
## the tail of a longer path.
func _add_path(path: String, word: String) -> void:
	var parts := PackedStringArray()
	for part in path.replace("\\", "/").split("/", false):
		parts.append(_escaped(part))
	if parts.is_empty():
		return
	var lead := r"[\\/]+" if path.begins_with("/") or path.begins_with("\\") else ""
	_paths.append(RegEx.create_from_string(UNICODE + PATH_START + lead + r"[\\/]+".join(parts) + PATH_END))
	_path_words.append(word)


## A name, as a whole word in any case; none shorter than `min_chars`.
func _add_name(name: String, word: String, min_chars: int) -> void:
	if name.length() < min_chars:
		return
	_names.append(RegEx.create_from_string(UNICODE + r"(?<!\w)" + _escaped(name) + r"(?!\w)"))
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
