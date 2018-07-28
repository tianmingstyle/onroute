#!/bin/sh
#
# use in padavan firmware by huangyewudeng
# Automatic switching relay 2.4G-WiFi , now unsuport 5Gwireless
# This is a script to switch wifi node, when current network don't work.

. /etc/storage/switchwifi.conf
apLists=$(echo "$apLists" | awk '{for(ap=1;ap<=NF;ap++){print $ap}}')
#定义扫描WIFI热点函数
scan24Gwifi() {
   iwpriv apcli0 set SiteSurvey=1 && sleep 6 
   scanAp=$(iwpriv apclix0 get_site_survey)
}
ping -c 3 -w 8 www.baidu.com &> /dev/null && exit
[ `nvram get rt_mode_x` -eq 0 ] && nvram set rt_mode_x=4
if [ `nvram get rt_mode_x` -ne 0 ];then
	for apList in $apLists;do
                #Current wifi works?
                ping -c 3 -w 8 www.baidu.com &> /dev/null && exit

		apSid=$(echo $apList | awk -F: '{print $1}')
		apPwd=$(echo $apList | awk -F: '{print $2}')
  		[ $apSid == $(nvram get rt_sta_ssid) ] && continue
 		#扫描WIFI热点
		scan24Gwifi
		#拿扫描到的所有WIFI热点信息和当前循环的已知WIFI作匹配
 		apInfo=`echo $scanAp | grep $apSid`
		if [ -z "$apInfo" ];then
			for I in `seq 2`;do
				scan24Gwifi
				apInfo=`echo "$scanAp" | grep $apSid`
				[ -n "$apInfo" ] && break	
			done
		fi
		#用匹配到的信息，设置路由器并重启
		if [ -n "$apInfo" ];then
			 ch=`echo "$apInfo" | awk -F' ' '{print $2}'`
                         nvram set rt_sta_ssid=$apSid
                         nvram set rt_sta_wpa_psk=$apPwd 
                         nvram set rt_channel=$ch
                         nvram commit && sleep 2
                         radio2_restart
		else 
			continue
		fi
		
	done
fi
