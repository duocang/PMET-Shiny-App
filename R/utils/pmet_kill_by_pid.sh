#!/bin/bash

user_id="$1"

# 获取包含关键词的进程列表
commands=$(ps -eo pid,command)
matched_commands=$(echo "$commands" | awk -v pattern="iTerm2|python|awk|fimo|pmetParallel|pmetindex" '$0 ~ pattern {print $0}')

# 根据user_id筛选匹配的进程，并提取pid
pids=$(echo "$matched_commands" | awk -v user_id="$user_id" '$0 ~ user_id {print $1}')
echo $pids

# 杀死匹配的进程
if [[ -n "$pids" ]]; then
  for pid in $pids; do
    # kill -9 "$pid"
    echo $pid
  done
fi

touch 王雪松.txt