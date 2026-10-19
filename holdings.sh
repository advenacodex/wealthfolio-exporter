#!/usr/bin/env bash
# holdings_csv.sh — Export holdings per account using Wealthfolio's calculated snapshots.
#
# This version uses the pre-calculated snapshots from the database, which
# correctly handle stock splits (like AAPL 4:1), average costs, and lots.
#
# Usage:
#   ./scripts/holdings_csv.sh                          # searches for wealthfolio.db
#   ./scripts/holdings_csv.sh /path/to/wealthfolio.db  # custom path
set -euo pipefail
# Default search paths
DB="${1:-./wealthfolio.db}"
if [[ ! -f "$DB" && -f "../wealthfolio_data/wealthfolio.db" ]]; then
  DB="../wealthfolio_data/wealthfolio.db"
fi
if [[ ! -f "$DB" ]]; then
  echo "ERROR: database not found." >&2
  echo "Put wealthfolio.db in the current directory or provide the path as an argument." >&2
  exit 1
fi
sqlite3 -header -csv "$DB" "
WITH latest_snapshots AS (
    -- Get the most recent snapshot date for each account
    SELECT account_id, MAX(snapshot_date) as max_date
    FROM holdings_snapshots
    GROUP BY account_id
)
SELECT
    acc.name                                               AS Account,
    COALESCE(a.display_code, a.instrument_symbol, a.name)  AS Ticker,
    a.name                                                 AS Name,
    json_extract(pos.value, '$.inceptionDate')             AS First_Buy_Date,
    ROUND(json_extract(pos.value, '$.quantity'), 6)         AS Shares,
    COALESCE(a.instrument_exchange_mic, '')                AS Market,
    ROUND(json_extract(pos.value, '$.averageCost'), 4)      AS Avg_Price,
    json_extract(pos.value, '$.currency')                  AS Currency
FROM holdings_snapshots hs
JOIN latest_snapshots ls ON hs.account_id = ls.account_id 
                        AND hs.snapshot_date = ls.max_date
JOIN accounts acc        ON acc.id = hs.account_id
CROSS JOIN json_each(hs.positions) AS pos
JOIN assets a            ON a.id = pos.key
WHERE Shares > 0
ORDER BY Account, Ticker;
"
