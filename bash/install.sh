#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH
Green_font="\033[32m" && Red_font="\033[31m" && Font_suffix="\033[0m"
Info="${Green_font}[Info]${Font_suffix}"
Error="${Red_font}[Error]${Font_suffix}"
echo -e "${Green_font}
#======================================
# Project: SSR-nanqinlang
# Author: nanqinlang
# Github: https://github.com/nanqinlang
#======================================${Font_suffix}"

#check system
check_system(){
	cat /etc/issue | grep -q -E -i "debian" && release="debian" 
	cat /etc/issue | grep -q -E -i "ubuntu" && release="ubuntu"
	if [[ "${release}" = "debian" || "${release}" != "ubuntu" ]]; then 
	echo -e "${Info} system is ${release}"
	else echo -e "${Error} not support!" && exit 1
	fi
}

#check root
check_root(){
	if [[ "`id -u`" = "0" ]]; then
	echo -e "${Info} user is root"
	else echo -e "${Error} must be root user" && exit 1
	fi
}

get_port(){
	echo -e "${Info} input required server port:"
	stty erase '^H' && read -p "(defaultly use '2000'):" port
	[[ -z "${port}" ]] && port=2000
}

get_password(){
	echo -e "${Info} input required password:"
	stty erase '^H' && read -p "(defaultly use 'wallace'):" password
	[[ -z "${password}" ]] && password=wallace
}

get_method(){
	echo -e "${Info} select required method:\n1.none\n2.aes-256-cfb\n3.aes-256-ctr\n4.rc4-md5\n5.rc4-md5-6\n6.salsa20\n7.chacha20\n8.chacha20-ietf"
	stty erase '^H' && read -p "(defaultly use 'none'):" method
	[[ -z "${method}" ]] && method=none
	[[ "${method}" = "1" ]] && method=none
	[[ "${method}" = "2" ]] && method=aes-256-cfb
	[[ "${method}" = "3" ]] && method=aes-256-ctr
	[[ "${method}" = "4" ]] && method=rc4-md5
	[[ "${method}" = "5" ]] && method=rc4-md5-6
	[[ "${method}" = "6" ]] && method=salsa20
	[[ "${method}" = "7" ]] && method=chacha20
	[[ "${method}" = "8" ]] && method=chacha20-ietf
	[[ "${method}" = "salsa20" || "${method}" = "chacha20" || "${method}" = "chacha20-ietf" ]] && wget https://raw.githubusercontent.com/nanqinlang/libsodium/master/libsodium.sh && chmod 7777 libsodium.sh && ./libsodium.sh
}

get_protocol(){
    echo -e "${Info} select required protocol:\n1.origin\n2.auth_sha1_v4\n3.auth_aes128_sha1\n4.auth_aes128_md5\n5.auth_chain_a"
	stty erase '^H' && read -p "(defaultly use 'auth_chain_a'):" protocol
	[[ -z "${protocol}" ]] && protocol=auth_chain_a
	[[ "${protocol}" = "1" ]] && protocol=origin
	[[ "${protocol}" = "2" ]] && protocol=auth_sha1_v4
	[[ "${protocol}" = "3" ]] && protocol=auth_aes128_sha1
	[[ "${protocol}" = "4" ]] && protocol=auth_aes128_md5
	[[ "${protocol}" = "5" ]] && protocol=auth_chain_a
	[[ "${protocol}" = "6" ]] && protocol=auth_chain_b
}

get_obfs(){
	echo -e "${Info} select required obfs:\n1.plain\n2.http_simple\n3.http_post\n4.tls1.2_ticket_auth\n5.tls1.2_ticket_fastauth"
	stty erase '^H' && read -p "(defaultly use 'tls1.2_ticket_auth'):" obfs
	[[ -z "${obfs}" ]] && obfs=tls1.2_ticket_auth
	[[ "${obfs}" = "1" ]] && obfs=plain
	[[ "${obfs}" = "2" ]] && obfs=http_simple
	[[ "${obfs}" = "3" ]] && obfs=http_post
	[[ "${obfs}" = "4" ]] && obfs=tls1.2_ticket_auth
	[[ "${obfs}" = "5" ]] && obfs=tls1.2_ticket_fastauth
}

get_redirect(){
	echo -e "${Info} input required redirect:"
	stty erase '^H' && read -p "(defaultly use ''):" redirect
	[[ -z "${redirect}" ]] && redirect=
}

install(){
	check_system
	check_root
	apt-get update && apt-get install git python-m2crypto python-dev libevent-dev python-setuptools python-gevent -y && easy_install greenlet gevent
	cd /home && git clone -b full https://github.com/nanqinlang/shadowsocksr-nanqinlang.git shadowsocksr
	[[ ! -d shadowsocksr ]] && echo -e "${Error} get files failed, please check " && exit 1
	cd /home/shadowsocksr/run
	get_port
	get_password
	get_method
	get_protocol
	get_obfs
	get_redirect
	echo -e "{
	\"server\": \"0.0.0.0\",
	\"server_ipv6\": \"::\",
	\"local_address\": \"127.0.0.1\",
	\"local_port\": 1080,

	\"server_port\": ${port},
	\"password\": \"${password}\",
	\"method\": \"${method}\",
	\"protocol\": \"${protocol}\",
	\"protocol_param\": \"\",
	\"obfs\": \"${obfs}\",
	\"obfs_param\": \"\",

	\"speed_limit_per_con\": 0,
	\"speed_limit_per_user\": 0,

	\"additional_ports\" : {}, // only works under multi-user mode
	\"additional_ports_only\" : false, // only works under multi-user mode

	\"timeout\": 120,
	\"udp_timeout\": 60,
	\"dns_ipv6\": false,
	\"connect_verbose_info\": 0,

	\"redirect\": \"${redirect}\",
	\"fast_open\": true
}\c" > user-config.json
	python server.py -d start
	status
}

status(){
	if [[ -e /home/shadowsocksr/run/shadowsocksr.pid ]]; then
	echo -e "${Info} ssr is running" && exit 0
	else echo -e "${Error} ssr is not running,please check" && exit 0
	fi
}

uninstall(){
	cd /home/shadowsocksr/run && python server.py -d stop
	rm -rf /home/shadowsocksr
	echo -e "${Info} uninstall ssr finished"
	exit 0
}

command=$1
if [[ "${command}" = "" ]]; then
	echo -e "${Info}command not found, usage: ${Green_font}{ install | status | uninstall }${Font_suffix}" && exit 0
else
	command=$1
fi
case "${command}" in
	 install)
	 install 2>&1
	 ;;
	 status)
	 status 2>&1
	 ;;
	 uninstall)
	 uninstall 2>&1
	 ;;
esac
