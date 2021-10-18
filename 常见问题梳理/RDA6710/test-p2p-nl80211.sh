#!/bin/ash
ECHO="echo -e"

#ECHO_CMD=""
ECHO_CMD="echo -e \tcmd:"
#BUSYBOX="busybox"
IFCONFIG="$BUSYBOX ifconfig"
UDHCPC="$BUSYBOX udhcpc"
UDHCPD="$BUSYBOX udhcpd"
KILL="$BUSYBOX kill"
PS="$BUSYBOX ps"
SED="$BUSYBOX sed"
PING="$BUSYBOX ping"
HOSTAPD_ROOT_PATH="."
HOSTAPD="$HOSTAPD_ROOT_PATH/hostapd"
HOSTAPD_CLI="$HOSTAPD_ROOT_PATH/hostapd_cli"
WPA_SUPPLICANT="$HOSTAPD_ROOT_PATH/bin/wpa_supplicant"
WPA_CLI="$HOSTAPD_ROOT_PATH/bin/wpa_cli"
WPA_CONFIG="./p2p_supplicant.conf"

START=""
END=""
DIFF=""

pincode=12345678
IFNAME=p2p0
mode=1
peermac=""

DUMP_FILE="/tmp/wfa.status"
DUMP_WPSPIN="/tmp/wfa.wps_pin"
DUMP_PEER="/tmp/wfa.peer"

DUMP_P2P_GROUP_INTERFACE="/tmp/wfa.action.GIFNAME"
VERSION_STRING="ver_0.5"
HWADDR=""
DEV_NAME=""
P2P_STATUS="idle"
FIND_TIMEOUT="0"
GO_INTENT=""
LISTEN_CH="1"
OPER_CH="1"
FAST_REAUTH=""
COUNTRY=""
PERSISTENT_RECONNECT=""

WPS_METHODS="pbc"
WPS_PIN=""
P2P_GROUP_INTERFACE=""

OPER_SSID=""
JOIN=""

USERIF="0"

_DEBUG="on"

#############################################################################
DEBUG()
{
 [ "$_DEBUG" == "on" ] &&  $@
}

NoDEBUG()
{
 [ "$_DEBUG" != "on" ] &&  $@
}

