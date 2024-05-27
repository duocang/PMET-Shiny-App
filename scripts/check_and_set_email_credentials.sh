#!/bin/bash

source scripts/colored_print.sh

# 定义函数 check_and_set_email_credentials
check_and_set_email_credentials() {

    credential_path="data/email_credential.txt"

    # 初始化 file_flag 为 F，表示默认情况下文件状态为不满足条件
    file_flag="F"
    # 检查文件是否存在，且至少有5行非空内容
    if [[ -f "$credential_path" ]] && [[ $(grep -v '^[[:blank:]]*$' "$credential_path" | wc -l) -ge 5 ]]; then
        print_orange "  Please check your email credential in $credential_path"
        # 读取文件内容到变量
        readarray -t lines < "$credential_path"
        username="${lines[0]}"
        password="${lines[1]}"
        address="${lines[2]}"
        smtp_link="${lines[3]}"
        ssl_port="${lines[4]}"
        echo "    User name (email): $username"
        echo "    Password         : $password"
        echo "    Address          : $address"
        echo "    SMTP Link        : $smtp_link"
        echo "    SSL Port         : $ssl_port"

        print_orange_no_br "  Is this information correct? (Y/n): "
        read confirmation
        confirmation=${confirmation:-Y}  # 如果用户没有输入任何内容，则将 confirmation 设置为 'Y'
        if [[ "$confirmation" =~ ^[Yy]$ ]]; then
            file_flag="T"
        else
            file_flag="F"
        fi
    else
        current_date=$(date '+%Y%m%d%H%M')

        # 检查文件是否存在
        if [[ -f "$credential_path" ]]; then
            # 构造新的文件名
            new_filename="data/email_credential_${current_date}.txt"

            mv "$credential_path" "$new_filename"
            print_red "  Invalid email credential: $credential_path"
            print_red "  The file has been renamed to '$new_filename'."
        else
            print_red "  Email credential '$credential_path' does not exist."
        fi

        file_flag="F"
    fi

    # 根据 file_flag 做进一步操作
    if [[ "$file_flag" == "F" ]]; then
        print_orange "  Please provide the required information."
        rm -rf "$credential_path"
        touch "$credential_path"
        # 循环直到输入非空的用户名
        while true; do
            read -p "    User name (email): " username
            # 检查用户名是否非空
            if [[ -z "$username" ]]; then
                print_red "    Email (User name) cannot be empty. Please try again."
            else
                break  # 用户名非空，跳出循环
            fi
        done
        # 循环直到输入非空的密码
        while true; do
            read -p "    Password : " password
            if [[ -z "$password" ]]; then
                print_red "    Password cannot be empty. Please try again."
            else
                break  # 密码非空，跳出循环
            fi
        done
        # 循环直到输入非空的address
        while true; do
            read -p "    Address (email): " address
            # 检查用户名是否非空
            if [[ -z "$address" ]]; then
                print_red "    Address (email) cannot be empty. Please try again."
            else
                break  # 用户名非空，跳出循环
            fi
        done
        # 接收并验证 SMTP 链接
        while true; do
            read -p "    SMTP link: " smtp_link
            if [[ -n "$smtp_link" ]]; then
                break
            else
                print_red "    SMTP link cannot be empty. Please try again."
            fi
        done
        # 接收并验证 SSL 端口号
        while true; do
            read -p "    SSL Port  : " ssl_port
            if [[ -n "$ssl_port" ]] && [[ "$ssl_port" -ne 0 ]]; then
                break
            else
                print_red "    SSL Port cannot be zero or empty. Please try again."
            fi
        done
        echo

        # 存储信息到文件 Store information to file
        echo "$username"  >> "$credential_path"
        echo "$password"  >> "$credential_path"
        echo "$address"   >> "$credential_path"
        echo "$smtp_link" >> "$credential_path"
        echo "$ssl_port"  >> "$credential_path"
        # show message
        {
            read -r username
            read -r password
            read -r address
            read -r smtp_link
            read -r ssl_port
        } < "$credential_path"
        print_green "    User name: $username"
        print_green "    Password : $password"
        print_green "    Address  : $address"
        print_green "    User name: $smtp_link"
        print_green "    Password : $ssl_port"
    fi
}

# 导出函数，使其在source a.sh后可以被调用
export -f check_and_set_email_credentials
