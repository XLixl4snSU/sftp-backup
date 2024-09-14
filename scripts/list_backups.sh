#!/bin/bash

# ------- Helper Functions:--------
# Import Output Functions

. /home/scripts/global_functions.sh

json_list_existing_backups() {
    json_list=()
    for d in $dest_folder*; do
        if [ -d "$d" ] && [[ $d =~ ^.*/[[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2}$ ]]; then
            folder_name=$(du -sh $d | awk -F" +|/" '{print $NF}')
            folder_path="$d"
            readable_date=$(convert_date_to_readable $(du -sh $d | awk -F" +|/" '{print $NF}'))
            total_size=$(du -sh $d | awk '{print $1;}')
            json_string=$( jq -n \
                    --arg fn "$folder_name" \
                    --arg fp "$folder_path" \
                    --arg rd "$readable_date" \
                    --arg sz "$total_size" \
                    '{folderName: $fn, folderPath: $fp, readableDate: $rd, totalSize: $sz}' )
            json_list+=($json_string)
        fi
    done

    printf "%s\n" "${json_list[@]}" > /etc/OliveTin/backup_list.json
}

json_list_logfile_dates() {
    log_date_list=()
    pattern="(.*)([[:digit:]]{4}-[[:digit:]]{2}-[[:digit:]]{2})(.*)"
    for f in /config/logs/*; do
        if [[ $f =~ $pattern ]]; then
            log_date_list+=(${BASH_REMATCH[2]})
        fi
    done
    sorted_unique_log_date_list=($(echo "${log_date_list[@]}" | tr ' ' '\n' | sort -ur | tr '\n' ' '))
    json_logfile_list=()
    for d in "${sorted_unique_log_date_list[@]}" ; do
        readable_date=$(convert_date_to_readable $d)
        json_logfile_string=$( jq -n \
                    --arg date "$d" \
                    --arg rd "$readable_date" \
                    '{date: $date, readable_log_Date: $rd}' )
        json_logfile_list+=($json_logfile_string)
    done
    printf "%s\n" "${json_logfile_list[@]}" > /etc/OliveTin/logfile_list.json
}

json_list_logfile_dates & json_list_existing_backups
wait