#!/bin/bash

# Constantes
dormir=5
ERROR=1
OK=0

# PATH=$PATH:/home/estefania/Facu/SistemasOperativos/gastos/bin
# export PATH

# Paths
path=$GRUPO #/home/estefania/Facu/SistemasOperativos/gastos
arridir=$ARRIDIR
area_tab=$CONFDIR/area.tab
gastos_conf=$CONFDIR/gastos.conf
reci=$ARRIDIR/reci
noreci=$ARRIDIR/noreci

#Recibe el nombre del archivo
validar_anio()
{
	#obtengo los caracteres correspondientes al año
	local anio=$(echo $1 | cut -c 8-11)

#	echo "el anio a validar es: $anio"

	local anio_maximo=$(sed -n 4p $gastos_conf | cut -f 3 -d\ )

#	echo "el anio_maximo es: $anio_maximo"
	
	# anio >= anio_maximo
	if [ "$anio" -ge "$anio_maximo" ] 
	then
#		echo "anio valido"
		return $OK
	else
#		echo "anio invalido"
		return $ERROR
	fi
}


# Recibe un string a buscar dentro del archivo. 
#Devuelve la cantidad de ocurrencias del mismo.
buscar_en_archivo()
{
#	echo "estoy en buscar_en_archivo. Quiero buscar en: $area_tab"
	local resultado=$(cat $area_tab | grep "$1;" | wc -l)
#	echo "encontro el area?: $resultado"
	return $resultado
}

# Recibe como argumento el nombre de archivo.
validar_area()
{
#	echo "estoy validando area. en \$1 hay: $1"
	#obtengo los primeros 6 caracteres
	local area=$(echo $1 | cut -c 1-6)

#	echo "en area me queda: $area"

	buscar_en_archivo $area
	area_encontrada="$?"

#	echo "sali de buscar archivo, area_encontrada: $area_encontrada"

	return $area_encontrada
}

validar_nombre_archivo()
{
	
	#primero valida que el formato sea codigo de area[6caracteres numericos].fecha[6caracteres numericos]
	local resultado=$(echo $1 | grep -c '^[0-9]\{6\}\.[0-9]\{6\}$')
	
#	echo "resultadoGlobal: $resultado"

	#si el nombre del archivo es del formato correcto
	if [ "$resultado" -eq 1 ] 
		then
#		echo "voy a validar area"
		validar_area $1
		resultado="$?"

#		echo "resultadoArea: $resultado"

		if [ "$resultado" -gt 0 ] 
			then # Si el area es valida
	
#			echo "voy a validar año"
			validar_anio $1 # Valido el anio
			resultado="$?"

#			echo "resultado de validar_anio: $resultado"
			
			if [ "$resultado" = 0 ] 
				then
				return $OK
			else
				return $ERROR
			fi

		else
			return 	$ERROR	

		fi

	else 
		return $ERROR	
	fi
}

archivos_en_reci()
{
	local cant_archivos_en_reci=$(ls -l $reci | wc -l)

#	echo "ARCHIVOS EN RECI****************** $cant_archivos_en_reci"
	# Hay 2 carpetas en ese directorio.
	if [ $cant_archivos_en_reci -gt 3 ]
	then
		return $OK
	fi
	
	return $ERROR
}

if [ "$GINICIEXEC" == "" ]
then
#	echo "No se encuentra el entorno inicializado."
#	echo "Ejecute GINICI e intente nuevamente."

	exit 1
fi


while true
do
#cho "$arridir"
	for archi in `ls $arridir`
	do
		
		if [ ! -d $arridir/$archi ] 
		then

#			echo "archivo es: $archi"
			validar_nombre_archivo $archi
			resultad="$?"
			
#			echo "VALIDACION NOMBRE ARCHIVO: $resultad"
			if [ "$resultad" -eq "$OK" ] 
			then

#				echo "recibi $archi"
				mover.sh "$arridir/$archi" "$reci" "gemonilog"
			else
#				echo "no recibi $archi"
				mover.sh "$arridir/$archi" "$noreci" "gemonilog"
			fi
		fi
	done

	
	# se fija si esta corriendo galida.sh
	galida_corriendo=$( ps aux | grep -c galida )	
	# Se fija si hay archivos en reci
	archivos_en_reci
	
	hay_archivos="$?"

#	echo "galida_corriendo: $galida_corriendo"


	if [ "$galida_corriendo" -lt 2 ] && [ "$hay_archivos" -eq "$OK" ] 
	then
		galida.sh &
#	else
#		echo "esta corriendo galida!"
	fi

	sleep $dormir
done

 exit 0 
