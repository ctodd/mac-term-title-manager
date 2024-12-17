#!/bin/zsh

# Debug function to print debug messages
debug() {
    echo "[DEBUG] $1" >&2
}

# Path to the SQLite database
DB_PATH="$HOME/.ssh_project_mapping.db"

# Initialize database
initialize_db() {
    debug "Initializing SQLite database at $DB_PATH..."
    if [[ ! -f "$DB_PATH" ]]; then
        debug "Database does not exist. Creating it now."
        sqlite3 "$DB_PATH" <<-EOF
        CREATE TABLE IF NOT EXISTS projects (
            hostname TEXT PRIMARY KEY,
            project_name TEXT
        );
EOF
    fi
}

# Get or create a project name for a hostname
get_project_name() {
    local hostname="$1"
    local project_name
    local project_choice
    
    debug "Querying database for project mapping..."
    project_name=$(sqlite3 "$DB_PATH" "SELECT project_name FROM projects WHERE hostname = '$hostname';")
    
    if [[ $? -ne 0 ]]; then
        debug "Error querying the database for hostname: $hostname"
        echo "Error: Could not query the database." >&2
        return 1
    fi
    
    if [[ -z "$project_name" ]]; then
        debug "No project mapping found for $hostname"
        
        # Get existing projects from the database
        local existing_projects
        existing_projects=($(sqlite3 "$DB_PATH" "SELECT DISTINCT project_name FROM projects;"))
        
        if [[ ${#existing_projects[@]} -gt 0 ]]; then
            echo "Existing projects:" >&2
            local i
            for i in {1..${#existing_projects[@]}}; do
                echo "$i) ${existing_projects[$((i-1))]}" >&2
            done
            echo "0) Enter a new project name" >&2
            echo -n "Select a project (0-${#existing_projects[@]}): " >&2
            read -r project_choice
            
            if [[ "$project_choice" -gt 0 ]] && [[ "$project_choice" -le ${#existing_projects[@]} ]]; then
                project_name="${existing_projects[$((project_choice-1))]}"
            fi
        fi
        
        # Prompt for new project name if needed
        if [[ -z "$project_name" ]]; then
            echo -n "Enter a new project name: " >&2
            read -r project_name
            
            if [[ -z "$project_name" ]]; then
                debug "No project name entered"
                echo "Error: No project name entered." >&2
                return 1
            fi
        fi
        
        # Save the new mapping
        debug "Saving new mapping: $hostname -> $project_name"
        if ! sqlite3 "$DB_PATH" "INSERT INTO projects (hostname, project_name) VALUES ('$hostname', '$project_name');"; then
            debug "Error inserting new mapping"
            echo "Error: Could not save the new project mapping." >&2
            return 1
        fi
    fi
    
    debug "Retrieved project name: $project_name"
    echo "$project_name"
    return 0
}

# SSH wrapper function
ssh() {
    debug "Entered ssh wrapper function"
    
    # Initialize database if needed
    initialize_db
    
    local hostname=""
    local original_args=("$@")
    
    # Parse arguments to find hostname
    for arg in "$@"; do
        case "$arg" in
            *@*)
                hostname="${arg#*@}"
                debug "Found hostname from user@host: $hostname"
                ;;
            -*)
                continue
                ;;
            *)
                if [[ -z "$hostname" ]]; then
                    hostname="$arg"
                    debug "Found hostname from plain argument: $hostname"
                fi
                ;;
        esac
    done
    
    if [[ -z "$hostname" ]]; then
        echo "Error: No hostname provided." >&2
        return 1
    fi
    
    debug "Getting project name for $hostname"
    local project_name
    project_name=$(get_project_name "$hostname")
    
    if [[ $? -ne 0 ]] || [[ -z "$project_name" ]]; then
        debug "Failed to get project name"
        return 1
    fi
    
    debug "Project name: $project_name"
    
    # Set local terminal title
    printf "\e]0;%s - %s\a" "$project_name" "$hostname"
    debug "Set local terminal title"
    
    # Create remote command using the working declare approach
    local remote_command="declare -x PROMPT_COMMAND=\"printf \\\"\\033]0;$project_name - %s@%s:%s\\007\\\" \\\"\$USER\\\" \\\"\$HOSTNAME\\\" \\\"\$PWD\\\"\"; exec bash"
    
    debug "Remote command: $remote_command"
    
    # Execute SSH command
    debug "Executing SSH command with title updates"
    command ssh "${original_args[@]}" -t "$remote_command"
    printf "\e]0;$PWD\a"  # Both tab and window
    PS1="@%m %1~ %#"
}
