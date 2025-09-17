#!/bin/bash

# Importing modules
source ./tables.sh
source ./insert.sh
source ./update.sh

# ========== Database Management ==========
# Author: Hazem Abdelnasser  
# Responsibilities:
# - Main menu
# - Create/List/Drop/Connect databases
# - DB Folder structure setup

DB_PATH="./databases"

mkdir -p "$DB_PATH"

create_db() {
    read -p "Enter the new database name please: " db_name

    if [[ -z "$db_name" ]]; then
        echo "Error: Database name cannot be empty."
        return
    fi
    if [[ "$db_name" =~ [^a-zA-Z0-9_] ]]; then
        echo "Error: Database name can only contain letters, numbers, and underscores."
        return
    fi

    if [[ -d "$DB_PATH/$db_name" ]]; then
        echo "Error: Database '$db_name' already exists."
    else
        mkdir -p "$DB_PATH/$db_name"
        echo "Database '$db_name' was created successfully."
    fi



}

list_dbs() {
    echo "Available Databases:"
    if [ -z "$(ls "$DB_PATH")" ]; then
        echo "No databases found."
    else
        ls "$DB_PATH"
    fi
}

drop_db() {
    read -p "Enter the database name you want to drop: " db_name

    if [[ -z "$db_name" ]]; then
        echo "Error: Database name cannot be empty."
        return
    fi

    if [[ -d "$DB_PATH/$db_name" ]]; then
        rm -rf "$DB_PATH/$db_name"
        echo "Database '$db_name' was dropped successfully."
    else
        echo "Error: Database '$db_name' does not exist."
    fi
}


connect_db() {
    read -p "Enter the database name you want to connect to: " db_name

    if [[ -z "$db_name" ]]; then
        echo "Error: Database name cannot be empty."
        return
    fi

    if [[ -d "$DB_PATH/$db_name" ]]; then
        echo "Connected to database '$db_name'."
        DB_DIR="$DB_PATH/$db_name" # variable to hold the current database path, export if needed or just pass it to functions
        export $DB_DIR
        main_tb_menu    #  ya beshooo Call the database menu function from tables.sh
    else
        echo "Error: Database '$db_name' does not exist."
    fi
}

main_menu() {
    while true; do
        clear
        echo "=============================="
        echo "========== Main Menu ========="
        echo "=============================="

        echo "1. Create Database"
        echo "2. List Databases"
        echo "3. Drop Database"
        echo "4. Connect to Database"
        echo "5. Exit"
        read -p "Choose an option (1-5): " choice

        case $choice in
            1) 
                clear
                create_db
                read -p "Press Enter to continue..." ;;
            2) 
                clear
                list_dbs 
                read -p "Press Enter to continue..." ;;
            3) 
                clear
                drop_db 
                read -p "Press Enter to continue..." ;;
            4) 
                clear
                connect_db
                read -p "Press Enter to continue..."  ;;
            5) echo "Exiting..."; exit 0 ;;
            *) echo "Invalid option. Please try again (if you want to exit, choose 5 ,please)."
                read -p "Press Enter to continue..."   ;;
        esac
    done
}

# initialize program
clear
echo "=============================="
echo " Database Management System"
main_menu