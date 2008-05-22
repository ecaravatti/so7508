Instructivo de Instalación del Sistema Gastos
---------------------------------------------

1º) Crear en el directorio corriente el directorio "grupo03"

	mkdir grupo03

2º) Setear manualmente la variable de entorno $GRUPO

	export GRUPO=$PWD/grupo03

3º) Copiar el archivo gastos.tgz en el directorio corriente

	cp /media/floppy/gastos.tgz .

4º) Descomprimir gastos.tgz de manera de generar gastos.tar

	gzip -d gastos.tgz

5º) Extraer los archivos de gastos.tar

	tar -xvf gastos.tar

6º) Ingresar al directorio "install" que se encuentra del directorio corriente

	cd install

7º) Ejecutar el script de instalación

	./ginsta.sh

8º) Seguir los pasos de la instalación, teniendo en cuenta que cuando GINSTA le solicite el ingrese de algún dato, si presiona ENTER automáticamente se tomará el valor por defecto que se muestra entre paréntesis.

9º) Si lo desea, al finalizar la instalación, puede eliminar el directorio "install"

