# AudioFileManagement
e.g. conversion of .wav to .mp3

## convert_wav_to_mp3.sh
Convert all .wav files in a named folder to .mp3 and store them in a sub-directory named `mp3`.

Usage:
```
chmod +x convert_wav_to_mp3.sh
dir=/path/to/folder
./convert_wav_to_mp3.sh $dir$
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
## split_mp3_file.sh
Split a single mp3 into N equal parts (approx.). Defaults to 4 parts and writes files to a `split` folder next to the input file.

Usage:
```
chmod +x split_mp3_file.sh
./split_mp3_file.sh x.mp3
./split_mp3_file.sh x.mp3 -n 6 --outdir parts
```

Options:
- `-n` / `--parts` — number of parts to split into (default 4)
- `--outdir` — output folder name (default: `split`)
- `--no-force` — do not overwrite existing files; script will skip those

Output:
Files will be created as `x-1.mp3`, `x-2.mp3`, ... in the output folder.

---

## AudioFileManagement — Quick Reference ✅

A small collection of shell scripts for common audio tasks using `ffmpeg`.

### Included scripts
- **change_track_speed.sh** — change playback speed of an audio track (supports chaining `atempo` filters when needed).
- **convert_mp4_to_mp3.sh** — convert a single `.mp4` to `.mp3`.
- **convert_wav_to_mp3.sh** — convert all `.wav` files in a folder to `.mp3` (supports VBR/CBR, recursion).
- **split_audio_file.sh** — split any audio file into N equal parts.
- **split_mp3_file.sh** — split a single `.mp3` into N parts (outputs into `split/` folder).

### Requirements
- `ffmpeg` (with `libmp3lame` for MP3 encoding)
- A POSIX-compatible shell (Bash recommended)
- On Windows: run from WSL or place files under `/mnt/*` for easiest use

> ⚠️ Note: `convert_wav_to_mp3.sh` checks for `libmp3lame` and will fail if your `ffmpeg` build lacks the MP3 encoder.

### Quick usage examples

- change_track_speed.sh
```
./change_track_speed.sh input.mp3 [speed] [output.mp3]
# Examples:
./change_track_speed.sh track.mp3 0.7 slowed.mp3
./change_track_speed.sh track.mp3 1.25      # auto-generates track_1.25x.mp3
```

- convert_mp4_to_mp3.sh
```
./convert_mp4_to_mp3.sh video.mp4
# -> output: video.mp3
```

- convert_wav_to_mp3.sh
```
./convert_wav_to_mp3.sh /path/to/folder --recursive -b 192k --no-vbr
# -> output in /path/to/folder/mp3/
```

- split_audio_file.sh
```
./split_audio_file.sh lesson.mp3 4
# -> lesson_01.mp3, lesson_02.mp3, ...
```

### Tips & Troubleshooting
- If you see errors about missing encoders, install a full `ffmpeg` build (e.g., `apt install ffmpeg` on Debian/Ubuntu or download a static build).
- For Windows users, WSL is the simplest way to use these Bash scripts against local files.
- Scripts typically overwrite outputs unless explicitly disabled with options like `--no-force`.

### Contributing / License
- Contributions welcome — PRs and issues are appreciated.
- Add a `LICENSE` file if you want to attach a license (MIT is common for utility scripts).



