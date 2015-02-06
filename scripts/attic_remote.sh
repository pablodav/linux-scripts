#!/bin/bash

verbose=
log=
config=
initial=

# FUNCTION DEFINITIONS

usage(){
    cat <<EOF
usage: ${0##*/} OPTIONS
    -c | --config       Config file.
    -o | --outfile      Log file. [optional]
    -v | --verbose      Verbose mode. [optional]
	-I | --initialize	Initialize repository in first run.
EOF
}

if_file_exists(){
    local f="$1"
    [[ -f "$f" ]] && return 0 || return 1
}

if_dir_exists(){
    local d="$1"
    [[ -d "$d" ]] && return 0 || return 1
}

if_var_empty(){
    local v="$1"
    [[ -z "$v" ]] && return 1 || return 0
}

logging(){
    local msg="$(date +%Y-%m-%d\ %H:%M) $1"
    [[ $verbose -eq 1 ]] && echo $msg
    [[ "$log" != "" ]] && echo $msg >> $log
}

cmd_remote(){
    logging "INFO: Executing remote command: $1"
    ssh $host_user@$host_ip $1
    return $?
}

update_repo(){
    logging "INFO: Updating repository status."
    date > $repository/status/update
}

update_host(){
    logging  "INFO: Updated last successful run."
    date > $repository/status/$host_name.last
}

integrity(){
    logging "INFO: Checking repository integrity."
    attic check $repository
    if [[ $? -ne 0 ]]
    then
        rm -f $repository/status/update
        logging "ERROR: Repository broken. Bye."
        exit 1
    else
        logging "INFO: Repository healthy."
    fi
}

initialize(){
	logging "INFO: Initializing repository."
	if_dir_exists $repository
	if [[ $? -eq 0 ]]
	then
		logging "WARN: Repository already exists. Skipping initialization."
	else
		attic init $repository
		if [[ $? -eq 0 ]]
		then
			mkdir $repository/status
			logging "INFO: Repository initialized."
		else
			logging "ERROR: Initialization failed."
			exit 1
		fi
	fi
}

# STARTING PROGRAM

# Display usage if not parameters provided
[[ $# -eq 0 ]] && usage && exit 1

# Parsing parameters
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|-\?|--help)     	# Call a "usage" function to display a syntax, then exit.
            usage
            exit
            ;;
        -c|--config)       	# Takes an option argument, ensuring it has been specified.
            if [ "$#" -gt 1 ]; then
                config=$2
                shift 2
                continue
            else
                echo 'ERROR: Must specify a non-empty "--config FILE" argument.' >&2
                exit 1
            fi
            ;;
        --config=?*)
            config=${1#*=}	# Delete everything up to "=" and assign the remainder.
            ;;
        --config=)          # Handle the case of an empty --file=
            echo 'ERROR: Must specify a non-empty "--config FILE" argument.' >&2
            exit 1
            ;;
		-I|--initialize)
            initial=1
            ;;
        -o|--logfile)    	# Takes an option argument, ensuring it has been specified.
            if [ "$#" -gt 1 ]; then
                log=$2
                shift 2
                continue
            else
                echo 'ERROR: Must specify a non-empty "--logfile FILE" argument.' >&2
                exit 1
            fi
            ;;
        --logfile=?*)
            log=${1#*=}  	# Delete everything up to "=" and assign the remainder.
            ;;
        --logfile=)      	# Handle the case of an empty --logfile=
            echo 'ERROR: Must specify a non-empty "--logfile FILE" argument.' >&2
            exit 1
            ;;
        -v|--verbose)
            verbose=1
            ;;
		-i|--initialize)
            initial=1
            ;;
        --)              	# End of all options.
            shift
            break
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               	# Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

# Check if config file exists
if_file_exists $config
if [[ $? -eq 1 ]]
then
    logging "ERROR: Config file doesn't exists. Bye."
    exit 1
fi

# Load variables in config file
source $config

# Check variables
if_dir_exists "$clients" && if_var_empty "$server_ip" && if_var_empty "$server_user" && if_dir_exists "$repository"
if [[ $? -eq 1 ]]
then
    logging "ERROR: Config file syntax error. Bye."
    exit 1
fi

# Initialize repository in case of first run
[[ $initial -eq 1 ]] || initialize

# Run backup for each host in clients, one host per file, <hostname>.conf
for f in $clients/*.conf
do
    logging  "INFO: Starting client file: $f."

	# Load variables in host file
    source $f
	
	# Check if host is marked for automatic backups
    if [[ "$host_auto" == "yes" ]]
    then
		# Check integrity of repository
        integrity
		
		# Send attic backup command to host
        cmdremote "sudo attic create --stats $host_excludes $server_user@$server_ip:$repository::$host_name-$(date +%Y%m%d%H%M) $host_path"

		# If remote command run successful, update last run
        if [[ $? -eq 0 ]]
        then
            logging "INFO: Backup finished successfully."
            update_host
        else
            logging "ERROR: Backup failed."
        fi
		# Update repository status
        update_repo
    else
        logging "INFO: Skipping configuration file."
    fi
done

integrity
logging "INFO: Cleaning old backups."
attic prune --keep-within 30d $repository
integrity

logging "INFO: Bye."

exit 0