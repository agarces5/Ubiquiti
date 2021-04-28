#!/bin/bash

HELP_MENU(){
    echo 'OPCIÓN 1: 
    Se introduce la IP de la red a la que conectarse, la nueva IP 
    y las máscaras si se quieren cambiar 
    (en formato extendido ej. 255.255.255.0) 
    '
    echo 'OPCION 2:
    Se conecta al primer equipo que se va a cambiar y se muestra la configuración (como ayuda)
    Se van introduciendo las lineas que se quieren modificar, si son nuevas se añaden y si se quiere realizar algun cambio, 
    como el cambio se realiza a la derecha del = se introduce la nueva linea y se "machaca"
    '
}

echo "---- MENU DE USO: ----"
echo "1) CAMBIAR IP Y MASCARAS"
echo "2) REALIZAR EL MISMO CAMBIO EN TODOS"
read -p "Opcion: " opt

case "$opt" in
1)
    bash unCambio.sh
    ;;
2)
    echo -n "Introduzca la IP/mask del primer equipo de la red: "
    read HOST_IP
    bash script2.sh -i $HOST_IP
    ;;
*)
    HELP_MENU
    ;;
esac
