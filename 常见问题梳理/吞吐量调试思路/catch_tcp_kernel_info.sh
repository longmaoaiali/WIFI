#!/system/bin/sh
function catch_dir(){
	read_path=$1
	save_file=$2
	file_list=$(ls $read_path)
	rm -rf /data/${save_file}
	for filename in ${file_list}
	do 
		echo ${filename} >> ${save_file}
		cat ${read_path}/${filename} >> ${save_file}
		echo "" >> ${save_file}
	done
}

catch_dir /proc/sys/net/core proc_sys_net_core.txt
catch_dir /proc/sys/net/ipv4 proc_sys_net_ipv4.txt