kill_daemon() {
    NAME=$1
    PLIST=`$PS | grep $NAME | cut -f2 -d" "`
    if [ ${#PLIST} -eq 0 ]; then
		PLIST=`$PS | grep $NAME | cut -f3 -d" "`
    fi

	PID=`echo $PLIST | cut -f1 -d" "`
    if [ $PID -gt 0 ]; then
        $KILL $PID
    fi
}

RUN_START() {
	START=$(date +%S.%N)
}

RUN_END() {
	END=$(date +%S.%N)
	DIFF=$(echo "$END - $START" | bc)
	$ECHO "\t\t[$DIFF seconds]"
}

SHOW_VER() {
	$ECHO "$0 :\t$VERSION_STRING"
}

SHOW_PEERS() {
	$ECHO "================================================================"
	peers=$($WPA_CLI -i $IFNAME p2p_peers)
	for peer in $peers
	do
		result=$($WPA_CLI -i $IFNAME p2p_peer $peer \
				| awk '{printf("%s, ",$0);}' \
				| cut -d "," -f1,3,8,9,10,13,23,26,29,31,32 \
				| sed 's/,//g' \
				| sed 's/config_methods/\\n\\tconfig_methods/g' \
				| sed 's/status/\\n\\tstatus/g' \
				| sed 's/wfd_subelems/\\n\\twfd_subelems/g')
		$ECHO $result
	done
	$ECHO "================================================================"
}



#
# p2p_set
#discoverability
#managed
#listen_channel
#ssid_postfix
#noa
#ps
#oppps
#ctwindow
#disabled
#conc_pref
#force_long_sd
#peer_filter
#cross_connect
#go_apsd
#client_apsd
#disallow_freq
#disc_int
#
#
#set
#p2p_listen_reg_class
#p2p_listen_channel
#p2p_oper_reg_class
#p2p_oper_channel
#p2p_go_intent
#p2p_ssid_postfix
#persistent_reconnect
#p2p_intra_bss
#p2p_group_idle
#p2p_pref_chan
#p2p_go_ht40
#p2p_disabled
#p2p_no_group_IFNAME
#p2p_ignore_shared_freq


SET_P2P_PARAMS() {
	$ECHO $1 $2 $3 $#
}

PARAMS() {
	$ECHO $1 $2 $3 $#
}

SHOW_PARAMS() {
	$ECHO "================================================================"
	$ECHO " MAC Address : $HWADDR  Device Name : $DEV_NAME"
	$ECHO " P2P Status  : $P2P_STATUS" "\t\t" " P2P Find timeout : $FIND_TIMEOUT"
	$ECHO " Mode        : $MODE"
	$ECHO " GO Intent   : $GO_INTENT"
	$ECHO " Listen CH.  : $LISTEN_CH" "\t\t" " Oper CH. : $OPER_CH"
	$ECHO " WPS Methods : $WPS_METHODS" "\t\t" " WPS_PIN : $WPS_PIN"
	$ECHO " WPS_STATUS  : $WPS_STATUS"
	$ECHO " IP Address  : $IPADDR" "\t" " GATEWAY : $GATEWAY"
	$ECHO " SSID        : $SSID"
	$ECHO " WFD Port    : 0x${WFD_ELEMENTS:10:4}"
	$ECHO "================================================================"
}

DASH_BOARD() {
	$ECHO "================================================================"
	SHOW_VER
	SHOW_PARAMS
	$ECHO "================================================================"
	$ECHO " (-i)  Set Go Intent." "\t\t" " (-ft) Set find timeout."
	$ECHO " (-lc) Set listen channel." "\t" " (-oc) Set Operation channel."
	$ECHO " (-wm) Set WPS Methods." "\t" " (-pin) Set PIN Code."
	$ECHO " (-u)  Update Setting."
	$ECHO "----------------------------------------------------------------"
	$ECHO " (l) P2P Listen." "\t\t" " (f) P2P Find."
	$ECHO " (s) P2P Stop Listen/Find."
	$ECHO " (p)[enter] Show Peers"
	$ECHO " (P) Provision Discover"
	$ECHO " (iv) P2P Invitation"
	$ECHO " (c) P2P Connect." "\t\t" " (g) P2P GO."
	$ECHO " (F) P2P flush." "\t\t" " (d) P2P disconnect."
	$ECHO " (b) Push Button."
	$ECHO " (ping) Ping testing."
	$ECHO " (q) Quit."
	$ECHO "================================================================"
}

USAGE() {
	$ECHO "usage: p2p-nl80211.sh (-i ifname) [OPTION 1] [AGRUMENT 1]..."
	$ECHO "example:"
	$ECHO "   p2p-nl80211.sh -i p2p0 --listen-channel 1"
	$ECHO "   p2p-nl80211.sh -i p2p0 --p2p-connect BA:BA:BA:BA:BA:BA pbc 15 2412"
	$ECHO "----------------------------------------------------------------"
	$ECHO "   -h, --help                   show help."
	$ECHO "   st, --status                 show status."
	$ECHO ""
	$ECHO "   dn, --device-name            set device name."
	$ECHO "   gi, --go-intent              set go intent. *override p2p-connect go_intent"
	$ECHO "   lc, --listen-channel         set listen channel."
	$ECHO "   oc, --oper-channel           set operation channel."
	$ECHO "   sp, --ssid-postfix           set ssid postfix."
	$ECHO "----------------------------------------------------------------"
	$ECHO "   l, --p2p-listen              P2P listen."
	$ECHO "   f, --p2p-find                P2P devices search."
	$ECHO "   s, --stop-find               stop P2P devices search."
	$ECHO "   p, --prov-disc               P2P provision discovery."
	$ECHO "   c, --p2p-connect             connect to P2P GC/GO."
	$ECHO "   ga, --group-add              create P2P GO."
	$ECHO "   gr, --group-remove           remove P2P GO."
	$ECHO "   pbc, --wps-pbc               wps push button."
	$ECHO "   pin, --wps-pin               wps pin code."
	$ECHO "   res, --reset                 reset default."
	$ECHO ""
	$ECHO "[CMD user interface]"
	$ECHO "   ui, --user-interface         user interface."
	$ECHO "   q, --quit                    quit script."
	$ECHO "================================================================"

	$ECHO "   , --p2p-peers                Show Peers"
	$ECHO "   , --p2p-invitation           P2P Invitation"
	$ECHO "   F, --p2p-flush               P2P flush."
	$ECHO "   d, --p2p-disconnect          P2P disconnect."

}

PROV_DISC() {
	SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_prov_disc $1 $WPS_METHODS"
}

INVITATION() {
	SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_invite persistent=$1 group=$IFNAME peer=$2"
}

CONNECT() {
	if [ "$WPS_METHODS" == "pbc" ]; then
	    if [ "$3" == "" ]; then
		SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_connect $1 $WPS_METHODS persistent $JOIN go_intent=$2"
	    else
		SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_connect $1 $WPS_METHODS persistent $JOIN go_intent=$2 freq=$3"
	    fi
	else
	    if [ "$3" == "" ]; then
		SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_connect $1 $WPS_PIN $WPS_METHODS persistent $JOIN go_intent=$2"
	    else
		SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_connect $1 $WPS_PIN $WPS_METHODS persistent $JOIN go_intent=$2 freq=$3"
	    fi
	fi
}

RESET() {
	SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_stop_find"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_cancel"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_flush"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_group_remove $IFNAME"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME remove_network 0"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME remove_network 1"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME remove_network 2"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME disconnect"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME reconfigure"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME set ps 0"
	SEND_SET_CMD "$IFCONFIG $IFNAME 0.0.0.0"
}

INIT_PARAMS() {
	if [ -f $WPA_CONFIG ]; then
		DEV_NAME=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^device_name | cut -d= -f2")
		LISTEN_CH=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^p2p_listen_channel | cut -d= -f2")
		OPER_CH=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^p2p_oper_channel | cut -d= -f2")
		GO_INTENT=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^p2p_go_intent | cut -d= -f2")
		FAST_REAUTH=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^fast_reauth | cut -d= -f2")
		COUNTRY=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^country | cut -d= -f2")
		PERSISTENT_RECONNECT=$(SEND_GET_CMD "cat $WPA_CONFIG | grep ^persistent_reconnect | cut -d= -f2")
	fi
}

UPDATE_PARAMS() {
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET device_name $DEV_NAME"
	#SEND_SET_CMD "$WPA_CLI -i $IFNAME SET device_type 1-0050F204-1"
	#SEND_SET_CMD "$WPA_CLI -i $IFNAME SET config_methods 'virtual_display virtual_push_button keypad'"
	#SEND_SET_CMD "$WPA_CLI -i $IFNAME SET p2p_listen_reg_class 81"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET p2p_listen_channel $LISTEN_CH"
	#SEND_SET_CMD "$WPA_CLI -i $IFNAME SET p2p_oper_reg_class 81"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET p2p_oper_channel $OPER_CH"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET p2p_go_intent $GO_INTENT"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET fast_reauth $FAST_REAUTH"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET country $COUNTRY"
	SEND_SET_CMD "$WPA_CLI -i $IFNAME SET persistent_reconnect $PERSISTENT_RECONNECT"
}

LIST_PARAMS() {
	$ECHO -n "" > $DUMP_FILE
	$ECHO "mac="$HWADDR >> $DUMP_FILE
	$ECHO "mode="$MODE >> $DUMP_FILE
	$ECHO "ipaddr="$IPADDR >> $DUMP_FILE
	$ECHO "bcast="$BCAST >> $DUMP_FILE
	$ECHO "mask="$MASK >> $DUMP_FILE
	$ECHO "gateway="$GATEWAY >> $DUMP_FILE
### P2P
	$ECHO "p2p_status="$P2P_STATUS >> $DUMP_FILE
	$ECHO "devname="$DEV_NAME >> $DUMP_FILE
	$ECHO "oper_channel="$OPER_CH >> $DUMP_FILE
	$ECHO "devid="$DEVID >> $DUMP_FILE
	$ECHO "groupid="$GRPID >> $DUMP_FILE
	$ECHO "bssid="$GRPID >> $DUMP_FILE
	$ECHO "ssid="$SSID >> $DUMP_FILE
	$ECHO "groupids="$GRPID $SSID >> $DUMP_FILE
	$ECHO "ssid_postfix="$SSID_POSTFIX >> $DUMP_FILE
	$ECHO "go_passphase="$GO_PASSPHASE >> $DUMP_FILE
	$ECHO "wfd_elements="$WFD_ELEMENTS >> $DUMP_FILE
	$ECHO "wfd_port=0x"${WFD_ELEMENTS:10:4} >> $DUMP_FILE
### P2P

	$ECHO "wps_status="$WPS_STATUS >> $DUMP_FILE

	DEBUG "cat $DUMP_FILE"
}

GET_STATUS() {
### HW Interface
	HWADDR=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep ^address | cut -d= -f2")
	if [ "$HWADDR" == "" ]; then
		HWADDR="BA:BA:BA:BA:BA:BA"
	fi

### HW Interface
### WPS
	WPS_STATUS=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep wpa_state | cut -d= -f2")
	if [ "$WPS_STATUS" == "" ]; then
		WPS_STATUS="none"
	fi
### WPS


### P2P
	DEVID=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep p2p_device_address | cut -d= -f2")
	GRPID=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep ^bssid | cut -d= -f2")
	SSID=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep ^ssid | cut -d= -f2")
	if [ "$SSID" == "" ]; then
		SSID="DIRECT-"
	fi
	GO_PASSPHASE=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME p2p_get_passphrase")
	if [ "$WPS_STATUS" == "COMPLETED" ]; then
		WFD_ELEMENTS=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME p2p_peer $GRPID | grep ^wfd_subelems | cut -d= -f2")
	fi
### P2P

### IP
	IPADDR=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep ip_address | cut -d= -f2")
	if [ "$IPADDR" == "" ]; then
		IPADDR="0.0.0.0"
	fi
	BCAST=$(SEND_GET_CMD "$BUSYBOX ifconfig $IFNAME| grep 'inet addr' | cut -f3 -d: | cut -f1 -d ' '")
	if [ "$BCAST" == "" ]; then
		BCAST="255.255.255.255"
	fi
	MASK=$(SEND_GET_CMD "$BUSYBOX ifconfig $IFNAME| grep 'inet addr' | cut -f4 -d:")
	if [ "$MASK" == "" ]; then
		MASK="255.255.255.255"
	fi
	GATEWAY=$(SEND_GET_CMD "ip route | grep default | grep $IFNAME| cut -d ' ' -f3")
	if [ "$GATEWAY" == "" ]; then
		GATEWAY="0.0.0.0"
	fi
### IP

	MODE=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep mode | cut -d= -f2")
	if [ "$MODE" == "" ]; then
		MODE="none"
	fi
}

GET_PEER_OPER_SSID() {
    # for Wi-Fi Sigma Tool
    case $GO_NEG in
	0) JOIN="auth";;
	1)
	    OPER_SSID=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME p2p_peer $1 | grep oper_ssid | cut -d= -f2")
	    if [ "$OPER_SSID" != "" ]; then
		JOIN="join"
	    else
		JOIN=""
	    fi
	    ;;
	*) JOIN="";;
    esac
}

