@tool
extends SceneTree
## Minimaler Plugin-Manager für Godot (gd-plug).
##
## Fork von [url=https://github.com/imjp94/gd-plug]imjp94/gd-plug[/url],
## Original von Tan Jian Ping, MIT-Lizenz. Details zu Befehlen und Optionen stehen in der README.[br]
## Das Skript wird headless als Hauptschleife gestartet:
## [code]godot --headless -s plug.gd <befehl>[/code]
## (Befehle: init, status, install/update, uninstall, clean, upgrade, version).
##
## Die [code]plug.gd[/code] des Projekts erbt von dieser Datei, überschreibt [method _plugging]
## und deklariert dort mit [method plug] die gewünschten Plugins. Optional kann sie
## [method _on_updated] überschreiben, um nach jeder Installation oder Aktualisierung zu reagieren.
## Installierte Plugins werden in [code]res://.plugged/index.cfg[/code] festgehalten.
##
## [codeblock]
## extends "res://addons/gd-plug/plug.gd"
##
## func _plugging() -> void:
##     plug("bitwes/Gut", {"tag": "v9.4.0"})
## [/codeblock]
##
## Intern wird ein Plugin als [Dictionary] geführt mit den Schlüsseln [code]name[/code],
## [code]url[/code], [code]plug_dir[/code], [code]include[/code], [code]exclude[/code],
## [code]branch[/code], [code]tag[/code], [code]commit[/code], [code]dev[/code],
## [code]on_updated[/code], [code]install_root[/code], [code]strip_prefix[/code] und
## nach der Installation [code]dest_files[/code] (Liste der installierten Dateien).
## @tutorial(README): https://github.com/Fox-Alpha/fork-gd-plug#readme

#region Signals
## Wird emittiert, nachdem ein Plugin installiert oder aktualisiert wurde.[br]
## [param plugin] — Kopie des Plugin-Dictionaries inklusive [code]dest_files[/code].
signal updated(plugin: Dictionary)
#endregion

#region Constants
## Version von gd-plug, wird vom Befehl "version" ausgegeben.
const VERSION: String = "0.3.0"
## URL-Vorlage für Kurzangaben der Form "user/repo"; [code]%s[/code] wird durch die Kurzangabe ersetzt.
const DEFAULT_PLUGIN_URL: String = "https://git::@github.com/%s.git"
## Verzeichnis, in das die Plugin-Repositories geklont werden.
const DEFAULT_PLUG_DIR: String = "res://.plugged"
## Pfad der Index-Datei, in der die installierten Plugins gespeichert werden.
const DEFAULT_CONFIG_PATH: String = DEFAULT_PLUG_DIR + "/index.cfg"
## Pfad der plug.gd des Projekts, die vom Befehl "init" angelegt wird.
const DEFAULT_USER_PLUG_SCRIPT_PATH: String = "res://plug.gd"
## Pfad dieses Basisskripts im Projekt. Derzeit ungenutzt.
const DEFAULT_BASE_PLUG_SCRIPT_PATH: String = "res://addons/gd-plug/plug.gd"
## Name der Umgebungsvariable, die den Modus "production" (ohne dev-Plugins) markiert.
const ENV_PRODUCTION: String = "production"
## Name der Umgebungsvariable für den Testmodus (es werden keine Dateien verändert).
const ENV_TEST: String = "test"
## Name der Umgebungsvariable, die das Überschreiben vorhandener Dateien erlaubt.
const ENV_FORCE: String = "force"
## Name der Umgebungsvariable: ".import"-Dateien beim Deinstallieren behalten.
const ENV_KEEP_IMPORT_FILE: String = "keep_import_file"
## Name der Umgebungsvariable: importierte Ressourcen aus ".import" beim Deinstallieren behalten.
const ENV_KEEP_IMPORT_RESOURCE_FILE: String = "keep_import_resource_file"
# Quelle für den Befehl "upgrade": eigener Fork statt imjp94/gd-plug, damit die Änderungen des Forks erhalten bleiben
## Standard-Repository für "upgrade", wenn [constant ENV_UPGRADE_REPO] nicht gesetzt ist.
const DEFAULT_UPGRADE_REPO: String = "Fox-Alpha/fork-gd-plug"
## Standard-Branch für "upgrade", wenn [constant ENV_UPGRADE_BRANCH] nicht gesetzt ist.
const DEFAULT_UPGRADE_BRANCH: String = "development"
# Umgebungsvariablen zum Überschreiben von Repo und Branch beim Aufruf von "upgrade"
## Umgebungsvariable, die das Repository für "upgrade" vorgibt.
const ENV_UPGRADE_REPO: String = "GD_PLUG_UPGRADE_REPO"
## Umgebungsvariable, die den Branch für "upgrade" vorgibt.
const ENV_UPGRADE_BRANCH: String = "GD_PLUG_UPGRADE_BRANCH"
## Meldung der Assertions, die [method _plug_start] als Voraussetzung prüfen.
const MSG_PLUG_START_ASSERTION: String = "_plug_start() must be called first"
## Inhalt der plug.gd, die der Befehl "init" im Projekt anlegt.
const INIT_PLUG_SCRIPT: String = """extends "res://addons/gd-plug/plug.gd"
## Plugins of this project, managed by gd-plug.
##
## Install or update: [code]godot --headless -s plug.gd install[/code][br]
## More commands: [code]godot --headless -s plug.gd help[/code]


## Declares the plugins with [code]plug(repo, args)[/code].
func _plugging() -> void:
	# By default, only the "addons/" directory of a repository is installed:
	#plug("bitwes/Gut")
	# Freeze to a tag, branch or commit:
	#plug("bitwes/Gut", {"tag": "v9.4.0"})
	# Addon nested in another directory (stripped automatically with install_root):
	#plug("hi-godot/godot-ai", {"install_root": "addons/godot_ai", "include": ["plugin/addons/godot_ai/"]})
	pass
"""
#endregion

#region Public Vars
## Zugriff auf das Projektverzeichnis [code]res://[/code], wird in [method _init] geöffnet.
var project_dir: DirAccess
## Konfigurationsdatei [code]res://.plugged/index.cfg[/code] mit den installierten Plugins.
var installation_config := ConfigFile.new()
## Ausgabe von Meldungen auf der Konsole, zählt auch gemeldete Fehler.
var logger := _Logger.new()
## Führt Installationen und Deinstallationen parallel in Threads aus.
var threadpool := _ThreadPool.new(logger)
#endregion

#region Private Vars
# Plugins aus .plugged/index.cfg, Schlüssel ist der Name des Plugins
var _installed_plugins: Dictionary = { }
# Plugins aus plug.gd des Projekts, Schlüssel ist der Name des Plugins
var _plugged_plugins: Dictionary = { }
# Ersetzt die frühere Prüfung von _installed_plugins auf null
var _is_plug_started: bool = false
# Schützt _installed_plugins, weil die Threads des Pools darauf zugreifen
var _mutex := Mutex.new()
# Startzeit in Millisekunden, für die Laufzeitangabe am Ende
var _start_time: int = 0
#endregion


#region Lifecycle
## Richtet Threadpool und Projektverzeichnis ein; beendet das Programm, sobald alle Threads fertig sind.
func _init() -> void:
	threadpool.all_thread_finished.connect(request_quit)
	project_dir = DirAccess.open("res://")


## Einstiegspunkt: wertet die Kommandozeile aus, ruft [method _plugging] auf und führt den Befehl aus.
func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_args()
	# Trim unwanted args passed to godot executable
	for arg in Array(args):
		args.remove_at(0)
		if "plug.gd" in arg:
			break

	var help: bool = false
	var help_config: bool = false
	for arg in args:
		# NOTE: "--key" or "-key" will always be consumed by godot executable,
		# see https://github.com/godotengine/godot/issues/8721
		var key: String = arg.to_lower()
		match key:
			"help":
				help = true
			"help-config":
				help_config = true
			"detail":
				logger.log_format = _Logger.DEFAULT_LOG_FORMAT_DETAIL
			"debug", "d":
				logger.log_level = _Logger.LogLevel.DEBUG
			"quiet", "q", "silent":
				logger.log_level = _Logger.LogLevel.NONE
			"production":
				OS.set_environment(ENV_PRODUCTION, "true")
			"test":
				OS.set_environment(ENV_TEST, "true")
			"force":
				OS.set_environment(ENV_FORCE, "true")
			"keep-import-file":
				OS.set_environment(ENV_KEEP_IMPORT_FILE, "true")
			"keep-import-resource-file":
				OS.set_environment(ENV_KEEP_IMPORT_RESOURCE_FILE, "true")

	logger.debug("cmdline_args: %s" % args)
	_start_time = Time.get_ticks_msec()
	_plug_start()
	if help_config:
		show_config_syntax()
	elif help or args.is_empty():
		show_syntax()
	else:
		_plugging()
		match args[0]:
			"init":
				_plug_init()
			"install", "update":
				_plug_install()
			"uninstall":
				_plug_uninstall()
			"clean":
				_plug_clean()
			"upgrade":
				_plug_upgrade()
			"status":
				_plug_status()
			"version":
				logger.info(VERSION)
			_:
				logger.error("Unknown command %s" % args[0])
				show_syntax()
	# NOTE: Do no put anything after this line except request_quit(), as _plug_*() may call request_quit()
	request_quit()


## Treibt den Threadpool in jedem Frame an.
## [b]return[/b] [bool] — immer [code]false[/code], die Hauptschleife wird nicht beendet.
func _process(delta: float) -> bool:
	threadpool.process(delta)
	return false # Must return false, unless we are terminating.


