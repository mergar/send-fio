#!/bin/sh
echo "PROFILE: ${PROFILE}" | tee -a /tmp/hooks.txt
echo "BS: ${FIO_BS}" | tee -a /tmp/hooks.txt
echo "DEPTH: ${FIO_DEPTH}" | tee -a /tmp/hooks.txt
echo "JOBS: ${FIO_NUMJOBS}" | tee -a /tmp/hooks.txt
echo "RWMIXREAD: ${FIO_RWMIXREAD}" | tee -a /tmp/hooks.txt
echo "FS: ${FS}" | tee -a /tmp/hooks.txt
echo "R_MB: ${R_MB}" | tee -a /tmp/hooks.txt
echo "R_KB: ${R_KB}" | tee -a /tmp/hooks.txt
echo "W_MB: ${W_MB}" | tee -a /tmp/hooks.txt
echo "W_KB: ${W_KB}" | tee -a /tmp/hooks.txt
echo "R_OPS: ${R_IOPS}" | tee -a /tmp/hooks.txt
echo "R_IOPS_MAX: ${R_IOPS_MAX}" | tee -a /tmp/hooks.txt
echo "R_IOPS_MIN: ${R_IOPS_MIN}" | tee -a /tmp/hooks.txt
echo "W_IOPS: ${W_IOPS}" | tee -a /tmp/hooks.txt
echo "W_IOPS_MAX: ${W_IOPS_MAX}" | tee -a /tmp/hooks.txt
echo "W_IOPS_MIN: ${W_IOPS_MIN}" | tee -a /tmp/hooks.txt
