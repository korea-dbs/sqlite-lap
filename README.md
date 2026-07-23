# SQLite-LAP
SQLite-LAP prefetches the corresponding leaf pages identified by the
Final Interior Node, enabling non-blocking and parallel processing of I/O requests to
maximize system throughput and resource utilization. SQLite-LAP fur-
ther optimizes data access by enabling concurrent prefetching, thereby
maximizing cache utilization and reducing query latency.

## Features
- **Asynchronous operation**:
  Vanilla, which was originally synchronous, was modified to perform asynchronously.

- **Optimize Read operation**:
  We optimized SQLite's read operation to achieve better read performance.

- **Seamless Integration with SQLite**:
  The project is designed to work directly with SQLite and libSQL enabling transparent and efficient integration without modifying the core database engine.

- **Parallelism**:
  Maximized parallelism through the utilization of multithreading in FIN-leaf level.


## Docker

A `Dockerfile` at the repo root builds both engines (`sqlite3-construct` and `sqlite3-lap`)
into one image, with `liburing` built from source since it isn't packaged for the base image.

```bash
docker build -t sqlite-lap .
```

Run it with a directory mounted at `/data` for your database files. `SQLite-LAP`'s
`IORING_SETUP_SQPOLL` mode needs extra permissions that Docker doesn't grant by default:

```bash
docker run --rm -it \
  --security-opt seccomp=unconfined \
  --ulimit memlock=-1:-1 \
  --cap-add SYS_ADMIN \
  -v "$(pwd)/data:/data" \
  sqlite-lap
```

Inside the container:
```bash
sqlite3-construct test.db   # build + .finconstruct
sqlite3-lap test.db         # read-only experiments
```



## Repository layout
```
git clone https://github.com/korea-dbs/sqlite-lap.git
cd sqlite-lap
```

Each engine variant is a self-contained SQLite 3.42.0 source tree:

```
<variant>/
  src/          # SQLite source (btree.c, shell.c.in, ...)
  ext/, tool/   # extensions + build tooling (fts5, rtree, lemon, mksqlite3c.tcl, ...)
  configure, Makefile.in, ...
```

`SQLite-LAP` and `init_construct_fin_table_src` are set up this way and build standalone —
no external source tree is required.

## Prerequisites
- `gcc`, `make`, `tclsh` (used to generate the amalgamation during build)
- `liburing` dev headers (`liburing.h`, `-luring`) — required for `SQLite-LAP` only
- readline/ncurses dev headers (used by the shell CLI)
- Linux kernel with `io_uring` support (5.1+) for `SQLite-LAP`

## The two-engine workflow (important)

There are two separate binaries, used for two separate purposes. **Do not mix them up.**

| Engine | Use for | Do NOT use for |
|---|---|---|
| `init_construct_fin_table_src` | Creating tables, loading/inserting data, running `.finconstruct` | — |
| `SQLite-LAP` | Read-only queries (`SELECT`) on an already-constructed DB | Creating tables or inserting data |

Always build and load your dataset with `init_construct_fin_table_src` first, run
`.finconstruct`, and only then switch to the `SQLite-LAP` binary to run the read-side
experiment.

## Engine variants

`( libSQL-LAP | ReadAheadsrc | SQLite-LAP | Vanilla+BG | Vanilla+uring )`

- **SQLite-LAP** combines three major components: iouring, background execution, and FIN aware prefetching.
- **Vanilla+ReadAhead** enables readahead, which prefetches five consecutive pages following the currently accessed page in a single I/O operation, where five is selected as the number that yields the best performance in our empirical evaluation.
- **Vanilla+uring** issues batch read requests for the leaf pages under a FIN via iouring on the main thread upon reaching a FIN during B-tree traversal, but blocks the main thread until all I/O completions are acknowledged.
- **Vanilla+BG** decouples leaf-page I/O from the main thread via two background threads, the same thread count as SQLite-LAP, upon reaching a FIN during B-tree traversal, but issues a separate system call for each page read without batching.

## Build

Build each engine the same way:

```bash
cd SQLite-LAP                 # or init_construct_fin_table_src
mkdir bld && cd bld
../configure
```

For `SQLite-LAP` only, edit `bld/Makefile` to link `pthread`/`io_uring`:
```make
CC = gcc
CFLAGS =   -g -O2 -DSQLITE_OS_UNIX=1 -pthread
LIBS += -luring -pthread
```
(`init_construct_fin_table_src` does not use `io_uring`/threads, so it needs no Makefile edit.)

```bash
make -j
```
This produces `bld/sqlite3`.

## `.finconstruct`

Both engines' shells have a `.finconstruct` dot-command that builds/refreshes the FIN
bitmap in one step — it replaces the old manual "create `bitmap_table`, then `SELECT *`
every table by hand" process:

```sql
.finconstruct
```

It creates `bitmap_table` if missing, then runs a full `SELECT *` scan over every user
table. Each scan drives the FIN-promotion logic in `btree.c`'s `moveToChild()`: qualifying
interior pages get flagged as FIN (page-type byte `0x05` → `0x07`) and the corresponding
`(fippgno, childpg)` edges get recorded in `bitmap_table`. Run it once after loading data
(before switching to `SQLite-LAP`), and again any time you add tables/rows through
`init_construct_fin_table_src`.

`bitmap_table` schema:
```sql
CREATE TABLE bitmap_table (
    fippgno INTEGER,
    childpg INTEGER,
    PRIMARY KEY (fippgno, childpg)
);
```

## Example: build a dataset and run it through SQLite-LAP

```bash
# 1) Build the dataset with the construction-only engine
./init_construct_fin_table_src/bld/sqlite3 test.db
```
```sql
CREATE TABLE t1(a INTEGER PRIMARY KEY, b TEXT);

WITH RECURSIVE seq(x) AS (
  SELECT 1
  UNION ALL
  SELECT x+1 FROM seq WHERE x < 5000
)
INSERT INTO t1 SELECT x, hex(randomblob(50)) FROM seq;

.finconstruct
SELECT count(*) FROM bitmap_table;   -- sanity check: should be > 0
.quit
```

```bash
# 2) Switch to SQLite-LAP for the actual (read-only) experiment
./SQLite-LAP/bld/sqlite3 test.db
```
```sql
SELECT count(*), sum(length(b)) FROM t1;
.quit
```

On open, `SQLite-LAP` prints `ring init IAM-nomem` / `THD-Pool init` to stderr once the
`io_uring` ring and background thread pool are initialized. On `.quit`, it prints
`close func hit : N ,miss : M` — the pager cache hit/miss count for the session. A high
hit ratio here means the background prefetcher is successfully warming leaf pages (via
`bitmap_table` + batched `io_uring` reads) ahead of the cursor reaching them.


