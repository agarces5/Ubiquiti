#!/bin/bash
source funciones.sh
#Inicializar variables
user=admin
#---------------------------------------------------------------------------------------------------------------------
#--------------------------------- COMIENZO DEL SCRIPT ---------------------------------------------------------------
#---------------------------------------------------------------------------------------------------------------------
resp=$(echo $* | grep -iw "y$" | awk '{print $NF}')
passwdFile=pass.conf
key=key
ccrypt -d -k $key $passwdFile
#Leer variables
while getopts u:i:s:c: flag; do
    case "${flag}" in
    u) user=${OPTARG} ;;
    i) IP=${OPTARG} ;;
    s) script=${OPTARG} ;;
    c) comando=${OPTARG} ;;
    esac
done
mostrar_args
if [[ -z $IP ]]; then
    echo "-----------------------------------------------------------"
    echo "Debes introducir una direccion IP"
    echo
    help_menu
fi
if [[ -z $script && -z $comando ]]; then
    echo "No has introducido ni script ni comando"
fi
IFS=./ read -r i1 i2 i3 i4 mask <<<$IP  # Leer y separar la IP y la mascara que introducimos
if [[ -z $mask ]]; then
    if [[ -n $script ]]; then
        if [[ $(grep -c "\<$IP\>" $passwdFile) -ne 0 ]]; then
            pass=$(grep "\<$IP\>" $passwdFile | awk '{print $NF}' | sed -e 's/\[//; s/\]//')
            ejecutar_script -p "$pass" "$script" "$user" "$IP"
            unset pass
        else
            leer_passwd
            add_passwd "$IP" "$SECRET_PASSWD"
            ejecutar_script -p "$SECRET_PASSWD" "$script" "$user" "$IP"
        fi
    fi
    if [[ -n $comando ]]; then
        if [[ $(grep -c "\<$IP\>" $passwdFile) -ne 0 ]]; then
            pass=$(grep "\<$IP\>" $passwdFile | awk '{print $NF}' | sed -e 's/\[//; s/\]//')
            ejecutar_comando -p "$pass" "$user" "$IP" "$comando"
            unset pass
        else
            leer_passwd
            add_passwd "$IP" "$SECRET_PASSWD"
            ejecutar_comando -p "$SECRET_PASSWD" "$user" "$IP" "$comando"
        fi
    fi
else    # Si se pasa una red
    red=$(network $i1.$i2.$i3.$i4 $mask)            # Calculamos la red
    IFS=. read -r i1 i2 i3 i4 <<<$red               # Nos quedamos con la IP de la red
    broadcast=$(broadcast $i1.$i2.$i3.$i4 $mask)    # Calculamos el broadcast
    IFS=. read -r b1 b2 b3 b4 <<<$broadcast         # Guardamos la IP del broadcast
    netmask=$(netmask $mask)                        # Convertimos la máscara en formato A.B.C.D
    networkIP=()                                    # Creamos un array para guardar las IP de la red
    m=0
    networkIP[0]=$red                               
    for ((i = $i1; i <= $b1; i++)); do              # Guardamos todas las IP de la red en el array
        for ((j = $i2; j <= $b2; j++)); do
            for ((k = $i3; k <= $b3; k++)); do
                for ((h = $((i4 + 1)); h <= $b4; h++)); do
                    let m++
                    networkIP[$m]=$i.$j.$k.$h       # Guardo las IP de la red
                done
            done
        done
    done 
    for ((m = 1; m < $((${#networkIP[@]} - 1)); m++)); do           # Recorro todas las IP de la red (sin la primera y la última)
        if [[ -n $script ]]; then
            if [[ $(grep -c "\<${networkIP[$m]}\>" $passwdFile) -ne 0 ]]; then
                pass=$(grep "\<${networkIP[$m]}\>" pass.conf | awk '{print $NF}' | sed -e 's/\[//; s/\]//')
                ejecutar_script -p "$pass" "$script" "$user" "${networkIP[$m]}"
                unset pass
            else
                leer_passwd
                add_passwd "$IP" "$SECRET_PASSWD"
                ejecutar_script -p "$SECRET_PASSWD" "$script" "$user" "${networkIP[$m]}"
            fi
        fi
        if [[ -n $comando ]]; then
            if [[ $(grep -c "\<${networkIP[$m]}\>" $passwdFile) -ne 0 ]]; then
                pass=$(grep "\<${networkIP[$m]}\>" pass.conf | awk '{print $NF}' | sed -e 's/\[//; s/\]//')
                ejecutar_comando -p "$pass" "$user" "${networkIP[$m]}" "$comando"
                unset pass
            else
                leer_passwd
                add_passwd "$IP" "$SECRET_PASSWD"
                ejecutar_comando -p "$SECRET_PASSWD" "$user" "${networkIP[$m]}" "$comando"
            fi
        fi
    done
fi
ccrypt -e -k $key $passwdFile