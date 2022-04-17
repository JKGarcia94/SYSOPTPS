#!/bin/bash
nombreScript=$(readlink -f $0)
dir_base=`dirname $nombreScript`

monitorizarDirectorio(){ # directorioM [acciones] directorioAcopiarArchivoDePublicar ListaDeArchivosMasDirectorio
	lista=($4)

	IFS=" "

	cadena="$2"
	cadena=${cadena//,/" "}
	acciones=($(echo "$cadena"))

	declare -A acc
	acc["listar"]=0
	acc["peso"]=0
	acc["compilar"]=0
	acc["publicar"]=0

	inicio=0
	#Usamos el array asociativo para insertar 1 en aquellas acciones que tenemos en la lista de acciones.
	while [ "$inicio" -ne "${#acciones[*]}" ];do
		acc["${acciones[$inicio]}"]=1
		let inicio=$inicio+1
	done



	for i in ${!acc[*]}
	do
		#Si la accion esta en la lista, debería tener como valor un 1. Aquellas con valor 0 no podrán estar ahí.
		if [[ "${acc[$i]}" == 1 ]]; then
			let inicio=0
			case "$i" in
				'listar')
						fechaControl=$(echo `cat fechaIni`)
						while [ $inicio -ne ${#lista[@]} ]; do
							echo 
							if [ -e "${lista[$inicio]}" ];
							then
								fechaMod=`date -r "${lista[$inicio]}" +%s`
								if [[ $fechaControl < $fechaMod ]];
								then
									linea="${lista[$inicio]}"
									echo "${linea##*/} fue modificado"
								fi
							else
									linea="${lista[$inicio]}"
									echo "${linea##*/} fue modificado (renombrado o eliminado o recientemente creado)"
							fi
							let inicio=$inicio+1
						done
				;;
				'peso')
						fechaControl=$(echo `cat fechaIni`)
						while [ $inicio -ne ${#lista[@]} ]; do
							if [ -e "${lista[$inicio]}" ];
							then
								fechaMod=`date -r "${lista[$inicio]}" +%s`
								if [[ $fechaControl < $fechaMod ]];
								then
									linea="${lista[$inicio]}"
									tamanio=$(stat -c %s "${lista[$inicio]}")
									echo "$tamanio bytes, pesa el archivo ${linea##*/}"
								fi
							else
								echo "el archivo ${linea##*/} ha sido eliminado o renombrado o recientemente creado"
							fi
							let inicio=$inicio+1
						done
				;;
				'compilar')
						fechaControl=$(echo `cat fechaIni`)
						let inicio=0
						cambio=0
						while [ $inicio -ne ${#lista[@]} ]; do
							if [ -e "${lista[$inicio]}" ];
							then
								fechaMod=`date -r "${lista[$inicio]}" +%s`
								if [[ $fechaControl < $fechaMod ]];
								then
									let cambio=1
									break
								fi
							else
								let cambio=1
								break
							fi
							let inicio=$inicio+1
						done

						if [[ $cambio == 1 ]]; then
							while [ $inicio -ne ${#lista[@]} ]; do
								cat "${lista[$inicio]}" >> "$dir_base/bin/$(cat $pidFile).txt"
								let inicio=$inicio+1
							done
						fi
				;;
				'publicar')
					cp "$dir_base/bin/$(cat $pidFile).txt" "$3/$(cat $pidFile).txt"
				;;
			 esac
		fi
	done
}




validarParametros1() {
	if [ ! -d "$1" ];
	then
		return 1
	fi
	
	if [ ! -r "$1" ];
	then
		return 2
	fi

	if [ ! -n "$2" ];
	then
		return 3
	fi

	return 0;
}

validarParametros2() {
	#crear una lista la cual almacena sin las comas cada acción.
	if [ ! -n "$1" ]; then
		return 4
	fi

	cadena=$1
	cadena=${cadena//,/" "}
	#transformar dicha cadena en una lista de acciones.
	IPS=' '
	lista=($cadena)
	if [[ ${#lista[@]} > 4 || ${#lista[@]} < 1 ]]; then
		return 1
	fi

	inicio=0

	while [ $inicio -ne ${#lista[@]} ];do
		if [[ "${lista[$inicio]}" != "listar" && "${lista[$inicio]}" != "peso" && "${lista[$inicio]}" != "compilar" && "${lista[$inicio]}" != "publicar" ]]; then
			return 2
		fi
		if [[ "${lista[$inicio]}" == "compilar" && ! -e "$dir_base/bin" ]];
		then
			mkdir "$dir_base/bin"
		fi
		let inicio=$inicio+1
	done
	let inicio=0
	comp=0
	pub=0

	while [ $inicio -ne ${#lista[@]} ];do
		if [[ "${lista[$inicio]}" == "compilar" ]]; then
			let comp=1
		fi
		if [[ "${lista[$inicio]}" == "publicar" ]]; then
			let pub=1
		fi
		let inicio=$inicio+1
	done

	if [[ $comp == 0 && $pub == 1 ]]; then
		return 3
	fi

	return 0
}

validarParametros3() {
	if [[ $1 != "-s" ]]; then
		return 1
	fi

	if [ ! -e "$2" ]; then
		return 2
	fi

	if [ ! -d "$2" ];
	then
		return 3
	fi
	
	if [ ! -r "$2" ];
	then
		return 4
	fi

	if [ ! -w "$2" ];
	then
		return 5
	fi

	return 0
}

loop() {
	IFS=$'\n'
   	lista=(`readlink -e $(find "$1" -type f) 2>/dev/null`)
	date -u +%s > fechaIni
   	while [[ true ]];do
			monitorizarDirectorio "$1" "$2" "$3" "${lista[*]}"
  			date -u +%s > fechaIni
  			IFS=$'\n'
   			lista=(`readlink -e $(find "$1" -type f) 2>/dev/null`) #lista con elementos actualizados, ya que podrian haber elementos renonbrados o eliminados o agregados.
  			sleep 20
  	done
}

existe() {
   if [[ ! -s "$1" ]];then
      return 0;
   fi
   if [[ -n $(ps aux | grep `cat "$1"` | grep -v grep) ]];then
      return 1;
   else
      return 0;
   fi
}

#esta funcion ejecutara solo dos veces.
iniciarDemonio() { 
   existe
   if [[ $? -eq 1 ]];then
      echo "el demonio ya existe"
      exit 1;
   fi
	if [[ "$1" == "-nohup-" ]];then
		#por aca pasa la primera ejecución, abriendo mi script en segundo plano...
		echo "Demonio creado"
	   	nohup bash $0 $@ 2>/dev/null &
	else
		#por aca debería pasar la segunda ejecución pudiendo almacenar el PID del proceso para luego eliminarlo.
		#Tambien se inicia el loop
   	    pidFile="$dir_base/$$.pid";
		touch "$pidFile"
   	    echo $$ > "$pidFile"
   	    loop "$1" "$2" "$3"
	fi
}

#esta función solo se ejecutara cuando envie el parametro -d
eliminarDemonio() {
	#Obtenemos todos los demonios creados en anteriores scripts
	demonios=(`readlink -e $(find "$dir_base" -name "*.pid"  -type f) 2>/dev/null`)
	inicio=0
	echo la cantidad de demonios es "${#demonios[*]}"
	if [[ "${#demonios[*]}" == 0 ]];
	then
		echo "No hay demonios que eliminar..."
	fi
	while [ $inicio -ne "${#demonios[*]}" ];do
		existe "${demonios[$inicio]}"
 		if [[ $? -eq 0 ]];then
      		echo "el demonio no existe"
      		exit 1;
   		fi
		kill `cat "${demonios[$inicio]}"`
		true > "${demonios[$inicio]}"
		linea="${demonios[$inicio]}"
		echo "demonio ${linea##*/} exterminado"
		rm "${demonios[$inicio]}"
		let inicio=$inicio+1
	done
	rm fechaIni
}




mostrarAyuda() {
	echo "Modo de uso: bash $0 [-c] [Directorio a analizar] [-a] [[listar],[peso],[compilar],[publicar]] [-s] [directorio a copiar el archivo generado en publicar]"
	echo ""
	echo "Monitorear un directorio para ver si hubo cambios en este"
	echo "-d 	indica el directorio a monitorear"
	echo "El directorio a monitorear indicado en -d puede estar vacío."
	echo "-a 	una lista de acciones separadas con coma a ejecutar cada vez que haya un cambio en el directorio a monitorear."
	echo "listar: muestra por pantalla los nombres de los archivos que sufrieron cambios (archivos creados, modificados, renombrados, borrados)."
	echo "peso: muestra por pantalla el peso de los archivos que sufrieron cambios."
	echo "compilar: concatena todos los archivos del directorio en un archivo ubicado en una carpeta bin en el mismo directorio donde se halla la script"
	echo "publicar: copia el archivo compilado (el generado con la opción “compilar”) a un directorio pasado como parámetro “-s”. Esta opción no se puede usar sin la opción “compilar”."
	echo "-s 	ruta del directorio utilizado por la acción “publicar”. Sólo es obligatorio si se envía “publicar” como acción en “-a”."
	echo "En caso de querer terminar el proceso escribimos bash $0 -d"
}


posi="$1"
if [[ "$1" == "-nohup-" ]]; then
	shift;	##borra el nohup y corre las demas variables una posición.
else # si no es igual a -nohup- significa que es la primer vuelva y apenas se comenzo a ejecutar el proceso por lo que aqui es donde tengo qeu crear las fifos donde se almacenaran la fecha inicial.
	if [[ "$1" != "-d" ]]; then

		fechaIni=/tmp/testpipe
		trap "rm -f $fechaIni" exit

		if [ ! -p $fechaIni ]; then
			mkfifo $fechaIni
			echo "se creo el fifo"
		else
			echo "ya se había creado"
		fi

		if [ ! -n "$2" ];then
			echo "ERROR: falta pasar directorio a monitorear"
			exit 1;
		fi
	fi
fi
case "$1" in
  '-c')
	if [[ "$posi" != "-nohup-" ]]; then
		#por primera ves debería pasar por aca.
    	if [[ "$3" != '-a' ]]; then
			echo "Error: el argumento 3 tiene que ser -a"
			exit 1;
		else
			validarParametros1 $2 $3
		fi
		retorno=$?
		if [[ $retorno == 1 ]]; then
				echo "Error: \"$2\" no es un directorio"
				exit 1;
		fi
		if [[ $retorno == 2 ]]; then
				echo "Error: sin permisos de lectura en directorio a monitorear"
				exit 1;
		fi

		validarParametros2 $4

		let retorno=$?
		if [[ $retorno == 1 ]]; then
			echo "Error, cantidad de acciones invalida"
			exit 1;
		fi
		if [[ $retorno == 2 ]]; then
			echo "Error, accion invalida"
			exit 1
		fi
		if [[ $retorno == 3 ]]; then
			echo "Error, no puede haber un publicar y no un compilar"
			exit 1
		fi

		if [[ $retorno == 4 ]]; then
			echo "Error, no hay acciones que realizar"
			exit 1
		fi

		validarParametros3 $5 $6

		let retorno=$?

		if [[ $retorno == 1 ]]; then
			echo "Error, accion de control invalida"
			exit 1
		fi

		if [[ $retorno == 3 ]]; then
			echo "Error: \"$6\" no es un directorio"
			exit 1
		fi

		if [[ $retorno == 4 ]]; then
			echo "Error, \"$6\" no tiene permisos de lectura"
			exit 1
		fi

		if [[ $retorno == 5 ]]; then
			echo "Error, \"$6\" no tiene permisos de escritura"
			exit 1
		fi

		if [[ $retorno == 2 ]]; then
			#si el directorio no existe mandare el directorio de la script.
			iniciarDemonio "-nohup-" $1 "$2" $3 "$4" $5 "$6" "$dir_base"
		else
			iniciarDemonio "-nohup-" $1 "$2" $3 "$4" $5 "$6"
		fi
	else
			#por aqui pasa la segunda
    		iniciarDemonio "$2" "$4" "$6"
	fi
    ;;
  '-h' | '-help' | '-?')
	mostrarAyuda
    ;;
   '-d')
	eliminarDemonio
	;;
  *)
  echo "Obtener ayuda $0 [ -h | -help | -? ]"
esac
