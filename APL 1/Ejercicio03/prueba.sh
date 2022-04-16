#!/bin/bash
#cadena="listar,peso,compilar,publicar"
#echo $cadena
#cadena=${cadena//,/" "}
#echo $cadena
#lista=($cadena)
#echo ${lista[@]}
#echo ${#lista[@]}
#IFS=\n
#lista1=($cadena)
#echo ${lista1[@]}
#echo ${#lista1[@]}


#SCRIPT=$(readlink -f $0)
#echo $SCRIPT
#dir_base=`dirname $SCRIPT`
#echo "y se encuentra en $dir_base"
#echo "cambie"

		#fechaIni=/tmp/testpipe
		#trap "rm -f $fechaIni" exit

		#if [[ ! -p $fechaIni ]]; then
		#	mkfifo fechaIni
		#	echo "se creo el fifo"
		#else
			#echo "ya se había creado"
		#fi
		#date > fechaIni

		#echo "`cat fechaIni`"

		#rm fechaIni

#lista=("listar" "compilar" "publicar" "peso")
#echo "${lista[*]} ${#lista[*]}"

#declare -A acc
#acc["listar"]=0
#acc["peso"]=0
#acc["compilar"]=0
#acc["publicar"]=0

#inicio=0

#while [ "$inicio" -ne "${#acc[*]}" ];do
#	acc["${lista[$inicio]}"]=1
#	let inicio=$inicio+1
#done

#for i in ${!acc[@]}
#do
#	echo $i ${acc[$i]}

#done

#cosa=($(ls -l $0))
#echo ${cosa[@]}
#cosa=(${cosa[4]})
#echo ${cosa[@]} bytes

directorio="/lucas/kami/loricho.exe"
echo ${directorio##*/}

inicio=0
list=($1)
echo ${#list[*]}
while [ $inicio -ne ${#list[@]} ]; do
	echo "${list[$inicio]}"
	let inicio=$inicio+1
done