#!/bin/bash
#Criado em: dom 06/nov/2016 hs 14:58
#Arquivos: 
#Autor: José Adalberto Façanha Gualeve

LOG=antnet-8x8-a.log
while [ 0 ]
do
	clear
	echo $LOG
	grep '^[C].*DATA' $LOG | wc
	grep '[GC].*Pack' $LOG
	sleep 30 
done
exit 0
