#$1 = Origen
#$2 = Destino
#$3 (Opcional) = Comando que invoca
#$4 (Opcional) = Información adicional


if [ -d $2 ] #Veo si el destino es un directorio
then
	destino=$2/`basename $1` #Conserva nombre de archivo original
else
	destino=$2 #Renombra archivo
fi

directorio_destino=`dirname $destino`
archivo_destino=`basename $destino`

if [ ! -e $1 ]
then
	echo "El archivo origen $1 no existe"
	exit 1
fi

if [ -d $1 ]
then
	echo "El archivo origen $1 es un directorio"
	exit 2
fi

if [ $1 = $2 ] #Esto no checkea si los archivos son iguales, porque quizas uno tiene path relativo y otro absoluto...
then
	echo "Destino y origen iguales"
	exit 3
fi

if [ -e $destino ] #Veo si el archivo existe
then
	if [ ! -e $directorio_destino/dup ] #Veo si no existe el directorio dup
	then
		echo "Creando directorio $directorio_destino/dup"
		mkdir $directorio_destino/dup
	else
		if [ ! -d $directorio_destino/dup ] #Chequeo si el dup existente no es un directorio
		then
			echo "No se pudo crear directorio $directorio_destino/dup ya que existe un archivo con ese nombre"
			exit 4
		fi
	fi

	archivos_duplicados=($(ls -r "$directorio_destino/dup" | grep  "^$archivo_destino\.[0-9][0-9][0-9]$"))
	
	if [ ${#archivos_duplicados[*]} == 0 ] #Veo si hay alguna otra duplicacion del mismo archivo
	then
		extension="000"
	else
		ultimo_archivo_duplicado=${archivos_duplicados[0]} #Es la posicion 0 porque hice ls -r (orden invertido)
		IFSaux=$IFS
		IFS=. #Pongo al punto como separador
		archivo_parseado=($ultimo_archivo_duplicado)
		cantidad_campos=${#archivo_parseado[*]}
		extension=${archivo_parseado[cantidad_campos-1]}
		IFS=$IFSaux #Reestablezco el separador original
		extension=`expr $extension + 1`
		
		if [ $extension -lt 10 ]
		then
			extension="00$extension"
		elif [ $extension -lt 100 ]
		then
			extension="0$extension"
		fi
	fi
		
	mv $1 $directorio_destino/dup/$archivo_destino.$extension
	if [ $? == 0 ]
	then
		echo "El archivo ya existia en directorio destino. Se lo guardo en $directorio_destino/dup/$archivo_destino.$extension"
		exit 5
	else
		echo "mv lanzo error al mover el archivo" #Error inesperado
		exit 6
	fi
else
	mv $1 $destino
	resultado=$?
	if [ $resultado == 0 ]
	then
		echo "El archivo $1 fue movido satisfactoriamente a $destino"
		exit 0
	else
		if [ $resultado == 1 ]
		then
			echo "El destino $destino no es correcto"
			exit 7
		else
			echo "mv lanzo error al mover el archivo" #Error inesperado
			exit 8
		fi
	fi
fi
