#!/system/bin/sh
file=/data/0426/iwpriv_stat_rx.log
rm -rf ${file}

echo "iwpriv wlan0 driver VER:" >> ${file} 
iwpriv wlan0 driver VER >> ${file}

echo "iwpriv wlan0 driver stat" >>  ${file}
while :
do
    iwpriv wlan0 driver stat >> ${file}
    echo >> ${file}
    sleep 1
done