## Speichert den Index, stoppt den Threadpool und gibt die Laufzeit aus.
func _finalize() -> void:
	_plug_end()
	threadpool.stop()
	logger.info("Finished, elapsed %.3fs" % ((Time.get_ticks_msec() - _start_time) / 1000.0))
#endregion


#region Public Funcs
## Virtuelle Methode: in der plug.gd des Projekts überschreiben und dort [method plug] aufrufen,
## um die gewünschten Plugins zu deklarieren. Wird bei jedem Befehl außer help vor der Ausführung aufgerufen.
func _plugging() -> void:
	pass


## Virtuelle Methode: kann in der plug.gd des Projekts überschrieben werden und wird nach jeder
## Installation oder Aktualisierung eines Plugins aufgerufen (aus einem Thread des Threadpools).[br]
## [param _plugin] — Kopie des Plugin-Dictionaries inklusive [code]dest_files[/code].
func _on_updated(_plugin: Dictionary) -> void:
	pass


## Gibt die Hilfe zu Befehlen und Optionen auf der Konsole aus.
func show_syntax() -> void:
	logger.info("gd-plug - Minimal plugin manager for Godot")
	logger.info("")
	logger.info("Usage: godot --headless -s plug.gd action [options...]")
	logger.info("")
	logger.info("Actions:")
	var actions: Dictionary[String, String] = {
		"init": "Initialize current project by creating plug.gd at root",
		"status": (
			"Check the status of plugins(installed, added or removed), " + "execute this command whenever in doubts"
		),
		"install(alias update)": "Install or update plugins based on plug.gd",
		"uninstall": "Uninstall all plugins, regardless of plug.gd",
		"clean": "Clean unused files/folders from /.plugged",
		"upgrade": (
			"Upgrade addons/gd-plug/plug.gd to the latest version of the fork "
			+ "(GD_PLUG_UPGRADE_REPO, GD_PLUG_UPGRADE_BRANCH)"
		),
		"version": "Print current version of gd-plug",
	}
	_log_table(actions)

	logger.info("")
	logger.info("Options:")
	var options: Dictionary[String, String] = {
		"production": "Install only plugins not marked as dev, or uninstall already installed dev plugins",
		"test": "Testing mode, no files will actually be installed/uninstalled",
		"force": (
			"Force gd-plug to overwrite destination files when running install command. "
			+ "*WARNING: Check README for more details*"
		),
		"keep-import-file": "Keep \".import\" files generated by plugin, when run uninstall command",
		"keep-import-resource-file": (
			"Keep files located in \".import\" that generated by plugin, when run uninstall command"
		),
		"debug(alias d)": "Print debug message",
		"detail": "Print with datetime and log level, \"[{time}] [{level}] {msg}\"",
		"quiet(alias q, silent)": "Disable logging",
		"help": "Show this help",
		"help-config": "plug.gd configuration documentation",
	}
	_log_table(options)
	logger.info("")


## Gibt die Hilfe zu den Argumenten von [method plug] auf der Konsole aus.
func show_config_syntax() -> void:
	logger.info("Configs: plug(src, args={})")
	logger.info("")
	logger.info("Sources:")
	logger.indent()
	logger.info("Github repo: \"username/repo\", for example, \"imjp94/gd-plug\"")
	logger.info("or")
	logger.info("Any valid git url, for example, \"git@github.com:username/repo.git\"")
	logger.dedent()
	logger.info("")
	logger.info("Arguments:")
	var arguments: Dictionary[String, String] = {
		"include": (
			"Array of strings that define what files or directory to include. "
			+ "Only \"addons/\" will be included if omitted"
		),
		"exclude": "Array of strings that define what files or directory to exclude",
		"branch": "Name of branch to freeze to",
		"tag": "Name of tag to freeze to",
		"commit": (
			"Commit hash string to freeze to, must be full length 40 digits commit-hash, "
			+ "for example, 7a642f90d3fb88976dd913051de994e58e838d1a"
		),
		"dev": (
			"Boolean to mark the plugin as dev or not, "
			+ "plugin marked as dev will not be installed when production command given"
		),
		"on_updated": (
			"Post update hook, a function name declared in plug.gd "
			+ "that will be called whenever the plugin installed/updated"
		),
		"install_root": "Destination directory where included files will be installed",
		"strip_prefix": (
			"Path prefix to strip from included source paths before copying to install_root. "
			+ "If omitted and install_root is set with a single included directory (other than addons/ or .), "
			+ "that directory is stripped automatically. Trailing / is added automatically if missing"
		),
	}
	_log_table(arguments)
	logger.info("")


## Beendet das Programm, sobald keine Threads laufen und keine Aufgaben mehr warten.
## [param exit_code] — Exit-Code; bei -1 wird 1 verwendet, wenn Fehler gemeldet wurden, sonst 0.
## [b]return[/b] [bool] — [code]true[/code], wenn beendet wurde;
## [code]false[/code], wenn der Threadpool noch arbeitet.
func request_quit(exit_code: int = -1) -> bool:
	if threadpool.is_all_thread_finished() and threadpool.is_all_task_finished():
		# Ohne ausdrücklichen Code: 1, sobald ein Fehler gemeldet wurde, sonst 0
		if exit_code == -1:
			exit_code = 1 if logger.error_count > 0 else 0
		quit(exit_code)
		return true
	logger.debug("Request quit declined, threadpool is still running")
	return false


# Index & validate plugin
## Deklariert ein Plugin; gehört in [method _plugging] der plug.gd des Projekts.
## Ungültige Angaben werden als Fehler gemeldet und das Plugin nicht vorgemerkt.
## [param repo] — Kurzform [code]"user/repo"[/code] (GitHub) oder eine beliebige Git-URL.
## [param args] — Optionen als [Dictionary]:[br]
## [code]include[/code] ([Array]): Dateien oder Verzeichnisse, die installiert werden;
## ohne Angabe nur [code]"addons/"[/code].[br]
## [code]exclude[/code] ([Array]): Dateien oder Verzeichnisse, die nicht installiert werden.[br]
## [code]branch[/code] ([String]): Branch, auf dem das Plugin festgehalten wird.[br]
## [code]tag[/code] ([String]): Tag, auf dem das Plugin festgehalten wird.[br]
## [code]commit[/code] ([String]): vollständiger 40-stelliger Commit-Hash, auf dem das Plugin
## festgehalten wird.[br]
## [code]dev[/code] ([bool]): markiert ein Entwicklungs-Plugin, das im Modus "production"
## nicht installiert bzw. wieder entfernt wird.[br]
## [code]on_updated[/code] ([String]): Name einer Methode der plug.gd, die nach Installation
## oder Aktualisierung mit dem Plugin-Dictionary aufgerufen wird.[br]
## [code]install_root[/code] ([String]): Zielverzeichnis relativ zu [code]res://[/code].[br]
## [code]strip_prefix[/code] ([String]): Pfadpräfix, das vor dem Kopieren von den Quellpfaden
## entfernt wird. Bei gesetztem [code]install_root[/code] und genau einem eingeschlossenen
## Verzeichnis (außer "addons/" und ".") wird es automatisch bestimmt.
func plug(repo: String, args: Dictionary = { }) -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	repo = repo.strip_edges()
	var plugin_name: String = get_plugin_name_from_repo(repo)
	if plugin_name in _plugged_plugins:
		logger.info("Plugin already plugged: %s" % plugin_name)
		return
	var plugin: Dictionary = { }
	plugin.name = plugin_name
	plugin.url = ""
	if ":" in repo:
		plugin.url = repo
	elif repo.find("/") == repo.rfind("/"):
		plugin.url = DEFAULT_PLUGIN_URL % repo
	else:
		logger.error("Invalid repo: %s" % repo)
	plugin.plug_dir = DEFAULT_PLUG_DIR + "/" + plugin_name

	var is_valid: bool = true
	plugin.include = args.get("include", [])
	is_valid = is_valid and validate_var_type(plugin, "include", TYPE_ARRAY, "Array")
	plugin.exclude = args.get("exclude", [])
	is_valid = is_valid and validate_var_type(plugin, "exclude", TYPE_ARRAY, "Array")
	plugin.branch = args.get("branch", "")
	is_valid = is_valid and validate_var_type(plugin, "branch", TYPE_STRING, "String")
	plugin.tag = args.get("tag", "")
	is_valid = is_valid and validate_var_type(plugin, "tag", TYPE_STRING, "String")
	plugin.commit = args.get("commit", "")
	is_valid = is_valid and validate_var_type(plugin, "commit", TYPE_STRING, "String")
	if is_valid and not (plugin.commit as String).is_empty():
		var is_valid_commit: bool = (plugin.commit as String).length() == 40
		if not is_valid_commit:
			logger.error("Expected full length 40 digits commit-hash string, given %s" % plugin.commit)
		is_valid = is_valid_commit
	plugin.dev = args.get("dev", false)
	is_valid = is_valid and validate_var_type(plugin, "dev", TYPE_BOOL, "Boolean")
	plugin.on_updated = args.get("on_updated", "")
	is_valid = is_valid and validate_var_type(plugin, "on_updated", TYPE_STRING, "String")
	plugin.install_root = args.get("install_root", "")
	is_valid = is_valid and validate_var_type(plugin, "install_root", TYPE_STRING, "String")
	plugin.strip_prefix = args.get("strip_prefix", "")
	is_valid = is_valid and validate_var_type(plugin, "strip_prefix", TYPE_STRING, "String")

	if is_valid:
		_plugged_plugins[plugin_name] = plugin
		logger.debug("Plug: %s" % plugin)
	else:
		logger.error("Failed to plug %s, validation error" % plugin_name)


