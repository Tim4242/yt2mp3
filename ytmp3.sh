#!/bin/bash

FILE=/home/$USER/Music/songs.txt
packages=("yt-dlp" "id3v2")
mfolder=/home/$USER/Music/
# Check for required packages, and install them if needed.
for pkg in ${packages[@]}; do

    is_pkg_installed=$(dpkg-query -W --showformat='${Status}\n' ${pkg} | grep "install ok installed")

    if [ "${is_pkg_installed}" == "install ok installed" ]; then
        echo ${pkg} is installed.
    else
    	sudo apt install -y ${pkg} 
    fi
done
cd $mfolder

if test -f "$FILE"; then
    echo "$FILE exists. Continuing..."
else 
	touch $FILE
	echo "$FILE file created"
fi

function enter_song_data() {
    url=$(zenity --entry --text "Enter video URL:")
    artist=$(zenity --entry --text "Enter artist name:")
    track=$(zenity --entry --text "Enter track name:")

    artist=($artist)
    artist="${artist[@]^}"
    track=($track)
    track="${track[@]^}"
	if [ -d "/home/$USER/Music/$artist/" ] 
		then
    	echo "Folder for $artist exists."
    	cd $artist
   	else
    	echo "Error: Folder for $artist does not exist. Creating folder now."
    	mkdir $artist
    	cd $artist
	fi
    yt-dlp --extract-audio --audio-format mp3 -o "$artist - $track.mp3" $url
    id3v2 -a "$artist" -t "$track" "$artist - $track.mp3"
    cd $mfolder
}

function download_from_data_file() {
    #file_path=$(zenity --file-selection --title="Select data file:")
	file_path=$FILE
    while read line; do
        IFS=$',' read -r url artist track <<< "$line"
        	if [ -d "/home/$USER/Music/$artist/" ] 
			then
    			echo "Folder for $artist exists."
   			else
    			echo "Error: Folder for $artist does not exist. Creating folder now."
    			mkdir $artist
			fi
        yt-dlp --extract-audio --audio-format mp3 -o /home/$USER/Music/$artist/"$artist - $track.mp3" $url
        id3v2 -a "$artist" -t "$track" "/home/$USER/Music/$artist/$artist - $track.mp3"
    done < "$file_path"

    echo -n "" > $file_path
}

function add_to_data_file() {
    url=$(zenity --entry --text "Enter video URL:")
    artist=$(zenity --entry --text "Enter artist name:")
    song=$(zenity --entry --text "Enter song name:")

    artist=($artist)
    artist="${artist[@]^}"
    song=($song)
    song="${song[@]^}"

    echo "$url,$artist,$song" >> songs.txt
    echo "Song added to list."

    #input="songs.txt"
    while read line; do
        IFS=$',' read -r url artist song <<< "$line"
        zenity --info --text "$url $artist $song"
    done < "$FILE"
}

while true; do
    choice=$(zenity --list \
        --title "Song Downloader" \
        --text "Choose an option:" \
        --radiolist \
        --column "" --column "Option" \
        TRUE "Enter song data manually" \
        FALSE "Download from data file" \
        FALSE "Add to data file")

    case $choice in
        "Enter song data manually")
            enter_song_data
            ;;
        "Download from data file")
            download_from_data_file
            ;;
        "Add to data file")
            add_to_data_file
            ;;
        *)
            exit
            ;;
    esac
done
