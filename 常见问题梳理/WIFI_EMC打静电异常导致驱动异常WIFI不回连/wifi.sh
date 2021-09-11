#!/bin/bash

i=0
counts=100

while [ $i -le $counts ]
do
  let 'i++'
  foo=$(ifconfig wlan0 | grep UP)
  echo "foo : ${foo}"
  if [ "$foo" = "" ]
  then
    echo "turn on wifi"
    svc wifi enable
  else
    echo "wifi is on"
    sleep 3
  fi
  
  sleep 3
  echo "exec ++"
done
