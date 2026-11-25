# Privacy policy — RomM for TerraMaster TOS (`rommdocker`)

**Last updated:** 2026-11-25
**Applies to:** RomM package version `5.4.1-1` and later, published by Moechz in
the TerraMaster App Center.
**Upstream project:** <https://github.com/rommapp/romm> (RomM 5.4.1, AGPL-3.0)
**Contact / data requests:** <https://github.com/Moechz/romm/issues>
**Upstream privacy-relevant docs:** <https://docs.romm.app/latest/>

This policy explains what the RomM package stores on your NAS, where it is
stored, how long it is kept, what leaves the NAS and to whom, which third-party
services can be contacted, and how you and the users of your instance can
access, correct or delete that data.

RomM is a **self-hosted** application. It runs entirely on your TerraMaster NAS
in two Docker containers (RomM and MariaDB). The packager does not operate a
server for this app, does not receive your ROM library, user accounts, saves,
logs or telemetry, and cannot access your NAS. For everything you put into
RomM, the **data controller is you** — the owner/administrator of the NAS. The
upstream cloud demo (`demo.romm.app`), the upstream documentation site and the
metadata providers listed in §4 are separate services with their own policies;
they are not operated by the packager.

RomM contains **no telemetry, analytics, advertising or crash reporting** of its
own, and the package adds none. Outbound requests happen only in the cases
listed in §4.

---

## 1. What the application stores

### 1.1 MariaDB database (system of record)

Structured data lives in the MariaDB cluster under
`/Volume1/DockerAppData/rommdocker/db` (container path `/var/lib/mysql`).

| Data | Table(s) | Why |
|---|---|---|
| **User accounts** — username, **e-mail address** (optional), **bcrypt password hash**, role (`admin`/`editor`/`viewer`), permission group, optional age limit, avatar path, UI settings, last login / last active timestamps, RetroAchievements username and cached progression | `users` | Sign-in, authorisation and personalisation. |
| **OIDC identity link** — issuer and subject of the external identity provider | `users` (`oidc_issuer`, `oidc_sub`) | Only populated if an administrator enables OIDC. |
| **API client tokens** — token name, **SHA-256 hash** of the token, scopes, expiry, last-used time, bound device | `client_tokens` | Let the mobile/desktop clients and sync agents authenticate without a password. |
| **Devices** — device id, name, platform, client and version, **IP address**, **MAC address**, hostname, sync mode/config, capabilities, last-seen time | `devices` | Save/state sync and "managed devices" in the UI. |
| **Play sessions** — user, device, ROM, save slot, start/end time, duration | `play_sessions` | Play history and "continue playing". |
| **Audit log** — actor (user/device/system), action, target, **IP address**, device id, JSON details, timestamp | `audit_events` | Security-relevant history (logins, user/role changes, deletions). |
| **Notifications** — title, body, level, link, icon, JSON payload, read time | `notifications` | In-app notifications. |
| **Notification channels** — type, name, **channel configuration (webhook URL / e-mail address and credentials)**, minimum level, topics, delivery status | `notification_channels` | Only created when a user configures a channel (e.g. webhook, e-mail). |
| **Library metadata** — platform, ROM title, file name and relative path, file size, **ROM hashes (CRC32/MD5/SHA1)**, matched provider ids (IGDB, MobyGames, ScreenScraper, SteamGridDB, RetroAchievements, Hasheous), descriptions, genres, companies, release dates, ratings, cover/screenshot/manual URLs, tags, notes, user status/rating/backlog, save-sync timestamps | `platforms`, `roms`, `rom_users`, `rom_notes`, `saves`, `states`, `screenshots`, `collections`, `smart_collections`, `permission_groups`, `firmware` | The library catalogue and its metadata. |
| **Save/state sync bookkeeping** — device, user, session status, counters, error message | `sync_sessions`, `device_save_syncs`, `sync_sessions` | Conflict detection during sync. |
| **Music/playlists, recommendations, deleted-asset tombstones** | `music`, `recommendations`, `deleted_assets` | Optional features (soundtracks, recommendations). |

No table stores ROM file contents; the ROMs themselves stay in the library
folder (§1.2).

