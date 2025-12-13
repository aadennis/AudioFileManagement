# AudioFileManagement
e.g. conversion of .wav to .mp3

## convert_wav_to_mp3.sh
Convert all .wav files in a named folder to .mp3 and store them in a sub-directory named `mp3`.

Usage:
```
chmod +x convert_wav_to_mp3.sh
./convert_wav_to_mp3.sh /path/to/folder
```

Options:
- `-r` / `--recursive`: search subfolders for `.wav` files
- `-b` / `--bitrate <rate>`: set mp3 bitrate (e.g. `192k`, `320k`) — only used when VBR is disabled
- `--vbr`: use libmp3lame VBR highest quality instead (default when `USE_VBR=true` in script)
- `--no-vbr`: use CBR mode with a fixed bitrate
- `--skip-up-to-date`: skip conversion when the target mp3 file exists and is newer than the source wav
- `--no-force`: prevent ffmpeg from overwriting target files (by default script uses -y to overwrite)

Config (top of `convert_wav_to_mp3.sh`):
- `USE_VBR=true` (or false) — If true, uses `-q:a 0` (VBR highest quality); otherwise uses `-b:a MP3_BITRATE`
- `MP3_BITRATE="320k"` — default bitrate when using CBR mode

Output:
Converted files will be placed under `<target>/mp3` with the same basename and `.mp3` extension.

