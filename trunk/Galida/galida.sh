#!/bin/bash
#
#
# Galida.sh
# No recibe argumentos.
#
# Descripcion:
# Este comando es el tercero en orden de ejecución.
# Se dispara automáticamente. 
# Graba un archivo de Log.(galidalog.<ext>)
# El propósito de este comando es:
# Validar los archivos recibidos, ordenar los archivos y dejarlos disponibles
# en el directorio GASTODIR/aproc para que el comando GONTRO los pueda utilizar.
# Invocar (si corresponde) al comando GONTRO.
########################################################################################
#
# Declaración de constantes:
ERROR=1
OK=0
#
########################################################################################
# 
# Declaracion de paths:
path=$GRUPO
reci=$ARRIDIR/reci 			# Directorio de archivos a procesar
reci_ok=$GASTODIR/reci/ok 		# Directorio de archivos procesados correctamente
reci_rech=$GASTODIR/reci/rech 		# Directorio de archivos rechazados por no cumplir con las
						# validaciones correspondientes.
a_procesar=$GASTODIR/aproc 		# Directorio de archivos procesados y ordenados.
log=$LOGIDIR				# Directorio de logs.
gastos_conf=$CONFDIR/gastos.conf	# Archivo de configuracion.
conceptos_x_area=$CONFDIR/cxa.tab	# Tabla de conceptos por area.



# Esta función recibe un archivo a ordenar como argumento.
# Lo ordena según la clave: día-concepto-comprobante y le agrega la extensio ".ord"
# Argumentos:
# 	$1: Archivo a ordenar.
ordenar_archivo()
{
	# ordena por el campo 1, luego por el 3 y luego por el 2. Usa como delimitador al caracter ";"
	sort -o "$reci_ok/$arch.ord" -t';' +0 -1 +2 -3 +1 -n "$reci_ok/$arch" # -o "nombre_archivo" indica el output.
	
	rm $reci_ok/$arch # elimina el archivo original.

	mover.sh "$reci_ok/$arch.ord" "$a_procesar" "galidalog"
	glog.sh "galidalog" "Archivo ordenado $arch.ord." "GALIDA"

	return $OK
}

# Esta funcion valida si el año es bisiesto o no.
# En caso positivo devuelve $OK; de lo contrario, $ERROR
# Argumentos:
#	$1: año
validar_bisiesto()
{
	local resto=$(expr $1 % 4) 	# si el resto de la division del año por 4 es nulo,
					# el año es bisiesto.

	if [ $resto -eq 0 ]
	then
		return $OK
	else
		return $ERROR
	fi
}

# Valida si el concepto que recibe como argumento, se encuentra en la tabla de de
# conceptos por area.
# Argumentos:
# 	$1: id de concepto
validar_concepto()
{
	# Busca si el concepto esta declarado en el 2do campo de alguno de los registros de la tabla.
	# grep -c devuelve la cantidad de coincidencias.
	local concepto_encontrado=$(cut -d';' -f 2 $conceptos_x_area | grep -c "^$1$") 	

	# Si $concepto_encontrado es cero no hubo match con el grep"
	if [ $concepto_encontrado -eq 0 ]
	then 
		return $ERROR	
	else
		return $OK
	fi	
}

# Valida una fecha, teniendo en cuenta años bisiestos.
# Argumentos:
# 	$1: dia
# 	$2: mes
# 	$3: anio
validar_fecha()
{
# Si el mes es 1,3,5,7,8,10 o 12, el dia debe ser menor o igual a 31.
if [ $2 -eq 01 ] || [ $2 -eq 03 ] || [ $2 -eq 05 ] || [ $2 -eq 07 ] || [ $2 -eq 08 ] || [ $2 -eq 10 ]  || [ $2 -eq 12 ]
then
	if [ $1 -gt 31 ]
	then
		return $ERROR
	fi

# Si el mes es 4,6,9 o 11, el dia debe ser menor o igual a 30.
elif [ $2 -eq  04 ] || [ $2 -eq 06 ] || [ $2 -eq 09 ] || [ $2 -eq 11 ]
then
		if [ $1 -gt 30 ]
		then
			return $ERROR
		fi

elif [ $2 -eq 02 ]
then
	validar_bisiesto $3
	local es_bisiesto=$?

	# Si el mes es 2 y el año es bisiesto, el dia debe ser menor o igual a 29.
	if [ $es_bisiesto -eq $OK ] || [ $1 -gt 29 ]
	then
		return $ERROR
	fi

	# si el mes es 2 y el año no es bisiesto y dia debe ser menor o igual a 28.
	if [ $es_bisiesto -eq $ERROR ] || [ $1 -gt 28 ]
	then
		return $ERROR
	fi

else
	# El mes no es valido.
	return $ERROR
fi
	# Fecha valida.
	return $OK
}

