#!/bin/bash

#---------------------------------------------------------------------------------------------------------------------
#-------------------######  ##  ##  ##  ##   ####   ######   ####   ##  ##  ######   ####  ---------------------------
#-------------------##      ##  ##  ### ##  ##  ##    ##    ##  ##  ### ##  ##      ##     ---------------------------
#-------------------####    ##  ##  ## ###  ##        ##    ##  ##  ## ###  ####     ####  ---------------------------
#-------------------##      ##  ##  ##  ##  ##  ##    ##    ##  ##  ##  ##  ##          ## ---------------------------
#-------------------##       ####   ##  ##   ####   ######   ####   ##  ##  ######   ####  ---------------------------
#---------------------------------------------------------------------------------------------------------------------

#---------------- MENU DE AYUDA ----------------
help_menu() {
    echo "---------------------- Menu de ayuda ----------------------"
    echo "-u [usuario]              ---> Para determinar el usuario (admin por defecto)"
    echo "-i [IP]                   ---> Para poner la IP (ej. 192.168.1.10) o una red (ej. 192.168.1.10/24"
    echo "-s [ruta_script]          ---> Para poner el script"
    echo "-c [comando]              ---> Comando para ejecutar en el router (el comando entre '' o \"\") "
    echo "-p [ruta_file_passwd]     ---> Leer password desde fichero "
    echo "y (al final de la linea)  ---> Para que no pida confirmacion para reiniciar el router de fabrica antes de cargar un script"
    exit 1
}
#---------------- MOSTRAR ARGUMENTOS ----------------
mostrar_args() {
    echo "-----------------------------------------------------------"
    echo "El usuario es: $user"
    echo "La IP es: $IP"
    echo "El script es: $script"
    echo "El comando es: $comando"
    echo "El pass esta en: $passwdFile"
}
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
#---------------- EJECUTAR SCRIPT ----------------
ejecutar_script() {
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$5"
    if [[ $resp == "yes" || $resp == "Yes" || $resp == "y" ]]; then # Ejecutar restableciendo de fábrica
        echo "Restableciendo de fabrica y Ejecutando script"
        if [[ -n $2 ]]; then # Si hay pass en el fichero
            sshpass $1 $2 scp -o "StrictHostKeyChecking no" $3 $4@$5:configuracion.rsc
            sleep 5s
            sshpass $1 $2 ssh -o "StrictHostKeyChecking no" $4@$5 "system reset-configuration no-defaults=yes run-after-reset=configuracion.rsc"
        else # Si no hay pass o está vacía
            scp -o "StrictHostKeyChecking no" $3 $4@$5:configuracion.rsc
            sleep 5s
            ssh -o "StrictHostKeyChecking no" $4@$5 "system reset-configuration no-defaults=yes run-after-reset=configuracion.rsc"
        fi
    else # Machacar encima de lo anterior
        echo "Ejecutando script"
        if [[ -n $2 ]]; then # Si hay pass en el fichero
            sshpass $1 $2 scp -o "StrictHostKeyChecking no" $3 $4@$5:configuracion.rsc
            sleep 5s
            sshpass $1 $2 ssh -o "StrictHostKeyChecking no" $4@$5 "import configuracion.rsc"
        else # Si no hay pass o está vacía
            scp -o "StrictHostKeyChecking no" $3 $4@$5:configuracion.rsc
            sleep 5s
            ssh -o "StrictHostKeyChecking no" $4@$5 "import configuracion.rsc"
        fi
    fi
}
#---------------- EJECUTAR COMANDO ----------------
ejecutar_comando() {
    ssh-keygen -f "/home/$USER/.ssh/known_hosts" -R "$4"
    if [[ -n $2 ]]; then # Si hay pass en el fichero
        sshpass $1 $2 ssh -o "StrictHostKeyChecking no" $3@$4 $5
    else # Si no hay pass o está vacía
        ssh -o "StrictHostKeyChecking no" $3@$4 $5
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
add_passwd() {
    # Sin pedir IP  --> Se ejecuta add_passwd $IP
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
