# La instalacion no sera correcta si perl no existe en el sistema
# dado que no se podra crear el encabezado #! de los script perl
# para indicarle donde esta el interprete
curr_bash=$(which bash)
curr_perl=$(which perl)

cat << ! > ./instalC.sh
echo " >  Ejecutando Auto-Extractor."
echo " >  Trabajo Practico de Sistemas Operativos."
echo " >  Grupo 7"

echo " >> Comenzando el proceso de instalacion."
grupo="grupo7"

# No puede existir ya una carpeta con el nombre de \$grupo
if [ -d \$(pwd)/\$grupo ]
then
	echo " >> Error, la carpeta \$grupo ya existe en este directorio."
fi

echo " >> Creando la estructura de directorios."

mkdir -m 755 \$(pwd)/\$grupo 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/arribos 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/bin 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/consultas 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/ivaC 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/norecibidos 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/prueba 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/recibidos 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/recibidos/procesados 2>> \$HOME/instaC.log
mkdir -m 755 \$(pwd)/\$grupo/tablas 2>> \$HOME/instaC.log

# Si el log no es nulo entonces surgio algun error al crear los directorios
if [ ! -z \$(cat \$HOME/instaC.log) ]
then
	echo "Error al tratar de crear la estructura de directorios, mostrando log de errores:".
	cat \$HOME/instaC.log	
	exit 1
fi

rm  \$HOME/instaC.log 

echo " >> Estructura de directorios creada correctamente."
!

cat << ! >>./instalC.sh
echo ""
echo ""
echo " >> Creando archivos de comandos."
!

echo "" >>  instalC.sh
echo "" >>  instalC.sh
echo "echo \" >>> Creando \$(pwd)/\$grupo/grabaL.sh.\"" >> instalC.sh
echo "cat << ! >> \$(pwd)/\$grupo/grabaL.sh" >>  instalC.sh
echo "#! $curr_bash" >>  instalC.sh
echo "" >>  instalC.sh
cat grabaL.sh | sed 's/\$/\\$/g' >>  instalC.sh
echo "!" >>  instalC.sh
echo "chmod -f 777 \$(pwd)/\$grupo/grabaL.sh" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
echo "echo \" >>> Creando \$(pwd)/\$grupo/validCo.sh.\"" >> instalC.sh
echo "cat << ! >> \$(pwd)/\$grupo/validCo.sh" >>  instalC.sh
echo "#! $curr_bash" >>  instalC.sh
echo "" >>  instalC.sh
cat validCo.sh | sed 's/\$/\\$/g' >>  instalC.sh
echo "!" >>  instalC.sh
echo "chmod -f 777 \$(pwd)/\$grupo/validCo.sh" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
echo "echo \" >>> Creando \$(pwd)/\$grupo/recibeC.sh.\"" >> instalC.sh
echo "cat << ! >> \$(pwd)/\$grupo/recibeC.sh" >>  instalC.sh
echo "#! $curr_bash" >>  instalC.sh
echo "" >>  instalC.sh
cat recibeC.sh | sed 's/\$/\\$/g' >>  instalC.sh
echo "!" >>  instalC.sh
echo "chmod -f 777 \$(pwd)/\$grupo/recibeC.sh" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
echo "echo \" >>> Creando \$(pwd)/\$grupo/iniciaC.\"" >> instalC.sh
echo "cat << ! >> \$(pwd)/\$grupo/iniciaC" >>  instalC.sh
echo "#! $curr_bash" >>  instalC.sh
echo "" >>  instalC.sh
cat iniciaC | sed 's/\$/\\$/g' >>  instalC.sh
echo "!" >>  instalC.sh
echo "chmod -f 777 \$(pwd)/\$grupo/iniciaC" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
echo "echo \" >>> Creando \$(pwd)/\$grupo/consulC.pl.\"" >> instalC.sh
echo "cat << ! >> \$(pwd)/\$grupo/consulC.pl" >>  instalC.sh
echo "#! $curr_perl" >>  instalC.sh
cat consulC.pl | sed 's/\\\\/\\\\\\\\/g' | sed 's/\$/\\$/g'  >>  instalC.sh
echo "!" >>  instalC.sh
echo "chmod -f 777 \$(pwd)/\$grupo/consulC.pl" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
echo "echo \" >> Archivos de comandos creados correctamente.\"" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
cat << ! >> ./instalC.sh
echo ""
echo ""
echo " >> Generando archivos de datos."
!

for i in $(ls ./tablas/*.*)
do
	nombre=$(echo $i | sed 's/\.\/tablas\/\(.*\)$/\1/')
	echo "" >>  instalC.sh
	echo "" >>  instalC.sh
	echo "echo \">>> Creando \$(pwd)/\$grupo/tablas/$nombre\"" >> instalC.sh	
	echo "cat << ! >> \$(pwd)/\$grupo/tablas/$nombre" >>  instalC.sh
	cat $i >>  instalC.sh
	echo "!" >>  instalC.sh
	echo "chmod -f 666 \$(pwd)/\$grupo/tablas/$nombre" >> instalC.sh
done

for i in $(ls ./prueba/*.*)
do
	nombre=$(echo $i | sed 's/\.\/prueba\/\(.*\)$/\1/')
	echo "" >>  instalC.sh
	echo "" >>  instalC.sh
	echo "echo \">>> Creando \$(pwd)/\$grupo/prueba/$nombre\"" >> instalC.sh	
	echo "cat << ! >> \$(pwd)/\$grupo/prueba/$nombre" >>  instalC.sh
	cat $i >>  instalC.sh
	echo "!" >>  instalC.sh
	echo "chmod -f 666 \$(pwd)/\$grupo/prueba/$nombre" >> instalC.sh
done

echo "echo \" >> Archivos de datos creados correctamente\"" >> instalC.sh

echo "" >>  instalC.sh
echo "" >>  instalC.sh
cat << ! >> ./instalC.sh
echo ""
echo ""
echo " > Fin de la instalacion."
!

chmod -f 777 instalC.sh