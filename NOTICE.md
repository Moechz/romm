# Notices — RomM for TerraMaster TOS (`rommdocker`)

**Package version:** `5.4.1-1`
**Packager:** Moechz (independent community package)
**Upstream application:** RomM 5.4.1, <https://github.com/rommapp/romm>
**App Center:** <https://developer.terra-master.com>

This file records the licences, image provenance and trademark attributions for
the RomM TOS package. It is not the licence of the upstream application; the
upstream licence text and source are available at the links below.

---

## 1. Upstream application — RomM 5.4.1

| Item | Value |
|---|---|
| Project | RomM — self-hosted ROM manager and browser emulator front end |
| Upstream source | <https://github.com/rommapp/romm> (tag `5.4.1`, commit `9c74d0143fbb876f2f62260b91c6fd0b3f590226`) |
| Licence | **GNU Affero General Public License, version 3 only (AGPL-3.0-only)** — as declared by the upstream image label `org.opencontainers.image.licenses` |
| Licence text | <https://github.com/rommapp/romm/blob/5.4.1/LICENSE> |
| Copyright | RomM contributors |
| Container image | `rommapp/romm:5.4.1` (official image on Docker Hub) |
| Multi-arch index digest | `rommapp/romm@sha256:8677fb7b81b1d3db20b849e989a1dadc2a11159e51eb34a2acdcb01102274edf` |
| `linux/amd64` manifest | `sha256:923a808be529a834a171b3e045821aeb7e2851f4b6fc9514076785b68a9142f6` |
| `linux/arm64` manifest | `sha256:ebfd7670e2689beb42291bf4ae69860ebae9d20949cce5862b88c86678f688fa` |
| Image build date | 2026-10-22 |
| Runtime | Debian-based, Python 3.14 virtualenv, Node-built frontend, bundled Valkey and EmulatorJS |

The TOS package **does not contain or modify RomM source code**. It contains a
Compose file that pulls the official image unmodified from Docker Hub, the TOS
metadata and icon, and a small wrapper script that waits for the database
credential, persists the auth secret and then hands over to the upstream
entrypoint. Because the image is pulled by the user's Docker daemon, the image
itself is distributed by the upstream project under the AGPL-3.0-only terms
above; the corresponding source is available at the upstream repository and
tag. The wrapper is a separate work and is not a derivative of the RomM source.

### 1.1 EmulatorJS and bundled emulator cores (inside the RomM image)

RomM serves the browser player from EmulatorJS assets bundled in its own image
(`/romm/static/assets/emulatorjs`). EmulatorJS is distributed under the
**GPL-3.0**; the individual libretro emulator cores bundled with it keep their
own upstream licences (a mix of GPL-2.0, GPL-3.0 and permissive licences, per
core). They are redistributed inside the unmodified upstream image, not by this
package, and their sources are available from the EmulatorJS and libretro
projects linked from <https://emulatorjs.org> and <https://www.libretro.com>.
No emulator core is added, removed or patched by this package.

---

## 2. Database — MariaDB 11.8.6

| Item | Value |
|---|---|
| Project | MariaDB Server 11.8 (LTS line) |
| Upstream source | <https://github.com/MariaDB/server> · <https://mariadb.org> |
| Licence | **GNU General Public License, version 2 (GPL-2.0)** — as declared by the image label `org.opencontainers.image.licenses` |
| Licence text | <https://github.com/MariaDB/server/blob/11.8/COPYING> |
| Container image | `mariadb:11.8.6` (official image on Docker Hub) |
| Multi-arch index digest | `mariadb@sha256:78a5047d3ba33975f183f183c2464cc7f1eab13ec8667e57cc9a5821d6da7577` |
| `linux/amd64` manifest | `sha256:df764e5c6d6d3fcf4a6c298f9ab52d4e783d34f6dc0347da91933ad7f5f6ebb6` |
| `linux/arm64` manifest | `sha256:a7a644e095da9f033a8277df91f1cbf8ae9411a9109e2eea2861e7b046d73580` |
| Image build date | 2026-04-15 |
| Base | `ubuntu:noble` |

