#!/bin/bash
# ******************************************************************************************************
# Trabajo Práctico de Sistemas Operativos (75.08)
# Primer Cuatrimestre 2008 - Curso Martes
#
# Comando: ginici.sh
#
# Descripción: este comando se encarga de preparar el entorno de ejecución del TP.
#
# Ubicación: directorio $BINDIR
#
# Variables de Entorno que utiliza: GRUPO
#
# ******************************************************************************************************

# En el archivo "ginici.conf" se encuentra almacenado el path y el nombre del archivo de configuración
# del sistema GASTOS
ARCHIVO_CONF="ginici.conf"

FIN_OK=0
ERROR_GEMONI=1

# La siguiente función ejecuta GEMONI (si éste no se encuentra corriendo).
# Si el comando ya esta corriendo, muestra por pantalla un mensaje que indica cuanto hace que se esta corriendo.
# Si el comando no esta corriendo, lo ejecuta y muestra el ID del proceso.
iniciarGemoni()
{
	comando_a_verificar="gemoni"
	comando=$(ps | grep "$comando_a_verificar")
	if [ -z "$comando" ]
	then
		gemoni.sh
		if [ "$?" -eq 0 ]
		then
			comando=$(ps | grep $comando_a_verificar)
			id=$(echo $comando | cut -d ' ' -f1)
			echo "****************************************************************
* Demonio corriendo bajo el número: $id	       *
****************************************************************"
			return $FIN_OK
		else
			return $ERROR_GEMONI
		fi
	else
		tiempo_corriendo=$(ps -e | grep $comando_a_verificar | cut -c15-23)
		echo "El comando GEMONI se encuentra corriendo hace $tiempo_corriendo"
		return $FIN_OK
	fi
}

echo "Iniciando configuración del entorno..."

read ARCHIVO_CONF_GRAL < $ARCHIVO_CONF

i=0
while read linea
do
	vectorParametros[$i]=${linea#* = }
	i=`expr $i + 1`
done < $ARCHIVO_CONF_GRAL

# Se settean las variables de ambiente
export GRUPO=${vectorParametros[1]}
export CONFDIR=${vectorParametros[2]}
export ANIO=${vectorParametros[3]}
export PATH="$PATH:${vectorParametros[1]:${vectorParametros[4]}"
export ARRIDIR=${vectorParametros[5]}
export GASTODIR=${vectorParametros[6]}
export LOGDIR=${vectorParametros[8]}
export LOGEXT=${vectorParametros[9]}
export LOGSIZE=${vectorParametros[10]}

# Se settea una variable de control para saber si GINICI fue ejecutado
export GINICIEXEC=1
export GPROCNUM=0

# Se invoca a GEMONI (si es que no se encuentra corriendo)
iniciarGemoni
retorno="$?"

echo "Configuración del entorno completada."

exit $retorno

