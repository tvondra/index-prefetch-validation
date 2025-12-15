set terminal pdfcairo size 18,8 enhanced font 'Verdana,12'
set output '22-io_uring.pdf'

set yrange [0:]
set key bottom left

set xlabel '# values'
set ylabel "timing [ms]"

set log x

set ytics out
set y2tics
set autoscale y2fix

unset log y2
set y2range [0:2]

set multiplot layout 2,4 rowsfirst title "create unlogged table t (a bigint, b text) with (fillfactor = 100);\ninsert into t select 1 * a, b from (select r, a, b, generate_series(0,4-1) AS p from (select row_number() over () AS r, a, b from (select i AS a, md5(i::text) AS b from generate_series(1, 2500000) s(i) ORDER BY (i + 16 * (random() - 0.5))) foo) bar) baz ORDER BY ((r * 4 + p) + 2048 * (random() - 0.5));\ncreate index idx on t(a DESC);"

set title "cold\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a ASC"

unset log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-asc.data" using 1:3 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-asc.data" using 1:3 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-asc.data" using 1:3 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:2 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:3 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

unset ylabel

set title "cold (log)\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a ASC"

set log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-asc.data" using 1:3 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-asc.data" using 1:3 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-asc.data" using 1:3 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:2 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:3 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

set title "cold\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a DESC"

unset log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-desc.data" using 1:3 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-desc.data" using 1:3 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-desc.data" using 1:3 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:2 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:3 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

set title "cold (log)\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a DESC"

set y2label "comparison"
set log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-desc.data" using 1:3 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-desc.data" using 1:3 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-desc.data" using 1:3 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:2 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:3 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

unset y2label

set ylabel "timing [ms]"
set title "warm\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a ASC"

unset log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-asc.data" using 1:4 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-asc.data" using 1:4 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-asc.data" using 1:4 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:4 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:5 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

unset ylabel

set title "warm (log)\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a ASC"

set log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-asc.data" using 1:4 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-asc.data" using 1:4 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-asc.data" using 1:4 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:4 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-asc.data" using 1:5 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

set title "warm\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a DESC"

unset log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-desc.data" using 1:4 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-desc.data" using 1:4 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-desc.data" using 1:4 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:4 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:5 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"

set title "warm (log)\nSELECT * FROM t WHERE a BETWEEN $1 AND $2 ORDER BY a DESC"

set y2label "comparison"
set log y
plot "output/20251213-171740/22/io_uring/master-off-12-16-desc.data" using 1:4 with lines lc '#00cc00' title "master", \
     "output/20251213-171740/22/io_uring/master-patched-off-12-16-desc.data" using 1:4 with lines lc '#0000cc' title "patched/off", \
     "output/20251213-171740/22/io_uring/master-patched-on-12-16-desc.data" using 1:4 with lines lc '#cc0000' title "patched/on", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:4 axes x1y2 with lines dt 2 lt 8 lc '#0000cc' title "compare patched/off", \
     "output/20251213-171740/22/io_uring/compare-12-16-desc.data" using 1:5 axes x1y2 with lines dt 2 lt 9 lc '#cc0000' title "compare patched/on"
