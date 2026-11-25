# Changelog

All notable user-visible changes to the RomM TOS application package.

## 5.4.1-1 — 2026-11-25

Remediation of the App Center listing review for `4.8.1-4` (codes C10 C3 C4 C5
C6 C7 C8 C9 T1, plus the non-blocking S11 finding). Upstream upgraded
**4.8.1 → 5.4.1**; the existing data folder is migrated automatically on first
start.

### Added
- **C3/C4/C5/C6/C7 — privacy policy** (`PRIVACY.md`): what is stored and where
  (ROMs, users, saves/states, metadata, logs, database, secrets), retention,
  user rights (access/correct/delete, account deletion, full data deletion),
  security measures, deletion channel and contact. `tosapp.json.help` and
  `config.ini.help` point to the public URL.
- **C8 — third-party disclosure**: complete endpoint table with the data sent
  and the destination region — IGDB (Twitch), MobyGames, ScreenScraper,
  SteamGridDB, RetroAchievements, Hasheous, GitHub release check/changelog,
  Docker Hub, EmulatorJS CDN, UPC lookup, optional PlayMatch/LaunchBox/
  Flashpoint/HowLongToBeat/Demozoo/Pouët/CSDb/Steam/TheGamesDB, SMTP and OIDC.
  `HASHEOUS_API_ENABLED` is pinned to `false` so the runtime matches the
  declaration.
- **C10 — repository/README**: full README with repository layout, how it works,
  first start, data and uninstall, privacy/notices, build, submit and
  troubleshooting sections.
- **`NOTICE.md` (licence/provenance, C2-equivalent)**: upstream AGPL-3.0-only, MariaDB GPL-2.0,
  EmulatorJS/core licences, image digests (multi-arch index + per-arch
  manifests), packaging MIT, trademark attribution.

### Changed
- **T1 — upstream security upgrade** 4.8.1 → 5.4.1 (certifi/CA trust fix and
  dependency upgrades for the eMudhra CA compromise, aiohttp, Pillow, Node,
  pip). Database image upgraded 11.8.2 → **11.8.6** (current patch of the same
  LTS line).
- **C9 — descriptions**: rewrote the 23-language text; `zh-cn`/`zh-hk` no
  longer describe a habit-tracking app (they were copied from an unrelated
  application) and now describe RomM's actual features, configuration and data location.
- **S11 — file permissions**: the entrypoint now uses `umask 077`, waits up to
  60 s for the database credential instead of silently starting without it,
  and keeps `auth_secret` at `0600`; the database password is generated with
  `umask 077`/`chmod 600` and the healthcheck reads it through `MYSQL_PWD`
  (never in the process list).
- **Robustness**: the MariaDB healthcheck now authenticates with the generated
  password (`mariadb-admin ping --silent`) instead of an unauthenticated ping,
  so "healthy" really means "the app can log in"; the RomM healthcheck interval
  is 15 s with a 300 s start period to cover first-start migrations.
- Removed the leftover `probe` block (it still carried an image digest and
  trial-run log from an unrelated application) and fixed `entrypoint_file` to `src/entrypoint.sh`.
  `tosapp.json.env.DB_USER` now matches the compose file (`romm`, not `root`).

## 4.8.1-1 — 2026-11-12

### Added
- First release. RomM (`rommapp/romm:4.8.1`, Docker Hub official image, unmodified)
  packaged as a TOS 7 Docker application, published on port 8099 and running
  as a non-root user (1000:1000).
- Persistent data is kept under `/Volume1/DockerAppData/rommdocker/`.