## Lädt ein Plugin bei Bedarf herunter und installiert es.
## Dev-Plugins werden im Modus "production" übersprungen.
## [param plugin] — Plugin-Dictionary, wie von [method plug] angelegt.
func install_plugin(plugin: Dictionary) -> void:
	var can_install: bool = not plugin.dev or not _is_env_set(ENV_PRODUCTION)
	if not can_install:
		return

	logger.info("Installing plugin %s..." % plugin.name)
	var result: int = is_plugin_downloaded(plugin)
	if result != OK:
		result = download(plugin)
	else:
		logger.info("Plugin already downloaded")

	if result == OK:
		install(plugin)
	else:
		logger.error("Failed to install plugin %s with error code %d" % [plugin.name, result])


## Entfernt die installierten Dateien eines Plugins und löscht dessen Verzeichnis in .plugged.
## [param plugin] — Plugin-Dictionary mit [code]dest_files[/code] aus dem Index.
func uninstall_plugin(plugin: Dictionary) -> void:
	logger.info("Uninstalling plugin %s..." % plugin.name)
	uninstall(plugin)
	directory_delete_recursively(plugin.plug_dir, { "exclude": [DEFAULT_CONFIG_PATH], "test": _is_env_set(ENV_TEST) })


## Prüft ein bereits installiertes Plugin auf Änderungen der Einstellungen und neue Commits
## und aktualisiert es bei Bedarf (neu klonen, pullen oder neu installieren).
## Ist das Plugin noch nicht installiert, passiert nichts.
## [param plugin] — Plugin-Dictionary aus plug.gd, verglichen mit dem Stand im Index.
## [param checking] — Wenn [code]true[/code], wird nur der Status gemeldet, nichts verändert.
func update_plugin(plugin: Dictionary, checking: bool = false) -> void:
	if not (plugin.name in _installed_plugins):
		logger.info("%s new plugin" % plugin.name)
		return

	var git := _GitExecutable.new(ProjectSettings.globalize_path(plugin.plug_dir), logger)
	var installed_plugin: Dictionary = get_installed_plugin(plugin.name)
	var changes: Array[String] = compare_plugins(plugin, installed_plugin)
	var branch: String = plugin.branch
	var should_clone: bool = false
	var should_pull: bool = false

	if plugin.tag or plugin.commit:
		for rev: String in ["tag", "commit"]:
			var freeze_at: String = plugin[rev]
			if not freeze_at.is_empty():
				logger.info("%s frozen at %s \"%s\"" % [plugin.name, rev, freeze_at])
				break
	else:
		var ahead_behind: Array[int] = []
		if git.fetch("origin " + branch if branch else "origin").exit == OK:
			ahead_behind = git.get_commit_comparison("HEAD", "origin/" + branch if branch else "origin")
		var is_commit_behind: bool = ahead_behind.size() == 2 and ahead_behind[1] > 0
		if is_commit_behind:
			logger.info("%s %d commits behind, update required" % [plugin.name, ahead_behind[1]])
			should_pull = true
		else:
			logger.info("%s up to date" % plugin.name)

	var should_reinstall: bool = not changes.is_empty()
	if should_reinstall:
		logger.info("%s changed %s" % [plugin.name, changes])
		if "url" in changes or "branch" in changes or "tag" in changes or "commit" in changes:
			logger.info("%s repository setting changed, update required" % plugin.name)
			should_clone = true

	if checking:
		return

	if should_clone:
		logger.info("%s cloning from %s..." % [plugin.name, plugin.url])
		uninstall(get_installed_plugin(plugin.name))
		directory_delete_recursively(
			plugin.plug_dir,
			{ "exclude": [DEFAULT_CONFIG_PATH], "test": _is_env_set(ENV_TEST) },
		)
		if download(plugin) == OK:
			install(plugin)
	elif should_pull:
		logger.info("%s pulling updates from %s..." % [plugin.name, plugin.url])
		uninstall(get_installed_plugin(plugin.name))
		if git.pull().exit == OK:
			install(plugin)
	elif should_reinstall:
		logger.info("%s reinstalling..." % plugin.name)
		uninstall(get_installed_plugin(plugin.name))
		install(plugin)


## Meldet den Status eines Plugins (aktuell, hinterher, geändert), ohne etwas zu verändern.
## [param plugin] — Plugin-Dictionary aus plug.gd.
func check_plugin(plugin: Dictionary) -> void:
	update_plugin(plugin, true)


## Klont das Repository eines Plugins nach [code]plug_dir[/code].
## Bei einem Fehler wird das Verzeichnis wieder aufgeräumt.
## [param plugin] — Plugin-Dictionary mit url und optional branch, tag oder commit.
## [b]return[/b] [int] — [constant OK] bei Erfolg, sonst der Exit-Code von git.
func download(plugin: Dictionary) -> int:
	logger.info("Downloading %s from %s..." % [plugin.name, plugin.url])
	var global_dest_dir: String = ProjectSettings.globalize_path(plugin.plug_dir)
	if project_dir.dir_exists(plugin.plug_dir):
		directory_delete_recursively(plugin.plug_dir)
	project_dir.make_dir(plugin.plug_dir)
	var result: Dictionary = _GitExecutable.new(global_dest_dir, logger).clone(
		plugin.url,
		global_dest_dir,
		{ "branch": plugin.branch, "tag": plugin.tag, "commit": plugin.commit },
	)
	if result.exit == OK:
		logger.info("Successfully download %s" % plugin.name)
	else:
		logger.info("Failed to download %s" % plugin.name)
		# Make sure plug_dir is clean when failed
		directory_delete_recursively(
			plugin.plug_dir,
			{ "exclude": [DEFAULT_CONFIG_PATH], "test": _is_env_set(ENV_TEST) },
		)
	project_dir.remove(plugin.plug_dir) # Remove empty directory
	return result.exit


## Kopiert die ausgewählten Dateien eines geklonten Plugins ins Projekt, trägt es in den Index ein
## und ruft [method _on_updated], die [code]on_updated[/code]-Methode sowie das Signal [signal updated] auf.
## Ohne den Befehl "force" wird abgebrochen, wenn dabei Dateien überschrieben würden.
## [param plugin] — Plugin-Dictionary; [code]dest_files[/code] wird hier gesetzt.
## [b]return[/b] [enum Error] — [constant OK] oder [constant ERR_ALREADY_EXISTS], wenn Zieldateien existieren.
func install(plugin: Dictionary) -> Error:
	var include: Array = plugin.get("include", [])
	if include.is_empty(): # Auto include "addons/" folder if not explicitly specified
		include = ["addons/"]

	var install_root: String = plugin.install_root
	var strip_prefix: String = plugin.get("strip_prefix", "")
	# Auto strip included directory into install_root when install_root is set
	# and a single non-default directory is included
	if strip_prefix.is_empty() and not install_root.is_empty() and include.size() == 1:
		var include_path: String = include[0]
		if include_path != "." and include_path != "addons/" and not include_path.is_empty():
			if project_dir.dir_exists(plugin.plug_dir + "/" + include_path):
				strip_prefix = include_path
	if not strip_prefix.is_empty() and not strip_prefix.ends_with("/"):
		strip_prefix += "/"

	var copy_args: Dictionary = {
		"include": include,
		"exclude": plugin.exclude,
		"strip_prefix": strip_prefix,
		"root_from": plugin.plug_dir,
	}
	if not _is_env_set(ENV_FORCE) and not _is_env_set(ENV_TEST):
		var is_exists: bool = false
		# Trockenlauf, um vor dem Kopieren zu erkennen, ob Dateien überschrieben würden
		var test_args: Dictionary = copy_args.duplicate()
		test_args["test"] = true
		test_args["silent_test"] = true
		for dest_file in directory_copy_recursively(plugin.plug_dir, "res://" + install_root, test_args):
			if project_dir.file_exists(dest_file):
				logger.warn("%s attempting to overwrite file %s" % [plugin.name, dest_file])
				is_exists = true
		if is_exists:
			logger.warn(
				"Installation of %s terminated to avoid overwriting user files, " % plugin.name
				+ "you may disable safe mode with command \"force\""
			)
			return ERR_ALREADY_EXISTS

	logger.info("Installing files for %s..." % plugin.name)
	var run_args: Dictionary = copy_args.duplicate()
	run_args["test"] = _is_env_set(ENV_TEST)
	var dest_files: Array = directory_copy_recursively(plugin.plug_dir, "res://" + install_root, run_args)
	plugin.dest_files = dest_files
	logger.info("Installed %d file%s for %s" % [dest_files.size(), _plural_s(dest_files.size()), plugin.name])
	# gd-plug selbst (Befehl "upgrade") kommt nicht in den Index, sonst würde das nächste "install" es
	# als nicht deklariertes Plugin deinstallieren
	if plugin.name != "gd-plug":
		set_installed_plugin(plugin)

	logger.debug("Execute \"_on_updated\" function for %s" % plugin.name)
	# Kopien übergeben, damit Hooks und Signal-Empfänger das Plugin im Index nicht verändern
	_on_updated(plugin.duplicate())
	var on_updated: String = plugin.on_updated
	if not on_updated.is_empty() and has_method(on_updated):
		logger.debug("Execute post-update function \"%s\" for %s" % [on_updated, plugin.name])
		call(on_updated, plugin.duplicate())
	logger.debug("Emit \"updated\" signal for %s" % plugin.name)
	updated.emit(plugin.duplicate())
	return OK


