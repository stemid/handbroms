#!/usr/bin/env bash

if [ ${BASH_VERSION:0:3} != "4.3" ]; then
    echo "Must use Bash v4.3 for background job processing (wait -n)" 1>&2
    exit 1
fi

hbcmd=$(which "HandBrakeCLI")
h_rc=$?
test $h_rc -ne 0 && exit $h_rc

etcmd=$(which "exiftool")
e_rc=$?
test $e_rc -ne 0 && exit $e_rc

proc_count=0
max_proc_count=4

strip_space() {
    str="$1"

    _str="${str/# /}"
    _str="${_str/% /}"

    echo $_str
}

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

process_file() {
    file=$1 && shift

    filetype=$(get_filetype "$file")
    test $? -ne 0 && return 1

    if [ "$filetype" = "MKV" ]; then
        basedir=$(dirname "$file")
        _filename=$(basename -s .mkv "$file")
        new_file=$_filename.mp4
        srtfile="$basedir/$_filename.srt"

        if [ -f "$srtfile" ]; then
            srtarg="--srt-file \"$srtfile\""
        else
            srtarg=''
        fi

        local_log="$basedir/handbrake.log"

        echo "Starting HandBrakeCLI for $file [$!]"
        $hbcmd -i "$file" -o "$basedir/$new_file" --encoder x264  --optimize $srtarg &> "$local_log"

        if [ $? -eq 0 ]; then
            mv "$local_log" "$local_log.done"
        fi
    fi
}

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
