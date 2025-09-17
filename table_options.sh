#!/bin/bash

# ========== Table Operations ==========
# Author: Hossam Ahmed Elleithy
# Responsibilities:
# - Select rows from table (with column filtering and WHERE condition)
# - Insert rows into table (PK uniqueness check, NULL handling)
# Friendly notes:
#   - Beshoo : I made some modifications in ' create_table() ' func to be more efficient & I add ' Select table ' in your ' main_tb_menu() '  func to connect to my file to make operations 

# ===============================
# Function: select_from_table
# Purpose: Show data from the table, with optional filters
# ===============================

source ./update.sh

select_from_table() {
    # First, check if user even selected a table
    if [[ -z "$TABLE_NAME" ]]; then
        echo "Error: No table selected. Please select a table first."
        return
    fi

    # Paths for schema (.meta) and data (.data)
    meta_file="$DB_DIR/$TABLE_NAME.meta"
    data_file="$DB_DIR/$TABLE_NAME.data"

    # If either file doesn’t exist → the table isn’t real
    if [[ ! -f "$meta_file" || ! -f "$data_file" ]]; then
        echo "Error: Table '$TABLE_NAME' does not exist."
        return
    fi

    # =======================
    # Load schema (columns)
    # =======================
    schema=$(cat "$meta_file")
    IFS=',' read -r -a columns <<< "$schema"   # split schema by commas into array

    echo "Table columns: "
    for i in "${!columns[@]}"; do
        # Each column looks like: name:type:constraint
        cname=$(echo "${columns[$i]}" | cut -d':' -f1)
        echo "$((i+1)). $cname"   # show numbered column names
    done

    # Ask which columns the user wants to see
    read -p "Enter column numbers to retrieve (comma-separated, or * for all): " col_choice

    if [[ "$col_choice" == "*" ]]; then
        # Select all columns
        selected_cols=("${!columns[@]}")
    else
        # Split user input into array
        IFS=',' read -r -a selected_cols <<< "$col_choice"
        # Validate: must be numbers and inside column range
        for i in "${selected_cols[@]}"; do
            if ! [[ "$i" =~ ^[0-9]+$ && $i -ge 1 && $i -le ${#columns[@]} ]]; then
                echo "Invalid column selection."
                return
            fi
        done
    fi

    # =======================
    # Optional WHERE condition
    # =======================
    read -p "Do you want to add a WHERE condition? (y/n): " add_where
    where_col=""
    where_val=""
    if [[ "$add_where" == "y" ]]; then
        read -p "Enter column name for condition: " where_col
        read -p "Enter value to match: " where_val
    fi

    echo "---- Results ----"
    # =======================
    # Read each row from .data
    # =======================
    while IFS=',' read -r -a row; do
        # Handle WHERE condition if user added one
        if [[ -n "$where_col" ]]; then
            match_index=-1
            for i in "${!columns[@]}"; do
                cname=$(echo "${columns[$i]}" | cut -d':' -f1)
                if [[ "$cname" == "$where_col" ]]; then
                    match_index=$i
                    break
                fi
            done
            if [[ $match_index -eq -1 ]]; then
                echo "Invalid WHERE column."
                return
            fi
            # If this row doesn’t match → skip it
            if [[ "${row[$match_index]}" != "$where_val" ]]; then
                continue
            fi
        fi

        # =======================
        # Print selected columns
        # =======================
        out=""
        for i in "${selected_cols[@]}"; do
            if [[ "$col_choice" == "*" ]]; then
                idx=$i
            else
                idx=$((i-1))   # adjust for human input (1-based)
            fi
            out+="${row[$idx]} | "
        done
        echo "${out% | }"   # trim the last pipe
    done < "$data_file"
}

# ===============================
# Function: insert_into_table
# Purpose: Add a new row into the table
# ===============================
insert_into_table() {
    if [[ -z "$TABLE_NAME" ]]; then
        echo "Error: No table selected. Please select a table first."
        return
    fi

    meta_file="$DB_DIR/$TABLE_NAME.meta"
    data_file="$DB_DIR/$TABLE_NAME.data"

    if [[ ! -f "$meta_file" || ! -f "$data_file" ]]; then
        echo "Error: Table '$TABLE_NAME' does not exist."
        return
    fi

    # Load schema
    schema=$(cat "$meta_file")
    IFS=',' read -r -a columns <<< "$schema"
    new_row=()

    # Ask for each column value
    for i in "${!columns[@]}"; do
        colname=$(echo "${columns[$i]}" | cut -d':' -f1)
        coltype=$(echo "${columns[$i]}" | cut -d':' -f2)
        constraint=$(echo "${columns[$i]}" | cut -d':' -f3)

        read -p "Enter value for column '$colname' ($coltype): " value

        # =======================
        # Primary Key checks
        # =======================
        if [[ "$constraint" == "PK" ]]; then
            # Duplicate check (first value in line must be unique)
            if grep -q "^$value," "$data_file"; then
                echo "Error: Duplicate primary key '$value'."
                return
            fi
            # NULL check
            if [[ -z "$value" ]]; then
                echo "Error: Primary key cannot be NULL."
                return
            fi
        fi

        # =======================
        # Type validation
        # =======================
        if [[ -n "$value" ]]; then
            if [[ "$coltype" == "int" && ! "$value" =~ ^[0-9]+$ ]]; then
                echo "Error: Column '$colname' must be an integer."
                return
            fi
        else
            # If user didn’t enter anything → save NULL
            value="NULL"
        fi

        # Add value to the new row array
        new_row+=("$value")
    done

    # Join values with commas and save to .data file
    echo "${new_row[*]}" | sed 's/ /,/g' >> "$data_file"
    echo "Row inserted successfully."
}

# ===============================
# Submenu: Table Operations Menu
# ===============================
table_ops_menu() {
    while true; do
        clear
        echo "==============================="
        echo "     Table Operations Menu     "
        echo "==============================="
        echo "Table: $TABLE_NAME"
        echo
        echo "1. Select from table"
        echo "2. Insert into table"
        echo "3. Update rows"
        echo "4. Delete rows"
        echo "5. Back"
        read -p "Choose an option: " choice

        case $choice in
            1) clear; select_from_table; read -p "Press Enter to continue..." ;;
            2) clear; insert_into_table; read -p "Press Enter to continue..." ;;
            3) clear; update_rows; read -p "Press Enter to continue..." ;;
            4) clear; delete_rows; read -p "Press Enter to continue..." ;;
            5) break ;;
            *) echo "Invalid choice."; sleep 1 ;;
        esac
    done
}
