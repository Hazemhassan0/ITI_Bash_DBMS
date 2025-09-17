#!/bin/bash

# ========== Update & Delete Operations ==========
# Author: Ahmed Gamal
# Responsibilities:
# - Update rows in a table (with WHERE condition)
# - Delete rows from a table (with WHERE condition)


# ============================================================
# Purpose:
#   - let user choose a column to update, enter a new value , apply changes to rows that match 
# ============================================================

update_rows() {

    if [[ -z "$TABLE_NAME" ]]; then
        echo "error: no table selected. please select a table first."
        return
    fi

    meta_file="$DB_DIR/$TABLE_NAME.meta"
    data_file="$DB_DIR/$TABLE_NAME.data"

    if [[ ! -f "$meta_file" || ! -f "$data_file" ]]; then
        echo "error: table '$TABLE_NAME' does not exist."
        return
    fi


    schema=$(cat "$meta_file")
    IFS=',' read -r -a columns <<< "$schema"

    echo "available columns:"
    for i in "${!columns[@]}"; do
        cname=$(echo "${columns[$i]}" | cut -d':' -f1)
        echo "$((i+1)). $cname"
    done

    read -p "enter column name to update: " update_col
    read -p "enter new value: " new_val
    read -p "enter WHERE column name: " where_col
    read -p "enter WHERE value: " where_val


    update_index=-1
    where_index=-1

    for i in "${!columns[@]}"; do
        cname=$(echo "${columns[$i]}" | cut -d':' -f1)
        if [[ "$cname" == "$update_col" ]]; then update_index=$i; fi
        if [[ "$cname" == "$where_col" ]]; then where_index=$i; fi
    done

    if [[ $update_index -eq -1 || $where_index -eq -1 ]]; then
        echo "error: invalid column name."
        return
    fi

    tmp_file=$(mktemp)
    updated=false


    while IFS=',' read -r -a row; do

        if [[ "${row[$where_index]}" == "$where_val" ]]; then
            row[$update_index]="$new_val"
            updated=true
        fi

        echo "${row[*]}" | sed 's/ /,/g' >> "$tmp_file"
    done < "$data_file"

    mv "$tmp_file" "$data_file"

    if $updated; then
        echo "rows updated successfully."
    else
        echo "no rows matched the condition."
    fi
}

# ============================================================
# Purpose:
#   - remove rows from a table based on a WHERE match
# ============================================================
delete_rows() {

    if [[ -z "$TABLE_NAME" ]]; then
        echo "error: no table selected. please select a table first."
        return
    fi

    meta_file="$DB_DIR/$TABLE_NAME.meta"
    data_file="$DB_DIR/$TABLE_NAME.data"


    if [[ ! -f "$meta_file" || ! -f "$data_file" ]]; then
        echo "error: table '$TABLE_NAME' does not exist."
        return
    fi


    schema=$(cat "$meta_file")
    IFS=',' read -r -a columns <<< "$schema"


    echo "available columns:"
    for i in "${!columns[@]}"; do
        cname=$(echo "${columns[$i]}" | cut -d':' -f1)
        echo "$((i+1)). $cname"
    done


    read -p "enter WHERE column name: " where_col
    read -p "enter WHERE value: " where_val


    where_index=-1
    for i in "${!columns[@]}"; do
        cname=$(echo "${columns[$i]}" | cut -d':' -f1)
        if [[ "$cname" == "$where_col" ]]; then where_index=$i; fi
    done


    if [[ $where_index -eq -1 ]]; then
        echo "error: invalid WHERE column."
        return
    fi

    tmp_file=$(mktemp)
    deleted=false


    while IFS=',' read -r -a row; do

        if [[ "${row[$where_index]}" == "$where_val" ]]; then
            deleted=true
            continue
        fi

        echo "${row[*]}" | sed 's/ /,/g' >> "$tmp_file"
    done < "$data_file"

    mv "$tmp_file" "$data_file"

    if $deleted; then
        echo "rows deleted successfully."
    else
        echo "no rows matched the condition."
    fi
}
