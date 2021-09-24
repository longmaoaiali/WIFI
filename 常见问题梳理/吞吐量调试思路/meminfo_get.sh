#!/system/bin/sh
file=/data/05_18/iperf_thread_1_meminfo.txt
rm -rf ${file}

while :
do
    cat /proc/meminfo >> ${file}
    echo >> ${file}
    sleep 1
done

