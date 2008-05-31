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

	local resultado=$(cat $area_tab | grep "$1;" | wc -l)

	return $resultado
}

# Recibe como argumento el nombre de archivo.
validar_area()
{
	#obtengo los primeros 6 caracteres
	local area=$(echo $1 | cut -c 1-6)

	buscar_en_archivo $area
	area_encontrada="$?"

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
	local cant_archivos_en_reci=$(ls -l $reci | grep -c '^-')

	if [ $cant_archivos_en_reci -gt 0 ]
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
	#galida_corriendo = 0 : galida.sh no se encuentra en ejecucion
	#galida_corriendo = 1 : galida.sh estan en ejecucion
	galida_corriendo=$(ps | grep -c "galida.sh")
	
	# verifica que haya archivos en reci
	archivos_en_reci	
	hay_archivos=$?

	if [ $galida_corriendo -eq 0 ] && [ $hay_archivos -eq $OK ] 
	then
		galida.sh &
	fi

	sleep $dormir
done

IFS="$IFSOriginal"

exit 0 