## Löscht die installierten Dateien eines Plugins und entfernt es aus dem Index.
## [param plugin] — Plugin-Dictionary mit [code]dest_files[/code].
func uninstall(plugin: Dictionary) -> void:
	# Array aus index.cfg, deshalb untypisiert
	var dest_files: Array = plugin.get("dest_files", [])
	var count: int = dest_files.size()
	logger.info("Uninstalling %d file%s for %s..." % [count, _plural_s(count), plugin.name])
	directory_remove_batch(
		dest_files,
		{
			"test": _is_env_set(ENV_TEST),
			"keep_import_file": _is_env_set(ENV_KEEP_IMPORT_FILE),
			"keep_import_resource_file": _is_env_set(ENV_KEEP_IMPORT_RESOURCE_FILE),
		},
	)
	logger.info("Uninstalled %d file%s for %s" % [count, _plural_s(count), plugin.name])
	remove_installed_plugin(plugin.name)


## Prüft, ob das Repository eines Plugins bereits geklont und auf dem gewünschten Stand ist.
## [param plugin] — Plugin-Dictionary aus plug.gd.
## [b]return[/b] [int] — [constant OK], wenn aktuell; [constant ERR_DOES_NOT_EXIST], wenn nicht geklont;
## sonst [constant FAILED] (veraltet oder falscher Branch).
func is_plugin_downloaded(plugin: Dictionary) -> int:
	if not project_dir.dir_exists(plugin.plug_dir + "/.git"):
		return ERR_DOES_NOT_EXIST

	var git := _GitExecutable.new(ProjectSettings.globalize_path(plugin.plug_dir), logger)
	return git.is_up_to_date(plugin)


# Get installed plugin, thread safe
## Liefert den Eintrag eines installierten Plugins aus dem Index.
## [param plugin_name] — Name des Plugins; muss im Index vorhanden sein.
## [b]return[/b] [Dictionary] — Plugin-Dictionary inklusive [code]dest_files[/code].
func get_installed_plugin(plugin_name: String) -> Dictionary:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	_mutex.lock()
	var installed_plugin: Dictionary = _installed_plugins[plugin_name]
	_mutex.unlock()
	return installed_plugin


# Set installed plugin, thread safe
## Trägt ein Plugin im Index der installierten Plugins ein oder ersetzt den Eintrag.
## [param plugin] — Plugin-Dictionary; der Schlüssel ist sein [code]name[/code].
func set_installed_plugin(plugin: Dictionary) -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	_mutex.lock()
	_installed_plugins[plugin.name] = plugin
	_mutex.unlock()


# Remove installed plugin, thread safe
## Entfernt ein Plugin aus dem Index der installierten Plugins.
## [param plugin_name] — Name des Plugins.
## [b]return[/b] [bool] — [code]true[/code], wenn ein Eintrag entfernt wurde.
func remove_installed_plugin(plugin_name: String) -> bool:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	_mutex.lock()
	var result: bool = _installed_plugins.erase(plugin_name)
	_mutex.unlock()
	return result


## Kopiert Dateien rekursiv von einem Verzeichnis in ein anderes. Eine Datei wird kopiert, wenn ihr Pfad
## einen Schlüssel aus [code]include[/code] enthält und keinen aus [code]exclude[/code].
## [param from] — Quellverzeichnis.
## [param to] — Zielverzeichnis.
## [param args] — Optionen: [code]include[/code], [code]exclude[/code] (Arrays von Teilstrings),
## [code]test[/code] (nur melden, nicht schreiben), [code]silent_test[/code] (im Test nichts melden),
## [code]strip_prefix[/code] (Präfix, das aus den Zielpfaden entfällt),
## [code]root_from[/code] (Wurzel für die relativen Pfade, Standard ist [param from]).
## [b]return[/b] [Array] — Pfade der (im Testmodus: zu schreibenden) Zieldateien.
func directory_copy_recursively(from: String, to: String, args: Dictionary = { }) -> Array:
	var include: Array = args.get("include", [])
	var exclude: Array = args.get("exclude", [])
	var test: bool = args.get("test", false)
	var silent_test: bool = args.get("silent_test", false)
	var strip_prefix: String = args.get("strip_prefix", "")
	var root_from: String = args.get("root_from", from)
	# Untypisiert, weil die Liste als dest_files in index.cfg landet
	var dest_files: Array = []
	var dir := DirAccess.open(from)
	if dir == null:
		logger.error("Failed to access path: %s" % from)
		return dest_files

	dir.include_hidden = true
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var source: String = _join_path(dir.get_current_dir(), file_name)
		var relative_to_root: String = source.trim_prefix(root_from).trim_prefix("/")

		var dest: String
		if strip_prefix.is_empty():
			dest = _join_path(to, file_name)
		elif dir.current_is_dir():
			var dir_prefix: String = relative_to_root + "/" if not relative_to_root.is_empty() else ""
			if strip_prefix.begins_with(dir_prefix) or dir_prefix.begins_with(strip_prefix):
				dest = to
			else:
				dest = _join_path(to, file_name)
		else:
			dest = _join_path(to, relative_to_root.trim_prefix(strip_prefix))

		if dir.current_is_dir():
			dest_files.append_array(directory_copy_recursively(source, dest, args))
		elif _matches_any(source, include) and not _matches_any(source, exclude):
			if test:
				if not silent_test:
					logger.warn("[TEST] Writing to %s" % dest)
			else:
				dir.make_dir_recursive(dest.get_base_dir())
				if dir.copy(source, dest) == OK:
					logger.debug("Copy from %s to %s" % [source, dest])
			dest_files.append(dest)
		file_name = dir.get_next()
	dir.list_dir_end()
	return dest_files


## Löscht ein Verzeichnis rekursiv.
## [param dir_path] — Zu löschendes Verzeichnis.
## [param args] — Optionen: [code]remove_empty_directory[/code] (leere Verzeichnisse entfernen, Standard
## [code]true[/code]), [code]exclude[/code] (Dateipfade, die erhalten bleiben), [code]test[/code] (nur melden),
## [code]silent_test[/code] (im Test nichts melden).
## [b]return[/b] [DirAccess] — Zugriff auf das Verzeichnis oder [code]null[/code],
## wenn es nicht geöffnet werden konnte.
func directory_delete_recursively(dir_path: String, args: Dictionary = { }) -> DirAccess:
	var remove_empty_directory: bool = args.get("remove_empty_directory", true)
	var exclude: Array = args.get("exclude", [])
	var test: bool = args.get("test", false)
	var silent_test: bool = args.get("silent_test", false)
	var dir := DirAccess.open(dir_path)
	if dir == null:
		logger.error("Failed to access path: %s" % dir_path)
		return null

	dir.include_hidden = true
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var source: String = _join_path(dir.get_current_dir(), file_name)
		if dir.current_is_dir():
			directory_delete_recursively(source, args)
			if remove_empty_directory:
				if test:
					if not silent_test:
						logger.warn("[TEST] Remove empty directory: %s" % source)
				elif source.get_file() == ".git":
					# Hacks to remove .git, as git pack files stop it from being removed
					# See https://stackoverflow.com/questions/1213430/how-to-fully-delete-a-git-repository-created-with-init
					if _remove_directory_by_shell(source) == OK:
						logger.debug("Remove empty directory: %s" % source)
					else:
						logger.debug("Failed to remove empty directory: %s" % source)
				elif dir.remove(source) == OK:
					logger.debug("Remove empty directory: %s" % source)
		else:
			# Umgekehrte Richtung als beim Kopieren: exclude enthält hier vollständige Pfade
			var excluded: bool = exclude.any(
				func(exclude_key: String) -> bool:
					return source in exclude_key,
			)
			if not excluded:
				if test:
					if not silent_test:
						logger.warn("[TEST] Remove file: %s" % source)
				elif dir.remove(file_name) == OK:
					logger.debug("Remove file: %s" % source)
		file_name = dir.get_next()
	dir.list_dir_end()

	if remove_empty_directory:
		dir.remove(dir.get_current_dir())

	return dir


## Löscht eine Liste von Dateien samt zugehöriger ".import"-Dateien und räumt danach leere
## Verzeichnisse und deren leere Elternverzeichnisse auf.
## [param files] — Pfade der zu löschenden Dateien.
## [param args] — Optionen: [code]keep_import_file[/code] (".import"-Dateien behalten),
## [code]keep_import_resource_file[/code] (importierte Ressourcen behalten),
## [code]test[/code] (nur melden), [code]silent_test[/code] (im Test nichts melden).
func directory_remove_batch(files: Array, args: Dictionary = { }) -> void:
	var keep_import_file: bool = args.get("keep_import_file", false)
	var keep_import_resource_file: bool = args.get("keep_import_resource_file", false)
	var test: bool = args.get("test", false)
	var silent_test: bool = args.get("silent_test", false)
	var dirs: Dictionary[String, DirAccess] = { }
	for file: String in files:
		var file_dir: String = file.get_base_dir()
		var dir: DirAccess = dirs.get(file_dir)
		if dir == null:
			dir = DirAccess.open(file_dir)
			if dir == null:
				logger.warn("Failed to access path: %s" % file_dir)
				continue
			dirs[file_dir] = dir

		if file.ends_with(".import"):
			if not keep_import_file:
				_remove_import_file(dir, file, keep_import_resource_file, test, silent_test)
		else:
			if test:
				if not silent_test:
					logger.warn("[TEST] Remove file: " + file)
			elif dir.remove(file.get_file()) == OK:
				logger.debug("Remove file: " + file)
			if not keep_import_file:
				_remove_import_file(dir, file + ".import", keep_import_resource_file, test, silent_test)

	for dir: DirAccess in dirs.values():
		var current_dir: String = dir.get_current_dir()
		var slash_count: int = current_dir.count("/") - 2 # Deduct 2 slash from "res://"
		if test:
			if not silent_test:
				logger.warn("[TEST] Remove empty directory: %s" % current_dir)
		elif dir.remove(current_dir) == OK:
			logger.debug("Remove empty directory: %s" % current_dir)
		# Dumb method to clean empty ancestor directories
		logger.debug("Removing empty ancestor directory for %s..." % current_dir)
		for i in slash_count:
			current_dir = current_dir.get_base_dir()
			var ancestor := DirAccess.open(current_dir)
			if ancestor == null:
				continue
			if test:
				if not silent_test:
					logger.warn("[TEST] Remove empty ancestor directory: %s" % ancestor.get_current_dir())
			elif ancestor.remove(ancestor.get_current_dir()) == OK:
				logger.debug("Remove empty ancestor directory: %s" % ancestor.get_current_dir())


