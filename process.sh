#!/usr/bin/env bash

RESDIR=$1

rm -f $RESDIR.db
rm -Rf output/$RESDIR

sqlite3 $RESDIR.db <<EOF
create table results (did int, tid int, qid int, seed numeric, fillfactor int, branch text, prefetch text, dedup text, ROWS int, distinct_vals int, relpages int, fuzz int, fuzz2 int, step int, iomethod text, ioworkers int, eic int, direction text, run int, index_order text, query_order text, num_values int, start_value int, end_value int, time_uncached numeric, time_cached numeric, distance_uncached numeric, distance_cached numeric, buffers_read int, buffers_hit int);

.mode csv
.separator ' '
.import --skip 1 $RESDIR/results.csv results
EOF

sqlite3 $RESDIR.db <<EOF
create table results_aggregated as
select
  did, branch, prefetch, iomethod, ioworkers, eic, query_order, num_values,
  count(*) as cnt,
  avg(time_uncached) as time_uncached,
  avg(time_cached) as time_cached,
  avg(distance_uncached) as distance_uncached,
  avg(distance_cached) as distance_cached,
  avg(buffers_read) as buffers_read,
  avg(buffers_hit) as buffers_hit
from results
group by did, branch, prefetch, iomethod, ioworkers, eic, query_order, num_values;
EOF

sqlite3 $RESDIR.db > series.list <<EOF
.mode csv
.separator ' '
select distinct did, branch, prefetch, iomethod, ioworkers, eic, query_order
from results_aggregated
EOF

while IFS= read -r line; do

	IFS=' ' read -r -a strarray <<< "$line"

	did="${strarray[0]}"
	branch="${strarray[1]}"
	prefetch="${strarray[2]}"
	iomethod="${strarray[3]}"
	ioworkers="${strarray[4]}"
	eic="${strarray[5]}"
	qorder="${strarray[6]}"

	qorder=$(echo $qorder | sed "s/\r//")

	mkdir -p output/$RESDIR/$did/$iomethod/

	sqlite3 $RESDIR.db > output/$RESDIR/$did/$iomethod/$branch-$prefetch-$ioworkers-$eic-$qorder.data <<EOF
.mode tab
SELECT
  num_values, 
  cnt,
  time_uncached,
  time_cached,
  distance_uncached,
  distance_cached,
  buffers_read,
  buffers_hit
FROM
  results_aggregated
WHERE
  did = $did AND branch = '$branch' AND prefetch = '$prefetch' AND iomethod = '$iomethod' AND ioworkers = $ioworkers AND eic = $eic AND query_order = '$qorder'
ORDER BY
  num_values
EOF

done < series.list

sqlite3 $RESDIR.db <<EOF
CREATE VIEW results_comparison AS
SELECT
  r1.did,
  r1.num_values,
  r1.iomethod,
  r1.ioworkers,
  r1.eic,
  r1.query_order,
  r1.time_uncached AS master_uncached,
  r1.time_cached AS master_cached,
  r2.time_uncached AS patched_off_uncached,
  r2.time_cached AS patched_off_cached,
  r3.time_uncached AS patched_on_uncached,
  r3.time_cached AS patched_on_cached
FROM
  results_aggregated r1
  JOIN results_aggregated r2 ON (r1.did = r2.did AND r1.num_values = r2.num_values AND r1.iomethod = r2.iomethod AND r1.ioworkers = r2.ioworkers AND r1.eic = r2.eic AND r1.query_order = r2.query_order)
  JOIN results_aggregated r3 ON (r1.did = r3.did AND r1.num_values = r3.num_values AND r1.iomethod = r3.iomethod AND r1.ioworkers = r3.ioworkers AND r1.eic = r3.eic AND r1.query_order = r3.query_order)
WHERE
  r1.branch = 'master'
  AND r2.branch = 'master-patched'
  AND r3.branch = 'master-patched'
  AND r2.prefetch = 'off'
  AND r3.prefetch = 'on'
EOF



sqlite3 $RESDIR.db > series.list <<EOF
.mode csv
.separator ' '
select distinct did, iomethod, ioworkers, eic, query_order
from results_comparison
EOF

while IFS= read -r line; do

	IFS=' ' read -r -a strarray <<< "$line"

	did="${strarray[0]}"
	iomethod="${strarray[1]}"
	ioworkers="${strarray[2]}"
	eic="${strarray[3]}"
	qorder="${strarray[4]}"

	qorder=$(echo $qorder | sed "s/\r//")

	#mkdir -p output/$RESDIR/$did/$iomethod/

	sqlite3 $RESDIR.db > output/$RESDIR/$did/$iomethod/compare-$ioworkers-$eic-$qorder.data <<EOF
