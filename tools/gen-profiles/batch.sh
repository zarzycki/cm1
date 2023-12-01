#!/bin/bash

# Start date
start_month="01"
start_day="08"

# End date
end_month="02"
end_day="18"

# Convert start and end dates to integer values
start_date=$(date -d "$start_month/$start_day" +%s)
end_date=$(date -d "$end_month/$end_day" +%s)

# Loop through dates
current_date="$start_date"
while [ "$current_date" -le "$end_date" ]; do
  # Extract month and day from the current date
  mm=$(date -d "@$current_date" "+%m")
  dd=$(date -d "@$current_date" "+%d")

  for hour in "00" "03" "06" "09" "12" "15" "18" "21"; do
    ncl get-profile-from-ERA5.ncl 'month="'$mm'"' 'day="'$dd'"' 'hh="'$hour'"'
  done

  current_date=$((current_date + 86400))
done
