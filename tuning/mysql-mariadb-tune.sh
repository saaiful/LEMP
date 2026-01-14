#!/usr/bin/env bash
# ===============================================================
#  MySQL/MariaDB Auto-Tuner + basic storage speed check
#  Works from 1 GB VPS → 512+ GB servers (2026 edition)
#  Now includes rough SSD/HDD detection
#  Run as root/sudo
# ===============================================================

set -u
set -e

# ── Output helpers ───────────────────────────────────────────────
RED='\033[0;31m'    ; GREEN='\033[0;32m'    ; YELLOW='\033[1;33m' ; NC='\033[0m'
die()    { echo -e "${RED}ERROR:${NC} $*" >&2 ; exit 1 ; }
info()   { echo -e "${GREEN}INFO:${NC}  $*"; }
warn()   { echo -e "${YELLOW}WARN:${NC}  $*"; }

# ── Detect MySQL or MariaDB ──────────────────────────────────────
if command -v mariadbd >/dev/null 2>&1; then
    FLAVOR="MariaDB"
    BIN="mariadbd"
    SERVICE="mariadb"
elif command -v mysqld >/dev/null 2>&1; then
    FLAVOR="MySQL"
    BIN="mysqld"
    SERVICE="mysql"
else
    die "Neither mysqld nor mariadbd found"
fi

VERSION=$("$BIN" --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
[[ -z "$VERSION" ]] && die "Cannot detect version"

info "Detected → $FLAVOR $VERSION"

# ── Hardware detection ───────────────────────────────────────────
RAM_GB=$(awk '/MemTotal/ {printf "%.0f", $2 / 1024 / 1024}' /proc/meminfo 2>/dev/null || echo 4)
CORES=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo 2>/dev/null || echo 2)

info "Hardware → ${RAM_GB} GB RAM  |  ${CORES} cores"

# ── Simple storage speed test ────────────────────────────────────
info "Running quick sequential disk speed test (this may take 5–30 seconds)..."

TEST_DIR="${PWD}"
[[ ! -w "$TEST_DIR" ]] && TEST_DIR="/tmp"
TEST_FILE="$TEST_DIR/.mysql_tune_speedtest_$$"

# Write test (1 GB)
WRITE_SPEED=0
if dd if=/dev/zero of="$TEST_FILE" bs=1M count=1024 conv=fdatasync 2>/dev/null; then
    TIME_WRITE=$(dd if=/dev/zero of="$TEST_FILE" bs=1M count=1024 conv=fdatasync 2>&1 | grep -o '[0-9.]\+ s' | head -1 || echo "1 s")
    TIME_WRITE_NUM=$(echo "$TIME_WRITE" | grep -o '[0-9.]\+' || echo 1)
    WRITE_SPEED=$(awk "BEGIN {printf \"%.0f\", 1024 / $TIME_WRITE_NUM}")
    info "Write ≈ ${WRITE_SPEED} MB/s"
else
    warn "Write test failed (permission / space issue?)"
fi

# Read test
READ_SPEED=0
if [[ -f "$TEST_FILE" ]]; then
    # Try to drop caches (needs root)
    if [[ "$EUID" -eq 0 ]]; then
        sync; echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true
    else
        warn "Not root → read test may be cached / too optimistic"
    fi

    TIME_READ=$(dd if="$TEST_FILE" of=/dev/null bs=1M count=1024 2>&1 | grep -o '[0-9.]\+ s' | head -1 || echo "1 s")
    TIME_READ_NUM=$(echo "$TIME_READ" | grep -o '[0-9.]\+' || echo 1)
    READ_SPEED=$(awk "BEGIN {printf \"%.0f\", 1024 / $TIME_READ_NUM}")
    info "Read  ≈ ${READ_SPEED} MB/s"
fi

# Cleanup
rm -f "$TEST_FILE" 2>/dev/null

# Rough classification & tuning influence
STORAGE_TYPE="unknown"
if (( READ_SPEED > 1500 || WRITE_SPEED > 1200 )); then
    STORAGE_TYPE="NVMe (or very fast SSD)"
    IO_CAPACITY_BASE=4000
elif (( READ_SPEED > 400 || WRITE_SPEED > 350 )); then
    STORAGE_TYPE="SATA SSD (decent)"
    IO_CAPACITY_BASE=1200
