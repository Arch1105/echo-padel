extends Node
## Self-updater: checks GitHub Releases for a build newer than AppVersion.
## CURRENT, and - if the player agrees - downloads it and hands off to a
## small batch-script helper that waits for this process to fully exit,
## copies the new files over the current install, relaunches the new
## EchoPadel.exe, and cleans up after itself.
##
## Windows won't let a running .exe overwrite its own file, so this can't be
## done in-process: the helper script polls `tasklist` until EchoPadel.exe is
## no longer running, then copies. That's why begin_update() ends by calling
## get_tree().quit() once the helper is launched, rather than trying to swap
## files itself.
##
## Deliberately inert when run from the editor (OS.has_feature("editor") is
## true for *any* run through the editor binary, including this project's own
## headless -s test scripts) - only a real exported build ever touches disk
## here. check_for_update() still works from the editor (harmless, just an
## HTTP GET) so the check itself is testable; begin_update() refuses.

signal update_check_finished(available: bool, version: String, download_url: String)
signal update_check_failed(reason: String)
signal update_download_progress(fraction: float)
signal update_failed(reason: String)

const REPO := "Arch1105/echo-padel"
const API_URL := "https://api.github.com/repos/%s/releases/latest" % REPO
const ASSET_NAME := "EchoPadel-Windows.zip"
const EXE_NAME := "EchoPadel.exe"
const USER_AGENT := "EchoPadel-Updater"

var _check_request: HTTPRequest
var _download_request: HTTPRequest
var _pending_zip_path: String
var _progress_timer: Timer

func _ready() -> void:
	_check_request = HTTPRequest.new()
	add_child(_check_request)
	_check_request.request_completed.connect(_on_check_completed)

	_download_request = HTTPRequest.new()
	add_child(_download_request)
	_download_request.download_chunk_size = 65536
	_download_request.request_completed.connect(_on_download_completed)

	_progress_timer = Timer.new()
	_progress_timer.wait_time = 0.2
	_progress_timer.timeout.connect(_on_progress_tick)
	add_child(_progress_timer)

func check_for_update() -> void:
	var err: int = _check_request.request(API_URL, [
		"User-Agent: %s" % USER_AGENT,
		"Accept: application/vnd.github+json",
	])
	if err != OK:
		update_check_failed.emit("request_error")

func _on_check_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_check_failed.emit("check_failed")
		return
	var parsed: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY:
		update_check_failed.emit("bad_response")
		return
	var tag: String = str(parsed.get("tag_name", ""))
	var remote_version: String = tag.trim_prefix("v")
	var download_url: String = ""
	for asset in parsed.get("assets", []):
		if asset.get("name", "") == ASSET_NAME:
			download_url = str(asset.get("browser_download_url", ""))
			break
	var available: bool = download_url != "" and _is_newer(remote_version, AppVersion.CURRENT)
	update_check_finished.emit(available, remote_version, download_url)

## Plain dotted version compare (e.g. "1.2.0" vs "1.10.0") - not a full semver
## parser (no pre-release/build-metadata suffixes), which is all a hand-bumped
## "X.Y.Z" tag on this project ever needs.
static func _is_newer(remote: String, current: String) -> bool:
	var r: PackedStringArray = remote.split(".")
	var c: PackedStringArray = current.split(".")
	var parts: int = maxi(r.size(), c.size())
	for i in range(parts):
		var rv: int = int(r[i]) if i < r.size() else 0
		var cv: int = int(c[i]) if i < c.size() else 0
		if rv != cv:
			return rv > cv
	return false

func begin_update(download_url: String) -> void:
	if OS.has_feature("editor"):
		update_failed.emit("editor_mode")
		return
	var exe_dir: String = OS.get_executable_path().get_base_dir()
	var staging_dir: String = exe_dir.path_join("update_staging")
	var dir_err: int = DirAccess.make_dir_recursive_absolute(staging_dir)
	if dir_err != OK and dir_err != ERR_ALREADY_EXISTS:
		update_failed.emit("staging_dir_failed")
		return
	_pending_zip_path = staging_dir.path_join("update.zip")
	_download_request.download_file = _pending_zip_path
	var err: int = _download_request.request(download_url, ["User-Agent: %s" % USER_AGENT])
	if err != OK:
		update_failed.emit("download_start_failed")
		return
	_progress_timer.start()

func _on_progress_tick() -> void:
	var body_size: int = _download_request.get_body_size()
	var downloaded: int = _download_request.get_downloaded_bytes()
	if body_size > 0:
		update_download_progress.emit(float(downloaded) / float(body_size))

