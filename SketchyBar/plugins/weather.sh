#!/bin/bash
# Author - https://github.com/TaylorFinklea

# Tomorrow.io script to pull weather updates using free tier
# Designed to be used with Polybar, but should work with any status bar

# Must install curl and jq for this to work
# Recommended to install Nerd-Fonts, or you can replace the icons with your own
# https://www.nerdfonts.com/cheat-sheet

# To see what the weather status codes coorespond to, see the tomorrow.io api docs
# https://docs.tomorrow.io/reference/data-layers-core

#################
### VARIABLES ###
#################

#########################################################
### Provide your API key, latitude and longitude here ###
#########################################################
KEY=""
LAT=""
LON=""
UNITS="imperial" # imperial or metric
SYMBOL="°"

# If you want moon phases, each API call will consume 2 calls. Set LOW_CALL to `false`
# Otherise, set LOW_CALL to `true`. It will use another API for getting sunset and sunrise times.
LOW_CALL=true # true or false

# Fixed variables
FIELDS="weatherCode,temperature,temperatureApparent,humidity"
SUNFIELDS="sunriseTime,sunsetTime,moonPhase"
API="https://api.tomorrow.io/v4/timelines"

#################
### FUNCTIONS ### 
#################

get_icon() {
    case $1 in
        # Icons for weather-icons
        1000d) icon=" ";;
        1000n) icon=" ";;
        1100d) icon=" ";;
        1100n) icon=" ";;
        1101d) icon=" ";;
        1101n) icon=" ";;
        1102d) icon=" ";;
        1102n) icon=" ";;
        1001*) icon=" ";;
	# Fog (light,foggy)
        2100d) icon=" ";;
        2100n) icon=" ";;
        2000*) icon=" ";;
	# Rain (light,low,medium,heavy)
        4000*) icon=" ";;
        4200*) icon=" ";;
        4001*) icon=" ";;
        4201*) icon=" ";;
	# Snow (light,low,medium,heavy)
        5001d) icon=" ";;
        5001n) icon=" ";;
        5100*) icon=" ";;
        5000*) icon=" ";;
        5101*) icon=" ";;
	# Sleet/Freezing Rain (light,low,medium,heavy)
        6000d) icon=" ";;
        6000n) icon=" ";;
        6200*) icon=" ";;
        6001*) icon=" ";;
        6201*) icon=" ";;
	# Hail (light,medium,heavy)
        7102d) icon=" ";;
        7102n) icon=" ";;
        7000*) icon=" ";;
        7101*) icon=" ";;
	# Other
        8000d) icon=" ";;
        8000n) icon=" ";;
        *) icon="";
    esac
    echo $icon
}

get_moon_icon() {
    case $1 in
        0) icon="";;
        1) icon="";;
        2) icon="";;
        3) icon="";;
        4) icon="";;
        5) icon="";;
        6) icon="";;
        7) icon="";;
        *) icon="";
    esac

    echo $icon
}

