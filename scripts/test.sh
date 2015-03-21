#!/bin/bash
appsremote=" remmina x2goclient ssh x2goserver qweborf "

function instalar() {
    paquetes=${!1}
    echo "parametro $1"
    echo "value of [${1}] is: [${!1}]"
    echo "paquetes a instalar: $paquetes"
}

instalar appsremote
