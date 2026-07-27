extends RefCounted
class_name AppVersion
## The running build's own version stamp. Bump this by hand (and tag/push a
## matching GitHub release, see tools/release.ps1) every time a new build is
## cut - Updater.gd compares this against the latest GitHub release tag to
## decide whether to offer an update.

const CURRENT := "1.3.0"
