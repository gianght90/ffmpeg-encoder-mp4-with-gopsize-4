#!/bin/bash
SOURCE_DIR=$1
DEST_DIR=$2
if [[ $SOURCE_DIR == "" ]]; then
  read -p "Enter the input SOURCE DIR: " SOURCE_DIR
fi
if [[ $DEST_DIR == "" ]]; then
  read -p "Enter the input DEST DIR: " DEST_DIR
fi

mkdir -p "$DEST_DIR"

for input in "$SOURCE_DIR"/*.mp4; do
    filename=$(basename "$input")
    echo "🔍 Processing: $filename"

    fps=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate \
        -of default=noprint_wrappers=1:nokey=1 "$input" | awk -F/ '{ printf "%.3f", $1/$2 }')

    gop=$(awk -v fps="$fps" 'BEGIN { printf "%d", fps * 4 }')


    bitrate=$(ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate \
        -of default=noprint_wrappers=1:nokey=1 "$input")

    if [[ -z "$bitrate" ]]; then
        continue
    fi

    output="$DEST_DIR/${filename%.*}_gop4.mp4"

    ffmpeg -i "$input" -c:v libx264 -b:v "$bitrate" -preset slow \
        -x264-params "keyint=$gop:min-keyint=$gop:scenecut=0" \
        -c:a copy -movflags +faststart "$output"
done
