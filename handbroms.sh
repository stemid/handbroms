#!/usr/bin/env bash
# by Stefan Midjich <swehack [at] gmail.com> - 2017

# These values could be changed by users
#
# Max number of HandBrakeCLI processes to run simultaneously.
max_proc_count=4
#
# Subtitle languages to save when converting files with subtitles.
subtitle_languages=swe,dan,eng,hrv,nno
#
#######################################

# Reset proc_count to 0 before starting processes
proc_count=0

# Ensure we're using Bash >= 4.3
if ! (( BASH_VERSINFO[0] > 4 || BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] >= 3 )); then
    echo "Must use Bash v4.3 for background job processing (wait -n)" 1>&2
    exit 1
fi

# Find relevant commands
hbcmd=$(which "HandBrakeCLI")
h_rc=$?
test $h_rc -ne 0 && exit $h_rc

etcmd=$(which "exiftool")
e_rc=$?
test $e_rc -ne 0 && exit $e_rc

# Strip spaces
strip_space() {
    str="$1"

    _str="${str/# /}"
    _str="${_str/% /}"

    echo $_str
}

# Get number of audiochannels, might be useful later but for now HandBrakeCLI
# seems to handle it.
get_audiochannels() {
    file=$1

    output=$($etcmd -AudioChannels "$file" 2>/dev/null)
    test $rc -ne 0 && return 1

    regex='^Audio Channels\s*: ([0-9]+)$'

    if [[ "$output" =~ $regex ]]; then
        echo ${BASH_REMATCH[1]}
    else
        return 1
    fi
}

# Useful to know which types of files to convert.
get_filetype() {
    file=$1

    output=$($etcmd -FileType "$file" 2>/dev/null)
    test $rc -ne 0 && return 1

    regex='^File Type\s*: ([^$]+)$'

    if [[ "$output" =~ $regex ]]; then
        strip_space "${BASH_REMATCH[1]}"
    else
        return 1
    fi
}

# Process a single file.
process_file() {
    file=$1 && shift

    filetype=$(get_filetype "$file")
    test $? -ne 0 && return 1

    if [ "$filetype" = "MKV" ]; then
        basedir=$(dirname "$file")
        _filename=$(basename -s .mkv "$file")
        new_file=$_filename.mp4
        srtfile="$basedir/$_filename.srt"

        srtarg="--subtitle-lang-list $subtitle_languages --all-subtitles "
        if [ -f "$srtfile" ]; then
            srtarg+="--srt-file \"$srtfile\""
        fi

        pid=$BASHPID
        local_log="$basedir/handbrake.$pid.log"

        echo "$(date): Starting HandBrakeCLI for $file [$pid]"
        $hbcmd -i "$file" -o "$basedir/$new_file" --encoder x264  --optimize $srtarg &> "$local_log"

        if [ $? -eq 0 ]; then
            mv "$local_log" "$local_log.done"
        fi
    fi
}

# Recursively process a directory
walk_dir() {
    dir=$1

    for file in "$dir"/*; do
        if [ -f "$file" ]; then
            process_file "$file" &
            ((proc_count++))

            if [ $proc_count -ge $max_proc_count ]; then
                wait -n
                ((proc_count--))
            fi
        fi

        if [ -d "$file" ]; then
            walk_dir "$file"
        fi
    done
}

arg1=$1
rc=0

if [ -d "$arg1" ]; then
    walk_dir "$arg1"
elif [ -f "$arg1" ]; then
    process_file "$arg1"
    rc=$?
fi

exit $rc
