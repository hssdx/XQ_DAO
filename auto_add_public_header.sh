function filtHeaderFile()
{
	filename="$1"
	filepath="$2/$1"
	blackList="Pods"
	if [[ $filepath =~ $blackList ]]; then
		return 1
	fi
	blackList="XQKit.h"
	if [[ $filepath =~ $blackList ]]; then
		return 2
	fi
	if [ "${filename##*.}" = "h" ]; then
		echo "#import <XQKit/$filename>" >> ./tmp_XQKit.h
		#cat "./LICENSE" >> ./copy_license_file.txt
		#echo "$filename" >> ./tmp_XQKit.h
		#echo ">" >> ./tmp_XQKit.h

		#f [ ! -z "`grep "MIT License" $filepath`" ]; then
		#	echo "[$filepath] aleady has license describe."
			#test
		#else
		#	echo "#import <XQKit/" > ./tmp_XQKit.h
			#cat "./LICENSE" >> ./copy_license_file.txt
		#	echo "$filename" >> ./tmp_XQKit.h
		#	cat ">" >> ./tmp_XQKit.h
			#mv ./copy_license_file.txt $filepath
			#echo "[$filepath]"
		#fi
	fi
}

function traversingFiles()
{
	#1st param, the dir name
	for file in `ls $1`;
	do
		if [ -d "$1/$file" ]; then
			traversingFiles "$1/$file" "$1"
		else
			filtHeaderFile $file $1
		fi
	done
	#rm -f ./tmp_XQKit.h
}

traversingFiles "."
