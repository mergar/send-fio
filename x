[0;35mOS: [0;32mFreeBSD[0m
[0;35mOPSYS: [0;32mFreeBSD[0m
TPL2: http://perf.spacevm.ru/fio/read.fio, CFG: http://perf.spacevm.ru/fio/read.config, OFFLINE: 1
environment override for: RUNTIME (10)
environment override for: RWMIXREAD (50)
DIRECTORY RUNTIME BS IOENGINE DIRECT NUMJOBS THREAD SIZE IODEPTH RWMIXREAD
Auto-detect if O_DIRECT flags is supported /tmp/test: supported
Auto-detect for BS /tmp/test: 1m
FIO_DIR: /tmp/test
CHECK for: /tmp/test/job.0.0
/usr/local/bin/fio --output-format=json --output=/tmp/spacevm-perf-fio/tests/1m/read-iodepth-16-numjobs-8.json /tmp/profile.fio --eta-newline=1


[1;37m======== [read] [bs:1m,depth:,jobs:8,rwmixread:50,fs:raw] result ========:[0m
[1;32mRead: 5883[0;35m MB/s ( [1;32m6024330[0;35m KB/s )[0m
[1;32mWrite: 0[0;35m MB/s ( [1;32m0[0;35m KB/s )[0m
[1;32mRead IOPS: 5883.135059 ( max:6654,min:5003 )[0m
[1;32mWrite IOPS: 0.000000 ( max:0,min:0 )[0m
Hooks found: fio-hook-example.sh
  :: fio-hook-example.sh
PROFILE: read
BS: 1m
DEPTH: 
JOBS: 8
RWMIXREAD: 50
FS: raw
R_MB: 5883
R_KB: 6024330
W_MB: 0
W_KB: 0
R_OPS: 5883.135059
R_IOPS_MAX: 6654
R_IOPS_MIN: 5003
W_IOPS: 0.000000
W_IOPS_MAX: 0
W_IOPS_MIN: 0

Clean dir: /tmp/test
rmdir: /tmp/test: Directory not empty
spacevm-perf-fio-send: skip reporting, offline mode

Summary:
profile: read  |fs: raw  |read: 5883  |write: 0  |r-iops: 5883.135059  |w-iops: 0.000000
[0;32mPlease type for re-run: [0;32m/usr/local/bin/spacevm-perf-fio-run[0m
