Instructivo de Instalación del Sistema Gastos
---------------------------------------------

1º) Crear en el directorio corriente el directorio "grupo03"

	mkdir grupo03

2º) Setear manualmente la variable de entorno $GRUPO

	export GRUPO=$PWD/grupo03
	
3º) Ingresar al directorio grupo03

	cd grupo03
	
4º) Copiar el archivo gastos.tgz en el directorio corriente (grupo03)

	cp <direccion_floppy>/gastos.tgz .
	
	(Por lo general la dirección de la unidad de disquete es /media/floppy)

5º) Descomprimir gastos.tgz de manera de generar gastos.tar

	gzip -d gastos.tgz

6º) Extraer los archivos de gastos.tar

	tar -xvf gastos.tar

7º) Ingresar al directorio "install" que se encuentra del directorio corriente (grupo03)

	cd install

8º) Ejecutar el script de instalación

	./ginsta.sh

9º) Seguir los pasos de la instalación, teniendo en cuenta que cuando GINSTA le solicite el ingreso de algún dato, si presiona ENTER automáticamente se tomará el valor por defecto que se muestra entre paréntesis.