### 1.2 Files created by the package itself

Everything below is inside the application data folder and is created on first
start. None of it is shipped in the public package.

| Path (host) | Container path | Contents |
|---|---|---|
| `/Volume1/DockerAppData/rommdocker/library` | `/romm/library` | **Your ROM files** (the library you fill yourself), including multi-disc folders and patches. Stored as you put them; RomM only reads/hashes them and writes converted or patched copies on request. |
| `/Volume1/DockerAppData/rommdocker/resources` | `/romm/resources` | Downloaded artwork and metadata assets: covers, screenshots, manuals, title screens, platform icons, EmulatorJS core assets. |
| `/Volume1/DockerAppData/rommdocker/assets` | `/romm/assets` | **User-generated data**: save files, save states, memory cards, uploaded screenshots, uploaded ROMs/patches, user avatars. |
| `/Volume1/DockerAppData/rommdocker/config` | `/romm/config` | `config.yml` (instance and scanning configuration) and `auth_secret` (the random key that signs access/refresh tokens and the session cookie). Created on first start, mode `0600`. |
| `/Volume1/DockerAppData/rommdocker/redis` | `/redis-data` | Valkey (Redis-compatible) data: background-task queue, scan progress, cached frontend/config responses, short-lived task results. |
| `/Volume1/DockerAppData/rommdocker/db` | `/var/lib/mysql` | The MariaDB data directory described in §1.1. |
| `/Volume1/DockerAppData/rommdocker/creds` | `/run/creds` | `db_password`, the random MariaDB password generated on first start and shared by the two containers, mode `0600`. |

### 1.3 Logs

Both containers log to stdout/stderr, which the Docker engine writes to its
`json-file` log (`docker logs rommdocker`, `docker logs rommdocker-db`). These
logs can contain usernames, **client IP addresses**, requested paths, scan
results, file names of scanned ROMs and error messages that include provider
responses. They are stored by Docker on the NAS (default location
`/Volume1/@apps/DockerEngine/DockerData/containers/...`), rotated by the Docker
daemon's logging configuration, and are **not** sent anywhere by this package.
RomM 5 also offers an in-app backend log viewer; it reads the same logs and is
admin-only.

### 1.4 Credentials the package generates

- **Database password** — 32 random characters, written to
  `/Volume1/DockerAppData/rommdocker/creds/db_password`, mode `0600`, used by
  both containers, never logged and never sent off the NAS.
- **RomM auth secret** — 32 random bytes (base64), written to
  `/Volume1/DockerAppData/rommdocker/config/auth_secret`, mode `0600`. It signs
  session cookies and OAuth tokens; it is not a third-party key.
- **API keys you enter** for metadata providers are stored in the database
  (settings) or in `config.yml`, in plain text, because RomM must send them to
  the provider. They are readable by anyone who can read the data folder or the
  database; protect it like a password store.

---

## 2. Where the data is stored

Everything stays on the NAS, below `/Volume1/DockerAppData/rommdocker/`, on the
volume you chose during installation. The containers write nothing outside
their own data folders except ephemeral files in the container filesystem
(`/tmp`, `/run`, the image itself), which are discarded when the container is
recreated. The package does not use S3/object storage, does not mount
`/var/run/docker.sock`, and does not expose the database or Redis ports to the
LAN — only the RomM web port `8099` is published.

Access to the files follows the NAS filesystem: the containers run as uid/gid
`1000:1000`, and the App Center creates the folders owned by that user. Any NAS
account with read access to `/Volume1/DockerAppData` can read the ROMs, saves and
database files directly.

---

## 3. Legal basis and roles (self-hosted)

- The **NAS owner/administrator** decides what is scanned, which users exist,
  which providers are configured and how long data is kept. In GDPR terms the
  administrator is normally the controller and the packager is not a processor:
  the packager never receives the data.
- **End users** of an instance should ask their instance administrator for
  access, correction or deletion; the administrator has the tools described in
  §7.
- The **packager** processes only what is necessary to publish the package
  (GitHub repository and release assets, App Center listing) and any message you
  choose to send to the issue tracker; that is governed by GitHub's and
  TerraMaster's own policies.

---

