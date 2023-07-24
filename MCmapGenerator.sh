#!/bin/bash

##constants

#Only run when CPUn load drops below this percentage
cpuLoadlimit=80

#Number of seconds to sleep before checking CPU load
sleepTime=5

##Variables
cpuLoad=5
cpuLoopCount=0
runLoop=true

#The user to be moved around with the tp command to trigger map generation
playerName="bigmonmulgrew"
serverName="2022BigMonD"
worldName="world"
teleportHeight=90

#Radius from spawn to pregenerate
blockGenerationRadius=5000

#Current search coordinates
mapX=0
mapZ=0

#This is double the set view distance on the server.
chunkViewDistance=10
blockViewDistance=20
moveSteps=20

serverLocation="/opt/msm/servers/2022BigMonD"

function CheckCPU
{
  cpuLoad=$(mpstat  1 1| grep -A 5 "%idle" | tail -n 1 | awk -F " " '{print 100 - $12}') 
}

function TeleportPlayer
{
  radial_distance=`echo "scale=2; sqrt(($mapX*$mapX)+($mapZ*$mapZ))" | bc`
  
  if [ "$(bc <<< "$radial_distance < $blockGenerationRadius+($moveSteps/2)")" == "1"  ];
  then
    formattedX=$(printf "%5s" $mapX)
    formattedZ=$(printf "%5s" $mapZ)
    echo "TPing $playerName to $formattedX :$formattedZ CPU load: $cpuLoad TP radius: $radial_distance"
    sudo msm $serverName cmd tp $playerName $mapX $teleportHeight $mapZ > /dev/null
  fi
}

function NextCoordinate
{
  if (( $(echo "$mapX < -$blockGenerationRadius" | bc -l) )); 
  then
    if (( $(echo "$mapZ < -$blockGenerationRadius" | bc -l) )); 
    then
      runLoop=false
    else
      mapZ=$(($mapZ-$moveSteps))
    fi
  mapX=$blockGenerationRadius
  else
    mapX=$(($mapX-$moveSteps))
  fi
  
  
}

function GetViewRadius
{
  chunkViewDistance=$(grep -hr "view-distance" $serverLocation/server.properties | awk -F "=" '{print $2}' )
  
  blockViewDistance=$(($chunkViewDistance*16))
  moveSteps=$(($blockViewDistance))
  
  echo "Server view distance set to $chunkViewDistance chunks, setting movement steps to $moveSteps blocks"
}

function printSettings
{
  echo "$(printf '%-15s' 'Server name:') $serverName"
  echo "$(printf '%-15s' 'Server path:') $serverLocation"
  echo "$(printf '%-15s' 'Player name:') $playerName"
  echo "$(printf '%-15s' 'CPU load limit:') $cpuLoadlimit"
  echo "$(printf '%-15s' 'Gen radius:') $blockGenerationRadius blocks"
}
### Program execution Starts here ###

printSettings
GetViewRadius

mapX=$blockGenerationRadius
mapZ=$blockGenerationRadius

#Loop continuously until stopped
while $runLoop;
do
  CheckCPU
  
  if [ "$(bc <<< "$cpuLoad < $cpuLoadlimit")" == "1"  ];
  then
    echo -ne "                                                          "\\r
    cpuLoopCount=0
        
    TeleportPlayer
    NextCoordinate
    
  else 
    cpuLoopCount=$(($cpuLoopCount+1))
    echo -ne "                                                          "\\r
    echo -ne "CPU too busy, waiting. $cpuLoad. Wait count: $cpuLoopCount"\\r
  fi
 
  sleep $sleepTime
done
