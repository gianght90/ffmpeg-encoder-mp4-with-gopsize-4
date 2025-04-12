$sourceFolder = ""
$destFolder = ""

if (!(Test-Path $destFolder)) {
    New-Item -ItemType Directory -Path $destFolder
}

Get-ChildItem -Path $sourceFolder -Filter *.mp4 | ForEach-Object {
    $input = $_.FullName
    $filename = $_.BaseName
    $output = Join-Path $destFolder "$filename`_gop4.mp4"

    Write-Host "🚀 Processing: $input"

    $fpsRaw = ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate `
              -of default=noprint_wrappers=1:nokey=1 "$input"
    $fps = [math]::Round(([double]($fpsRaw.Split("/")[0]) / [double]($fpsRaw.Split("/")[1])), 2)
    $gop = [math]::Round($fps * 4)
    Write-Host "🎯 FPS: $fps → GOP size: $gop frames"

    $bitrate = ffprobe -v error -select_streams v:0 -show_entries stream=bit_rate `
                -of default=noprint_wrappers=1:nokey=1 "$input"

    if (-not $bitrate) {
        return
    }

    # Encode use FFmpeg + NVIDIA GPU
    ffmpeg -y -hwaccel cuda -i "$input" `
        -c:v h264_nvenc -b:v $bitrate `
        -preset slow `
        -rc cbr `
        -g $gop -forced-idr 1 -sc_threshold 0 `
        -c:a copy -movflags +faststart `
        "$output"
}
