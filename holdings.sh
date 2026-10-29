#!/usr/bin/env bash
# holdings.sh — Export holdings per account using Wealthfolio's calculated snapshots.
# Writes YYYYMMDD_holdings.csv and YYYYMMDD_holdings.md (current directory by default).
#
# Configuration: holdings.conf next to this script (copy holdings.conf.example), or the
# file named in $HOLDINGS_CONF. It is a bash file that sets DB and, optionally, OUTPUT_DIR.
#
# Usage:
#   ./holdings.sh                          # database path from holdings.conf
#   ./holdings.sh /path/to/wealthfolio.db  # path given here overrides holdings.conf

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG="${HOLDINGS_CONF:-$SCRIPT_DIR/holdings.conf}"

DB=""
OUTPUT_DIR=""

if [[ -f "$CONFIG" ]]; then
  # shellcheck source=/dev/null
  source "$CONFIG"
elif [[ -n "${HOLDINGS_CONF:-}" ]]; then
  echo "ERROR: config file not found: $CONFIG" >&2
  exit 1
fi

DB="${1:-$DB}"

if [[ -z "$DB" ]]; then
  echo "ERROR: no database path." >&2
  echo "Create $SCRIPT_DIR/holdings.conf (see holdings.conf.example) or pass the path to wealthfolio.db as an argument." >&2
  exit 1
fi

if [[ ! -f "$DB" ]]; then
  echo "ERROR: database not found." >&2
  echo "Checked: $DB — set DB in $CONFIG or pass the path as an argument." >&2
  exit 1
fi

PREFIX=""
if [[ -n "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR"
  PREFIX="${OUTPUT_DIR%/}/"
fi

OUTPUT="${PREFIX}$(date +%Y%m%d)_holdings.csv"

sqlite3 -csv -header "$DB" "
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
    json_extract(pos.value, '$.currency')                  AS Currency,
    ROUND(CAST(q.close AS REAL), 4)                        AS Last_Price,
    q.day                                                  AS Last_Price_Date
FROM holdings_snapshots hs
JOIN latest_snapshots ls ON hs.account_id = ls.account_id
                         AND hs.snapshot_date = ls.max_date
JOIN accounts acc        ON acc.id = hs.account_id
CROSS JOIN json_each(hs.positions) AS pos
JOIN assets a            ON a.id = pos.key
LEFT JOIN quotes q       ON q.id = (
    SELECT id FROM quotes
    WHERE asset_id = a.id
    ORDER BY day DESC, timestamp DESC
    LIMIT 1
)
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
