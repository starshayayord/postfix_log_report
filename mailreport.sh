#!/bin/bash
#while read HOST ; do ssh $HOST "uname -a" < /dev/null; done < servers.txt
file="/root/maillog";
outfile="/root/mailout"
declare -A BadMailHash
BadMail=()
idRegex="([a-zA-Z0-9]{5,}):"
toRegex="to=<(.*?)>, relay"
reasonRegex="status=[a-z]{1,} (.*)$"
fromRegex="from=<(.*?)>, size"
clientRegex="client=(.*?)\["
#processing
if [ ! -f $file ]; then 
    echo "File $file not found!"
else
    echo "File $file was found!"
    echo "Parsing bad codes..."
    while read line; do	 
		if [[ $line == *"dsn=4"* ]] || [[  $line == *"dsn=5"* ]]; then 
			if [[ $line =~ $idRegex ]]; then
			#	BadMail+=(${BASH_REMATCH[1]})
				id=${BASH_REMATCH[1]}
				#BadMail+=($id)
				if [[ $line =~ $toRegex ]]; then
					to="${BASH_REMATCH[1]}"	
				fi
				if [[ $line =~ $reasonRegex ]]; then
                                        reason="${BASH_REMATCH[1]}"
                                fi
				str="TO: $to ;| REASON: $reason;"
				BadMailHash[$id]=$str
			fi
		fi
    done < $file
fi

#parse from
#echo "${BadMail[@]}"
echo "Completed!"
echo "Parsing bad senders..."
while read line; do
	if [[ $line =~ $idRegex ]]; then                       
		id="${BASH_REMATCH[1]}"
		#if [[ " ${BadMail[*]} " == *" $id "* ]]; then	
		if [[ ${BadMailHash[$id]} ]]; then
			if [[ $line =~ $fromRegex ]]; then 
				from="${BASH_REMATCH[1]}"
				if [[ ! "${BadMailHash[$id]}" =~ ^FROM ]]; then 
					#echo "${BadMailHash[$id]}"
					newstr="FROM: $from;| ${BadMailHash[$id]}"
					BadMailHash[$id]=$newstr
				fi
				
			fi
			if [[ $line =~ $clientRegex ]]; then
                                client="${BASH_REMATCH[1]}"
                                if [[ ! "${BadMailHash[$id]}" =~ ^CLIENT ]]; then
                                newstr="CLIENT: $client;| ${BadMailHash[$id]}"
                                BadMailHash[$id]=$newstr
                                fi
                        fi

		fi
	fi
 done < $file
#final output
echo "Generating report..."

for Value in "${BadMailHash[@]}"; do echo $Value; done | sort -n | uniq > $outfile
echo "OK! Report: $outfile"
