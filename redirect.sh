#!/bin/sh
# CRONJOB (sudo crontab -e):
# * * * * * /path/to/this/script

# /////////////////////////////////////////////////////////
#
#				Add your Dyn DNS here
DYN_ADRESS='vzpokxjfdxziknpdpvduucsemjaqbisq.slando.ovh'
#
#
# /////////////////////////////////////////////////////////
SCRIPT_PATH="$(dirname $(readlink -f $0))"
#text file
PORTFILE="$SCRIPT_PATH/ports.ini"
IPFILE='currentip.store'

if  ! test -f "$IPFILE"; then
	touch "$IPFILE"
fi
if  ! test -f "$PORTFILE"; then
		echo '#Only one config per line, like <Protocoll> <Ingoing Port> <Outgoing Port> <-Name>. Example "udp 1234 1234 -MinecraftServer". Commentout unused rules with "#"' > "$PORTFILE"
		echo 'Commentout unused rules with "#"' >> "$PORTFILE"
		echo '' >> "$PORTFILE"
		echo '#udp 1234 1234 -Examle' >> "$PORTFILE"
fi

#Assign IP from resolving DynDNS to $DYN_IP
DYN_IP="$(nslookup $DYN_ADRESS | grep 'Address: ' | cut -d ' ' -f2)"
#
CURRENT_IP="$(cat $SCRIPT_PATH/$IPFILE)"

# Use: del_port <single iptable line>
del_port()
{
	echo "$1" | grep 'tcp' | \
	while read line; do
		SRC_PORT=$(echo "$line" | cut -d ':' -f2 | sed 's/ to//g')
		DST_PORT=$(echo "$line" | cut -d ':' -f4)
		sudo iptables -t nat -D PREROUTING -i ens3 -p tcp --dport "$SRC_PORT" -j DNAT --to "$CURRENT_IP":"$DST_PORT"
	done
	echo "$1" | grep 'udp' | \
        while read line; do
		SRC_PORT=$(echo "$line" | cut -d ':' -f2 | sed 's/ to//g')
        DST_PORT=$(echo "$line" | cut -d ':' -f4)
		sudo iptables -t nat -D PREROUTING -i ens3 -p udp --dport "$SRC_PORT" -j DNAT --to "$CURRENT_IP":"$DST_PORT"
	done
}
#Use: conf_port <line from PORTFILE>
conf_port()
{
	sudo iptables -t nat -A PREROUTING -i ens3 -p "$1" --dport "$2" -j DNAT --to "$DYN_IP":"$3"
}

#echo "Current IP: $CURRENT_IP"
#echo "Dynamic IP: $DYN_IP"
#Check if the IP in the IPTABLES rules is still valid
if [ "$CURRENT_IP" != "$DYN_IP" ] || [ "$(whoami)" != "root" ]
then
	#Filters iptable by old IP
	sudo iptables -t nat -L | grep "to:$CURRENT_IP" | \
	while IFS= read i; do
			del_port "$i"
	done
	#Reads Ports  and Protocol from PORTFILE

	cat $PORTFILE | grep -v '#' | cut -d '-' -f1 | \
	while read line; do
		if [ ! -z "$line" ]
		then
			conf_port $line
		fi
	done
	sudo iptables -t nat -D POSTROUTING -o ens3 -j MASQUERADE
	sudo iptables -t nat -A POSTROUTING -o ens3 -j MASQUERADE
	echo "$DYN_IP" > "$SCRIPT_PATH"/"$IPFILE"
	
	else
		echo "IPs are equal"
		exit 0
fi
