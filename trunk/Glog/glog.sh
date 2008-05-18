#$1 = Nombre de archivo de log
#$2 = Mensaje a loggear
#$3 = Comando que me invoca. Si tiene el .sh no importa, ya que se lo saco.

LOGSIZE=6 #Solo para probarlo hasta que no tenga bien setteado esto

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
	#cmd=$(ps -p $PPID -o "%a" | sed -n 's/^.*\.\/\([^.]*\)\.sh.*$/\1/p')
	comando=`echo $3 | sed 's/\.sh$//'` #Le saco el .sh si es que lo tiene
	mensaje="`date` - `basename $comando` - `whoami` - $2"
	echo $mensaje >> $1

	if [ "$LOGSIZE" != "" ]
	then
		if [ `expr $(stat -c%s "$1") / 1024` -ge $LOGSIZE ]
		then
			IFSOriginal=$IFS
			IFS=$'\t\n ' #IFS default, lo setteo por las dudas que quien me invoca lo tenga cambiado
			cant_lineas=(`wc -l $1`)
			IFS=$IFSOriginal
			if [ $cant_lineas -gt 70 ]
			then
				ultima_linea=$(expr $cant_lineas - 70)
				sed "1,$ultima_linea d" <$1 >$1.temp
				mv $1.temp $1
			fi
		fi
	fi

	exit 0
fi