func _on_download_completed(result: int, response_code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	_progress_timer.stop()
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		update_failed.emit("download_failed")
		return
	var exe_dir: String = OS.get_executable_path().get_base_dir()
	var staging_dir: String = exe_dir.path_join("update_staging")
	var extract_dir: String = staging_dir.path_join("extracted")
	if not _extract_zip(_pending_zip_path, extract_dir):
		update_failed.emit("extract_failed")
		return
	if not FileAccess.file_exists(extract_dir.path_join(EXE_NAME)):
		update_failed.emit("extract_incomplete")
		return
	if not _write_and_launch_helper(exe_dir, staging_dir, extract_dir):
		update_failed.emit("helper_launch_failed")
		return
	get_tree().quit()

func _extract_zip(zip_path: String, dest_dir: String) -> bool:
	var reader := ZIPReader.new()
	if reader.open(zip_path) != OK:
		return false
	for path in reader.get_files():
		if path.ends_with("/"):
			continue
		var out_path: String = dest_dir.path_join(path)
		var mkdir_err: int = DirAccess.make_dir_recursive_absolute(out_path.get_base_dir())
		if mkdir_err != OK and mkdir_err != ERR_ALREADY_EXISTS:
			reader.close()
			return false
		var data: PackedByteArray = reader.read_file(path)
		var f: FileAccess = FileAccess.open(out_path, FileAccess.WRITE)
		if f == null:
			reader.close()
			return false
		f.store_buffer(data)
		f.close()
	reader.close()
	return true

## Windows won't let the game overwrite its own running .exe, so a detached
## helper does it after this process exits: wait for EchoPadel.exe to stop
## appearing in `tasklist` (bounded retries, not an infinite wait), copy the
## extracted build over the install directory, and relaunch it. Cleanup of
## the staging folder is a *separate* script, launched by the first one and
## left to delete its own containing folder after a short delay - splitting
## it out avoids the fragile nested-quoting a single one-liner would need to
## both run a detached command *and* pass it a quoted path with spaces.
func _write_and_launch_helper(exe_dir: String, staging_dir: String, extract_dir: String) -> bool:
	var apply_bat_path: String = staging_dir.path_join("apply_update.bat")
	var cleanup_bat_path: String = staging_dir.path_join("cleanup_staging.bat")

	var apply_template := """@echo off
setlocal
set "SRC={src}"
set "DEST={dest}"
set "EXE={exe}"
set "COUNT=0"

:waitloop
tasklist /FI "IMAGENAME eq %EXE%" 2>NUL | find /I "%EXE%" >NUL
if not errorlevel 1 (
    set /a COUNT+=1
    if %COUNT% GEQ 60 goto giveup
    timeout /t 1 /nobreak >nul
    goto waitloop
)

set "COUNT=0"
:copyloop
xcopy "%SRC%\\*" "%DEST%\\" /E /Y /I >NUL 2>&1
if errorlevel 1 (
    set /a COUNT+=1
    if %COUNT% GEQ 10 goto giveup
    timeout /t 1 /nobreak >nul
    goto copyloop
)

start "" "%DEST%\\%EXE%"
start "" "{cleanup}"
exit /b 0

:giveup
exit /b 1
"""
	var apply_text: String = apply_template.format({
		"src": extract_dir.replace("/", "\\"),
		"dest": exe_dir.replace("/", "\\"),
		"exe": EXE_NAME,
		"cleanup": cleanup_bat_path.replace("/", "\\"),
	})

	# Self-deletes its own containing folder - safe here because by the time
	# it runs, apply_update.bat (the only other process that had files open
	# in this folder) has already finished and exited. If rmdir fails for any
	# reason, that's just a harmless leftover folder, not a broken install -
	# the 2>nul keeps it silent either way.
	var cleanup_template := """@echo off
timeout /t 2 /nobreak >nul
rmdir /S /Q "{staging}" 2>nul
"""
	var cleanup_text: String = cleanup_template.format({
		"staging": staging_dir.replace("/", "\\"),
	})

	var apply_f: FileAccess = FileAccess.open(apply_bat_path, FileAccess.WRITE)
	if apply_f == null:
		return false
	apply_f.store_string(apply_text)
	apply_f.close()

	var cleanup_f: FileAccess = FileAccess.open(cleanup_bat_path, FileAccess.WRITE)
	if cleanup_f == null:
		return false
	cleanup_f.store_string(cleanup_text)
	cleanup_f.close()

	var pid: int = OS.create_process("cmd.exe", ["/c", apply_bat_path], false)
	return pid > 0
