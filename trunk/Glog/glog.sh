#$1 = Nombre de archivo de log
#$2 = Mensaje a loggear
#$3 = Comando que me invoca. No deberia tener que recibirlo creo.

LOGSIZE=6 #Solo para probarlo hasta que no tengo bien setteado esto

if [ -d $1 ] #Veo si es un directorio
then
	echo "El archivo donde desea escribir es un directorio"
	exit 1
elif [ ! -e `dirname $1` ]
then
	echo "Path del archivo donde desea escribir invalido"
	exit 2
else
	# Busco el nombre del proceso que invoco el log.
	# Si es un script le quito el .sh
	#cmd=$(ps -p $PPID -o "%a" | sed -n 's/^.*\.\/\([^.]*\)\.sh.*$/\1/p')
	mensaje="`date` - `basename $3` - `whoami` - $2"

	if test -e $1 -a "$LOGSIZE" != ""
	then
		if [ `expr $(stat -c%s "$1") / 1024` -ge $LOGSIZE ]
		then
			echo "TODO cortar archivo"
		fi
	fi

	echo $mensaje >> $1
	exit $?
fi
