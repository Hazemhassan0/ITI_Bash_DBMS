    #!/bin/bash

    # ========== Tables Management ==========
    # Author: Beshoy Botros Hanna
    # Responsibilities:
    # - Create Table.
    # - List Tables.
    # - Drop Table.
    # - Handles schema storage (.meta file).
    # - Validates table.

    source ./table_options.sh

    # Create Table

    create_table() {
        read -p "Enter table name: " tname
        if [[ -z "$tname" || "$tname" =~ [^a-zA-Z0-9_] ]]; then
            echo "Invalid table name. Use only letters, numbers, underscores."
            return
        fi

        target_meta="$DB_DIR/$tname.meta"
        target_data="$DB_DIR/$tname.data"

        # do not overwrite existing table
        if [[ -e "$target_meta" || -e "$target_data" ]]; then
            echo "Table '$tname' already exists." >&2
            return 
        fi

        read -p "Enter number of columns: " cols
        # positive integer only
        if ! [[ "$cols" =~ ^[1-9][0-9]*$ ]]; then
            echo "Invalid column count. Must be a positive integer." >&2
            return 
        fi

        schema=""
        for (( i=1; i<=cols; i++ )); do
            # loop until a valid column name is provided
            while true; do
                read -p "Enter name of column $i: " colname
                if [[ "$colname" =~ ^[A-Za-z0-9_]+$ ]]; then
                    break
                fi
                echo "Invalid column name. Use only letters, numbers, underscores."
            done

            # loop until a valid datatype is provided (accepts 'int' or 'string')
            while true; do
                read -p "Enter datatype (int/string) for $colname: " coltype
                coltype="${coltype,,}"   # ya Beshoo we use this to convert the "coltype" to lowercase  ex:  Int ---> int
                if [[ "$coltype" =~ ^(int|string)$ ]]; then
                    break
                fi
                echo "Invalid datatype. Please enter 'int' or 'string'."
            done

            if [[ $i -eq 1 ]]; then
                # first column is PRIMARY KEY
                schema+="$colname:$coltype:PK,"
                echo "Note: Column '$colname' is set as PRIMARY KEY."
            else
                schema+="$colname:$coltype,"
            fi
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

    # Select table

    select_table() {
        echo "Available tables:"
        local tables=()

        # collect all table names
        for meta_file in "$DB_DIR"/*.meta; do
            [[ -e "$meta_file" ]] || { echo "No tables found."; return; }
            tables+=( "$(basename "$meta_file" .meta)" )
        done

        # show menu
        select tname in "${tables[@]}"; do
            if [[ -n "$tname" ]]; then
                TABLE_NAME="$tname"
                export TABLE_NAME
                table_ops_menu
                return
            else
                echo "Invalid choice. Try again."
            fi
        done
    }


    # main_tb_menu

    main_tb_menu() {
        while true; do
            clear
            echo "==============================="
            echo "       Tables operations       "
            echo "==============================="
            echo "DB Name: $(echo "$DB_DIR" | awk -F/ '{print $NF}')"
            echo "==============================="

            echo "1. Create table."
            echo "2. List tables."
            echo "3. Delete table."
            echo "4. Select table."
            echo "5. Exit"

            read -p "Enter your choice: " choice
            case $choice in
                1) 
                    clear
                    create_table 
                    read -p "Press Enter to continue..." ;;
                2) 
                    clear
                    list_tables 
                    read -p "Press Enter to continue..." ;;
                3) 
                    clear
                    drop_table 
                    read -p "Press Enter to continue..." ;;
                4) 
                    clear
                    select_table
                    read -p "Press Enter to continue..." ;;
                5) break ;;
                *) 
                    echo "Invalid choice. Please try again."
                    sleep 1 ;;
            esac
        done
    }



