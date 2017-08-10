# 
# author xxq
# create time: 2017年08月10日15:24:57
# 

project_name="XQ_DAO"
public_header_file_pod="./tmp_public_header.txt"
public_header_file_no_pod="./tmp_public_header_no_pod.txt"
result_file="${project_name}/${project_name}.h"

# echo $result_file

function filtHeaderFile()
{
	filename="$1"
	filepath="$2/$1"
	blackList="Pods"
	if [[ $filepath =~ $blackList ]]; then
		return 1
	fi
	blackList="${project_name}.h"
	if [[ $filepath =~ $blackList ]]; then
		return 2
	fi
	if [ "${filename##*.}" = "h" ]; then
		echo "#import <XQKit/$filename>" >> $public_header_file_pod
		echo "#import \"$filename\"" >> $public_header_file_no_pod
	fi
}

function traversingFiles()
{
	for file in `ls $1`;
	do
		if [ -d "$1/$file" ]; then
			traversingFiles "$1/$file" "$1"
		else
			filtHeaderFile $file $1
		fi
	done
}

#清除之前的文件
#rm -f $result_file

traversingFiles "."


cat "./LICENSE" > $result_file
echo "#import <Foundation/Foundation.h>

#if __has_include(<${project_name}/${project_name}.h>)

FOUNDATION_EXPORT double ${project_name}VersionNumber;
FOUNDATION_EXPORT const unsigned char ${project_name}VersionString[];

"  >> $result_file

cat $public_header_file_pod >> $result_file

echo "

#else

" >> $result_file

cat $public_header_file_no_pod >> $result_file

echo "

#endif

" >> $result_file

#清理文件
rm -f $public_header_file_pod
rm -f $public_header_file_no_pod
