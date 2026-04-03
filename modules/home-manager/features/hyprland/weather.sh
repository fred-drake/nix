#!/usr/bin/env bash

city="Tampa, Florida"
coords=$(curl -s "https://nominatim.openstreetmap.org/search?format=json&q=${city// /+}" | jq -r ".[0] | .lat + \",\" + .lon")
lat=${coords%%,*}
lon=${coords##*,}
weather_data=$(curl -s --max-time 5 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true&hourly=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,wind_direction_10m&temperature_unit=fahrenheit&wind_speed_unit=mph&timezone=America%2FToronto&forecast_days=1")

if [ -n "$weather_data" ]; then
    temp=$(echo "$weather_data" | jq -r ".current_weather.temperature // empty" | cut -d. -f1)
    code=$(echo "$weather_data" | jq -r ".current_weather.weathercode // empty")
    wind_speed=$(echo "$weather_data" | jq -r ".current_weather.windspeed // empty" | cut -d. -f1)
    wind_dir=$(echo "$weather_data" | jq -r ".current_weather.winddirection // empty")
    current_hour=$(date +%H)
    humidity=$(echo "$weather_data" | jq -r ".hourly.relative_humidity_2m[$current_hour] // empty")
    feels_like=$(echo "$weather_data" | jq -r ".hourly.apparent_temperature[$current_hour] // empty" | cut -d. -f1)
    
    if [ -n "$temp" ] && [ -n "$code" ]; then
        case "$code" in
            0) icon="☀️";;
            1|2|3) icon="🌤️";;
            45|48) icon="🌫️";;
            51|53|55|56|57) icon="🌦️";;
            61|63|65|66|67) icon="🌧️";;
            71|73|75|77) icon="❄️";;
            80|81|82) icon="🌧️";;
            85|86) icon="❄️";;
            95|96|99) icon="⛈️";;
            *) icon="🌤️";;
        esac
        
        wind_arrow=""
        if [ -n "$wind_dir" ]; then
            if [ "$wind_dir" -ge 338 ] || [ "$wind_dir" -lt 23 ]; then
                wind_arrow="↓"
            elif [ "$wind_dir" -ge 23 ] && [ "$wind_dir" -lt 68 ]; then
                wind_arrow="↙"
            elif [ "$wind_dir" -ge 68 ] && [ "$wind_dir" -lt 113 ]; then
                wind_arrow="←"
            elif [ "$wind_dir" -ge 113 ] && [ "$wind_dir" -lt 158 ]; then
                wind_arrow="↖"
            elif [ "$wind_dir" -ge 158 ] && [ "$wind_dir" -lt 203 ]; then
                wind_arrow="↑"
            elif [ "$wind_dir" -ge 203 ] && [ "$wind_dir" -lt 248 ]; then
                wind_arrow="↗"
            elif [ "$wind_dir" -ge 248 ] && [ "$wind_dir" -lt 293 ]; then
                wind_arrow="→"
            elif [ "$wind_dir" -ge 293 ] && [ "$wind_dir" -lt 338 ]; then
                wind_arrow="↘"
            fi
        fi
        
        echo "${icon} ${temp}°F"
        [ -n "$feels_like" ] && [ "$feels_like" != "$temp" ] && echo "Feels ${feels_like}°F"
        [ -n "$wind_speed" ] && [ -n "$wind_arrow" ] && echo "💨 ${wind_speed}mph ${wind_arrow}"
        [ -n "$humidity" ] && echo "💧 ${humidity}%"
    else
        echo "🌤️ --°"
    fi
else
    echo "🌤️ --°"
fi