WFD_SUBELEM_INIT() {
	SEND_SET_CMD "$WPA_CLI -i $IFNAME set wifi_display 1"
	# wfd_subelem_set <ID> [CONETENTS]
	# ex: wfd_subelem_set 0 000601111C44000A
	#                     ^ ID: 0
	#                       ^^^^ Length: 6
	#                           ^^^^^^^^^^^^ Value
	#                           ^^^^ Content protect, Available for WFD Session, Primary Sink
	#                               ^^^^ session port: 7236
	#                                   ^^^^ max throughput: 10 Mbps
	# reference Wi-Fi Display Technical Specification : Chapter 5 Frame Formats

	# Set WFD information Subelement(ID:0)
	SEND_SET_CMD "$WPA_CLI -i $IFNAME wfd_subelem_set 0 000600111C440041"
	# Set Associated BSSID Subelement(ID:1)
	SEND_SET_CMD "$WPA_CLI -i $IFNAME wfd_subelem_set 1 0006000000000000"
	# Set Coupled Sink Information Subelement(ID:6)
	SEND_SET_CMD "$WPA_CLI -i $IFNAME wfd_subelem_set 6 000700000000000000"
}

PING () {
	if [ "$#" != "1" ]; then
		ping $GATEWAY -c 4
	else
		ping $1 -c 4
	fi
}

