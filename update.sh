#!/bin/bash

# ========== Update & Delete Operations ==========
# Author: Ahmed Gamal
# Responsibilities:
# - Update rows in a table (with WHERE condition)
# - Delete rows from a table (with WHERE condition)


# ============================================================
# Function: update_rows
# Purpose:
#   - let user update columns, enter a new value,
#     apply changes to rows that match the WHERE condition
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

    coltype=$(echo "${columns[$update_index]}" | cut -d':' -f2)
    constraint=$(echo "${columns[$update_index]}" | cut -d':' -f3)

    if [[ -z "$new_val" ]]; then
        new_val="NULL"
    fi

    if [[ "$coltype" == "int" && "$new_val" != "NULL" && ! "$new_val" =~ ^[0-9]+$ ]]; then
        echo "error: column '$update_col' must be an integer."
        return
    fi

    if [[ "$constraint" == "PK" ]]; then
        if [[ "$new_val" == "NULL" ]]; then
            echo "error: primary key cannot be NULL."
            return
        fi
        if grep -q "^$new_val," "$data_file"; then
            echo "error: duplicate primary key '$new_val'."
            return
        fi
    fi

    tmp_file=$(mktemp)
    updated=0

    while IFS=',' read -r -a row; do
        if [[ "${row[$where_index]}" == "$where_val" ]]; then
            row[$update_index]="$new_val"
            ((updated++))
        fi
        echo "${row[*]}" | sed 's/ /,/g' >> "$tmp_file"
    done < "$data_file"

    mv "$tmp_file" "$data_file"

    if [[ $updated -eq 0 ]]; then
        echo "no rows matched the condition."
    else
        echo "$updated row(s) updated successfully."
    fi
}


# ============================================================
# Function: delete_rows
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
    deleted=0

    while IFS=',' read -r -a row; do
        if [[ "${row[$where_index]}" == "$where_val" ]]; then
            ((deleted++))
            continue
        fi
        echo "${row[*]}" | sed 's/ /,/g' >> "$tmp_file"
    done < "$data_file"

    mv "$tmp_file" "$data_file"

    if [[ $deleted -eq 0 ]]; then
        echo "no rows matched the condition."
    else
        echo "$deleted row(s) deleted successfully."
    fi
}
