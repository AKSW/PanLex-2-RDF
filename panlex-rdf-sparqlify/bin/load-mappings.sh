#!/bin/bash
shopt -s nullglob
source config.ini

filenames=$@

dir="$( cd "$( dirname "$0" )" && pwd )"

psql $psql_options -f "$dir/schema-links.sql"


for filename in $filenames; do
    echo "Loading: $filename"
    # Make the file unique
    #tmpFile="$filename"
    tmpFile=`tempfile`
    uniq -u $dir/$filename >> $tmpFile

    psql $psql_options -c "COPY links_dbpedia FROM '$tmpFile'"
    rm "$tmpFile"
done