.mode tab
SELECT
  num_values, 
  (1.0 * patched_off_uncached / master_uncached) AS patched_off_uncached,
  (1.0 * patched_on_uncached / master_uncached) AS patched_on_uncached,
  (1.0 * patched_off_cached / master_cached) AS patched_off_cached,
  (1.0 * patched_on_cached / master_cached) AS patched_on_cached
FROM
  results_comparison
WHERE
  did = $did AND iomethod = '$iomethod' AND ioworkers = $ioworkers AND eic = $eic AND query_order = '$qorder'
ORDER BY
  num_values
EOF

done < series.list


sqlite3 $RESDIR.db > cases.list <<EOF
.mode csv
.separator ' '
select distinct did, iomethod
from results_aggregated
order by did, iomethod
EOF

mkdir output/$RESDIR/plot
mkdir output/$RESDIR/pdf
mkdir output/$RESDIR/png

function get_query {
	tid=$(sqlite3 $RESDIR.db "SELECT distinct tid FROM results WHERE did = $1 AND query_order = '$2' ORDER BY random() LIMIT 1")
	cat $RESDIR/templates/$tid
}

while IFS= read -r line; do

	IFS=' ' read -r -a strarray <<< "$line"

	did="${strarray[0]}"
	iomethod="${strarray[1]}"

	iomethod=$(echo $iomethod | sed "s/\r//")

	title=$(cat "$RESDIR/datasets/$did" | sed ':a;N;$!ba;s/\n/\\\\n/g')

	Q1=$(get_query $did asc)
	Q2=$(get_query $did desc)
	Q3=$(get_query $did asc)
	Q4=$(get_query $did desc)

	sed "s/DID/$did/g" plot.template | sed "s/MACHINE/$RESDIR/" | sed "s/IOMETHOD/$iomethod/g" | sed "s/TITLE/$title/" | sed "s/Q1/$Q1/g" | sed "s/Q2/$Q2/g" | sed "s/Q3/$Q3/g" | sed "s/Q4/$Q4/g" > $did-$iomethod.plot
	#sed "s/DID/$did/g" plot-log.template | sed "s/MACHINE/$RESDIR/" | sed "s/IOMETHOD/$iomethod/g" > $did-$iomethod-log.plot

	gnuplot $did-$iomethod.plot
	#gnuplot $did-$iomethod-log.plot

	for f in *.pdf; do
		magick -density 120 $f -background '#ffffff' -flatten ${f/.pdf/.png}
	done

	mv *.plot output/$RESDIR/plot
	mv *.pdf output/$RESDIR/pdf
	mv *.png output/$RESDIR/png

	echo "## $did" >> output/$RESDIR/$iomethod.md
	echo "![$did](png/$did-$iomethod.png)" >> output/$RESDIR/$iomethod.md
	echo "[pdf](pdf/$did-$iomethod.pdf)" >> output/$RESDIR/$iomethod.md

done < cases.list

sqlite3 $RESDIR.db > $RESDIR-uncached-off.txt <<EOF
.mode table
SELECT
  *,
  100.0 * (patched_off_uncached / master_uncached) AS patched_off_coeff,
  100.0 * (patched_on_uncached / master_uncached) AS patched_on_coeff
FROM results_comparison
ORDER BY patched_off_coeff DESC
EOF

sqlite3 $RESDIR.db > $RESDIR-uncached-on.txt <<EOF
.mode table
SELECT
  *,
  100.0 * (patched_off_uncached / master_uncached) AS patched_off_coeff,
  100.0 * (patched_on_uncached / master_uncached) AS patched_on_coeff
FROM results_comparison
ORDER BY patched_on_coeff DESC
EOF

sqlite3 $RESDIR.db > $RESDIR-cached-off.txt <<EOF
.mode table
SELECT
  *,
  100.0 * (patched_off_cached / master_cached) AS patched_off_coeff,
  100.0 * (patched_on_cached / master_cached) AS patched_on_coeff
FROM results_comparison
ORDER BY patched_off_coeff DESC
EOF

sqlite3 $RESDIR.db > $RESDIR-cached-on.txt <<EOF
.mode table
SELECT
  *,
  100.0 * (patched_off_cached / master_cached) AS patched_off_coeff,
  100.0 * (patched_on_cached / master_cached) AS patched_on_coeff
FROM results_comparison
ORDER BY patched_on_coeff DESC
EOF
