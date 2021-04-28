#!/bin/bash
# Se muestra la configuracion de una de las antenas
# Se pide que se introduzcan las lineas nuevas/cambios que se desean
# Se ejecuta LA MISMA CONFIGURACION en todas las antenas
# Sirve si se quieren modificar el mismo parámetro en todas
# CUIDADO SI SE QUIERE PONER LA IP QUE PONE EN TODAS LA MISMA Y SI SE QUIERE MODIFICAR LA MASCARA LO HACE EN LA MISMA INTERFAZ (UTILIZAR EL OTRO SCRIPT)

source funciones.sh
while getopts i: flag; do
    case "${flag}" in
    i) DIRECCION_IP_HOST=${OPTARG} ;;
    esac
done
IFS=./ read -r i1 i2 i3 i4 mask <<<$DIRECCION_IP_HOST # Leer y separar la IP y la mascara que introducimos
leer_passwd
crearScript "$SECRET_PASSWD"
if [[ -z $mask ]]; then
    realizar_cambios "$SECRET_PASSWD" "$DIRECCION_IP_HOST"
else
    red=$(network $i1.$i2.$i3.$i4 $mask)         # Calculamos la red
    IFS=. read -r i1 i2 i3 i4 <<<$red            # Nos quedamos con la IP de la red
    broadcast=$(broadcast $i1.$i2.$i3.$i4 $mask) # Calculamos el broadcast
    IFS=. read -r b1 b2 b3 b4 <<<$broadcast      # Guardamos la IP del broadcast
    netmask=$(netmask $mask)
    M=0                                # Convertimos la máscara en formato A.B.C.D
    for ((i = $i1; i <= $b1; i++)); do # Guardamos todas las IP de la red en el array
        for ((j = $i2; j <= $b2; j++)); do
            for ((k = $i3; k <= $b3; k++)); do
                for ((h = $i4; h <= $b4; h++)); do
                    if [[ $M -eq 0 ]]; then
                        continue
                    fi
                    DIRECCION_IP_HOST=$i.$j.$k.$h # Guardo las IP de la red
                    realizar_cambios "$SECRET_PASSWD" "$DIRECCION_IP_HOST"
                    let M++
                done
            done
        done
    done
fi