## 4. What leaves the NAS, to whom, and when (third-party disclosure)

Nothing in §4.1–§4.3 is enabled by default in this package; those providers
require credentials that only an administrator can enter. §4.4–§4.8 are
transport-level or opt-in-by-action contacts.

### 4.1 Metadata and artwork providers (opt-in: need your own API key)

| Provider | Endpoint | Data sent | Credential | Destination / region | Enabled |
|---|---|---|---|---|---|
| **IGDB** (Twitch) | `https://api.igdb.com/v4/*`, OAuth token at `https://id.twitch.tv/oauth2/token` | Game-title search terms derived from ROM file names and platform ids; IGDB game ids when refreshing a match. No file contents, no hashes. | `IGDB_CLIENT_ID` + `IGDB_CLIENT_SECRET` (Twitch developer application) | Twitch/Amazon, United States | Only if both keys are set |
| **MobyGames** | `https://api.mobygames.com/v1/*` | Game-title search terms and MobyGames ids. No file contents. | `MOBYGAMES_API_KEY` | MobyGames, United States | Only if the key is set |
| **ScreenScraper** | `https://api.screenscraper.fr/api2/*` | **ROM hashes (CRC32, MD5, SHA-1)**, file size, file name, platform/system id, and your ScreenScraper account name. No ROM content. | `SCREENSCRAPER_USER` + `SCREENSCRAPER_PASSWORD` (free developer account) | ScreenScraper, France (EU) | Only if both are set |
| **SteamGridDB** | `https://steamgriddb.com/api/v2/*` | Game name, platform, IGDB/SteamGridDB ids. No file contents. | `STEAMGRIDDB_API_KEY` | SteamGridDB, United States | Only if the key is set |
| **RetroAchievements** | `https://retroachievements.org/API/*` | **MD5 hash of the ROM**, your RetroAchievements username and API key, progress queries for that user. | `RETROACHIEVEMENTS_API_KEY` (+ the username stored per user) | RetroAchievements, United States | Only if the key is set |

When RomM asks one of these providers for metadata it also **downloads** the
returned covers, screenshots and manuals into `resources/`; those downloads
carry your NAS's public IP address to the provider's CDN (IGDB images are served
from `images.igdb.com`, a Twitch/Amazon CDN).

### 4.2 Hash lookups (off by default in this package)

| Provider | Endpoint | Data sent | Credential | Destination | Enabled |
|---|---|---|---|---|---|
| **Hasheous** | `https://hasheous.org/api/v1/Lookup/ByHash`, `/MetadataProxy/IGDB/*` | **MD5/SHA-1/CRC32 hashes** of the scanned files (and, in the IGDB proxy calls, IGDB ids). No file contents, no names. | None (public service) | Hasheous, United States | **Forced off** — the package sets `HASHEOUS_API_ENABLED=false`. Set it to `true` in `config.yml` to opt in. |

### 4.3 Optional provider integrations (off by default)

These are available in RomM but disabled unless an administrator turns them on;
each sends the game title / platform id / barcode it is asked about to the
listed service:

| Integration | Endpoint | Data | Default |
|---|---|---|---|
| PlayMatch | `https://playmatch.retrorealm.dev/api/v2` (or your own URL) | game title, platform id | off (`PLAYMATCH_API_ENABLED=false`) |
| LaunchBox metadata | LaunchBox metadata index (download) | no user data; downloads a public metadata index | off |
| Flashpoint | Flashpoint API | game title | off |
| HowLongToBeat | HLTB API | game title | off |
| Demozoo / Pouët / CSDb | respective APIs | scene release id or title | off |
| Steam | Steam store API | game title, PC platform | off |
| TheGamesDB | `https://api.thegamesdb.net` | game title | off |

### 4.4 UPC / barcode lookup (on, but only when you scan a barcode)

`https://api.upcitemdb.com/prod/trial/lookup` — RomM sends **only the barcode**
you type or scan when adding a physical game, and receives the product title.
No account data is sent. Controlled by `UPC_LOOKUP_ENABLED` (default `true`);
set it to `false` to disable.

### 4.5 Update check and changelog (on, from the browser)