# LOW_CALL true
if $LOW_CALL; then
    # If you provided a location, that will be used
    if [ -n "$LAT" ]; then
        current=$(curl -sf "$API?apikey=$KEY&location=$LAT,$LON&fields=$FIELDS&timesteps=5m&units=$UNITS")
        sun=$(curl -sf "https://api.sunrise-sunset.org/json?lat=$LAT&lng=$LON&formatted=0")
    # Otherwise, your location will be pulled by your IP
    else
        location=$(curl -sf https://location.services.mozilla.com/v1/geolocate?key=geoclue)
        if [ -n "$location" ]; then
            location_lat="$(echo "$location" | jq '.location.lat')"
            location_lon="$(echo "$location" | jq '.location.lng')"

            current=$(curl -sf "$API?apikey=$KEY&location=$location_lat,$location_lon&fields=$FIELDS&timesteps=5m")
            sun=$(curl -sf "https://api.sunrise-sunset.org/json?lat=$location_lat&lng=$location_lon&formatted=0")
        fi
    fi

    if [ -n "$current" ] && [ -n "$sun" ]; then
        sunrise=$(echo $sun | jq ".results.sunrise")
        sunset=$(echo $sun | jq ".results.sunset")
        now=$(echo $current | jq ".data.timelines[0].intervals[0].startTime")
        hour=$(echo $current | jq ".data.timelines[0].intervals[12].startTime")
        nowEpoch=$(date --date=${now:1:-1} +"%s")
        hourEpoch=$(date --date=${hour:1:-1} +"%s")
        sunsetEpoch=$(date --date=${sunset:1:-1} +"%s")
        current_temp=$(echo "$current" | jq ".data.timelines[0].intervals[0].values.temperatureApparent" | cut -d "." -f 1 )
        current_humidity=$(echo "$current" | jq ".data.timelines[0].intervals[0].values.humidity" | cut -d "." -f 1)
        forecast_temp=$(echo "$current" | jq ".data.timelines[0].intervals[12].values.temperatureApparent" | cut -d "." -f 1 )

        # Day Current
        if (($nowEpoch < $sunsetEpoch)); then
                current_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[0].values.weatherCode")d
        # Night
        else
                current_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[0].values.weatherCode")n
        fi

        # Day Forecast
        if (($hourEpoch < $sunsetEpoch)); then
                forecast_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[12].values.weatherCode")d
        # Night
        else
                forecast_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[12].values.weatherCode")n

        fi

        if (($current_temp > $forecast_temp )); then
            trend=""
        elif (($forecast_temp > $current_temp)); then
            trend=""
        else
            trend=""
        fi
    fi

# LOW_CALL false
else
    # If you provided a location, that will be used
    if [ -n "$LAT" ]; then
        current=$(curl -sf "$API?apikey=$KEY&location=$LAT,$LON&fields=$FIELDS&timesteps=5m&units=$UNITS")
        sun=$(curl -sf "$API?apikey=$KEY&location=$LAT,$LON&fields=$SUNFIELDS&timesteps=1d&units=$UNITS")
    # Otherwise, your location will be pulled by your IP
    else
        location=$(curl -sf https://location.services.mozilla.com/v1/geolocate?key=geoclue)
        if [ -n "$location" ]; then
            location_lat="$(echo "$location" | jq '.location.lat')"
            location_lon="$(echo "$location" | jq '.location.lng')"

            current=$(curl -sf "$API?apikey=$KEY&location=$location_lat,$location_lon&fields=$FIELDS&timesteps=5m&units=$UNITS")
            sun=$(curl -sf "$API?apikey=$KEY&location=$location_lat,$location_lon&fields=$SUNFIELDS&timesteps=1d&units=$UNITS")
        fi
    fi

    # Forecast is 1 hour, which is 12 intervals since those are 5 minutes
    if [ -n "$current" ] && [ -n "$sun" ]; then
        sunrise=$(echo $sun | jq ".data.timelines[0].intervals[0].values.sunriseTime")
        sunset=$(echo $sun | jq ".data.timelines[0].intervals[0].values.sunsetTime")
        moon=$(echo $sun | jq ".data.timelines[0].intervals[0].values.moonPhase")
        now=$(echo $current | jq ".data.timelines[0].intervals[0].startTime")
        hour=$(echo $current | jq ".data.timelines[0].intervals[12].startTime")
        # Epoch is generated to compare times easily in Bash
        nowEpoch=$(date --date=${now:1:-1} +"%s")
        hourEpoch=$(date --date=${hour:1:-1} +"%s")
        sunsetEpoch=$(date --date=${sunset:1:-1} +"%s")
        # Cut to round to nearest degree
        current_temp=$(echo "$current" | jq ".data.timelines[0].intervals[0].values.temperatureApparent" | cut -d "." -f 1 )
        current_humidity=$(echo "$current" | jq ".data.timelines[0].intervals[0].values.humidity" | cut -d "." -f 1)
        forecast_temp=$(echo "$current" | jq ".data.timelines[0].intervals[12].values.temperatureApparent" | cut -d "." -f 1 )

        # Day Current
        if (($nowEpoch < $sunsetEpoch)); then
                current_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[0].values.weatherCode")d
        # Night
        else
                current_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[0].values.weatherCode")n
        fi

        # Day Forecast
        if (($hourEpoch < $sunsetEpoch)); then
                forecast_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[12].values.weatherCode")d
        # Night
        else
                forecast_icon=$(echo "$current" | jq -r ".data.timelines[0].intervals[12].values.weatherCode")n

        fi

        if (($current_temp > $forecast_temp )); then
            trend=""
        elif (($forecast_temp > $current_temp)); then
            trend=""
        else
            trend=""
        fi
    fi
fi

# --moon won't work if you are using LOW_CALL=true
# case "$1" in
#     --moon)
# 	STATUS="$(get_moon_icon "$moon") | $(get_icon "$current_icon") $current_temp$SYMBOL$trend$(get_icon "$forecast_icon") $forecast_temp$SYMBOL | 懲$current_humidity%"
#         ;;
#     --humidity)
# 	STATUS="$(get_icon "$current_icon") $current_temp$SYMBOL$trend$(get_icon "$forecast_icon") $forecast_temp$SYMBOL | 懲$current_humidity%"
#         ;;
#     *)
# 	STATUS="$(get_icon "$current_icon") $current_temp$SYMBOL$trend$(get_icon "$forecast_icon") $forecast_temp$SYMBOL"
#         ;;
# esac
STATUS="$(get_icon "$current_icon") $current_temp$SYMBOL$trend$(get_icon "$forecast_icon") $forecast_temp$SYMBOL"
# STATUS="$(get_icon "$current_icon") $current_temp$SYMBOL$trend$(get_icon "$forecast_icon") $forecast_temp$SYMBOL | $current_humidity%"
WEATHER=$(echo $STATUS)

sketchybar --set $NAME label="$WEATHER"