elif (( READ_SPEED > 150 || WRITE_SPEED > 120 )); then
    STORAGE_TYPE="Slow SSD or good HDD"
    IO_CAPACITY_BASE=400
else
    STORAGE_TYPE="HDD or very slow storage"
    IO_CAPACITY_BASE=200
fi

info "Detected storage ≈ $STORAGE_TYPE  (read ~${READ_SPEED} MB/s, write ~${WRITE_SPEED} MB/s)"

# ── Scaling logic ─────────────────────────────────────────────────
if (( RAM_GB <= 4 )); then
    INNODB_BUFFER="1024M"
    MAX_CONN=80
    TMP_TABLE="24M"
    HEAP_TABLE="24M"
    SORT_BUF="768K"
    LOG_FILE="64M"
    THREAD_STACK="192K"
    warn "Very low RAM — conservative settings"
elif (( RAM_GB <= 8 )); then
    INNODB_BUFFER="4G"
    MAX_CONN=150
    TMP_TABLE="48M"
    HEAP_TABLE="48M"
    SORT_BUF="1M"
    LOG_FILE="128M"
    THREAD_STACK="256K"
elif (( RAM_GB <= 16 )); then
    INNODB_BUFFER="10G"
    MAX_CONN=300
    TMP_TABLE="96M"
    HEAP_TABLE="96M"
    SORT_BUF="2M"
    LOG_FILE="256M"
    THREAD_STACK="320K"
elif (( RAM_GB <= 32 )); then
    INNODB_BUFFER="22G"
    MAX_CONN=500
    TMP_TABLE="128M"
    HEAP_TABLE="128M"
    SORT_BUF="2M"
    LOG_FILE="512M"
    THREAD_STACK="384K"
else
    PCT=$(( 70 + (RAM_GB / 64) ))
    (( PCT > 80 )) && PCT=80
    INNODB_BUFFER="$(( RAM_GB * PCT / 100 ))G"
    MAX_CONN=$(( 400 + CORES * 20 ))
    (( MAX_CONN > 2000 )) && MAX_CONN=2000
    TMP_TABLE="256M"
    HEAP_TABLE="256M"
    SORT_BUF="4M"
    LOG_FILE="1G"
    THREAD_STACK="512K"
    warn "Large server — review innodb_flush_log_at_trx_commit and max_connections"
fi

# Adjust IO capacity based on detected storage speed
IO_CAPACITY=$(( IO_CAPACITY_BASE + (CORES * 50) ))
(( IO_CAPACITY > 12000 )) && IO_CAPACITY=12000
IO_CAPACITY_MAX=$(( IO_CAPACITY * 2 ))

# Buffer pool instances
CORES_FOR_INSTANCES=$CORES
(( CORES_FOR_INSTANCES > 64 )) && CORES_FOR_INSTANCES=64
(( CORES_FOR_INSTANCES < 4 )) && CORES_FOR_INSTANCES=4

# IO threads — more aggressive on fast storage
IO_THREADS=$(( CORES > 8 ? 16 : CORES * 2 ))
(( IO_THREADS > 32 )) && IO_THREADS=32

# ── Find config location ─────────────────────────────────────────
find_main_cnf() {
    local candidates=(/etc/mysql/my.cnf /etc/my.cnf /etc/mysql/mariadb.cnf
                      /etc/mysql/mysql.conf.d/mysqld.cnf
                      /etc/mysql/mariadb.conf.d/50-server.cnf)
    for f in "${candidates[@]}"; do [[ -f "$f" ]] && echo "$f" && return; done
    die "Cannot find main .cnf file"
}

MAIN_CNF=$(find_main_cnf)

# Include dir
for d in /etc/mysql/mariadb.conf.d /etc/mysql/mysql.conf.d /etc/mysql/conf.d /etc/my.cnf.d; do
    [[ -d "$d" ]] && SNIPPET_DIR="$d" && break
done
[[ -z "${SNIPPET_DIR:-}" ]] && SNIPPET_DIR="/etc/mysql/conf.d" && mkdir -p "$SNIPPET_DIR" || true

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="${MAIN_CNF}.backup-${TIMESTAMP}"
OUT_FILE="${SNIPPET_DIR}/zz-autotune.cnf"

info "Main config  : $MAIN_CNF"
info "Snippet dir  : $SNIPPET_DIR"
info "Output file  : $OUT_FILE"

