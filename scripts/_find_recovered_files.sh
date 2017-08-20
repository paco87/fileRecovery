#!/bin/bash
photoshop=(
PSD
PSB

)

movies=(
wmv
)

pictures=(

)


function printNames()
{
echo "starting: $@"
counter=1
for name in "$@" ;do

	echo "${counter}. ${name}"
	let counter++;
done

}

printNames ${photoshop[@]}
printNames ${movies[@]}
