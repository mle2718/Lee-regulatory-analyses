#! /bin/bash

for img in /home2/mlee/RasterRequests/A8_background_2017-06-13/*.pdf; do
    filename=${img%.*}

  if [ -f $filename.png ];
then 
	echo "File $filename.png exists. Skipping."
else  
	echo "File $filename.png does not exist. converting pdf to png."
	convert -density 100x100 "$filename.pdf" "$filename.png"
fi 
done