# Esta función recibe un importe y valida, en primer instancia que tenga un formato numerico positivo.
# Luego corrobora que no sea nulo.
# Argumentos:
# 	$1: importe
validar_importe()
{
	# Valida el formato numerico positivo.
	local importe_valido=$(echo $1 | grep -c '^[0-9]*\.[0-9][0-9]$')
	
	if [ $importe_valido -eq 1 ]
	then
		# se fija si es nulo.
		importe_valido=$(echo $1 | grep -c '^0*\.00$')
		
		if [ $importe_valido -eq 1 ]
		then
			# importe nulo.
			return $ERROR
		fi
#		# importe no nulo.
		return $OK
	else
		# no cumple con el formato.
		return $ERROR
	fi
}

validar_numerico()
{
es_numerico=$(echo "$1" | grep -c "^[0-9]*$")
 if [ $es_numerico -eq 1 ]
then
	return $OK
else
	return $ERROR
fi
}

# Esta funcion recibe el nombre del archivo a validar.
# Valida todos los registros, y devuelve el numero de registros erroneos.
# Argumentos:
#	$1: nombre del archivo a validar.
validar_registros_archivo() 
{
	local numero_registro=0
	local cantidad_registros_erroneos=0

	for linea in `cat $reci/$1`
	do
		numero_registro=`expr $numero_registro + 1`
		
		# Obtiene la cantidad de campos del registro.
		cantidad_campos=$(echo $linea | awk -F';' '{print NF}')

		# Un archivo valido debe contener 4 campos.
		if [ "$cantidad_campos" -eq 4 ]
		then
			# Obtiene los distintos campos.
			dia=$(echo $linea | awk -F';' '{print $1}')
			comprobante=$(echo $linea | awk -F';' '{print $2}')
			id_concepto=$(echo $linea | awk -F';' '{print $3}')
			importe=$(echo $linea | awk -F';' '{print $4}')


			validar_numerico $id_concepto
			es_numerico="$?"
			
			if [ $es_numerico -eq $ERROR ]
			then
				glog.sh "galidalog" "El registro $numero_registro es rechazado debido a  concepto invalido." "GALIDA"
				cantidad_registros_erroneos=`expr $cantidad_registros_erroneos + 1`
				continue
			fi

			# Obtiene año y mes del nombre del archivo.
			anio=$(echo $1 | cut -c 8-11)
			mes=$(echo $1 | cut -c 12-13)

			validar_fecha $dia $mes $anio
			local dia_valido=$?

			if [ $dia_valido -eq $ERROR ]
			then
				# Fecha invalida.
				glog.sh "galidalog" "El registro $numero_registro es rechazado debido a fecha invalida." "GALIDA"
				cantidad_registros_erroneos=`expr $cantidad_registros_erroneos + 1`
				continue
			fi

			validar_importe $importe
			local importe_valido=$?

			if [ $importe_valido -eq $ERROR ]
			then 
				# Importe invalido.
				glog.sh "galidalog" "El registro $numero_registro es rechazado debido a importe invalido." "GALIDA"
				cantidad_registros_erroneos=`expr $cantidad_registros_erroneos + 1`
				continue
			fi
			
			validar_concepto $id_concepto
			local concepto_valido=$?

			if [ $concepto_valido -eq $ERROR ]
			then
				# Concepto invalido.
				glog.sh "galidalog" "El registro $numero_registro es rechazado debido a concepto invalido." "GALIDA"
				cantidad_registros_erroneos=`expr $cantidad_registros_erroneos + 1`
				continue
			fi

		else
			# Cantidad de campos invalida.
			glog.sh "galidalog" "El registro $numero_registro es rechazado debido a cantidad de campos invalida." "GALIDA"
			cantidad_registros_erroneos=`expr $cantidad_registros_erroneos + 1`
			continue
		fi
	done
	
	# Devuelve la cantidad de registros erroneos.
	return $cantidad_registros_erroneos
}

# Esta funcion se fija si el archivo ordenado existe (ya fue procesado).
# En caso positivo,devuelve ERROR, de lo contrario devuelve OK.
# Argumentos:
#	$1: nombre del archivo sin ordenar (sin la extension ".ord")
verificar_archivo_ordenado()
{
	local existe=$(ls -l $a_procesar | grep -c "$1.ord")

	if [ $existe -eq 1 ]
	then
		return $ERROR
	else
		return $OK
	fi
}

# Esta funcion valida que el nombre de un archivo este conformado de la siguiente manera:
# <codigo area>.<periodo>
# Ambos campos deben tener 6 caracteres numericos.
# Argumentos:
#	$1: nombre del archivo a validar.
validar_nombre_archivo()
{	
	#primero valida que el formato sea codigo de area[6caracteres numericos].fecha[6caracteres numericos]
	local resultado=$(echo $1 | grep -c '^[0-9]\{6\}\.[0-9]\{6\}$')

	if [ $resultado -eq 1 ]
	then
		return $OK
	else
		return $ERROR
	fi
}

