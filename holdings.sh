#!/usr/bin/env bash
# holdings_csv.sh — Export holdings per account using Wealthfolio's calculated snapshots.
#
# Usage:
#   ./scripts/holdings_csv.sh                          # searches for wealthfolio.db
#   ./scripts/holdings_csv.sh /path/to/wealthfolio.db  # custom path

set -euo pipefail

DB="${1:-/volume2/docker/volumes/wealthfolio/wealthfolio.db}"


if [[ ! -f "$DB" ]]; then
  echo "ERROR: database not found." >&2
  echo "Put wealthfolio.db in the current directory or provide the path as an argument." >&2
  exit 1
fi

OUTPUT="$(date +%Y%m%d)_holdings.csv"

sqlite3 -header -csv "$DB" "
WITH latest_snapshots AS (
    SELECT account_id, MAX(snapshot_date) as max_date
    FROM holdings_snapshots
    GROUP BY account_id
)
SELECT
    acc.name                                               AS Account,
    COALESCE(a.display_code, a.instrument_symbol, a.name) AS Ticker,
    a.name                                                 AS Name,
    json_extract(pos.value, '$.inceptionDate')             AS First_Buy_Date,
    ROUND(json_extract(pos.value, '$.quantity'), 6)        AS Shares,
    COALESCE(a.instrument_exchange_mic, '')                AS Market,
    ROUND(json_extract(pos.value, '$.averageCost'), 4)     AS Avg_Price,
    json_extract(pos.value, '$.currency')                  AS Currency
FROM holdings_snapshots hs
JOIN latest_snapshots ls ON hs.account_id = ls.account_id
                         AND hs.snapshot_date = ls.max_date
JOIN accounts acc        ON acc.id = hs.account_id
CROSS JOIN json_each(hs.positions) AS pos
JOIN assets a            ON a.id = pos.key
WHERE Shares > 0
ORDER BY Account, Ticker;
" > "$OUTPUT"

echo "Exported: $OUTPUT"
python3 -c "
import csv, sys
rows = list(csv.DictReader(open('$OUTPUT')))
if not rows: sys.exit()
headers = rows[0].keys()
print('| ' + ' | '.join(headers) + ' |')
print('| ' + ' | '.join(['---']*len(headers)) + ' |')
for r in rows: print('| ' + ' | '.join(r.values()) + ' |')
" > "${OUTPUT%.csv}.md"
