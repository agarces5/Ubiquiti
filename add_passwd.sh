#!/bin/bash
source funciones.sh
# Sin pedir IP  --> Se ejecuta add_passwd $IP
#----------- GUARDAR VARIABLES ----------------
passwdFile=pass.conf
key=key
SECRET_PASSWD=$2
IFS=./ read -r i1 i2 i3 i4 mask <<<$1
if [[ -z $SECRET_PASSWD ]]; then
    leer_passwd
fi
#----------------------------------------------
ccrypt -d -k $key $passwdFile
if [[ -z $mask ]]; then # Solo introducimos IP
    if [[ $(grep -c "\<$1\>" $passwdFile) -ne 0 ]]; then
        (grep -v "\<$1\>" $passwdFile && echo "IP = [$1] ; PASS = [$SECRET_PASSWD]") | sort >tmp.txt && cat tmp.txt >$passwdFile && rm tmp.txt
    else
        echo "IP = [$1] ; PASS = [$SECRET_PASSWD]" >>$passwdFile
        cat $passwdFile | sort >tmp.txt && cat tmp.txt >$passwdFile && rm tmp.txt
    fi
else                                             # Introducimos IP y máscara
    red=$(network $i1.$i2.$i3.$i4 $mask)         # Calculamos la red
    IFS=. read -r i1 i2 i3 i4 <<<$red            # Nos quedamos con la IP de la red
    broadcast=$(broadcast $i1.$i2.$i3.$i4 $mask) # Calculamos el broadcast
    IFS=. read -r b1 b2 b3 b4 <<<$broadcast      # Guardamos la IP del broadcast
    netmask=$(netmask $mask)                     # Convertimos la máscara en formato A.B.C.D
    networkIP=()                                 # Creamos un array para guardar las IP de la red
    m=0
    for ((i = $i1; i <= $b1; i++)); do # Guardamos todas las IP de la red en el array
        for ((j = $i2; j <= $b2; j++)); do
            for ((k = $i3; k <= $b3; k++)); do
                for ((h = $i4; h <= $b4; h++)); do
                    networkIP[$m]=$i.$j.$k.$h # Guardo las IP de la red
                    if [[ $m -ne 0 ]]; then
                        if [[ $(grep -c "\<${networkIP[$m]}\>" $passwdFile) -ne 0 ]]; then         # Si ya está en el passwdFile
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
ccrypt -e -k $key $passwdFile