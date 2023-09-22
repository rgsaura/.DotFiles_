#!/bin/bash

function main(){
  STATUS=""

  ETHERNET=$(networksetup -listnetworkserviceorder | grep 'LAN, Device' | sed -E "s/.*(en[0-9]).*/\1/")
  if [[ $ETHERNET ]]; then
    if [[ $(ifconfig $ETHERNET | grep -E "status: active") ]]; then
      STATUS+='󰈀 '
      STATUS+="$(ipconfig getifaddr $ETHERNET) "
      STATUS+=" "
    fi
  fi

  WIFI=$(networksetup -listnetworkserviceorder | grep 'Wi-Fi, Device' | sed -E "s/.*(en[0-9]).*/\1/")
  if [[ $WIFI ]]; then
    if [[ $(ifconfig $WIFI | grep -E "status: active") ]]; then
      STATUS+='󰖩 '
      STATUS+="$(ipconfig getifaddr $WIFI) "
      STATUS+=" "
    fi
  fi


  WAN=$(curl -s ifconfig.me)
  if [[ $WAN ]]; then
    STATUS+='󰖈 '
    STATUS+="$(echo $WAN)"
  fi

  sketchybar --set $NAME label="$STATUS"
}

main

