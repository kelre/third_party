
echo "delete .a"
rm -f libmusicplayer_static.mri
rm -f libmusicplayer.a
errorstatic="./obj.host/"
echo "create libmusicplayer.a" >> libmusicplayer_static.mri

echo $errorstatic

array=($(find ./ -name "*.a"))

for i in "${array[@]}"
do
	if [ "${i/$errorstatic}" = "$i" ]; then
		echo "addlib $i" >> libmusicplayer_static.mri
	else
		echo "do not deal with this static library"
	fi
done

echo "save" >> libmusicplayer_static.mri
echo "end" >> libmusicplayer_static.mri

echo "generate mri sucess"

echo "generate static libs"
ar -M < libmusicplayer_static.mri
