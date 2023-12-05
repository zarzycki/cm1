#!/bin/bash

# Start date
start_month="01"
start_day="08"
start_year="2020"

# End date
end_month="02"
end_day="18"
end_year="2020"

# Frequency per day
HOUR_INTERVAL=3

# Location to pull
lat_to_get=13.0
lon_to_get=-58.0

#############################################################################################

# Convert start and end dates to UNIX integer values
start_date=$(date -d "$start_month/$start_day/$start_year" +%s)
end_date=$(date -d "$end_month/$end_day/$end_year" +%s)

# Loop through dates
current_date="$start_date"
while [ "$current_date" -le "$end_date" ]; do
  # Extract month and day from the current date
  mm=$(date -d "@$current_date" "+%m")
  dd=$(date -d "@$current_date" "+%d")
  yyyy=$(date -d "@$current_date" "+%Y")

  # Create relevant profiles at "sub-hours" during this date
  for hour in $(seq -f "%02g" 0 $HOUR_INTERVAL 23); do
    echo $mm" "$dd" "$yyyy" "$hour"Z"
    ncl get-profile-from-ERA5.ncl 'year="'$yyyy'"' 'month="'$mm'"' 'day="'$dd'"' 'hh="'$hour'"' 'sample_lat="'$lat_to_get'"' 'sample_lon="'$lon_to_get'"'
  done

  # Advance day by 1
  current_date=$((current_date + 86400))
done
