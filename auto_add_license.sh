function filtCodeFile()
{
	filename="$1"
	filepath="$2/$1"
	blackList="Pods"
	if [[ $filepath =~ $blackList ]]; then
		return 1
	fi
	if [ "${filename##*.}" = "h" -o "${filename##*.}" == "m" ]; then
		if [ ! -z "`grep "MIT License" $filepath`" ]; then
			echo "[$filepath] aleady has license describe."
			#test
		else
			echo "/* " > ./copy_license_file.txt
			cat "./LICENSE" >> ./copy_license_file.txt
			echo " */" >> ./copy_license_file.txt
			cat "$filepath" >> ./copy_license_file.txt
			mv ./copy_license_file.txt $filepath
			echo "[$filepath] add license finish!"
		fi
	fi
}

function traversingFiles()
{
	#1st param, the dir name
	for file in `ls $1`;
	do
		if [ -d "$1/$file" ]; then
			#filtCodeFile $file $1
			traversingFiles "$1/$file" "$1"
		else
			filtCodeFile $file $1
		fi
	done
}

traversingFiles "."
#清理文件
rm -f ./copy_license_file.txt

