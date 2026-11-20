#!/bin/bash

# Setup and validate arguments
psql_host=$1
psql_port=$2
db_name=$3
psql_user=$4
psql_password=$5

# Check # of args
if [ "$#" -ne 5 ]; then
    echo "Illegal number of parameters"
    exit 1
fi

# Save machine info and current machine hostname to variables
hostname=$(hostname -f)
lscpu_out=$(lscpu)
cpu_info=$(cat /proc/cpuinfo)
vmstat_mem_out=$(vmstat -s --unit K)

# Retrieve hardware spec variables
cpu_number=$(echo "$lscpu_out" | egrep "^CPU\(s\):" | awk '{print $2}' | xargs)
cpu_architecture=$(echo "$lscpu_out"  | egrep "^Architecture:" | awk '{print $2}' | xargs)
cpu_model=$(echo "$lscpu_out"  | egrep "^Model name:" | awk -F: '{print $2}' | xargs)
cpu_mhz=$(echo "$cpu_info"  | egrep "^cpu MHz(\s*):" | head -n 1 | awk -F: '{print $2}' | xargs)
l2_cache=$(echo "$lscpu_out"  | egrep "^L2 cache:" | awk -F: '{print $2}' | awk '{print $1}' | xargs)
timestamp=$(date -u +"%Y-%m-%d %H:%M:%S") 
total_mem=$(echo "$vmstat_mem_out" | head -n 1 | awk '{print $1}')

# PSQL command to insert server info data into host_info table
insert_stmt="INSERT INTO host_info(hostname, cpu_number, cpu_architecture, cpu_model, cpu_mhz, l2_cache, timestamp, total_mem) 
VALUES ('$hostname', $cpu_number, '$cpu_architecture', '$cpu_model', $cpu_mhz, $l2_cache, '$timestamp', $total_mem)";

# Set up environment variable for PSQL cmd
export PGPASSWORD=$psql_password

# Insert data into database
psql -h $psql_host -p $psql_port -d $db_name -U $psql_user -c "$insert_stmt"
exit $?