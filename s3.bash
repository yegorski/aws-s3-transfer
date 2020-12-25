#!/usr/bin/env bash

buckets=()

read_bucket_list() {
    declare source_bucket_list="${1}"
    while read -r arg; do
        if [[ -z "${arg}" || "${arg}" =~ ^#.*$ ]]; then
            continue # skip empty lines and comments
        fi
        buckets+=("${arg}")
    done < ${source_bucket_list}.txt
}

backup_all_buckets() {
    declare source_bucket_list="${1}"
    read_bucket_list ${source_bucket_list}
    for bucket in ${buckets[@]}; do
        backup_bucket ${bucket}
    done
}

backup_bucket() {
    declare source_bucket="${1}"
    aws s3 sync s3://${source_bucket} s3://DESTINATOIN_BUCKET/${source_bucket} &> ${source_bucket}.log
}

"$@"
