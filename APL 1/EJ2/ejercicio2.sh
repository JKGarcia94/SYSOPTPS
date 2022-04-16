#!/bin/bash

function mostrarAyuda(){
    echo "El script devuelve 0 en caso de un commit valido y 1 en caso de un commit invalido\n";
    echo "Parametros de entrada:\n";
    echo "--diff: ruta de un directorio que contiene archivos de codigo\n";
    echo "--check: ruta de un archivo que contiene las cadenas a buscar dentro de los archivos del directorio pasado en el parametro anterior\n";
    echo "EL directorio puede estar vacio y el archivo puede estar vacio\n";
    echo "Ejemplo de Ejecucion:\n ./ejercicio2.sh MiDirectorio Prueba/cadenas";
}

function resolver(){

   if [[ ! -s $2 ]];then #SI esta vacio el archivo
        return 0;
      
    fi
   
    cont=0;
   
    while IFS= read -r line #leo el archivo de las cadenas de una cadena a la vez
    do
       
       archivos=$(ls "$1");
       #echo $archivos; 
      
        

        for arch in $archivos
        do
          #echo "esto es [$arch]";
          respuesta_grep=$(grep -r -w "$line" "$1/$arch"); #Busco esa cadena leida, si existe en el directorio pasado

          if [[ -n $respuesta_grep ]];then #Devuelve true si la cantidad o longitud de la cadena es distinta de null
            cont=$((cont+1));
          fi

          if [[ $cont != 0 ]];then
           return 0;
          fi

    
        done
       # echo $archivo;
        
    done < "$2"

    if [[ $cont != 0 ]];then
        return 0;
    else
       return 1;
    fi


}

function validarParametrosEntrada(){
    if [[ $# < 1  || $# > 2 ]];then
        echo "La cantidad de parametros es invalida:";
        echo "Solicite un ejemplo de ejecucion correcta ejecutando :";
        echo "./ejercicio2.sh -h || ./ejercicio2.sh -help || ./ejercicio2.sh -?";
        exit 1;
    fi
    if [[ "$1" == '-h' || "$1" == '-help' || "$1" == '-?' ]];then
        mostrarAyuda;
        exit 1;
    fi
    if [[ ! -d "$1" ]];then
        echo "Este parametro debe ser un directorio";
        echo "Solicite un ejemplo de ejecucion correcta ejecutando :";
        echo "./ejercicio2.sh -h || ./ejercicio2.sh -help || ./ejercicio2.sh -?"; 
        exit 1;
    fi
    if [[ ! -f "$2" ]];then
        echo "Este parametro debe ser un archivo";
        echo "Solicite un ejemplo de ejecucion correcta ejecutando :";
        echo "./ejercicio2.sh -h || ./ejercicio2.sh -help || ./ejercicio2.sh -?"; 
        exit 1;

    fi
    if [[ ! -r "$1" ]];then
        echo "Este directorio {{$1}} no posee permisos de lectura";
        exit 1;
    fi
    if [[ ! -r "$2" ]];then
        echo "Este archivo {{$2}} no posee permisos de lectura";
        exit 1;
    fi
}

function main (){
    
 validarParametrosEntrada "$@";   
 resolver "$@";
    
}
main "$@";
    