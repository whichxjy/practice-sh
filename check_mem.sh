#! /bin/bash

echo `date +"[======== %Y-%m-%d %H:%M:%S ========]"`
printf "%-17s%-15s%-18s\n" "[PID]" "[MEM]" "[Proc_Name]"

MB=1024
GB=1048576

# Find all pids (except 1)
for pid in `ls -l /proc | grep ^d | awk '{ print $9 }' | grep -v '[^0-9]'`
do
    # If pid == 1, continue loop
    if [ $pid -eq 1 ]
    then
        continue
    fi
    # Check current process's VmRSS (Virtual Memory Resident Set Size)
    grep -q "VmRSS" /proc/$pid/status 2>/dev/null
    # If VmRSS for current process was found($? == 0), then continue
    if [ $? -eq 0 ]
    then
        # Caculate the VmRSS of current process
        mem=$(grep VmRSS /proc/$pid/status | awk '{ sum += $2; } END { print sum }')
        # Get the name of current process
        proc_name=$(ps aux | grep -w "$pid" | grep -v "grep" \
               | awk '{ for (i = 11; i <= NF; i++) { printf("%s ", $i); } }')
        # Ignore "awk" process
        if [[ $proc_name =~ "awk" ]]
        then
            continue
        fi
        # If VmRSS > 0, then prinf the information
        if [ $mem -gt 0 ]
        then
            echo -e "$pid\t$mem\t$proc_name"
        fi
    fi
done | sort -k 2 -n \
        | awk -F '\t' '{
            pid[NR] = $1;
            size[NR] = $2;
            name[NR] = $3;
        }
        END {
            for (i = 1; i <= length(pid); i++) {
                if (size[i] < $MB) {
                    printf("%-10s%12.3f KB      %-s\n", pid[i], size[i], name[i]);
                }
                else if (size[i] < $GB) {
                    printf("%-10s%12.3f MB      %-s\n", pid[i], size[i] / $MB, name[i]);
                }
                else {
                    printf("%-10s%12.3f GB      %-s\n", pid[i], size[i] / $GB, name[i]);
                }
            }
        }'