SEND_SET_CMD() {
	if [ "$_DEBUG" == "on" ]; then
		echo -n "SEND_SET_CMD: $@ :"
        eval $@
	else
		eval $@ > /dev/null
    fi
}

SEND_GET_CMD() {
	if [ "$_DEBUG" == "on" ]; then
		eval $@
	else
		eval $@
	fi
}

#############################################################################

INIT_PARAMS
#UPDATE_PARAMS

#DEBUG "$ECHO input: $@"

if [ "$1" == "-i" ]; then
IFNAME=$2
input=$3
param1=$4
param2=$5
param3=$6
param4=$7
param5=$8
else
input=$1
param1=$2
param2=$3
param3=$4
param4=$5
param5=$6
fi

DEBUG "$ECHO input: $input $param1 $param2 $param3 $param4 $param5"

while :
do
	case $input in
#############################################################################
### Wi-Fi Station
#############################################################################
		sn | --set-network)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME set_network $param1 $param2 $param3"
			input=
			;;
#############################################################################
### Wi-Fi Direct (P2P)
#############################################################################
		pbc | --wps-pbc)
			WPS_METHODS="pbc"
			SEND_SET_CMD "$WPA_CLI -i $IFNAME wps_pbc"
			input=
			;;
		pin | --wps-pin)
			#WPS_PIN=$param1
			$ECHO -n "wps_pin=" > $DUMP_WPSPIN
			SEND_SET_CMD "$WPA_CLI -i $IFNAME wps_pin $param1 $param2 >> $DUMP_WPSPIN"
			DEBUG "cat $DUMP_WPSPIN"
			WPS_PIN=$(SEND_GET_CMD "cat $DUMP_WPSPIN")
			input=
			;;
		l | --p2p-listen)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_listen $param1"
			P2P_STATUS="listen"
			input=
			;;
		f | --p2p-find)
			RESET
			WFD_SUBELEM_INIT
			DEV_NAME=$param1
			HWADDR=$(SEND_GET_CMD "$WPA_CLI -i $IFNAME STATUS | grep ^address | cut -d= -f2")
			SEND_SET_CMD "$WPA_CLI -i $IFNAME SET device_name '$DEV_NAME($HWADDR)'"
			P2P_STATUS="finding"
			if [ "$param2" == "" ]; then
				FIND_TIMEOUT=0
			else
				FIND_TIMEOUT=$param2
			fi
			if [ "$FIND_TIMEOUT" == "0" ]; then
				SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_find"
			else
				SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_find $FIND_TIMEOUT"
				#l=0;
				#while [ $l -lt $FIND_TIMEOUT ]
				#do
				#	if [ "$?" == "1" ]; then
				#		break;
				#	else
				#		let l=$l+1;
				#		sleep 1
				#		$ECHO -n "."
				#	fi
				#done
				#$ECHO "P2P Stop Find."
				#P2P_STATUS="idle"
			fi

			input=
			;;
		s | --stop-find)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_stop_find"
			P2P_STATUS="idle"
			input=
			;;
		--peers)
			input=
			;;
		--peer)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_peer $param1 > $DUMP_PEER"
			input=
			;;
		P | --prov-disc)
			WPS_METHODS=$param2
			PROV_DISC $param1
			input=
			;;
		iv | --invite)
			INVITATION $param1 $param2
			input=
			;;
		c | --p2p-connect)
			GO_NEG=1
			#GOINITET=$GO_INTENT
			#if [ "$GO_INTENT" == "" ]; then
			#	GOINITET=$param3
			#else
			#	GOINITET=$GO_INTENT
			#fi
			if [ "$param2" == "pbc" ]; then
				WPS_METHODS=$param2
				GOINITET=$param3
				GET_PEER_OPER_SSID $param1 $GOINITET
				CONNECT $param1 $GOINITET $param4
			else
				WPS_PIN=$param2
				WPS_METHODS=$param3
				GOINITET=$param4
				GET_PEER_OPER_SSID $param1 $GOINITET
				CONNECT $param1 $GOINITET $param5
			fi
			P2P_STATUS="idle"
			input=
			;;
		pc | --p2p-pconnect)
			GO_NEG=0
			if [ "$param2" == "pbc" ]; then
				WPS_METHODS=$param2
				GOINITET=$param3
				GET_PEER_OPER_SSID $param1 $GOINITET
				CONNECT $param1 $GOINITET $param4
			else
				WPS_PIN=$param2
				WPS_METHODS=$param3
				GOINITET=$param4
				GET_PEER_OPER_SSID $param1 $GOINITET
				CONNECT $param1 $GOINITET $param5
			fi
			P2P_STATUS="idle"
			input=
			;;
		ga | --group-add)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_group_add freq=$param1"
			P2P_STATUS="idle"
			input=
			;;
		gr | --group-remove)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_group_remove $IFNAME"
			P2P_STATUS="idle"
			input=
			;;
		d)
			P2P_GROUP_INTERFACE=$(SEND_GET_CMD "cat $DUMP_P2P_GROUP_INTERFACE")
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_flush"
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_group_remove $P2P_GROUP_INTERFACE"
			if [ "$MODE" == "P2P GO" ]; then
				SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_group_remove $IFNAME"
			else
				SEND_SET_CMD "$WPA_CLI -i $IFNAME disable_network 0"
				SEND_SET_CMD "$WPA_CLI -i $IFNAME disable_network 1"
				SEND_SET_CMD "$WPA_CLI -i $IFNAME disable_network 2"
				SEND_SET_CMD "$WPA_CLI -i $IFNAME disconnect"
			fi
			P2P_STATUS="idle"
			input=
			;;
		F)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_flush"
			if [ "$MODE" == "P2P GO" ]; then
				SEND_SET_CMD "$WPA_CLI -i $IFNAME p2p_group_remove $IFNAME"
			else
				SEND_SET_CMD "$WPA_CLI -i $IFNAME remove_network 0"
				SEND_SET_CMD "$WPA_CLI -i $IFNAME remove_network 1"
				SEND_SET_CMD "$WPA_CLI -i $IFNAME remove_network 2"
				SEND_SET_CMD "$WPA_CLI -i $IFNAME disconnect"
			fi
			P2P_STATUS="idle"
			input=
			;;
		dn | --device-name)
			DEV_NAME=$param1
			SEND_SET_CMD "$WPA_CLI -i $IFNAME SET device_name $DEV_NAME"
			input=
			;;
		gi | --go-intent)
			GO_INTENT=$param1
			SEND_SET_CMD "$WPA_CLI -i $IFNAME SET p2p_go_intent $GO_INTENT"
			input=
			;;
		lc | --listen-channel)
			LISTEN_CH=$param1
			SEND_SET_CMD "$WPA_CLI -i $IFNAME set p2p_listen_channel $LISTEN_CH"
			input=
			;;
		oc | --oper-channel)
			OPER_CH=$param1
			SEND_SET_CMD "$WPA_CLI -i $IFNAME set p2p_oper_channel $OPER_CH"
			input=
			;;
		sp | --ssid-postfix)
			SSID_POSTFIX=$param1
			SEND_SET_CMD "$WPA_CLI -i $IFNAME set p2p_ssid_postfix $param1"
			input=
			;;
		ft)
			FIND_TIMEOUT=$param1
			input=
			;;
		wm)
			WPS_METHODS=$param1
			input=
			;;
		ud)
			UPDATE_PARAMS
			input=
			;;
		ping)
			PING $param1
			input=
			;;
		p)
			input=
			GET_STATUS
			DASH_BOARD
			;;
		st | --status)
			GET_STATUS
			LIST_PARAMS $param1
			input=
			;;