## Vergleicht zwei Plugin-Dictionaries anhand der Schlüssel von [param p1].
## [param p1] — Plugin aus plug.gd.
## [param p2] — Plugin aus dem Index.
## [b]return[/b] [Array] — Namen der Schlüssel, deren Werte sich unterscheiden.
func compare_plugins(p1: Dictionary, p2: Dictionary) -> Array[String]:
	var changed_keys: Array[String] = []
	for key: String in p1.keys():
		# Index älterer Versionen kennt neue Optionen nicht, fehlende Schlüssel zählen als Änderung
		if p1[key] != p2.get(key):
			changed_keys.append(key)
	return changed_keys


## Leitet den Plugin-Namen aus der Repo-Angabe ab (letzter Pfadteil ohne ".git").
## [param repo] — Kurzform "user/repo" oder Git-URL.
func get_plugin_name_from_repo(repo: String) -> String:
	return repo.replace(".git", "").trim_suffix("/").get_file()


## Prüft, ob ein Wert im Dictionary den erwarteten Typ hat, und meldet sonst einen Fehler.
## [param obj] — Dictionary mit dem Wert.
## [param var_name] — Schlüssel des Wertes.
## [param type] — Erwarteter Typ.
## [param type_string] — Name des Typs für die Fehlermeldung.
## [b]return[/b] [bool] — [code]true[/code], wenn der Typ passt.
func validate_var_type(obj: Dictionary, var_name: String, type: Variant.Type, type_string: String) -> bool:
	var value: Variant = obj.get(var_name)
	var is_valid: bool = typeof(value) == type
	if not is_valid:
		logger.error("Expected variable \"%s\" to be %s, given %s" % [var_name, type_string, value])
	return is_valid
#endregion


#region Private Funcs
# Index installed plugins, or create directory "plugged" if not exists
## Lädt den Index der installierten Plugins aus index.cfg; Voraussetzung für fast alle anderen Funktionen.
func _plug_start() -> void:
	logger.debug("Plug start")
	if not project_dir.dir_exists(DEFAULT_PLUG_DIR):
		if project_dir.make_dir(ProjectSettings.globalize_path(DEFAULT_PLUG_DIR)) == OK:
			logger.debug("Make dir %s for plugin installation" % DEFAULT_PLUG_DIR)
	if installation_config.load(DEFAULT_CONFIG_PATH) == OK:
		logger.debug("Installation config loaded")
	else:
		logger.debug("Installation config not found")
	_installed_plugins = installation_config.get_value("plugin", "installed", { })
	_is_plug_started = true


# Install plugin or uninstall plugin if unlisted
## Schreibt den Index der installierten Plugins zurück nach index.cfg (im Testmodus nicht).
func _plug_end() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	if not _is_env_set(ENV_TEST):
		installation_config.set_value("plugin", "installed", _installed_plugins)
		if installation_config.save(DEFAULT_CONFIG_PATH) == OK:
			logger.debug("Plugged config saved")
		else:
			logger.error("Failed to save plugged config")
	else:
		logger.warn("Skipped saving of plugged config in test mode")
	_is_plug_started = false


## Befehl "init": legt eine plug.gd mit Vorlage im Projekt an, sofern noch keine existiert.
func _plug_init() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	logger.info("Init gd-plug...")
	if FileAccess.file_exists(DEFAULT_USER_PLUG_SCRIPT_PATH):
		logger.warn("%s already exists!" % DEFAULT_USER_PLUG_SCRIPT_PATH)
		return

	var file := FileAccess.open(DEFAULT_USER_PLUG_SCRIPT_PATH, FileAccess.WRITE)
	file.store_string(INIT_PLUG_SCRIPT)
	file.close()
	logger.info("Created %s" % DEFAULT_USER_PLUG_SCRIPT_PATH)


## Befehl "install"/"update": installiert neue, aktualisiert vorhandene und
## deinstalliert nicht mehr deklarierte Plugins über den Threadpool.
func _plug_install() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	logger.info("Installing...")
	for plugin: Dictionary in _plugged_plugins.values():
		if plugin.name in _installed_plugins:
			var installed_plugin: Dictionary = get_installed_plugin(plugin.name)
			if (installed_plugin.dev or plugin.dev) and _is_env_set(ENV_PRODUCTION):
				logger.info("Remove dev plugin for production: %s" % plugin.name)
				threadpool.enqueue_task(uninstall_plugin.bind(installed_plugin))
			else:
				threadpool.enqueue_task(update_plugin.bind(plugin))
		else:
			threadpool.enqueue_task(install_plugin.bind(plugin))

	var removed_plugins: Array[Dictionary] = []
	for plugin: Dictionary in _installed_plugins.values():
		if not (plugin.name in _plugged_plugins):
			removed_plugins.append(plugin)
	if not removed_plugins.is_empty():
		# Verhindert, dass das Ende der Installationen das Programm beendet, bevor deinstalliert wurde
		threadpool.all_thread_finished.disconnect(request_quit)
		if not threadpool.is_all_thread_finished():
			threadpool.active = true
			await threadpool.all_thread_finished
			threadpool.active = false
			logger.debug("All installation finished! Ready to uninstall removed plugins...")
		threadpool.all_thread_finished.connect(request_quit)
		for plugin in removed_plugins:
			threadpool.enqueue_task(uninstall_plugin.bind(plugin), Thread.PRIORITY_LOW)
	threadpool.active = true


## Befehl "uninstall": deinstalliert alle Plugins aus dem Index, unabhängig von der plug.gd.
func _plug_uninstall() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	logger.info("Uninstalling...")
	for plugin: Dictionary in _installed_plugins.values():
		var installed_plugin: Dictionary = get_installed_plugin(plugin.name)
		threadpool.enqueue_task(uninstall_plugin.bind(installed_plugin), Thread.PRIORITY_LOW)
	threadpool.active = true


## Befehl "clean": löscht Verzeichnisse in .plugged, die zu keinem installierten Plugin gehören.
func _plug_clean() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	logger.info("Cleaning...")
	for dir_name in _get_orphan_dirs():
		logger.info("Remove %s" % dir_name)
		threadpool.enqueue_task(directory_delete_recursively.bind(DEFAULT_PLUG_DIR + "/" + dir_name))
	threadpool.active = true


## Befehl "upgrade": ersetzt addons/gd-plug durch den aktuellen Stand des Forks
## (Repo und Branch über [constant ENV_UPGRADE_REPO] und [constant ENV_UPGRADE_BRANCH] änderbar).
func _plug_upgrade() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	var upgrade_repo: String = OS.get_environment(ENV_UPGRADE_REPO).strip_edges()
	if upgrade_repo.is_empty():
		upgrade_repo = DEFAULT_UPGRADE_REPO
	var upgrade_branch: String = OS.get_environment(ENV_UPGRADE_BRANCH).strip_edges()
	if upgrade_branch.is_empty():
		upgrade_branch = DEFAULT_UPGRADE_BRANCH
	logger.info("Upgrading gd-plug from %s (branch %s)..." % [upgrade_repo, upgrade_branch])
	plug(upgrade_repo, { "branch": upgrade_branch })
	# Name aus dem Repo ableiten, beim Fork ist das "fork-gd-plug" statt "gd-plug"
	var gd_plug: Dictionary = _plugged_plugins.get(get_plugin_name_from_repo(upgrade_repo), { })
	if gd_plug.is_empty():
		logger.error("Failed to plug %s, upgrade aborted" % upgrade_repo)
		return
	# Stand gd-plug schon vorher im Index (über die plug.gd des Projekts), bleibt der Eintrag erhalten
	var keep_in_index: bool = gd_plug.name in _installed_plugins
	OS.set_environment(ENV_FORCE, "true") # Required to overwrite res://addons/gd-plug/plug.gd
	threadpool.enqueue_task(install_plugin.bind(gd_plug))
	threadpool.all_thread_finished.disconnect(request_quit)
	# Bei inaktivem Pool ist die Installation nur eingereiht, noch kein Thread läuft.
	# Ohne Prüfung der Warteschlange liefe das Löschen von plug_dir parallel zum Klonen.
	if not (threadpool.is_all_thread_finished() and threadpool.is_all_task_finished()):
		threadpool.active = true
		await threadpool.all_thread_finished
		threadpool.active = false
		logger.debug("All installation finished! Ready to uninstall removed plugins...")
	# Sonst stünde gd-plug in index.cfg und das nächste "install" würde es als entfernt deinstallieren
	if not keep_in_index:
		_installed_plugins.erase(gd_plug.name)
	threadpool.all_thread_finished.connect(request_quit)
	threadpool.enqueue_task(directory_delete_recursively.bind(gd_plug.plug_dir))
	threadpool.active = true


