#!/bin/bash

dme_path=""
returns=1

for var
do
	if [[ $var != -* && $var == *.dme ]]
	then
		dme_path=$(echo "$var" | sed -r 's/.{4}$//')
		break
	fi
done

if [[ $dme_path == "" ]]
then
	echo "No .dme file specified, aborting."
	exit 1
fi

if [[ -a $dme_path.tmpdme ]]
then
	rm "$dme_path.tmpdme"
fi

cp "$dme_path.dme" "$dme_path.tmpdme"
if [[ $? == 1 ]]
then
	echo "Failed to copy .dme, aborting."
	exit 2
fi

for var
do
	arg=$(echo "$var" | sed -r 's/^.{2}//')
	if [[ $var == -D* ]]
	then
		sed -i '1s/^/#define '"$arg"'\n/' "$dme_path.tmpdme"
		continue
	fi
	if [[ $var == -M* ]]
	then
		sed -i '1s/^/#define MAP_OVERRIDE\n/' "$dme_path.tmpdme"
		sed -i 's!// BEGIN_INCLUDE!// BEGIN_INCLUDE\n#include "maps\\'$arg'.dm"!' "$dme_path.tmpdme"
		continue
	fi
done

if hash DreamMaker 2>/dev/null
then
	DreamMaker "$dme_path.tmpdme" 2>&1 | tee result.log
	returns=$?
	if ! grep '\- 0 errors, 0 warnings' result.log
	then
		returns=1 #hard fail, due to warnings or errors
	fi
	else
		echo "Couldn't find the DreamMaker executable, aborting."
		exit 3
fi

mv "$dme_path.tmpdme.dmb" "$dme_path.dmb"
mv "$dme_path.tmpdme.rsc" "$dme_path.rsc"
rm "$dme_path.tmpdme"
exit $returns