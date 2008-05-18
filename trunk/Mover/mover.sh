#$1 = Origen
#$2 = Destino
#$3 (Opcional) = Archivo de log del comando que la invoca (podremos hacer esto???)
#$4 (Opcional) = Información adicional

GLOG=./glog.sh

if [ $# -lt 2 ]
then
	$GLOG $ARCHIVO_LOG "Cantidad de parametros invalida" $0
	exit 1
elif [ $# -gt 2 ]
then
	ARCHIVO_LOG=$3
else
	ARCHIVO_LOG=/dev/stdout
fi


if [ -d $2 ] #Veo si el destino es un directorio
then
	destino=$2/`basename $1` #Conserva nombre de archivo original
else
	destino=$2 #Renombra archivo
fi

directorio_destino=`dirname $destino`
archivo_destino=`basename $destino`

if [ ! -e $directorio_destino ]
then
	$GLOG $ARCHIVO_LOG "El directorio $directorio_destino no existe" $0
	exit 2
fi

if [ ! -e $1 ]
then
	$GLOG $ARCHIVO_LOG "El archivo origen $1 no existe" $0
	exit 3
fi

if [ -d $1 ]
then
	$GLOG $ARCHIVO_LOG "El archivo origen $1 es un directorio" $0
	exit 4
fi


#Obtengo los paths absolutos (sin .. o . intercalados) de ambos archivos, para ver si son el mismo archivo o no.
cd `dirname $1`
path1=`pwd`
cd - >> /dev/null
cd `dirname $2`
path2=`pwd`
cd - >> /dev/null
archivo_origen_absoluto=$path1/`basename $1`
archivo_destino_absoluto=$path2/`basename $2`

if [ $archivo_origen_absoluto == $archivo_destino_absoluto ] #Esto no checkea si los archivos son iguales, porque quizas uno tiene path relativo y otro absoluto...
then
	$GLOG $ARCHIVO_LOG "Destino y origen iguales" $0
	exit 5
fi

if [ -e $destino ] #Veo si el archivo existe
then
	if [ ! -e $directorio_destino/dup ] #Veo si no existe el directorio dup
	then
		$GLOG $ARCHIVO_LOG "Creando directorio $directorio_destino/dup" $0
		mkdir $directorio_destino/dup
	elif [ ! -d $directorio_destino/dup ] #Chequeo si el dup existente no es un directorio
	then
		$GLOG $ARCHIVO_LOG "No se pudo crear directorio $directorio_destino/dup ya que existe un archivo con ese nombre" $0
		exit 6
	fi

	IFSOriginal=$IFS
	IFS=$'\t\n ' #IFS default, lo setteo por las dudas que quien me invoca lo tenga cambiado
	archivos_duplicados=($(ls -r "$directorio_destino/dup" | grep  "^$archivo_destino\.[0-9]\{3\}$"))
	
	if [ ${#archivos_duplicados[*]} == 0 ] #Veo si hay alguna otra duplicacion del mismo archivo
	then
		extension="000"
	else
		ultimo_archivo_duplicado=${archivos_duplicados[0]} #Es la posicion 0 porque hice ls -r (orden invertido)
		IFS=. #Pongo al punto como separador
		archivo_parseado=($ultimo_archivo_duplicado)
		cantidad_campos=${#archivo_parseado[*]}
		extension=${archivo_parseado[cantidad_campos-1]}
		IFS=$IFSOriginal #Reestablezco el separador original
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
		$GLOG $ARCHIVO_LOG "El archivo ya existia en directorio destino. Se lo guardo en $directorio_destino/dup/$archivo_destino.$extension" $0
		exit 0 #Esta bien devolver 0 si fue mv duplicado?
	else
		$GLOG $ARCHIVO_LOG "mv lanzo error al mover el archivo" $0 #Error inesperado
		exit 7
	fi
else
	mv $1 $destino
	resultado=$?
	if [ $? == 0 ]
	then
		if [ $# -gt 3 ]
		then
			$GLOG $ARCHIVO_LOG "$4. El archivo $1 fue movido satisfactoriamente a $destino" $0
		else
			$GLOG $ARCHIVO_LOG "El archivo $1 fue movido satisfactoriamente a $destino" $0
		fi
		exit 0
	else
		$GLOG $ARCHIVO_LOG "mv lanzo error al mover el archivo" $0 #Error inesperado
		exit 8
	fi
fi
