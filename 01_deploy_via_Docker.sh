#!/bin/bash

source scripts/colored_print.sh
source scripts/check_and_set_email_credentials.sh
source scripts/check_CPU_number.sh
set -e

#################### 1 email
print_green "1. Configurations of email to send results"
check_and_set_email_credentials

#################### 2. CPU
print_green "2. Configuration of CPU number"
check_cpu_number

#################### 3. Docker build
print_green "3. Docker building"
chmod  777 logs result
docker-compose up -d
