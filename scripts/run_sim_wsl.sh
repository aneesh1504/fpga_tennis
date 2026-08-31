#!/usr/bin/env sh
set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
cd "$REPO_DIR"

if command -v iverilog >/dev/null 2>&1 && command -v vvp >/dev/null 2>&1; then
  exec scripts/run_sim.sh
fi

TOOL_ROOT=.build/tools/iverilog
DOWNLOAD_DIR="$TOOL_ROOT/download"
EXTRACT_DIR="$TOOL_ROOT/root"
mkdir -p "$DOWNLOAD_DIR" "$EXTRACT_DIR"

if ! find "$DOWNLOAD_DIR" -maxdepth 1 -name 'iverilog_*.deb' -print -quit | grep -q .; then
  (
    cd "$DOWNLOAD_DIR"
    apt-get download iverilog
  )
fi

DEB_FILE=$(find "$DOWNLOAD_DIR" -maxdepth 1 -name 'iverilog_*.deb' -print -quit)
dpkg-deb -x "$DEB_FILE" "$EXTRACT_DIR"

IVL_BASE="$REPO_DIR/$EXTRACT_DIR/usr/lib/x86_64-linux-gnu/ivl"
LOCAL_IVERILOG="$REPO_DIR/$EXTRACT_DIR/usr/bin/iverilog"
PATH="$REPO_DIR/$EXTRACT_DIR/usr/bin:$PATH"
export PATH

iverilog_local() {
  "$LOCAL_IVERILOG" -B "$IVL_BASE" "$@"
}

IVERILOG=iverilog_local
export IVERILOG
. scripts/run_sim.sh
