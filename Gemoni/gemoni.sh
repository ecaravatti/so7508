#!/bin/bash

# Constantes
dormir=5
ERROR=1
OK=0

# Paths
path=$GRUPO 
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
	local mes=$(echo $1 | cut -c 12-13)

	local anio_maximo=$(sed -n 4p $gastos_conf | cut -f 3 -d\ )
	
	if [ "$anio" -ge "$anio_maximo" ]
	then

		return $OK
	else

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

# Valida que el formato del archivo cumpla con las restricciones especificadas
validar_nombre_archivo()
{
	
	#primero valida que el formato sea codigo de area[6caracteres numericos].fecha[6caracteres numericos]
	local resultado=$(echo $1 | grep -c '^[0-9]\{6\}\.[0-9]\{6\}$')
	
	#si el nombre del archivo es del formato correcto
	if [ "$resultado" -eq 1 ] 
		then
# 		Valida que el area se encuentre en area.tab
		validar_area $1
		resultado="$?"

		if [ "$resultado" -gt 0 ] 
		then # Si el area es valida
			validar_anio $1 # Valido el anio
			resultado="$?"

			if [ "$resultado" -eq 0 ] 
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

# Verifica que haya archivos en el directorio reci
archivos_en_reci()
{
	local cant_archivos_en_reci=$(ls -l $reci | wc -l)

	# Si el directorio no contiene archivos, debe devolver 3, la linea donde indica el total y los directorios reci/ok y reci/rech.
	# Si devuelve un numero mas grande, quiere decir que hay archivos en el directorio.
	if [ $cant_archivos_en_reci -gt 3 ]
	then
		return $OK
	fi
	
	return $ERROR
}

if [ "$GINICIEXEC" == "" ]
then
	echo "No se encuentra el entorno inicializado."
	echo "Ejecute GINICI e intente nuevamente."

	exit 1
fi

IFSOriginal=$IFS
IFS=$'\n'
while true
do
	for archi in `ls $arridir`
	do
		
		if [ ! -d "$arridir/$archi" ] 
		then
			validar_nombre_archivo $archi
			resultad="$?"
			
			if [ "$resultad" -eq "$OK" ] 
			then

				mover.sh "$arridir/$archi" "$reci" "gemonilog"
			else
				mover.sh "$arridir/$archi" "$noreci" "gemonilog"
			fi
		fi
	done

	
	# verifica que esta corriendo galida.sh
	galida_corriendo=$( ps aux | grep -c galida )	
	# verifica que haya archivos en reci
	archivos_en_reci
	
	hay_archivos="$?"

	if [ "$galida_corriendo" -lt 2 ] && [ "$hay_archivos" -eq "$OK" ] 
	then
		galida.sh &
	fi

	sleep $dormir
done

IFS=$IFSOriginal

exit 0 
