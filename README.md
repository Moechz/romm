# romm-for-tos

> TerraMaster TOS 7 App Center — **Docker application** package for
> [RomM](https://github.com/rommapp/romm) 5.4.1.

RomM is a self-hosted ROM manager and browser emulator front end: scan a ROM
library, match titles, covers and screenshots from metadata providers you
configure, keep saves and save states in sync with your devices, and play
supported systems in the browser with EmulatorJS. This repository contains the
TOS packaging only; the application itself is the official upstream image, used
unmodified.

## What this is

A TOS Docker application archive (`rommdocker.tar.gz`) that installs RomM on
TOS 7 through the App Center. Two architectures are published:

| Package | Architecture | Submitted as |
|---|---|---|
| `rommdocker_x86_64.tar.gz` | x86_64 | App record `rommdocker` (platform `x86_64`) |
| `rommdocker_aarch64.tar.gz` | aarch64 | App record `rommdocker` (platform `aarch64`) |

The upstream image `rommapp/romm:5.4.1` is a multi-arch OCI index
(`linux/amd64` + `linux/arm64`), so both packages pull the same upstream
release; only the `config.ini` platform field differs.

## Repository layout

| Path | Contents |
|---|---|
| `tosapp.json` | Package specification: app id, upstream version, image, volumes, ports, translations, release notes. `tools/verify.py` and `scripts/build.sh` read it. |
| `src/config.ini` | TOS App Center metadata (id, name, version placeholder, port, category, `help` link). |
| `src/rommdocker.lang` | 23-language description file (`name`, `auth`, `version`, `descript`, `release_note`, `important`). Rendered from `tosapp.json` → `translations`. |
| `src/rommdocker.svg` | Application icon (512×512 viewBox, no embedded width/height). |
| `src/docker-compose.yml` | The two-service stack: RomM + MariaDB, non-root, health checks, `x-app-meta` web port. |
| `src/entrypoint.sh` | Wrapper entrypoint: waits for the database password, creates/persists the auth secret at `0600`, then hands over to the upstream entrypoint. Embedded into the compose file at build time. |
| `scripts/build.sh` | Stages the four files, substitutes `@@VERSION@@`/`@@PLATFORM@@`, embeds the entrypoint, runs the review-standards self-check, packs a deterministic tarball. |
| `scripts/build-dual.sh` | Builds both architectures into `out/` with `_x86_64` / `_aarch64` suffixes and runs the official `TOSAppSelfTestingTool -c` on both. |
| `tools/verify.py` | Review-standards self-check (archive layout, JSON validity, required fields, language coverage, ports, non-root user, per-service healthcheck/TZ/restart, no secrets, icon limits). Runs as the build gate. |
| `test/install-and-verify.sh` | On-device end-to-end install check (needs root; **not** used by the automated pipeline, which uses an isolated staging compose instead). |
| `PRIVACY.md` | Privacy policy: stored data, locations, retention, third-party endpoints, user rights, security measures, deletion channel. |
| `NOTICE.md` | Licences, image provenance/digests, trademark attribution. |
| `CHANGELOG.md` | Package change history. |
| `out/` | Build products (git-ignored): `rommdocker_x86_64.tar.gz`, `rommdocker_aarch64.tar.gz` and `.sha256`. |

`TOSAppSelfTestingTool` is the official TerraMaster checker binary, kept in the
repository root so both architectures can be checked reproducibly; the build
skips the official check with a warning if the binary is absent.

## How it works

| | |
|---|---|
| Containers | `rommdocker` (RomM 5.4.1, container port 8080) + `rommdocker-db` (MariaDB 11.8.6, internal only) |
| Container images | `rommapp/romm:5.4.1` and `mariadb:11.8.6` (Docker Hub, used unmodified, multi-arch) |
| Open | `http://<NAS-IP>:8099/` |
| Runs as | non-root, `user: "1000:1000"` for both services; no capabilities, no Docker socket, no host network |
| Persistent data | `/Volume1/DockerAppData/rommdocker/{library,resources,assets,config,redis,db,creds}` |
| Logs | `docker logs rommdocker` / `docker logs rommdocker-db` (stdout/stderr) |
| Health checks | RomM: HTTP `GET /` on container port 8080; MariaDB: authenticated `mariadb-admin ping` with the shared password |

## First start

1. Install from the App Center and open `http://<NAS-IP>:8099/`.
2. Complete the setup wizard: create the administrator account and choose a
   library folder (default `/romm/library`, i.e.
   `/Volume1/DockerAppData/rommdocker/library` on the NAS).
3. Put ROMs into the library folder (from the NAS file manager or an SMB share)
   and run **Scan** in the UI. RomM hashes the files and stores paths and
   metadata in its database; the ROM files themselves stay where they are.
4. Optional — metadata: enter your own API keys under **Settings → Metadata
   providers** (or in `config/.../config.yml`): IGDB, ScreenScraper,
   MobyGames, SteamGridDB, RetroAchievements. Without keys RomM still works
   offline, using file names only. Hasheous hash lookups are **off** in this
   package; enable them only if you accept sending ROM hashes to
   `hasheous.org` (see `PRIVACY.md` §4).
5. Optional — saves/sync: create users, install a RomM client (Playnite plugin,
   Android app, …) and pair it from **Settings → Devices**.

The database password and the RomM auth secret are generated on first start and
stored at `creds/db_password` and `config/auth_secret`, both mode `0600`. They
are never printed by the package.

## Data and uninstall

All data lives in one folder:

```
/Volume1/DockerAppData/rommdocker/
├── library/     your ROM files (you fill this)
├── resources/   downloaded covers, screenshots, manuals, EmulatorJS assets
├── assets/      saves, save states, memory cards, uploaded screenshots/patches, avatars
├── config/      config.yml + auth_secret (0600)
├── redis/       Valkey cache / task queue
├── db/          MariaDB data directory (users, library catalogue, audit log)
└── creds/       db_password (0600)
```

- **Update:** replaces the containers, keeps the folder. Database migrations run
  automatically on start (a 4.8.1 installation is migrated in place on first
  start of 5.4.1; back up `db/` first if the library matters to you).
- **Uninstall without data removal:** containers are removed, the folder stays.
  Reinstalling picks the data up again.
- **Uninstall with data removal:** the App Center deletes
  `/Volume1/DockerAppData/rommdocker/` — ROMs, saves, database and credentials
  are gone. Back up first. The package has no uninstall hook; deleting that
  folder (after stopping the app) is the complete removal.
- **Backup:** stop the app, copy the whole folder, start again. Copying `db/`
  while MariaDB is running can produce an inconsistent backup — use
  `mariadb-dump` inside the container or stop the stack first.

## Privacy and third-party services

Read [`PRIVACY.md`](PRIVACY.md). In short:

- Everything (ROMs, users, saves, database, logs) stays in
  `/Volume1/DockerAppData/rommdocker/` on your NAS. The packager receives
  nothing and cannot access your instance.
- No telemetry, analytics or crash reporting.
- Outbound requests only when you configure them: IGDB, MobyGames,
  ScreenScraper, SteamGridDB, RetroAchievements (each needs your API key),
  Hasheous (off), UPC barcode lookup (only when adding a physical game),
  optional SMTP/OIDC and optional provider integrations.
- Always-on transport contacts: the web UI's GitHub release check
  (`api.github.com`, browser side) and Docker Hub image pulls (install/update
  only). The EmulatorJS CDN is a fallback for missing local assets.
- Every endpoint, the data sent and its region are listed in `PRIVACY.md` §4.

## Notices and licences

Read [`NOTICE.md`](NOTICE.md).

- RomM 5.4.1 — **AGPL-3.0-only**, <https://github.com/rommapp/romm>. The
  official image `rommapp/romm:5.4.1` is pulled unmodified by your Docker
  daemon; no upstream source is redistributed in this repository.
- MariaDB 11.8.6 — **GPL-2.0**, official Docker Hub image, used unmodified as
  the internal database.
- EmulatorJS and bundled emulator cores ship inside the RomM image under their
  own licences (GPL-3.0 and per-core licences).
- This packaging layer — **MIT**, Copyright (c) 2026 Moechz.
- RomM, TerraMaster, Docker, MariaDB and the metadata-provider names are
  trademarks of their owners; this is an independent community package, not
  affiliated with or endorsed by any of them.

## Build

```bash
scripts/build.sh 5.4.1-1 x86_64     # -> out/rommdocker.tar.gz + .sha256
scripts/build-dual.sh 5.4.1-1       # -> both architectures + official -c on both
```

The build stages the four archive files, substitutes the version/platform
placeholders, embeds `src/entrypoint.sh` into the compose block scalar (escaping
every `$` as `$$`), normalises CRLF/BOM/AppleDouble, runs `tools/verify.py`
(review-standards gate) and then packs a deterministic tarball (GNU tar, uid/gid
0, zeroed mtimes, gzip without timestamp).

Official check (required before submitting):

```bash
./TOSAppSelfTestingTool -c out/rommdocker_x86_64.tar.gz    # must print "check passed"
./TOSAppSelfTestingTool -c out/rommdocker_aarch64.tar.gz   # must print "check passed"
```

## Submit

1. Publish the GitHub release with tag `v5.4.1-1` and assets
   `rommdocker_x86_64.tar.gz`/`.sha256` and `rommdocker_aarch64.tar.gz`/`.sha256`.
2. Developer platform → the app record → version management → upload the
   package for each architecture, add the review remark and submit.
3. Verify the platform's parsed `file_hash` equals the local `sha256sum`.

## Troubleshooting

| Symptom | Check |
|---|---|
| App Center page does not open | `docker ps` — both containers must be `Up (healthy)`; first start runs database migrations and can take 1–3 minutes. |
| `docker logs rommdocker` shows `Missing database credentials` | The `creds/` volume must be shared between both services; this package's compose does that. Reinstall if the folder was created by an older package. |
| First start fails on a slow NAS | Migrations can exceed the health-check grace period; the container keeps retrying (`restart: unless-stopped`). Wait, then check `docker logs`. |
| Metadata is never matched | No API key configured, or the provider cannot be reached from the NAS. RomM never falls back to sending your library anywhere else. |
| Port 8099 already used | Port collisions between App Center apps are expected; install one of the conflicting apps at a time or change the port in your own copy. The package keeps 8099 by policy. |
| Upgrade from 4.8.1 | Data is migrated automatically. Take a backup of `db/` and `assets/` first; downgrading after migration is not supported. |

## Licence

Packaging: MIT (see [`LICENSE`](LICENSE)). Upstream application: AGPL-3.0-only
(see [`NOTICE.md`](NOTICE.md)).