RomM's web interface asks the public GitHub API for the latest release
(`https://api.github.com/repos/rommapp/romm/releases/latest`) to show the "new
version" banner, and for the ten latest releases
(`https://api.github.com/repos/rommapp/romm/releases?per_page=10`) when you open
the changelog dialog. The request contains **no library, account or usage
data** — only what any HTTPS request to GitHub contains: your browser's IP
address, User-Agent and the repository path. GitHub (Microsoft, United States)
therefore learns that someone at your IP opened the RomM UI. Blocking
`api.github.com` at the firewall or DNS level only disables those two UI
elements; the app keeps working.

### 4.6 Container images (on, at install and update only)

The Docker daemon pulls `rommapp/romm:5.4.1` and `mariadb:11.8.2` from Docker
Hub (`registry-1.docker.io`, `auth.docker.io`, `production.cloudflare.docker.com`).
This reveals your public IP address to Docker Hub (Docker Inc., United States)
and its CDN. No library or user data is part of the request. If Docker Hub is
unreachable, configure a registry mirror in Docker Engine.

### 4.7 EmulatorJS web assets (fallback only)

The browser loads EmulatorJS from the local package
(`/assets/emulatorjs/data`). If a file is missing, RomM falls back to
`https://cdn.emulatorjs.org/<version>/data` (Cloudflare CDN, global anycast),
which reveals your browser's IP address and User-Agent to the CDN. Enabling
EmulatorJS netplay switches the order (CDN first). No ROM, save or account data
is sent by this fallback; gameplay stays between your browser and your NAS.

### 4.8 Netplay (off by default)

EmulatorJS netplay is disabled unless `emulatorjs.netplay.enabled: true` is set
in `config.yml`. When enabled, WebRTC uses the ICE/STUN/TURN servers listed
under `emulatorjs.netplay.ice_servers` — RomM ships none, so you must add your
own; those servers see your browser's IP address and WebRTC candidates. The
game session itself is relayed peer-to-peer or through your TURN server, never
through the packager.

### 4.9 Optional e-mail and single sign-on (off by default)

- **SMTP** — if you configure `SMTP_HOST`/`SMTP_FROM`, RomM sends notification
  e-mails and password-reset links through **your** mail server; recipient
  addresses and message bodies go to that server only.
- **OIDC/SSO** — if you enable it, your browser is redirected to **your**
  identity provider and RomM stores the issuer, subject, username and e-mail it
  receives. The packager operates neither service.

### 4.10 Summary

The only **automatic** outbound contacts of a default installation are the
GitHub API calls from the browser (§4.5), the Docker Hub pulls at install/update
(§4.6) and, only after you act, the UPC lookup (§4.4). No ROM, save, user or
usage data is sent to the packager, ever.

---

## 5. Retention

| Data | Retention |
|---|---|
| ROM library, saves, states, screenshots, resources | Kept until you delete them from the library/assets folders or remove the app data. RomM never deletes library files automatically. |
| Database rows (users, devices, play sessions, audit events, metadata) | Kept until deleted in the UI or with the app data. The audit log and play history are not auto-pruned. |
| Notifications | Kept until dismissed/deleted; read notifications can be cleared in the UI. |
| Valkey cache / task results | Task results default `TASK_RESULT_TTL=86400` (24 h); cache entries are evicted by Valkey or on container restart. |
| `config.yml`, `auth_secret`, `db_password` | For the life of the installation. |
| Docker logs | Governed by the Docker daemon (`json-file`, default rotation); the package does not configure a retention period. Remove with `docker logs` rotation settings or by recreating the container. |
| Backups you make | Your own retention. |

There is no packager-side copy of anything, so there is no packager-side
retention period.

---

## 6. Security measures

- **Non-root.** Both containers run as `user: "1000:1000"`; no `privileged`, no
  `cap_add`, no `network_mode: host`, no Docker socket, no `group_add`.
- **Minimal published surface.** Only `8099/tcp` (RomM UI) is published;
  MariaDB and Valkey are reachable only on the internal compose network.
- **Generated secrets, never hard-coded.** The MariaDB password and the RomM
  auth secret are random per installation and stored **mode `0600`** in
  `creds/` and `config/` (the entrypoint sets `umask 077` and re-applies
  `chmod 600`). The DB healthcheck reads the password through `MYSQL_PWD`, so it
  does not appear in the process list.
