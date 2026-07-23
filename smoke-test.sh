#!/bin/bash
# End-to-end smoke test for the SQLite-LAP Docker image:
#   1) build a dataset with the construction-only engine + .finconstruct
#   2) switch to SQLite-LAP and confirm the read-only experiment sees the same data
set -euo pipefail

DB="${1:-/data/smoke-test.db}"
ROWS="${2:-5000}"

rm -f "$DB" "$DB-journal"

echo "== [1/2] init_construct_fin_table_src: building ${ROWS}-row dataset + .finconstruct =="
sqlite3-construct "$DB" >/tmp/construct.out 2>/tmp/construct.err <<SQL
CREATE TABLE t1(a INTEGER PRIMARY KEY, b TEXT);
WITH RECURSIVE seq(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM seq WHERE x<${ROWS})
INSERT INTO t1 SELECT x, hex(randomblob(50)) FROM seq;
.finconstruct
SELECT count(*) FROM t1;
SELECT count(*) FROM bitmap_table;
SQL

T1_COUNT=$(grep -E '^[0-9]+$' /tmp/construct.out | sed -n '1p')
BITMAP_COUNT=$(grep -E '^[0-9]+$' /tmp/construct.out | sed -n '2p')
echo "   t1 rows          : $T1_COUNT"
echo "   bitmap_table rows: $BITMAP_COUNT"

if [ "$T1_COUNT" != "$ROWS" ]; then
  echo "FAIL: expected $ROWS rows in t1, got $T1_COUNT"
  exit 1
fi
if [ "$BITMAP_COUNT" -le 0 ]; then
  echo "FAIL: bitmap_table is empty -- .finconstruct did not populate it"
  exit 1
fi

echo
echo "== [2/2] SQLite-LAP: read-only experiment =="
sqlite3-lap "$DB" >/tmp/lap.out 2>/tmp/lap.err <<SQL
SELECT count(*) FROM t1;
SQL

LAP_COUNT=$(grep -E '^[0-9]+$' /tmp/lap.out | sed -n '1p')
HITMISS=$(grep "close func hit" /tmp/lap.err || echo "(no hit/miss line captured -- io_uring prefetch stats unavailable)")
echo "   t1 rows via SQLite-LAP: $LAP_COUNT"
echo "   $HITMISS"

if [ "$LAP_COUNT" != "$ROWS" ]; then
  echo "FAIL: SQLite-LAP read $LAP_COUNT rows, expected $ROWS"
  exit 1
fi

echo
echo "PASS: constructed $ROWS rows, bitmap_table has $BITMAP_COUNT entries, SQLite-LAP read them back correctly."
