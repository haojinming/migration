#!/bin/bash

set -euo pipefail

CUR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source $CUR/../_utils/test_prepare
source $CUR/owner.sh
source $CUR/capture.sh
source $CUR/processor.sh
WORK_DIR=$OUT_DIR/$TEST_NAME
CDC_BINARY=tikv-cdc

export DOWN_TIDB_HOST
export DOWN_TIDB_PORT

function prepare() {
	rm -rf $WORK_DIR && mkdir -p $WORK_DIR

	start_tidb_cluster --workdir $WORK_DIR

	cd $WORK_DIR

	start_ts=$(get_start_ts $UP_PD)
	run_cdc_cli changefeed create \
		--start-ts=$start_ts --sink-uri="tikv://${DOWN_PD_HOST}:${DOWN_PD_PORT}" \
		--disable-version-check
}

trap stop_tidb_cluster EXIT
prepare $*
test_owner_ha $*
test_capture_ha $*
test_processor_ha $*
check_logs $WORK_DIR
echo "[$(date)] <<<<<< run test case $TEST_NAME success! >>>>>>"