## Befehl "status": listet installierte, neu deklarierte und entfernte Plugins sowie verwaiste
## Verzeichnisse auf und prüft installierte Plugins auf Updates.
func _plug_status() -> void:
	assert(_is_plug_started, MSG_PLUG_START_ASSERTION)
	threadpool.active = false
	var installed_count: int = _installed_plugins.size()
	logger.info("Installed %d plugin%s" % [installed_count, _plural_s(installed_count)])
	var new_plugins: Dictionary = _plugged_plugins.duplicate()
	var has_checking_plugin: bool = false
	var removed_plugins: Array[Dictionary] = []
	for plugin: Dictionary in _installed_plugins.values():
		logger.info("- {name} - {url}".format(plugin))
		new_plugins.erase(plugin.name)
		if not (plugin.name in _plugged_plugins):
			removed_plugins.append(plugin)
		else:
			threadpool.enqueue_task(check_plugin.bind(_plugged_plugins[plugin.name]))
			has_checking_plugin = true
	if has_checking_plugin:
		logger.info("\n", true)
		threadpool.all_thread_finished.disconnect(request_quit)
		threadpool.active = true
		await threadpool.all_thread_finished
		threadpool.active = false
		threadpool.all_thread_finished.connect(request_quit)
		logger.debug("Finished checking plugins, ready to proceed")
	if not new_plugins.is_empty():
		logger.info("\nPlugged %d plugin%s" % [new_plugins.size(), _plural_s(new_plugins.size())])
		for plugin: Dictionary in new_plugins.values():
			if not (plugin.name in _installed_plugins):
				logger.info("- {name} - {url}".format(plugin))
	if not removed_plugins.is_empty():
		logger.info("\nUnplugged %d plugin%s" % [removed_plugins.size(), _plural_s(removed_plugins.size())])
		for plugin in removed_plugins:
			logger.info("- %s removed" % plugin.name)
	var orphan_dirs: Array[String] = _get_orphan_dirs()
	if not orphan_dirs.is_empty():
		logger.info(
			"\nOrphan directory, %d found in %s, execute \"clean\" command to remove"
			% [orphan_dirs.size(), DEFAULT_PLUG_DIR]
		)
		for dir_name in orphan_dirs:
			logger.info("- %s" % dir_name)
	threadpool.active = true

	if has_checking_plugin:
		request_quit()


# Verzeichnisse in .plugged, die zu keinem installierten Plugin gehören
## Ermittelt die Namen verwaister Verzeichnisse in .plugged.
func _get_orphan_dirs() -> Array[String]:
	var orphan_dirs: Array[String] = []
	var plugged_dir := DirAccess.open(DEFAULT_PLUG_DIR)
	if plugged_dir == null:
		return orphan_dirs
	plugged_dir.include_hidden = true
	plugged_dir.list_dir_begin()
	var file_name: String = plugged_dir.get_next()
	while not file_name.is_empty():
		if plugged_dir.current_is_dir() and not (file_name in _installed_plugins):
			orphan_dirs.append(file_name)
		file_name = plugged_dir.get_next()
	plugged_dir.list_dir_end()
	return orphan_dirs


## Löscht eine ".import"-Datei und, falls nicht ausgeschlossen, die daraus importierten Ressourcen.
## [param dir] — Verzeichnis, in dem die Datei liegt.
## [param file] — Pfad der ".import"-Datei.
## [param keep_import_resource_file] — Wenn [code]true[/code], bleiben die importierten Ressourcen erhalten.
## [param test] — Wenn [code]true[/code], wird nur gemeldet.
## [param silent_test] — Wenn [code]true[/code], bleibt auch die Meldung im Testmodus aus.
func _remove_import_file(
	dir: DirAccess,
	file: String,
	keep_import_resource_file: bool = false,
	test: bool = false,
	silent_test: bool = false,
) -> void:
	if not dir.file_exists(file):
		return

	if not keep_import_resource_file:
		var import_config := ConfigFile.new()
		if import_config.load(file) == OK:
			var metadata: Dictionary = import_config.get_value("remap", "metadata", { })
			var imported_formats: Array = metadata.get("imported_formats", [])
			if not imported_formats.is_empty():
				for format: String in imported_formats:
					_remove_import_resource_file(dir, import_config, "." + format, test)
			else:
				_remove_import_resource_file(dir, import_config, "", test)
	if test:
		if not silent_test:
			logger.warn("[TEST] Remove import file: " + file)
	elif dir.remove(file) == OK:
		logger.debug("Remove import file: " + file)
	else:
		# TODO: Sometimes Directory.remove() unable to remove random .import file
		# and return error code 1(Generic Error). Maybe enforce the removal from shell?
		logger.warn("Failed to remove import file: " + file)


## Löscht die in einer ".import"-Datei eingetragene Ressource und deren ".md5"-Prüfsumme.
## [param dir] — Verzeichnis, in dem die Dateien liegen.
## [param import_config] — Geladene ".import"-Datei.
## [param import_format] — Endung für Formate mit mehreren Ausgaben (z. B. ".s3tc"), sonst leer.
## [param test] — Wenn [code]true[/code], wird nur gemeldet.
func _remove_import_resource_file(
	dir: DirAccess,
	import_config: ConfigFile,
	import_format: String = "",
	test: bool = false,
) -> void:
	var import_resource_file: String = import_config.get_value("remap", "path" + import_format, "")
	if import_resource_file.is_empty():
		return

	if dir.file_exists(import_resource_file):
		if test:
			logger.info("[IMPORT] Remove import resource file: " + import_resource_file)
		elif dir.remove(import_resource_file) == OK:
			logger.debug("Remove import resource file: " + import_resource_file)
	var checksum_file: String = import_resource_file.get_basename() + ".md5"
	checksum_file = checksum_file.replace(import_format, "")
	if dir.file_exists(checksum_file):
		if test:
			logger.info("[IMPORT] Remove import checksum file: " + checksum_file)
		elif dir.remove(checksum_file) == OK:
			logger.debug("Remove import checksum file: " + checksum_file)


# Entfernt ein Verzeichnis über die Shell, nötig für .git mit schreibgeschützten Pack-Dateien
## Löscht ein Verzeichnis rekursiv über die Shell (rd bzw. rm -rf).
## [param path] — Zu löschendes Verzeichnis.
## [b]return[/b] [int] — Exit-Code des Shell-Befehls oder [constant FAILED] auf unbekannten Systemen.
func _remove_directory_by_shell(path: String) -> int:
	var global_path: String = ProjectSettings.globalize_path(path)
	match OS.get_name():
		"Windows":
			var windows_path: String = "\"%s\"" % global_path.replace("/", "\\")
			return OS.execute("cmd", ["/C", "rd /s /q %s" % windows_path])
		"macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return OS.execute("bash", ["-c", "rm -rf '%s'" % global_path])
	return FAILED


## Prüft, ob eine Umgebungsvariable gesetzt und nicht leer ist.
## [param env_name] — Name der Umgebungsvariable.
func _is_env_set(env_name: String) -> bool:
	return not OS.get_environment(env_name).is_empty()


## Liefert "s" als Plural-Endung für die englischen Ausgaben, wenn [param count] größer als 1 ist.
func _plural_s(count: int) -> String:
	return "s" if count > 1 else ""


## Hängt einen Dateinamen an einen Pfad an; für "res://" ohne zusätzlichen Schrägstrich.
func _join_path(base: String, file_name: String) -> String:
	return base + ("/" if base != "res://" else "") + file_name


# Wahr, wenn einer der Schlüssel als Teilstring im Pfad vorkommt
## Prüft, ob mindestens einer der Schlüssel im Pfad enthalten ist.
func _matches_any(path: String, keys: Array) -> bool:
	return keys.any(
		func(key: String) -> bool:
			return key in path,
	)


## Gibt Schlüssel/Wert-Paare als eingerückte, spaltenweise ausgerichtete Tabelle aus.
func _log_table(rows: Dictionary[String, String]) -> void:
	logger.indent()
	logger.table_start()
	for key in rows:
		logger.table_row([key, rows[key]])
	logger.table_end()
	logger.dedent()
#endregion


