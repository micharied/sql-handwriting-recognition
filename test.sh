#!/usr/bin/env bash
set -u
shopt -s nullglob

pass=0
fail=0

for file in test_samples/*.json; do
    base=$(basename "$file" .json)
    expected="${base%%_*}"
    actual=$(duckdb :memory: -csv -noheader \
        -c "SET VARIABLE sample_file = '$file';" \
        -c ".read sql/import.sql" \
        -c ".read sql/pipeline.sql" \
        | sort | paste -sd, -)

    if [ "$actual" = "$expected" ]; then
        echo "PASS $file"
        pass=$((pass + 1))
    else
        echo "FAIL $file: expected {$expected}, got {$actual}"
        fail=$((fail + 1))
    fi
done

echo
echo "$pass/$((pass + fail)) passed"
[ "$fail" -eq 0 ]
