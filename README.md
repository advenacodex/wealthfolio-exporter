# wealthfolio-exporter

[Español](README.es.md)

Exports your [Wealthfolio](https://wealthfolio.app) holdings to **CSV** and a **Markdown** table, one row per account and asset.

## How it works

Reads Wealthfolio's SQLite database (`wealthfolio.db`) read-only and takes the **latest snapshot** of each account from `holdings_snapshots`. Snapshots already include splits, average cost and lots, so the figures match the app. It is safe to run while Wealthfolio is running (SQLite WAL supports concurrent readers).

## Requirements

`bash`, `sqlite3` (with JSON support), `python3`, and read access to `wealthfolio.db`.

## Usage

```bash
./holdings.sh [/path/to/wealthfolio.db]
```

Without an argument it uses the default in the `DB=` line of `holdings.sh`; edit it for your setup.

To work on a copy, do not copy the `.db` file directly (pending changes live in the `-wal` file). Use:

```bash
sqlite3 /path/to/wealthfolio.db ".backup copy.db"
./holdings.sh copy.db
```

## Output

Written to the current directory:

- `YYYYMMDD_holdings.csv`
- `YYYYMMDD_holdings.md`

Columns: `Account`, `Ticker`, `Name`, `First_Buy_Date`, `Shares`, `Market` (MIC code), `Avg_Price`, `Currency`, `Last_Price`, `Last_Price_Date`. Only positions with `Shares > 0`.

`Last_Price` is the most recent close stored in Wealthfolio's `quotes` table (in the quote's currency) and `Last_Price_Date` is its date. Check the date: an asset whose quote provider has stopped updating keeps its old price. Both are empty if the asset has no quotes.

## Scheduling

**cron**

```cron
0 22 * * * umask 077; cd /path/to/scripts && ./holdings.sh >> holdings.log 2>&1
```

**n8n** — if n8n runs in a container without `sqlite3`/`python3` or access to the database, use two SSH nodes (same credential) after a Schedule Trigger (`0 22 * * *`):

```bash
# 1. Cleanup: keep day-1-of-month files in archive/, delete the other exports
HOLDINGS=/path/to/output && mkdir -p ${HOLDINGS}/archive && find ${HOLDINGS} -maxdepth 1 \( -name '*_holdings.csv' -o -name '*_holdings.md' \) | while read f; do if basename "$f" | grep -qE '^[0-9]{6}01'; then mv "$f" ${HOLDINGS}/archive/; else rm "$f"; fi; done

# 2. Run and move
cd /path/to/scripts && bash holdings.sh && DATE=$(date +%Y%m%d) && cp ${DATE}*.csv ${DATE}*.md /path/to/output/ && rm ${DATE}*.csv ${DATE}*.md
```

Use the same output path in both. The cleanup step **deletes** matching `*_holdings.csv`/`*_holdings.md` files in that directory that are not from day 1 of a month.

## Privacy

Generated files contain your portfolio data. `.gitignore` excludes `*_holdings.csv` and `*_holdings.md`; do not commit them. The script never writes to the database.