#############################################################################
### Wi-Fi Display
#############################################################################
		--wifi-dispaly)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME set wifi_display $param1"
			input=
			;;
		--wfd-subelem-set)
			SEND_SET_CMD "$WPA_CLI -i $IFNAME set wfd_subelem_set $param1 $param2"
			input=
			;;
		--wfd-peer-port)
			PEER_WFD_ELEMENTS=$(SEND_GET_CMD "grep ^wfd_subelems $DUMP_PEER | cut -d= -f2")
			$ECHO "wfd_port=0x${PEER_WFD_ELEMENTS:10:4}" >> $DUMP_PEER
			input=
			;;
#############################################################################
### Common
#############################################################################
		-h | --help)
			USAGE
			input=
			break;
			;;
		h | help)
			USAGE
			input=
			;;
		res | --reset)
			RESET
			P2P_STATUS="idle"
			input=
			;;
		ui | --user-interface)
			USERIF=1
			RESET
			WFD_SUBELEM_INIT
			P2P_STATUS="idle"
			input=
			;;
		q | quit)
			input=
			break
			;;
		*)
			if [ "$USERIF" = "0" ]; then
				break
			fi
			$ECHO "\n\n"
			GET_STATUS
			SHOW_PEERS
			SHOW_PARAMS
			#DASH_BOARD

			#SET_P2P_PARAMS

			$ECHO -n "Input : "
			read input param1 param2 param3 param4
			#echo $input
			;;
	esac
done
