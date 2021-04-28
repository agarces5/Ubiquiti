#!/bin/bash

#---------------------------------------------------------------------------------------------------------------------
#-------------------######  ##  ##  ##  ##   ####   ######   ####   ##  ##  ######   ####  ---------------------------
#-------------------##      ##  ##  ### ##  ##  ##    ##    ##  ##  ### ##  ##      ##     ---------------------------
#-------------------####    ##  ##  ## ###  ##        ##    ##  ##  ## ###  ####     ####  ---------------------------
#-------------------##      ##  ##  ##  ##  ##  ##    ##    ##  ##  ##  ##  ##          ## ---------------------------
#-------------------##       ####   ##  ##   ####   ######   ####   ##  ##  ######   ####  ---------------------------
#---------------------------------------------------------------------------------------------------------------------

#---------------- LEER PASSWD SEGURO ----------------
leer_passwd() {
    # -- Se guarda la configuracion de la sesion
    # stty actual.
    STTY_SAVE=$(stty -g)
    stty -echo

    # -- Se solicita la introduccion del password al
    # usuario:
    echo
    echo -n "Introduzca su password: "
    read SECRET_PASSWD
    # -- Se restablece la sesion stty anterior.
    stty $STTY_SAVE
    echo
}
find() {
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$DIRECCION_IP_HOST" >/dev/null
    sshpass -p ubnt ssh -o "StrictHostKeyChecking no" ubnt@$DIRECCION_IP_HOST sh -c "'
        cat /tmp/system.cfg > /tmp/prueba.cfg
        grep "$buscador" /tmp/prueba.cfg
        exit
        '"
}
mostrar() {
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$DIRECCION_IP_HOST" >/dev/null
    if [[ -z $1 ]]; then
        ssh -o "StrictHostKeyChecking no" ubnt@$DIRECCION_IP_HOST sh -c "'
        cat /tmp/system.cfg > /tmp/prueba.cfg
        cat /tmp/prueba.cfg
        exit
        '"
    else
        sshpass -p $1 ssh -o "StrictHostKeyChecking no" ubnt@$DIRECCION_IP_HOST sh -c "'
        cat /tmp/system.cfg > /tmp/prueba.cfg
        cat /tmp/prueba.cfg
        exit
        '"
    fi
}
crearScript() {
    linea=not_empty
    touch scriptConfig.sh
    cat scriptConfig.sh >scriptConfig.sh
    chmod +x scriptConfig.sh
    echo "cat /tmp/system.cfg > /tmp/prueba.cfg" >>scriptConfig.sh
    mostrar $1
    echo "Modificar o añadir línea: (Dejar vacío para finalizar)"
    until [[ -z $linea ]]; do
        # echo -n "Buscar comando a modificar: "
        # read buscador
        # if [[ -n $buscador ]]; then
        #     find
        read linea
        # else
        #     linea=
        # fi
        if [[ -n $linea ]]; then
            IFS== read -r conf cambio <<<$linea
            echo "(grep -v \"$conf\" /tmp/prueba.cfg && echo \"$linea\") | sort > /tmp/system.cfg" >>scriptConfig.sh
        fi
    done
    echo cfgmtd -f /tmp/system.cfg -w >>scriptConfig.sh
    echo /usr/etc/rc.d/rc.softrestart save >>scriptConfig.sh
}
# modificar_script(){
    OLD_IP=$2
    IFS=. read -r ip1 ip2 ip3 ip4 <<<$OLD_IP
    let ip4++
    NEW_IP="$ip1.$ip2.$ip3.$ip4"
    sed -i 's/$OLD_IP/$NEW_IP/g' scriptConfig.sh 
}
realizar_cambios() {
    # modificar_script
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$2"
    if [[ -n $1 ]]; then
        sshpass -p $1 ssh -o "StrictHostKeyChecking no" ubnt@$2 'sh -s' <scriptConfig.sh
    else
        ssh -o "StrictHostKeyChecking no" ubnt@$2 'sh -s' <scriptConfig.sh
    fi
}
cambioUnico() {
    SECRET_PASSWD=$1; OLD_IP=$2; OLD_MASK=$3; NEW_IP=$4; NEW_MASK=$5;
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$2"
    if [[ -n $1 ]]; then
        sshpass -p $1 ssh -o "StrictHostKeyChecking no" ubnt@$2 sh -c "'
        buscar=$2; nuevo=$4
        par=$(grep \<$2\> /tmp/system.cfg | awk -F'.' {' print $1'.'$2 '})
        sed -i 's/$par.ip=$2/$par.ip=$4/g' /tmp/system.cfg
        sed -i 's/$par.netmask=$3/$par.netmask=$5/g' /tmp/system.cfg
        cfgmtd -f /tmp/system.cfg -w
        /usr/etc/rc.d/rc.softrestart save
        '"
    else
        ssh -o "StrictHostKeyChecking no" ubnt@$2 sh -c "'
        buscar=$2; nuevo=$4
        par=$(grep "\<$2\>" /tmp/system.cfg | awk -F'.' {' print $1"."$2 '})
        sed -i s/$par.ip=$2/$par.ip=$4/g /tmp/system.cfg
        sed -i s/$par.netmask=$3/$par.netmask=$5/g /tmp/system.cfg
        cfgmtd -f /tmp/system.cfg -w
        /usr/etc/rc.d/rc.softrestart save
        '"
    fi
}
#---------------- FUNCIONES PARA CALCULAR PARAMETROS DE LA RED ----------------
ipToint() { # PASAR UNA IP A ENTERO
    local a b c d
    { IFS=. read a b c d; } <<<$1
    echo $(((((((a << 8) | b) << 8) | c) << 8) | d)) #(((192*2^8+168)2^8)+0*2^8)+0=192*2^24+168*2^16+0*2^8+0
}
intToip() { # PASAR DE ENTERO A IP
    local ui32=$1
    shift
    local ip n
    for n in 1 2 3 4; do
        ip=$((ui32 & 0xff))${ip:+.}$ip
        ui32=$((ui32 >> 8))
    done
    echo $ip
}
netmask() { # CALCULAR MASCARA
    # Example: netmask 27 => 255.255.255.224
    local mask=$((0xffffffff << (32 - $1)))
    shift
    intToip $mask
}
broadcast() { # CALCULAR BROADCAST
    # Example: broadcast 192.168.0.0 27 => 192.168.0.31
    local addr=$(ipToint $1)
    shift
    local mask=$((0xffffffff << (32 - $1)))
    shift
    intToip $((addr | ~mask))
}
network() { # CALCULAR RED
    # Example: network 192.68.11.155 21 => 192.68.8.0
    local addr=$(ipToint $1)
    shift
    local mask=$((0xffffffff << (32 - $1)))
    shift
    intToip $((addr & mask))
}
help_add_passwd() {
    echo "' 
    MENU DE AYUDA
    MODO DE USO:
        add_passwd [IP] ----> pide por pantalla la contraseña
        add_passwd [IP][password] ----> añade directamente la contraseña
    
    '"
}
add_passwd() {
    # Sin pedir IP  --> Se ejecuta add_passwd $IP $SECRET_PASSWD
    #----------- GUARDAR VARIABLES ----------------
    local passwdFile=pass.conf
    local key=key
    local SECRET_PASSWD=$2
    IFS=./ read -r i1 i2 i3 i4 mask <<<$1
    if [[ -z $SECRET_PASSWD ]]; then
        leer_passwd
    fi
    #----------------------------------------------
    if [[ -z $mask ]]; then # Solo introducimos IP
        if [[ $(grep -c "\<$1\>" $passwdFile) -ne 0 ]]; then
            (grep -v "\<$1\>" $passwdFile && echo "IP = [$1] ; PASS = [$SECRET_PASSWD]") | sort >tmp.txt && cat tmp.txt >$passwdFile && rm tmp.txt
        else
            echo "IP = [$1] ; PASS = [$SECRET_PASSWD]" >>$passwdFile
            cat $passwdFile | sort >tmp.txt && cat tmp.txt >$passwdFile && rm tmp.txt
        fi
    else                                                   # Introducimos IP y máscara
        local red=$(network $i1.$i2.$i3.$i4 $mask)         # Calculamos la red
        IFS=. read -r i1 i2 i3 i4 <<<$red                  # Nos quedamos con la IP de la red
        local broadcast=$(broadcast $i1.$i2.$i3.$i4 $mask) # Calculamos el broadcast
        IFS=. read -r b1 b2 b3 b4 <<<$broadcast            # Guardamos la IP del broadcast
        local netmask=$(netmask $mask)                     # Convertimos la máscara en formato A.B.C.D
        local networkIP=()                                 # Creamos un array para guardar las IP de la red
        m=0
        for ((i = $i1; i <= $b1; i++)); do # Guardamos todas las IP de la red en el array
            for ((j = $i2; j <= $b2; j++)); do
                for ((k = $i3; k <= $b3; k++)); do
                    for ((h = $i4; h <= $b4; h++)); do
                        networkIP[$m]=$i.$j.$k.$h # Guardo las IP de la red
                        if [[ $m -ne 0 ]]; then
                            if [[ $(grep -c "\<${networkIP[$m]}\>" $passwdFile) -ne 0 ]]; then # Si ya está en el passwdFile
                                (grep -v "\<${networkIP[$m]}\>" $passwdFile && echo "IP = [${networkIP[$m]}] ; PASS = [$SECRET_PASSWD]") | sort >tmp.txt && cat tmp.txt >$passwdFile && rm tmp.txt
                            else
                                echo "IP = [${networkIP[$m]}] ; PASS = [$SECRET_PASSWD]" >>$passwdFile
                                cat $passwdFile | sort >tmp.txt && cat tmp.txt >$passwdFile && rm tmp.txt
                            fi
                        fi
                        let m++
                    done
                done
            done
        done
    fi
}
