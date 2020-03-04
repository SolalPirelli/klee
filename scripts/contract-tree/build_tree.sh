#!/bin/bash

set -euo pipefail

KLEE_DIR=~/projects/Bolt/klee
TREE_TYPE=$1
EXPECTED_PERF=$2
RESOLUTION=$3
CONSTRAINT_NODE=${4:-none}
TRACES_DIR=${5:-klee-last}

if [ "$TREE_TYPE" != "call-tree" ] && [ "$TREE_TYPE" != "full-tree" ] && [ "$TREE_TYPE" != "constraint-tree" ]; then
  echo "Unsupported tree type: $TREE_TYPE"
  exit
fi

pushd $TRACES_DIR >> /dev/null

grep "TRAFFIC_CLASS" *.call_path | awk -F: '{print $1 "," $2}' | awk -F' = ' '{print $1 "," $2}' | sed 's/\.call_path//g' > tc_tags

TREE_FILE="constraint-tree.txt"
CONSTRAINT_FILE="constraint-branches.txt"

# METRICS=("instruction count" "memory instructions" "execution cycles")
METRICS=("instruction count")
for METRIC in "${METRICS[@]}"; 
do 
  METRIC_NAME=$(echo "$METRIC" | sed -e 's/ /_/')
  python $KLEE_DIR/scripts/contract-tree/build_tree.py tc_tags combined_perf.txt perf-formula.txt "$METRIC" $TREE_FILE $CONSTRAINT_FILE $EXPECTED_PERF $RESOLUTION $CONSTRAINT_NODE
done

popd >> /dev/null

dot $TRACES_DIR/tree.dot -T png -o tree.png