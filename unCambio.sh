#!/bin/bash
source funciones.sh
# 192.168.1.30
# ------ PEDIR IP, PASS --------
echo -n "Introduce una IP de red: "
read DIRECCION_IP_HOST
leer_passwd
# ------ CALCULAR PARAMETROS RED -----
IFS=./ read -r i1 i2 i3 i4 mask <<<$DIRECCION_IP_HOST
if [[ -z $mask ]]; then
    red=$(network $i1.$i2.$i3.$i4 32)         # Calculamos la red
    IFS=. read -r i1 i2 i3 i4 <<<$red            # Nos quedamos con la IP de la red
    broadcast=$(broadcast $i1.$i2.$i3.$i4 32) # Calculamos el broadcast
    IFS=. read -r b1 b2 b3 b4 <<<$broadcast
else
    red=$(network $i1.$i2.$i3.$i4 $mask)         # Calculamos la red
    IFS=. read -r i1 i2 i3 i4 <<<$red            # Nos quedamos con la IP de la red
    broadcast=$(broadcast $i1.$i2.$i3.$i4 $mask) # Calculamos el broadcast
    IFS=. read -r b1 b2 b3 b4 <<<$broadcast
fi
# ----- PEDIR CAMBIOS --------
echo "Cambiar una red "
echo "----------------"
echo -n "Introduzca la nueva red: "
IFS=./ read -r n1 n2 n3 n4 nmask
echo -n "Introduce la máscara antigua: "
read old_mask
echo -n "Introduce la máscara nueva: "
read new_mask
if [[ -z $nmask ]]; then
    red2=$(network $n1.$n2.$n3.$n4 32)
    IFS=./ read -r n1 n2 n3 n4 <<<$red2
    broadcast2=$(broadcast $n1.$n2.$n3.$n4 32)
    IFS=. read -r nb1 nb2 nb3 nb4 <<<$broadcast2
    echo $red2 $broadcast2
else
    red2=$(network $n1.$n2.$n3.$n4 $nmask)
    IFS=./ read -r n1 n2 n3 n4 <<<$red2
    broadcast2=$(broadcast $n1.$n2.$n3.$n4 $nmask)
    IFS=. read -r nb1 nb2 nb3 nb4 <<<$broadcast2
fi
# ------ REALIZAR LOS CAMBIOS -----
for ((i = $i1, ni = $n1; i <= $b1, ni <= $nb1; i++, ni++)); do 
    for ((j = $i2, nj = $n2; j <= $b2, nj <= $nb2; j++, nj++)); do
        for ((k = $i3, nk = $n3; k <= $b3, nk <= $nb3; k++, nk++)); do
            for ((h = $i4, nh = $n4; h <= $b4, nh <= $nb4; h++, nh++)); do
                if [[ -n $mask ]]; then
                    continue
                fi
                cambioUnico "$SECRET_PASSWD" "$i.$j.$k.$h" "$old_mask" "$ni.$nj.$nk.$nh" "$new_mask"
            done
        done
    done
done