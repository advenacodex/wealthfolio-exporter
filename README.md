<div align="center">

# wealthfolio-exporter

**Export your [Wealthfolio](https://wealthfolio.app) holdings to CSV and Markdown**<br>
**Exporta tus posiciones de [Wealthfolio](https://wealthfolio.app) a CSV y Markdown**

[![License: MIT](https://img.shields.io/badge/license-MIT-2ea44f.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-4eaa25.svg)](holdings.sh)
[![Database](https://img.shields.io/badge/database-read--only-6b7280.svg)](#privacy)
[![Network](https://img.shields.io/badge/network-none-6b7280.svg)](#privacy)

[**English**](#english) · [**Español**](#español)

</div>

---

# English

> One row per account and asset, straight from the snapshots Wealthfolio itself
> calculates — so the figures match the app.

wealthfolio-exporter is a small bash script that reads Wealthfolio's SQLite
database and writes your current holdings to a **CSV** file and a **Markdown**
table. It is meant to run on a schedule, so you always have a fresh export to
read, diff, or feed to other tools.

## Contents

- [Highlights](#highlights)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Configuration](#configuration)
- [Usage](#usage)
- [Output](#output)
- [Scheduling](#scheduling)
- [Privacy](#privacy)
- [Disclaimer](#disclaimer)
- [License](#license)

## Highlights

| | |
| --- | --- |
| **CSV and Markdown** | Two files per run, one row per account and asset. |
| **Matches the app** | Uses Wealthfolio's own snapshots, which already include splits, average cost and lots. |
| **Last price included** | Latest stored close and its date, so stale quotes are easy to spot. |
| **Safe to run live** | Opens the database read-only; SQLite WAL supports concurrent readers. |
| **Schedule-ready** | Cron and n8n recipes, with a monthly archive. |
| **Private by design** | No network access, never writes to the database, your paths stay out of git. |

## How it works

Reads Wealthfolio's SQLite database (`wealthfolio.db`) read-only and takes the
**latest snapshot** of each account from `holdings_snapshots`. Snapshots already
include splits, average cost and lots, so the figures match the app. It is safe
to run while Wealthfolio is running (SQLite WAL supports concurrent readers).

## Requirements

`bash`, `sqlite3` (with JSON support), `python3`, and read access to
`wealthfolio.db`.

## Configuration

Copy the example and edit it with your own paths:

```bash
cp holdings.conf.example holdings.conf
```

`holdings.conf` sits next to `holdings.sh`, is a plain bash file, and is ignored
by git, so your real paths never get committed. It sets:

| Variable | Meaning |
| --- | --- |
| `DB` | Path to `wealthfolio.db` (opened read-only). |
| `OUTPUT_DIR` | Directory for the exported files. Empty (default) = current directory. |

To use another file, set `HOLDINGS_CONF=/path/to/file`. Because the file is
sourced by bash, only use one you trust.

## Usage

```bash
./holdings.sh [/path/to/wealthfolio.db]
```

Without an argument it reads `DB` from `holdings.conf`. A path given as an
argument takes precedence over the configuration.

To work on a copy, do not copy the `.db` file directly (pending changes live in
the `-wal` file). Use:

```bash
sqlite3 /path/to/wealthfolio.db ".backup copy.db"
./holdings.sh copy.db
```

## Output

Written to `OUTPUT_DIR` (default: the current directory):

- `YYYYMMDD_holdings.csv`
- `YYYYMMDD_holdings.md`

Columns: `Account`, `Ticker`, `Name`, `First_Buy_Date`, `Shares`, `Market` (MIC
code), `Avg_Price`, `Currency`, `Last_Price`, `Last_Price_Date`. Only positions
with `Shares > 0`.

`Last_Price` is the most recent close stored in Wealthfolio's `quotes` table (in
the quote's currency) and `Last_Price_Date` is its date. Check the date: an
asset whose quote provider has stopped updating keeps its old price. Both are
empty if the asset has no quotes.

## Scheduling

**cron**

```cron
0 22 * * * umask 077; cd /path/to/scripts && ./holdings.sh >> holdings.log 2>&1
```

**n8n** — if n8n runs in a container without `sqlite3`/`python3` or access to the
database, use two SSH nodes (same credential) after a Schedule Trigger
(`0 22 * * *`):

```bash
# 1. Cleanup: keep day-1-of-month files in archive/, delete the other exports
HOLDINGS=/path/to/output && mkdir -p ${HOLDINGS}/archive && find ${HOLDINGS} -maxdepth 1 \( -name '*_holdings.csv' -o -name '*_holdings.md' \) | while read f; do if basename "$f" | grep -qE '^[0-9]{6}01'; then mv "$f" ${HOLDINGS}/archive/; else rm "$f"; fi; done

# 2. Run and move
cd /path/to/scripts && bash holdings.sh && DATE=$(date +%Y%m%d) && cp ${DATE}*.csv ${DATE}*.md /path/to/output/ && rm ${DATE}*.csv ${DATE}*.md
```

`holdings.conf` must be next to `holdings.sh` on the machine that runs it. Use
the same output path in both. The cleanup step **deletes** matching
`*_holdings.csv`/`*_holdings.md` files in that directory that are not from day 1
of a month.

## Privacy

Generated files contain your portfolio data. `.gitignore` excludes
`*_holdings.csv` and `*_holdings.md`; do not commit them. The script never writes
to the database.

## Disclaimer

wealthfolio-exporter is an independent, unofficial tool: it is not affiliated
with, endorsed by, or supported by Wealthfolio. The figures come from the
snapshots Wealthfolio itself calculates and are informational only; they are
**not financial, investment, or tax advice**. Check them against your own
records.

The software is provided "as is", without warranty of any kind. You are
responsible for your data: back up `wealthfolio.db` before using it, and review
the cleanup step in [Scheduling](#scheduling), which **deletes** files.

## License

[MIT](LICENSE) © 2026 advenacodex

[![Support me on Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/advenacodex)

---

# Español

> Una fila por cuenta y valor, directamente de los snapshots que calcula el
> propio Wealthfolio, así que las cifras coinciden con las de la aplicación.

wealthfolio-exporter es un pequeño script de bash que lee la base de datos SQLite
de Wealthfolio y escribe tus posiciones actuales (*holdings*) en un fichero
**CSV** y en una tabla **Markdown**. Está pensado para ejecutarse de forma
programada, de modo que siempre tengas una exportación reciente para leer,
comparar o alimentar otras herramientas.

## Contenido

- [Lo más destacado](#lo-más-destacado)
- [Funcionamiento](#funcionamiento)
- [Requisitos](#requisitos)
- [Configuración](#configuración)
- [Uso](#uso)
- [Salida](#salida)
- [Programación](#programación)
- [Privacidad](#privacidad)
- [Aviso legal](#aviso-legal)
- [Licencia](#licencia)

## Lo más destacado

| | |
| --- | --- |
| **CSV y Markdown** | Dos ficheros por ejecución, una fila por cuenta y valor. |
| **Coincide con la app** | Usa los snapshots del propio Wealthfolio, que ya incluyen splits, coste medio y lotes. |
| **Con último precio** | Último cierre guardado y su fecha, para detectar cotizaciones desactualizadas. |
| **Seguro con la app abierta** | Abre la base de datos en solo lectura; SQLite WAL admite lectores concurrentes. |
| **Listo para programar** | Recetas de cron y n8n, con archivo mensual. |
| **Privado por diseño** | Sin acceso a red, nunca escribe en la base de datos y tus rutas no llegan a git. |

## Funcionamiento

Lee la base de datos SQLite de Wealthfolio (`wealthfolio.db`) en solo lectura y
toma el **último snapshot** de cada cuenta de `holdings_snapshots`. Los
snapshots ya incluyen splits, coste medio y lotes, así que las cifras coinciden
con las de la aplicación. Es seguro ejecutarlo con Wealthfolio en marcha (SQLite
WAL admite lectores concurrentes).

## Requisitos

`bash`, `sqlite3` (con soporte JSON), `python3` y acceso de lectura a
`wealthfolio.db`.

## Configuración

Copia el ejemplo y edítalo con tus propias rutas:

```bash
cp holdings.conf.example holdings.conf
```

`holdings.conf` está junto a `holdings.sh`, es un fichero bash normal y git lo
ignora, así que tus rutas reales nunca se suben. Define:

| Variable | Significado |
| --- | --- |
| `DB` | Ruta de `wealthfolio.db` (se abre en solo lectura). |
| `OUTPUT_DIR` | Directorio de los ficheros exportados. Vacío (por defecto) = directorio actual. |

Para usar otro fichero, define `HOLDINGS_CONF=/ruta/al/fichero`. Como bash lo
ejecuta con `source`, usa solo un fichero de confianza.

## Uso

```bash
./holdings.sh [/ruta/a/wealthfolio.db]
```

Sin argumento lee `DB` de `holdings.conf`. Una ruta pasada como argumento tiene
prioridad sobre la configuración.

Para trabajar sobre una copia, no copies el `.db` directamente (los cambios
pendientes están en el `-wal`). Usa:

```bash
sqlite3 /ruta/a/wealthfolio.db ".backup copia.db"
./holdings.sh copia.db
```

## Salida

Se escribe en `OUTPUT_DIR` (por defecto, el directorio actual):

- `YYYYMMDD_holdings.csv`
- `YYYYMMDD_holdings.md`

Columnas: `Account`, `Ticker`, `Name`, `First_Buy_Date`, `Shares`, `Market`
(código MIC), `Avg_Price`, `Currency`, `Last_Price`, `Last_Price_Date`. Solo
posiciones con `Shares > 0`.

`Last_Price` es el último cierre guardado en la tabla `quotes` de Wealthfolio (en
la moneda de la cotización) y `Last_Price_Date` su fecha. Conviene mirar la
fecha: un activo cuyo proveedor de cotizaciones ha dejado de actualizarse
conserva su precio antiguo. Ambos quedan vacíos si el activo no tiene
cotizaciones.

## Programación

**cron**

```cron
0 22 * * * umask 077; cd /ruta/a/scripts && ./holdings.sh >> holdings.log 2>&1
```

**n8n** — si n8n corre en un contenedor sin `sqlite3`/`python3` ni acceso a la
base de datos, usa dos nodos SSH (misma credencial) tras un Schedule Trigger
(`0 22 * * *`):

```bash
# 1. Limpieza: conserva en archive/ los del día 1 de mes y borra el resto de exportaciones
HOLDINGS=/ruta/de/salida && mkdir -p ${HOLDINGS}/archive && find ${HOLDINGS} -maxdepth 1 \( -name '*_holdings.csv' -o -name '*_holdings.md' \) | while read f; do if basename "$f" | grep -qE '^[0-9]{6}01'; then mv "$f" ${HOLDINGS}/archive/; else rm "$f"; fi; done

# 2. Ejecutar y mover
cd /ruta/a/scripts && bash holdings.sh && DATE=$(date +%Y%m%d) && cp ${DATE}*.csv ${DATE}*.md /ruta/de/salida/ && rm ${DATE}*.csv ${DATE}*.md
```

`holdings.conf` debe estar junto a `holdings.sh` en la máquina que lo ejecuta.
Usa la misma ruta de salida en ambos. La limpieza **borra** los
`*_holdings.csv`/`*_holdings.md` de ese directorio que no sean del día 1 de mes.

## Privacidad

Los ficheros generados contienen datos de tu cartera. `.gitignore` excluye
`*_holdings.csv` y `*_holdings.md`; no los subas al repositorio. El script nunca
escribe en la base de datos.

## Aviso legal

wealthfolio-exporter es una herramienta independiente y no oficial: no está
afiliada, respaldada ni soportada por Wealthfolio. Las cifras proceden de los
snapshots que calcula el propio Wealthfolio y son meramente informativas; **no
constituyen asesoramiento financiero, de inversión ni fiscal**. Contrástalas con
tus propios registros.

El software se ofrece «tal cual», sin garantía de ningún tipo. Tú eres
responsable de tus datos: haz una copia de seguridad de `wealthfolio.db` antes de
usarlo y revisa el paso de limpieza de [Programación](#programación), que
**borra** ficheros.

## Licencia

[MIT](LICENSE) © 2026 advenacodex

[![Apóyame en Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/advenacodex)