#region Inner Classes
## Kapselt git-Aufrufe, die über die Shell (bash bzw. cmd) im Verzeichnis [member cwd] laufen.
## Die Methoden liefern meist ein [Dictionary] mit [code]exit[/code] (Exit-Code) und [code]output[/code].
class _GitExecutable extends RefCounted:
	## Verzeichnis, in dem die git-Befehle ausgeführt werden.
	var cwd: String = ""
	## Logger für Debug- und Fehlermeldungen.
	var logger: _Logger


	## [param p_cwd] — Arbeitsverzeichnis der git-Befehle.
	## [param p_logger] — Logger für die Ausgabe.
	func _init(p_cwd: String, p_logger: _Logger) -> void:
		cwd = p_cwd
		logger = p_logger


	## Führt einen Shell-Befehl in [member cwd] aus.
	## [param command] — Auszuführender Befehl.
	## [param output] — Array, das die Ausgabe aufnimmt.
	## [param read_stderr] — Wenn [code]true[/code], wird auch stderr gelesen, sonst verworfen.
	## [b]return[/b] [int] — Exit-Code des Befehls oder [constant FAILED] auf unbekannten Systemen.
	func _execute(command: String, output: Array = [], read_stderr: bool = false) -> int:
		var cmd: String = "cd '%s' && %s" % [cwd, command]
		# NOTE: OS.execute() seems to ignore read_stderr
		var exit: int = FAILED
		match OS.get_name():
			"Windows":
				cmd = cmd.replace("'", "\"") # cmd doesn't accept single-quotes
				cmd = cmd if read_stderr else "%s 2> nul" % cmd
				logger.debug("Execute \"%s\"" % cmd)
				exit = OS.execute("cmd", ["/C", cmd], output, read_stderr)
			"macOS", "Linux", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
				cmd = cmd if read_stderr else "%s 2>/dev/null" % cmd
				logger.debug("Execute \"%s\"" % cmd)
				exit = OS.execute("bash", ["-c", cmd], output, read_stderr)
			var unhandled_os:
				logger.error("Unexpected OS: %s" % unhandled_os)
		logger.debug("Execution ended(code:%d): %s" % [exit, output])
		return exit


	## Führt [code]git init[/code] aus.
	func init() -> Dictionary:
		logger.debug("Initializing git at %s..." % cwd)
		return _run("git init", "Successfully init", "Failed to init")


	## Klont ein Repository flach (--depth=1); bei einem Commit über [method clone_commit].
	## [param src] — URL des Repositories.
	## [param dest] — Zielverzeichnis.
	## [param args] — Optionen [code]branch[/code], [code]tag[/code], [code]commit[/code];
	## Branch oder Tag haben Vorrang vor dem Commit.
	func clone(src: String, dest: String, args: Dictionary = { }) -> Dictionary:
		logger.debug("Cloning from %s to %s..." % [src, dest])
		var branch: String = args.get("branch", "")
		var tag: String = args.get("tag", "")
		var commit: String = args.get("commit", "")
		var command: String = "git clone --depth=1 --progress '%s' '%s'" % [src, dest]
		# git clone --branch akzeptiert Branch- und Tag-Namen
		if branch or tag:
			command = "git clone --depth=1 --single-branch --branch %s '%s' '%s'" % [
				branch if branch else tag,
				src,
				dest,
			]
		elif commit:
			return clone_commit(src, dest, commit)
		return _run(command, "Successfully cloned from %s" % src, "Failed to clone from %s" % src)


	## Holt genau einen Commit: init, Remote anlegen, Commit abrufen und hart darauf zurücksetzen.
	## [param src] — URL des Repositories.
	## [param dest] — Zielverzeichnis; geht nur in die Debug-Meldung ein, es zählt [member cwd].
	## [param commit] — Vollständiger 40-stelliger Commit-Hash.
	func clone_commit(src: String, dest: String, commit: String) -> Dictionary:
		if commit.length() < 40:
			logger.error("Expected full length 40 digits commit-hash to clone specific commit, given {%s}" % commit)
			return { "exit": FAILED, "output": [] }

		logger.debug("Cloning from %s to %s @ %s..." % [src, dest, commit])
		var result: Dictionary = init()
		if result.exit == OK:
			result = remote_add("origin", src)
			if result.exit == OK:
				result = fetch("%s %s" % ["origin", commit])
				if result.exit == OK:
					result = reset("--hard", "FETCH_HEAD")
		return result


	## Führt [code]git fetch[/code] aus.
	## [param rm] — Argumente für git fetch, Standard ist [code]--all[/code].
	func fetch(rm: String = "--all") -> Dictionary:
		logger.debug("Fetching %s..." % rm.replace("--", ""))
		return _run("git fetch %s" % rm, "Successfully fetched", "Failed to fetch")


	## Führt [code]git pull --rebase[/code] aus.
	func pull() -> Dictionary:
		logger.debug("Pulling...")
		return _run("git pull --rebase", "Successfully pulled", "Failed to pull")


	## Fügt ein Remote hinzu.
	## [param name] — Name des Remotes.
	## [param src] — URL des Remotes.
	func remote_add(name: String, src: String) -> Dictionary:
		logger.debug("Adding remote %s@%s..." % [name, src])
		return _run("git remote add %s '%s'" % [name, src], "Successfully added remote", "Failed to add remote")


	## Führt [code]git reset[/code] aus.
	## [param mode] — Modus, z. B. [code]--hard[/code].
	## [param to] — Ziel-Revision.
	func reset(mode: String, to: String) -> Dictionary:
		logger.debug("Resetting %s %s..." % [mode, to])
		return _run("git reset %s %s" % [mode, to], "Successfully reset", "Failed to reset")


	## Zählt, wie viele Commits [param branch_a] gegenüber [param branch_b] voraus bzw. zurück ist.
	## [param branch_a] — Erste Revision, meist [code]HEAD[/code].
	## [param branch_b] — Zweite Revision, z. B. [code]origin/main[/code].
	## [b]return[/b] [Array] — [code][voraus, zurück][/code]; leer, wenn der Vergleich scheitert.
	func get_commit_comparison(branch_a: String, branch_b: String) -> Array[int]:
		var ahead_behind: Array[int] = []
		var output: Array = []
		var exit: int = _execute("git rev-list --count --left-right %s...%s" % [branch_a, branch_b], output)
		# Ohne Erfolg gibt es keine Ausgabe, output[0] fehlt dann
		if exit != OK or output.is_empty():
			return ahead_behind
		for count in (output[0] as String).strip_edges().split("\t"):
			ahead_behind.append(count.to_int())
		return ahead_behind


	## Name des aktuellen Branches; leer bei einem Fehler.
	func get_current_branch() -> String:
		return _read_line("git rev-parse --abbrev-ref HEAD")


	## Name des Tags, auf dem HEAD genau steht; leer, wenn es keinen gibt.
	func get_current_tag() -> String:
		return _read_line("git describe --tags --exact-match")


	## Hash des aktuellen Commits; leer bei einem Fehler.
	func get_current_commit() -> String:
		# Voller Hash, plug() verlangt den Commit mit 40 Zeichen
		return _read_line("git rev-parse HEAD")


	## Prüft, ob HEAD auf keinen Branch zeigt (detached HEAD).
	func is_detached_head() -> bool:
		# symbolic-ref scheitert nur, wenn HEAD auf keinen Branch zeigt
		return _execute("git symbolic-ref -q HEAD") != OK


	## Prüft, ob das Repository dem gewünschten Stand entspricht und nicht hinter dem Remote liegt.
	## [param args] — Plugin-Dictionary oder Optionen mit [code]branch[/code], [code]tag[/code],
	## [code]commit[/code].
	## [b]return[/b] [int] — [constant OK], wenn aktuell; [constant FAILED], wenn fetch scheitert,
	## der Branch nicht passt oder neue Commits vorliegen.
	func is_up_to_date(args: Dictionary = { }) -> int:
		if fetch().exit != OK:
			return FAILED

		var branch: String = args.get("branch", "")
		var tag: String = args.get("tag", "")
		var commit: String = args.get("commit", "")
		if branch:
			# Falscher Branch: neu klonen. Richtiger Branch: unten auf neue Commits prüfen
			if branch != get_current_branch() or is_detached_head():
				return FAILED
		elif tag:
			if tag == get_current_tag():
				return OK
		elif commit:
			if commit == get_current_commit():
				return OK

		var ahead_behind: Array[int] = get_commit_comparison("HEAD", "origin/" + branch if branch else "origin")
		var is_commit_behind: bool = ahead_behind.size() == 2 and ahead_behind[1] > 0
		return FAILED if is_commit_behind else OK


	# Führt einen Git-Befehl aus und liefert {"exit": int, "output": Array}
	## [param command] — Auszuführender Befehl.
	## [param success_msg] — Debug-Meldung bei Erfolg.
	## [param failure_msg] — Debug-Meldung bei Misserfolg.
	func _run(command: String, success_msg: String, failure_msg: String) -> Dictionary:
		var output: Array = []
		var exit: int = _execute(command, output)
		logger.debug(success_msg if exit == OK else failure_msg)
		return { "exit": exit, "output": output }


	# Erste Zeile der Ausgabe ohne Zeilenumbruch, leer bei Fehler
	## [param command] — Auszuführender Befehl.
	func _read_line(command: String) -> String:
		var output: Array = []
		var exit: int = _execute(command, output)
		if exit != OK or output.is_empty():
			return ""
		return (output[0] as String).strip_edges()