# Esta funcion crea, si no existe, al directorio que se le pasa como argumento.
# Argumentos
#	$1: Directorio a crear (path absoluto)
crear_directorio()
{
if [ ! -e "$1" ] # Verifica la inexistencia de un archivo de nombre $1
	then
		glog.sh "galidalog" "Creando directorio $1." "GALIDA"
		mkdir "$1"
	elif [ ! -d "$1" ] # Se fija que el archivo existente no sea un directorio.
	then
		# Si no se puede crear el directorio, se aborta galida.
		glog.sh "galidalog" "No se pudo crear directorio $1 ya que existe un archivo con ese nombre" "GALIDA"
		exit 2
	fi
}

# Esta funcion crea, si no existen, los directorios necesarios para mover los archivos procesados.
# No recibe ningun argumento.
crear_directorios_necesarios()
{
	crear_directorio "$GASTODIR/reci"
	crear_directorio "$GASTODIR/reci/ok"
	crear_directorio "$GASTODIR/reci/rech"
}

# Verifica que el entorno haya sido inicializado.
# Si no es asi, aborta galida, y pide que se corra GINICI
# antes de intentar nuevamente.
# No recibe ningun argumento.
verificar_entorno()
{
if [ "$GINICIEXEC" == "" ]
then
	echo "No se encuentra el entorno inicializado."
	echo "Ejecute GINICI e intente nuevamente."

	exit 1
fi
}


# ********************************
# MAIN
# ********************************
verificar_entorno
crear_directorios_necesarios

glog.sh "galidalog" "Inicio de Ejecución." "GALIDA"

cantidad_archivos_procesados=0
cantidad_archivos_duplicados=0
cantidad_archivos_rechazados=0
cantidad_archivos_aceptados=0

# Obtiene los archivos que se colocaron en la carpeta de arribos para ser procesados.
for arch in `ls $reci`
do
	# Comprueba que no se trate de directorios.
	if [ ! -d $reci/$arch ]
	then
		validar_nombre_archivo $arch
		archivo_valido=$?
		
		if [ $archivo_valido -eq $OK ]
		then	
			# Si el nombre del archivo es correcto:
			cantidad_archivos_procesados=`expr $cantidad_archivos_procesados + 1`

			glog.sh "galidalog" "Validando archivo $arch" "GALIDA"
	
			# Comprueba que no exista un archivo ya ordenado con el mismo nombre.
			verificar_archivo_ordenado $arch
			resultado=$?

			if [ $resultado -eq $ERROR ]
			then
		
				# El archivo esta duplicado, lo mueve a rechazados"
				cantidad_archivos_duplicados=`expr $cantidad_archivos_duplicados + 1`

				mover.sh "$reci/$arch" "$reci_rech" "galidalog" "Archivo duplicado, ya existe un archivo del mismo nombre para procesar."
			else
				# El arch no es duplicado, valida los registros."
				validar_registros_archivo $arch
				resultado=$?

				if [ ! $resultado -eq $OK ]
				then
					# Si algun registro no es valido.
					mover.sh "$reci/$arch" "$reci_rech" "galidalog" "Archivo rechazado, algún registro no corresponde al formato adecuado"
					glog.sh "galidalog" "Cantidad de Registros con Error: $resultado." "GALIDA"

					cantidad_archivos_rechazados=`expr $cantidad_archivos_rechazados + 1`

				else
					# Si todos los registros son validos.
					mover.sh "$reci/$arch" "$reci_ok" "galidalog" "Archivo aceptado"

					# Ordena los registros del archivo.
					ordenar_archivo $arch
					cantidad_archivos_aceptados=`expr $cantidad_archivos_aceptados + 1`
				fi
			fi
		else
			# Nombre de archivo invalido.
			glog.sh "galidalog" "Archivo rechazado, nombre invalido: $arch." "GALIDA"
			mover.sh "$reci/$arch" "$reci_rech" "galidalog"
		fi
	fi
done

# Se fija si esta corriendo gontro.pl
gontro_corriendo=$( ps aux | grep -c gontro )	

if [ $gontro_corriendo -lt 2 ] 
then
	# Se invoca a gontro.
	perl -w gontro.pl &
fi

glog.sh "galidalog" "Cantidad de archivos procesados: $cantidad_archivos_procesados" "GALIDA"
glog.sh "galidalog" "Cantidad de archivos duplicados: $cantidad_archivos_duplicados" "GALIDA"
glog.sh "galidalog" "Cantidad de archivos rechazados: $cantidad_archivos_rechazados" "GALIDA"
glog.sh "galidalog" "Cantidad de archivos aceptados: $cantidad_archivos_aceptados" "GALIDA"
glog.sh "galidalog" "Fin de ejecucion" "GALIDA"

exit 0