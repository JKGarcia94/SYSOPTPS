#!/bin/bash

################################################################################
##  Ejercicio nro 4 del APL 1 - 1c 2022 - Entrega nro 1
##  Script: ejercicio04.sh
##
##  Integrantes del grupo
##  Schwab Maximiliano Alejandro, 34536455
##  Garcia Velez Kevin, 38619312
##  Villegas Lucas Ezequiel, 37792844
################################################################################

mostrarAyuda() {
	echo "Modo de uso: $0 -dir -ext [OPCION] -porc -salida "
	echo ""
	echo "-dir		se indica el directorio a analizar"		
	echo "-ext		se indica la ruta del archivo que posee las extensiones de archivos a analizar"
	echo "-porc		[NUMERO ENTERO]: si la similitud es >= a este numero se informan"
	echo "-salida 	[ARCHIVO]: salida al archivo archivosSimilares.txt"
	echo ""
	echo "OPCIONES:"
	echo "-coment	toma en cuenta las lineas comentadas en la comparacion (comienzan en // o #)"
	echo "-sincom	no toma en cuenta los comentarios"
	echo ""
	echo "Compara todos los archivos e informa los que su similitud sea mayor o igual a -porc"
	echo "Descarta los que tengan menos de -porc% de similitud"
	echo "Se toman en cuenta la cantidad de lineas del primer archivo contra la cantidad de lineas"
	echo "que tienen direrencia"
	echo "Se informan los archivos con ruta y el porcentaje de similitud"
}

###### DESDE ACÁ COMIENZA EL MAIN ########

dirOrig=$1
rutaExt=$2
coment=$3
porc=$4
archivo=$5
max_args=5
min_args=4

if [[ $1 == '-h' || $1 == '-?' || $1 == '-help' ]]
then
	mostrarAyuda
	exit 1;
fi

validarParametros(){
	if [[ $# > $max_args || $# < $min_args ]]
	then
		echo "ERROR: cantidad de argumentos inválida."
		exit
	fi

	if [ ! -d $dirOrig ]
	then
		echo "No existe el Directorio a analizar $1"
		echo $0 -h para ver el menu de ayuda
		exit
	fi 

	if [[ ! -e "$rutaExt" ]]
	then
		echo "No existe la ruta de extensiones $2"
		echo $0 -h para ver el menu de ayuda
		exit
	fi

	if [[ $coment != 'coment' && $coment != 'sincom' ]]
	then
		echo \$3 solo admite coment o sincom
		echo $0 -h para ver el menu de ayuda
		exit
	fi

	if [[ $archivo != 'ARCHIVO' && $archivo != '' ]]
	then
		echo \$5 solo admite ARCHIVO o nada
		echo $0 -h para ver el menu de ayuda
		exit
	else
		if [[ -f "./archivosSimilares.txt" ]]
		then
			rm archivosSimilares.txt
		fi
	fi
}

informarSimilitud(){
	
	#si se solicita archivo, se guarda en un archivo
	if [[ $4 == "ARCHIVO" ]] 
	then 
		echo -e "$2 \t- \t$3 \tSimilitud: $1%" >> archivosSimilares.txt
	else
		echo -e "$2 \t- \t$3 \tSimilitud: $1%"
	fi		  
}

main(){

	validarParametros "$@"
	
	IFS=';'
	line=$(<$rutaExt) #guardamos las estensiones en una variable
	archivosList=()

	#iteramos por cada extension
	for palabra in $line 
	do
		#asignamos a una variable la cantidad de archivos de cada extension
		cantFiles=$(find $dirOrig -type f -iname *.${palabra} | wc -l)
		
		#si hay archivoss los agregamos a una lista
		if [[ $cantFiles != 0 ]]
		then
			
			#guardamos todos los archivos de la extension en la lista
			while IFS=  read -r -d $'\0'; do
   				archivosList+=("$REPLY")
			done < <(find $dirOrig -type f -iname *.${palabra} -print0)

			# Cómo funciona
			# La primera línea crea una matriz vacía: array=()
			# Cada vez que se ejecuta la instrucción read, se lee un nombre de archivo separado por null 
			# desde la entrada estándar. La opción -r le dice a read que deje los caracteres de barra invertida solos.
			# El -d $'\0' le dice a read que la entrada será null-separada. 
			# Desde omitimos el nombre a read, el shell pone la entrada en el valor predeterminado nombre: REPLY.
			# La instrucción array+=("$REPLY") añade el nuevo nombre de archivo al array array.
			# La línea final combina la redirección y la sustitución de comandos para proporcionar la salida de find
			# a la entrada estándar del bucle while.
			
		fi	
	done
	
	#recorremos la lista para comparar la similitud entre archivos
	for (( i=0; i<${#archivosList[@]}-1; i++ ))
	do
		
		#calculamos la cantidad de lineas del archivo 1
		if [[ $coment == "sincom" ]]
		then
			tamArchivo1=$(cat ${archivosList[$i]} | grep -v -E "^//|^#" | wc -l)
		else
			tamArchivo1=$(cat ${archivosList[$i]} | wc -l)
		fi

		for (( j=i+1; j<${#archivosList[@]}; j++ ))
		do
			#calculamos la cantidad de lineas del archivo 2
			if [[ $coment == "sincom" ]]
			then
				tamArchivo2=$(cat ${archivosList[$j]} | grep -v -E "^//|^#" | wc -l)
			else
				tamArchivo2=$(cat ${archivosList[$j]} | wc -l)
			fi
			
			# calculamos su porcentaje de similitud
			# 100-((x-y)/x)*100
			if [[ $tamArchivo1 -eq $tamArchivo2 ]] 
				then
					similitud=100 
					
				else
					if [[ $tamArchivo1 -ge $tamArchivo2 ]]
					then
						if [[ $tamArchivo1 == 0 ]] # verificamos que el divisor no sea 0
						then
							similitud=0
						else
							similitud=$(bc <<< "scale=2; 100-(($tamArchivo1 - $tamArchivo2) / $tamArchivo1)*100")
						fi
					else
						if [[ $tamArchivo2 == 0 ]] # verificamos que el divisor no sea 0
						then
							similitud=0
						else
							similitud=$(bc <<< "scale=2; 100-(($tamArchivo2 - $tamArchivo1) / $tamArchivo2)*100")
						fi
					fi
				fi
			
			# si tienen mucha similitud lo informamos
			esMayorIgual=$(echo "$similitud>=$porc" | bc -l)
			if [[ esMayorIgual -eq 1 ]]
			then
				informarSimilitud $similitud ${archivosList[i]} ${archivosList[j]} $archivo
			fi
		done
	done

	if [[ $archivo == 'ARCHIVO' ]]
	then
		echo "Se ha guardado la salida en archivosSimilares.txt"
	fi
}

### EJECUTAMOSE EL MAIN ###

main "$@"