## Führt Aufgaben ([Callable]) parallel in Threads aus, höchstens einen je Prozessorkern.
## Solange [member active] [code]false[/code] ist, werden Aufgaben nur eingereiht.
class _ThreadPool extends RefCounted:
	## Wird emittiert, wenn der letzte laufende Thread seine Aufgabe beendet hat.
	signal all_thread_finished()

	## Wenn [code]false[/code], werden Aufgaben nur eingereiht und nicht gestartet.
	var active: bool = true
	## Logger für Debug-Meldungen.
	var logger: _Logger

	# Feste Plätze je Prozessorkern, null für einen freien Platz
	var _threads: Array[Thread] = []
	var _finished_threads: Array[Thread] = []
	var _mutex := Mutex.new()
	# Aufgaben als {"callable": Callable, "priority": Thread.Priority}
	var _tasks: Array[Dictionary] = []


	## [param p_logger] — Logger für die Ausgabe.
	func _init(p_logger: _Logger) -> void:
		logger = p_logger
		_threads.resize(OS.get_processor_count())


	## Reiht eine Aufgabe ein bzw. startet sie sofort, wenn der Pool aktiv ist und ein Thread frei ist.
	## [param callable] — Auszuführende Aufgabe.
	## [param priority] — Thread-Priorität.
	func enqueue_task(callable: Callable, priority: Thread.Priority = Thread.PRIORITY_NORMAL) -> void:
		enqueue({ "callable": callable, "priority": priority })


	## Wie [method enqueue_task], aber mit fertigem Aufgaben-Dictionary.
	## [param task] — Dictionary mit [code]callable[/code] und [code]priority[/code].
	func enqueue(task: Dictionary) -> void:
		var can_execute: bool = false
		if active:
			can_execute = _execute_task(task)
		if not can_execute:
			_tasks.append(task)


	## Startet wartende Aufgaben und räumt beendete Threads auf; wird in jedem Frame aufgerufen.
	func process(_delta: float) -> void:
		if active:
			_flush_tasks()
			_flush_threads()


	## Verwirft wartende Aufgaben und räumt beendete Threads auf.
	func stop() -> void:
		_tasks.clear()
		_flush_threads()


	## Prüft, ob kein Thread mehr eine Aufgabe ausführt.
	func is_all_thread_finished() -> bool:
		return _threads.all(
			func(thread: Thread) -> bool:
				return thread == null,
		)


	## Prüft, ob keine Aufgaben mehr in der Warteschlange stehen.
	func is_all_task_finished() -> bool:
		return _tasks.is_empty()


	## Startet eine Aufgabe in einem freien Thread.
	## [b]return[/b] [bool] — [code]false[/code], wenn kein Thread frei ist.
	func _execute_task(task: Dictionary) -> bool:
		var thread: Thread = _get_thread()
		if thread == null:
			return false

		task.thread = weakref(thread)
		var callable: Callable = task.callable
		thread.start(_execute.bind(task), task.priority)
		logger.debug("Execute task %s.%s() " % [callable.get_object(), callable.get_method()])
		return true


	## Läuft im Thread: führt die Aufgabe aus, gibt den Platz frei und meldet,
	## wenn alle Threads fertig sind.
	func _execute(task: Dictionary) -> void:
		var callable: Callable = task.callable
		callable.call()
		_mutex.lock()
		var thread: Thread = (task.thread as WeakRef).get_ref()
		_threads[_threads.find(thread)] = null
		_finished_threads.append(thread)
		var all_finished: bool = is_all_thread_finished()
		_mutex.unlock()

		logger.debug("Execution finished %s.%s() " % [callable.get_object(), callable.get_method()])
		if all_finished:
			logger.debug("All thread finished")
			all_thread_finished.emit()


	## Startet wartende Aufgaben der Reihe nach, bis kein Thread mehr frei ist.
	func _flush_tasks() -> void:
		while not _tasks.is_empty():
			if not _execute_task(_tasks.front()):
				return
			_tasks.pop_front()


	## Wartet auf beendete Threads, damit ihre Ressourcen freigegeben werden.
	func _flush_threads() -> void:
		for i in _finished_threads.size():
			var thread: Thread = _finished_threads.pop_front()
			if not thread.is_alive():
				thread.wait_to_finish()


	## Liefert einen freien oder noch nicht gestarteten Thread-Platz.
	## [b]return[/b] [Thread] — der Thread oder [code]null[/code], wenn alle belegt sind.
	func _get_thread() -> Thread:
		for i in OS.get_processor_count():
			var thread: Thread = _threads[i]
			if thread == null:
				thread = Thread.new()
				_threads[i] = thread
				return thread
			if not thread.is_started():
				return thread
		return null


## Gibt Meldungen nach Log-Level gefiltert aus (Warnungen und Fehler über push_warning/push_error),
## unterstützt Einrückung und Tabellen und zählt gemeldete Fehler.
class _Logger extends RefCounted:
	## Log-Level; Meldungen unterhalb des eingestellten Levels werden verworfen.
	enum LogLevel {
		ALL, ## Alles ausgeben.
		DEBUG, ## Debug-Meldungen.
		INFO, ## Normale Informationen.
		WARN, ## Warnungen.
		ERROR, ## Fehler.
		NONE, ## Nichts ausgeben.
	}

	## Format mit Zeit und Level, aktiviert durch den Befehl "detail".
	const DEFAULT_LOG_FORMAT_DETAIL: String = "[{time}] [{level}] {msg}"
	## Standardformat, nur die Meldung.
	const DEFAULT_LOG_FORMAT_NORMAL: String = "{msg}"

	## Niedrigstes Level, das noch ausgegeben wird.
	var log_level: LogLevel = LogLevel.INFO
	## Format einer Zeile mit den Platzhaltern [code]{time}[/code], [code]{level}[/code], [code]{msg}[/code].
	var log_format: String = DEFAULT_LOG_FORMAT_NORMAL
	## Format der Zeitangabe für [code]{time}[/code].
	var log_time_format: String = "{year}/{month}/{day} {hour}:{minute}:{second}"
	## Aktuelle Einrückungstiefe, je Stufe vier Leerzeichen.
	var indent_level: int = 0
	## Wenn [code]true[/code], wird nichts ausgegeben. Wird derzeit nirgends gesetzt.
	var is_locked: bool = false
	# Anzahl gemeldeter Fehler, bestimmt den Exit-Code von gd-plug
	var error_count: int = 0

	var _rows: Array[Array] = []
	var _is_table_started: bool = false
	var _max_column_length: Array[int] = []
	var _max_column_size: int = 0


	## Gibt eine Debug-Meldung aus.
	## [param msg] — Meldung, wird mit [code]str()[/code] umgewandelt.
	## [param raw] — Wenn [code]true[/code], ohne Zeilenumbruch.
	func debug(msg: Variant, raw: bool = false) -> void:
		_log(LogLevel.DEBUG, msg, raw)


	## Gibt eine Information aus.
	## [param msg] — Meldung, wird mit [code]str()[/code] umgewandelt.
	## [param raw] — Wenn [code]true[/code], ohne Zeilenumbruch.
	func info(msg: Variant, raw: bool = false) -> void:
		_log(LogLevel.INFO, msg, raw)


	## Gibt eine Warnung über [code]push_warning()[/code] aus.
	## [param msg] — Meldung, wird mit [code]str()[/code] umgewandelt.
	## [param raw] — Wird für Warnungen nicht ausgewertet.
	func warn(msg: Variant, raw: bool = false) -> void:
		_log(LogLevel.WARN, msg, raw)


	## Gibt einen Fehler über [code]push_error()[/code] aus und erhöht [member error_count].
	## [param msg] — Meldung, wird mit [code]str()[/code] umgewandelt.
	## [param raw] — Wird für Fehler nicht ausgewertet.
	func error(msg: Variant, raw: bool = false) -> void:
		error_count += 1
		_log(LogLevel.ERROR, msg, raw)


	## Formatiert eine Meldung nach [member log_format] und rückt sie gemäß [member indent_level] ein.
	## [param level] — Level der Meldung.
	## [param msg] — Text der Meldung.
	func format_log(level: LogLevel, msg: String) -> String:
		return log_format.format(
			{
				"time": log_time_format.format(get_formatted_datatime()),
				"level": LogLevel.keys()[level],
				"msg": msg.indent("    ".repeat(indent_level)),
			},
		)


	## Erhöht die Einrückung um eine Stufe.
	func indent() -> void:
		indent_level += 1


	## Verringert die Einrückung um eine Stufe, höchstens bis 0.
	func dedent() -> void:
		indent_level = maxi(indent_level - 1, 0)


	## Sperrt die Ausgabe. Derzeit ungenutzt.
	func lock() -> void:
		is_locked = true


	## Hebt die Sperre der Ausgabe auf. Derzeit ungenutzt.
	func unlock() -> void:
		is_locked = false


	## Beginnt eine Tabelle; die Zeilen werden mit [method table_row] gesammelt.
	func table_start() -> void:
		_rows = []
		_is_table_started = true


	## Gibt die gesammelten Zeilen mit ausgerichteten Spalten aus und setzt die Tabelle zurück.
	func table_end() -> void:
		assert(_is_table_started, "Expected table_start() to be called first")
		for columns in _rows:
			var text: String = ""
			for i in columns.size():
				var column: String = columns[i]
				var column_tabs: int = ceili(column.length() / 4.0)
				if i < _max_column_size - 1:
					# Auffüllen auf das nächste Vielfache von 4, dann Viererblöcke bis zur breitesten Zeile
					var tab_count: int = ceili(_max_column_length[i] / 4.0) - column_tabs
					var extra_spaces: int = column_tabs * 4 - column.length()
					text += column + " ".repeat(extra_spaces) + "    ".repeat(tab_count)
				else:
					text += column
			info(text)

		_rows.clear()
		_is_table_started = false
		_max_column_length.clear()
		_max_column_size = 0


	## Fügt der Tabelle eine Zeile hinzu und merkt sich die Spaltenbreiten.
	## [param columns] — Texte der Spalten.
	func table_row(columns: Array = []) -> void:
		assert(_is_table_started, "Expected table_start() to be called first")
		_rows.append(columns)
		_max_column_size = maxi(_max_column_size, columns.size())
		for i in columns.size():
			var column_length: int = (columns[i] as String).length()
			if _max_column_length.size() >= i + 1:
				_max_column_length[i] = maxi(_max_column_length[i], column_length)
			else:
				_max_column_length.append(column_length)


	## Liefert die Systemzeit als [Dictionary] mit zweistellig (Jahr: vierstellig) aufgefüllten Textwerten
	## für [member log_time_format].
	func get_formatted_datatime() -> Dictionary:
		var datetime: Dictionary = Time.get_datetime_dict_from_system()
		datetime.year = "%04d" % datetime.year
		datetime.month = "%02d" % datetime.month
		datetime.day = "%02d" % datetime.day
		datetime.hour = "%02d" % datetime.hour
		datetime.minute = "%02d" % datetime.minute
		datetime.second = "%02d" % datetime.second
		return datetime


	## Gemeinsame Ausgabe: verwirft Meldungen bei Sperre oder zu niedrigem Level.
	## [param level] — Level der Meldung.
	## [param msg] — Meldung.
	## [param raw] — Wenn [code]true[/code], ohne Zeilenumbruch (nur bei Info und Debug).
	func _log(level: LogLevel, msg: Variant, raw: bool = false) -> void:
		if is_locked or log_level > level:
			return

		var text: String = format_log(level, str(msg))
		match level:
			LogLevel.WARN:
				push_warning(text)
			LogLevel.ERROR:
				push_error(text)
			_:
				if raw:
					printraw(text)
				else:
					print(text)
#endregion
