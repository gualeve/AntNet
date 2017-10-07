#!/bin/bash
#Criado em: qui 15/dez/2016 hs 14:57
#Arquivos: 
#Autor: José Adalberto Façanha Gualeve
tmp0="{$1}.log"
tmp1=/tmp/out.log
tmp2="{$1}.csv"

grep '^[GC].*Pack' $tmp0 > $tmp1

IFS="
"
for i in $( cat $tmp1)
do
	echo "$i" | grep '^G' 2> /dev/null && LIN=$(echo $i | sed 's/.*\.//g')
	echo "$i" | grep '^C' 2> /dev/null && LIN="${LIN}, $(echo $i | sed 's/.*\.//g')"
	echo "$LIN" | grep ',' 2> /dev/null && echo $LIN >> $tmp2
done
exit 0
