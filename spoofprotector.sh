#!/bin/bash
function watchspoofing() {
	MACINI=`arp | egrep -w $1 | awk '{print $3}' 2> /dev/null` 
	CNET=`arp | egrep -w $1 | awk '{print $5}' 2> /dev/null` 
	echo "Conectado al Router con dirección MAC: $MACINI, mediante $CNET"
	echo -e "\e[1;32m[OK]\e[0m SpoofProtection ACTIVADO."
	while true; do 
		MACFIN=`arp | egrep -w $1 | tail -1 | awk '{print $3}' 2> /dev/null` 
		if [ $MACINI != $MACFIN ] && [ $(arp | egrep $MACFIN | wc -l ) -gt 1 ]; then 
			MACDUPL=`arp | egrep -vw $1 | egrep -w $MACFIN | awk '{print $1}' 2> /dev/null` 
			echo "[+] ALERTA: duplicación de la MAC detectado en la tabla ARP, ¡posible ataque MITM!"
			echo "[+] Bajando interfaz $CNET para prevenir sniffing de paquetes de datos"
			echo "[+] El presunto atacante es el host con la IP: $MACDUPL"
			sudo ifdown $CNET 2> /dev/null 
			sudo service networking stop || /etc/init.d/networking stop 2> /dev/null 
			read -p "Desea prevenir futuros ataques MITM por ARP Spoofing (s|n): " RESP1
			case $RESP1 in
				s|S)
					read -p "Escriba las direcciones IP: " DIRCS
					for ip in $DIRCS; do
						read -p "Escriba la dirección MAC de $ip: " MACS
						echo "Estableciendo entradas estaticas en la tabla ARP para $ip ..."
						sleep 1
						sudo arp -s $ip $MACS 2> /dev/null 
					done
					echo "Estos valores no permaneceran una vez reiniciado el equipo"
				;;
				n|N)
					echo "Saliendo..."
					exit 2
				;;
				*)
					echo "Opción desconocida..."
					exit 1
				;;
			esac
		fi
	done
}

if [ $# -ne 1 ]; then 
	echo "Uso: `basename $0` $gatewayIP | --menu " 
	exit 1
elif [ $1 != "--menu" ]; then 
	watchspoofing "$1"
else
	echo "   _____                   ____   ____             __            __"            
	echo "  / ___/____  ____  ____  / __/  / __ \_________  / /____  _____/ /_____  _____"
	echo "  \__ \/ __ \/ __ \/ __ \/ /_   / /_/ / ___/ __ \/ __/ _ \/ ___/ __/ __ \/ ___/"
	echo " ___/ / /_/ / /_/ / /_/ / __/  / ____/ /  / /_/ / /_/  __/ /__/ /_/ /_/ / /"    
	echo "/____/ .___/\____/\____/_/    /_/   /_/   \____/\__/\___/\___/\__/\____/_/"     
	echo "    /_/ by @deividgdt"
	echo ""                                                                       
	echo "Bienvenido a SpoofProtector"
	sleep 1
	echo -ne "1)Activar SpoofProtector \n2)Prevenir ataques MITM \nElija una opcion: "; read OPCION
	case $OPCION in
		1)
			read -p "Escriba la dirección IP de su Gateway: " DIRIP
			echo "RECOMENDACIÓN: CTRL+Z detiene el proceso, despues escriba bg en el terminal y lo establecerá en segundo plano."
			watchspoofing "$DIRIP" 
		;;
		2)
			read -p "Escriba las direcciones IP: " DIRCS
			for ip in $DIRCS; do
				read -p "Escriba la dirección MAC de $ip: " MACS
				echo "Estableciendo entradas estaticas en la tabla ARP para $ip ..."
				sleep 1
				sudo arp -s $ip $MACS 2> /dev/null
			done
		;;
	esac
fi
