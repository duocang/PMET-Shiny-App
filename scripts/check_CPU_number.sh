#!/bin/bash

source scripts/colored_print.sh

# Function to get user input for CPU number
get_cpu_number() {
    while true; do
        print_fluorescent_yellow_no_br "  Please enter a number for CPU configuration: "
        read cpu_number
        if [[ "$cpu_number" =~ ^[0-9]+$ ]]; then
            echo "$cpu_number" > "$file_path"
            echo "  CPU number: $cpu_number"
            break
        else
            print_red "  Invalid input. Please enter a numeric value."
        fi
    done
}

# 函数：检查CPU配置文件是否存在，并提示用户
check_cpu_number() {
    file_path="data/cpu_configuration.txt"

    # 检查文件是否存在且不为空
    if [ ! -f "$file_path" ] || [ ! -s "$file_path" ]; then
        get_cpu_number
    else
        cpu_number=$(cat "$file_path")
        # print_orange "  Check your CPU number in $file_path"
        echo  "  Number of CPU: $cpu_number"

        # 询问用户是否要修改CPU数量
        while true; do
            print_orange_no_br "  Do you want to modify the CPU number? [y/N]: "
            read modify

            modify=${modify:-N} # 默认为'N'，如果没有提供输入
            case "$modify" in
                [Yy]* )
                    get_cpu_number
                    break
                    ;;
                [Nn]* )
                    # echo "Keeping the existing CPU configuration: $cpu_number"
                    break
                    ;;
                * )
                    print_red "Please answer yes (y) or no (n)."
                    ;;
            esac
        done
    fi
}

# 导出函数，以便在source a.sh后可以被调用
export -f get_cpu_number
export -f check_cpu_number
