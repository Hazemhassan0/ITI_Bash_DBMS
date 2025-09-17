#!/bin/bash

# ========== Tables Management ==========
# Author: Beshoy Botros Hanna
# Responsibilities:
# - Create Table.
# - List Tables.
# - Drop Table.
# - Handles schema storage (.meta file).
# - Validates table.

# Create Table

create_table() {
    read -p "Enter table name: " tname
    if [[ -z "$tname" || "$tname" =~ [^a-zA-Z0-9_] ]]; then
        echo "Invalid table name. Use only letters, numbers, underscores."
        return
    fi

    if [[ -f "$DB_DIR/$tname.meta" ]]; then
        echo "Table '$tname' already exists."
        return
    fi

    read -p "Enter number of columns: " cols
    if ! [[ "$cols" =~ ^[0-9]+$ ]] || [[ "$cols" -le 0 ]]; then
        echo "Invalid column count."
        return
    fi

    schema=""
    for (( i=1; i<=cols; i++ )); do
        read -p "Enter name of column $i: " colname
        read -p "Enter datatype (int/string) for $colname: " coltype
        schema+="$colname:$coltype,"
    done

    schema=${schema%,}  # remove the last comma
    echo "$schema" > "$DB_DIR/$tname.meta"
    touch "$DB_DIR/$tname.data"

    echo "Table '$tname' created with schema: $schema"
}

# List Tables
list_tables() {
    echo "Tables in database:"

    for meta_file in "$DB_DIR"/*.meta; do

        [[ -e "$meta_file" ]] || { echo "No tables found."; return; }

        tname=$(basename "$meta_file" .meta)

        schema=$(head -n 1 "$meta_file")

        echo "Table: $tname | Schema: $schema"
    done
}
# Drop Table
drop_table() {
    read -p "Enter table name to drop: " tname
    if [[ ! -f "$DB_DIR/$tname.meta" ]]; then
        echo "Table '$tname' does not exist."
        return
    fi

    rm "$DB_DIR/$tname.meta" "$DB_DIR/$tname.data"
    echo "Table '$tname' dropped."
}


main_tb_menu(){

    while true; do
        echo "==============================="
        echo "       Tables operations       "
        echo "==============================="
        echo "========== Main Menu =========="
        echo "==============================="

        echo "1. create table."
        echo "2. list tables."
        echo "3. delete tables."

        read -p "Enter your choice: " choice
        case $choice in
            1) create_table ;;
            2) list_tables ;;
            3) drop_table ;;
            *) echo "Invalid choice. Please try again." ;;
        esac
    done
}

# main_tb_menu