# ── Backup ───────────────────────────────────────────────────────
[[ -f "$MAIN_CNF" ]] && cp -a "$MAIN_CNF" "$BACKUP" 2>/dev/null

# ── Write config ─────────────────────────────────────────────────
cat > "$OUT_FILE" << 'END_CONFIG'
# ===============================================================
#  Auto-tuned + disk test — DATE_HERE
#  FLAVOR_HERE VERSION_HERE   •   RAM_HERE GB   •   CORES_HERE cores
#  Storage ≈ STORAGE_TYPE_HERE  (R ~READ_HERE MB/s, W ~WRITE_HERE MB/s)
#  REVIEW VALUES — especially flush_log, max_connections, io_capacity!
# ===============================================================

[mysqld]

# InnoDB ──────────────────────────────────────── most important
innodb_buffer_pool_size         = BUFFER_HERE
innodb_buffer_pool_instances    = INSTANCES_HERE
innodb_flush_log_at_trx_commit  = 2               # 1 = safest, 2 = good perf / less durability
innodb_log_file_size            = LOGFILE_HERE
innodb_log_buffer_size          = 32M
innodb_flush_method             = O_DIRECT
innodb_io_capacity              = IOCAP_HERE
innodb_io_capacity_max          = IO_CAP_MAX_HERE
innodb_write_io_threads         = IOTHREADS_HERE
innodb_read_io_threads          = IOTHREADS_HERE

# Connections & thread handling
max_connections                 = MAXCONN_HERE
thread_cache_size               = CORES_HERE
table_open_cache                = 4000
table_definition_cache          = 2000
thread_stack                    = STACK_HERE

# Temp & per-session buffers
tmp_table_size                  = TMPTABLE_HERE
max_heap_table_size             = HEAPTABLE_HERE
sort_buffer_size                = SORTBUF_HERE
read_rnd_buffer_size            = 2M
join_buffer_size                = 1M

# Query cache — usually off
query_cache_type                = 0
query_cache_size                = 0

# MariaDB-only
innodb_page_cleaners            = CORES_HERE

# Others
tmpdir                          = /tmp            # /dev/shm if you have free RAM

END_CONFIG

# ── Substitute ───────────────────────────────────────────────────
sed -i \
    -e "s/DATE_HERE/$(date '+%Y-%m-%d %H:%M')/" \
    -e "s/FLAVOR_HERE/$FLAVOR/" \
    -e "s/VERSION_HERE/$VERSION/" \
    -e "s/RAM_HERE/$RAM_GB/" \
    -e "s/CORES_HERE/$CORES/g" \
    -e "s/STORAGE_TYPE_HERE/$STORAGE_TYPE/" \
    -e "s/READ_HERE/$READ_SPEED/" \
    -e "s/WRITE_HERE/$WRITE_SPEED/" \
    -e "s/BUFFER_HERE/$INNODB_BUFFER/" \
    -e "s/INSTANCES_HERE/$CORES_FOR_INSTANCES/" \
    -e "s/LOGFILE_HERE/$LOG_FILE/" \
    -e "s/IOCAP_HERE/$IO_CAPACITY/" \
    -e "s/IO_CAP_MAX_HERE/$IO_CAPACITY_MAX/" \
    -e "s/IOTHREADS_HERE/$IO_THREADS/" \
    -e "s/MAXCONN_HERE/$MAX_CONN/" \
    -e "s/STACK_HERE/$THREAD_STACK/" \
    -e "s/TMPTABLE_HERE/$TMP_TABLE/" \
    -e "s/HEAPTABLE_HERE/$HEAP_TABLE/" \
    -e "s/SORTBUF_HERE/$SORT_BUF/" \
    "$OUT_FILE"

chmod 644 "$OUT_FILE"

echo
info "Configuration written to: $OUT_FILE"
echo "First 25 lines preview:"
head -n 25 "$OUT_FILE"

warn "Important:"
warn "  • innodb_flush_log_at_trx_commit = 2  → faster but possible 1-sec data loss on crash"
warn "  • io_capacity = $IO_CAPACITY  (tuned from disk test)"
warn "  • max_connections = $MAX_CONN  → lower if OOM occurs"
warn "  • Restart: sudo systemctl restart $SERVICE"
warn "  • After 1–24 h real load → run mysqltuner.pl or check SHOW GLOBAL STATUS"

info "Done. Good luck!"
