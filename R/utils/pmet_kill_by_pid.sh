#!/bin/bash

user_id="$1"
cycle="$2"

for ((i=1; i<=cycle; i++))
do
    sleep 0.1
    # 获取包含关键词的进程列表
    commands=$(ps -eo pid,command)
    matched_commands=$(echo "$commands" | awk -v pattern="fimo|pmetParallel|pmetindex" '$0 ~ pattern {print $0}')

    # echo $matched_commands

    filtered_commands=$(echo "$matched_commands" | grep "$user_id")
    # echo $filtered_commands

    pids=$(echo "$filtered_commands" | awk '{print $1}')

    echo "$pids" | xargs kill -9
done
