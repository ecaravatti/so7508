#!/bin/bash

#$1 = Nombre de archivo de log (sin extensión)
#$2 = Mensaje a loggear
#$3 = Comando que me invoca. Si tiene el .sh no importa, ya que se lo saco.

if [ "$LOGDIR" == "" ]
then
	LOGDIR="./"
fi

ARCHIVO_LOG="$LOGDIR"/"$1""$LOGEXT"

if [ -d "$ARCHIVO_LOG" ] #Veo si es un directorio
then
	echo "El archivo donde desea escribir es un directorio"
	exit 1
elif [ ! -e `dirname "$ARCHIVO_LOG"` ]
then
	echo "Path del archivo donde desea escribir invalido"
	exit 2
else
	comando=`echo "$3" | sed 's/\.sh$//'` #Le saco el .sh si es que lo tiene
	mensaje="`date +%D\ %T` - `basename "$comando"` - `whoami` - "$2""
	echo -e $mensaje >> $ARCHIVO_LOG

	if [ "$LOGSIZE" != "" ]
	then
		if [ `expr $(stat -c%s "$ARCHIVO_LOG") / 1024` -ge $LOGSIZE ]
		then
			IFSOriginal=$IFS
			IFS=$'\t\n ' #IFS default, lo setteo por las dudas que quien me invoca lo tenga cambiado
			cant_lineas=(`wc -l "$ARCHIVO_LOG"`)
			IFS=$IFSOriginal
			if [ $cant_lineas -gt 70 ]
			then
				ultima_linea=$(expr $cant_lineas - 70)
				sed "1,$ultima_linea d" <"$ARCHIVO_LOG" >"$ARCHIVO_LOG".temp
				mv "$ARCHIVO_LOG".temp "$ARCHIVO_LOG"
			fi
		fi
	fi

	exit 0
fi