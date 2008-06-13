##################
# Imprime mensaje,fecha y usuario en un archivo de log
# con el nombre del proceso que lo invoco
#
# Arg1 -> Mensaje
#

# Busco el nombre del proceso que invoco el log.
# Si es un script le quito el .sh
cmd=$(ps -p $PPID -o "%a" | sed -n 's/^.*\.\/\([^.]*\)\.sh.*$/\1/p')

if [[ !(-d "$GRUPO/log/") ]]
then
	mkdir $GRUPO/log/	
fi

echo $1			>> "$GRUPO/log/$cmd.log"
echo $(date  +%d/%m/%y)	>> "$GRUPO/log/$cmd.log"
echo $(whoami)		>> "$GRUPO/log/$cmd.log"