- **Passwords are bcrypt hashes**; client tokens are stored as SHA-256 hashes.
- **Least privilege in the app.** RomM has admin/editor/viewer roles and
  per-user permission groups; create separate accounts for household members
  instead of sharing the administrator.
- **Health checks** on both containers; `restart: unless-stopped`.
- **Fixed image tags** from Docker Hub only, upgraded with security releases.
- **Limits of the default setup:** the App Center opens plain **HTTP** on the
  LAN. Session cookies are not marked `Secure` by default (no TLS terminator).
  Before exposing RomM to the internet, put a TLS reverse proxy in front, enable
  `ROMM_SESSION_SECURE_COOKIE=true`, and keep the NAS firewall closed to
  everything except that proxy. Back up the data folder; the package does not
  back it up for you.

---

## 7. Your rights and how to exercise them

You (and every user of your instance) can:

| Right | How |
|---|---|
| **Access / export** | Admins: **Settings → Users**, and the per-user profile; the API (`/api/users/me`) returns the account record. Library data is visible in the UI and in the MariaDB tables listed in §1.1. Saves/states/screenshots are ordinary files under `assets/` and can be copied at any time. |
| **Correct** | Change your username, e-mail, password, avatar and UI settings in the profile; admins can edit roles, permission groups, age limits and device entries. Metadata can be re-matched or edited per ROM. |
| **Delete a single item** | Delete ROMs, saves, states, screenshots, collections, notes, notifications, devices and API client tokens in the UI (deleting a ROM removes its database rows; delete the file from `library/` yourself if you want it gone from disk). |
| **Delete an account** | Admins: **Settings → Users → delete**. This cascades to that user's saves, states, screenshots, notes, collections, play sessions and client tokens (database `ON DELETE CASCADE`). |
| **Delete everything** | Stop the app, then delete `/Volume1/DockerAppData/rommdocker/` — the library, assets, resources, database, Redis data, config and credentials are all inside it. In the App Center, uninstalling **with data removal** does the same; uninstalling without it keeps the folder. |
| **Object / restrict** | Disable a user, remove provider API keys, set `HASHEOUS_API_ENABLED=false`/`UPC_LOOKUP_ENABLED=false`, block `api.github.com` and `cdn.emulatorjs.org`, or run the NAS without internet access — the local features keep working. |
| **Complain** | Contact your instance administrator first; the packager cannot access your data. The packager's contact channel is the public issue tracker above. |

Requests to the **packager** (e.g. about the package itself, not your data) are
handled at <https://github.com/Moechz/romm/issues>; there is no packager-held
personal data to export or erase.

---

## 8. Deletion channel

- **From the app:** per-item deletion in the UI, account deletion by an admin.
- **From the NAS:** delete `/Volume1/DockerAppData/rommdocker/` after stopping
  the app; this is the single folder that contains all application data.
- **From the App Center:** uninstall the app and choose to delete its data.
- **Backups/copies:** if you copied the folder elsewhere, delete those copies
  too; the package cannot reach them.

Deletion is immediate and irreversible; there is no soft-delete or trash for
the database (some UI deletes keep a tombstone row in `deleted_assets` for sync
consistency, which contains only the asset path and deletion time).

---

## 9. Children

RomM is a general-purpose ROM library manager with no age verification. An
administrator can set a per-user **age limit** so that games above it are
hidden, and can create restricted permission groups. The packager does not
knowingly collect data from anyone; there is no packager-side collection at all.

---

## 10. Changes to this policy

This document is versioned with the package. Material changes are described in
`CHANGELOG.md` and in the release notes of the version that introduces them.
The current version is always available at
<https://github.com/Moechz/romm/blob/main/PRIVACY.md> (the App Center `help`
link points there).

---

## 11. Contact

- Package issues and data questions: <https://github.com/Moechz/romm/issues>
- Upstream RomM: <https://github.com/rommapp/romm> ·
  <https://docs.romm.app/latest/>
- TerraMaster App Center: <https://developer.terra-master.com>