MariaDB is used unmodified as the application database. It is an internal-only
service: no port is published and it is reachable only from the RomM container
on the compose network. The package pins the current patch release of the 11.8
LTS line (11.8.2 → 11.8.6) so that the database receives the vendor's security
fixes while staying data-compatible with existing installations.

---

## 3. TOS packaging layer

| Item | Value |
|---|---|
| Package contents | `config.ini`, `rommdocker.lang`, `rommdocker.svg`, `docker-compose.yml` (four files, nothing else) |
| Packaging licence | **MIT** — see [`LICENSE`](LICENSE) in this repository |
| Copyright | Copyright (c) 2026 Moechz |
| Icon | Original RomM logo, distributed with the upstream project; used here only to identify the application |
| Wrapper | `src/entrypoint.sh`, MIT, embedded into the compose file at build time |

The packaging layer contains no upstream code and no third-party binaries. The
`rommdocker.lang` descriptions are original text written for this package.

---

## 4. Trademarks

- **RomM** and the RomM logo are trademarks of the RomM project / its
  contributors.
- **TerraMaster**, **TOS** and **App Center** are trademarks of TerraMaster.
- **Docker** and **Docker Hub** are trademarks of Docker, Inc.
- **MariaDB** is a trademark of the MariaDB Foundation.
- **IGDB** and **Twitch** are trademarks of Twitch Interactive, Inc. / Amazon.
- **MobyGames**, **ScreenScraper**, **SteamGridDB**, **RetroAchievements**,
  **Hasheous**, **EmulatorJS**, **LaunchBox**, **HowLongToBeat**, **TheGamesDB**
  and **Steam** are trademarks of their respective owners.

All trademarks are used only to describe the application and the services it
can optionally contact. This package is an **independent community submission
by Moechz**; it is not affiliated with, endorsed by or sponsored by the RomM
project, TerraMaster, or any of the metadata providers listed above.

---

## 5. Third-party services

RomM can contact third-party APIs **only when an administrator configures
credentials for them** (IGDB, MobyGames, ScreenScraper, SteamGridDB,
RetroAchievements) or **opts in** (Hasheous, PlayMatch, LaunchBox, Flashpoint,
HowLongToBeat, Demozoo, Pouët, CSDb, Steam, TheGamesDB, OIDC, SMTP). The default
installation additionally performs the browser-side GitHub release check, the
Docker Hub image pull, and the barcode lookup when a user adds a physical game.
Each service's own terms and privacy policy apply to the requests you enable.
The complete list of endpoints, the data sent and the destination region is in
[`PRIVACY.md`](PRIVACY.md) §4.

No API key, account or library data is bundled with this package. Providers'
terms may require a paid plan or a developer account; obtaining and complying
with those credentials is the administrator's responsibility.

---

## 6. Security and provenance notes for this release

- Upstream upgraded **4.8.1 → 5.4.1**. The 5.4.1 release specifically updates
  CA trust (removes compromised eMudhra intermediates) and upgrades aiohttp,
  Pillow, Node and pip; 5.0.0–5.4.1 include the upstream security and dependency
  fixes since 4.8.1.
- Database image upgraded **11.8.2 → 11.8.6**, the current patch release of the
  same LTS line.
- Both images are multi-arch OCI indexes (`linux/amd64` + `linux/arm64`), so the
  single package serves both TOS architectures.
- Images are referenced by fixed tags from Docker Hub; no `:latest`, no
  third-party registries, no local modifications.

---

## 7. Reporting

Licence or attribution problems: <https://github.com/Moechz/romm/issues>.
Security problems in the upstream application: the RomM project's security
policy at <https://github.com/rommapp/romm/security>.
