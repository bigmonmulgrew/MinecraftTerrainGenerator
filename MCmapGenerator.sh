#!/bin/bash

## Constants
#Time to sleep before checking CPU load again
checkInterval=1
#Number of units to move the player
moveInterval=5
#The unit size of a chunk
chunkSize=16
#Coordinates of the map origin
originPoint="0,0"
#The height of the player
yHeight=200
#The percentage of CPU usage before the next iteration runs, bear in mind 100% represents a single core, eg a 4 core CPU maxes out at 400%
cpuThreshold=80

## Startup Variables (including default values)
#Default server name
serverName="2023BigMonD"
#Folder the server is stored in
serverLocation="/opt/msm/servers/$serverName"
#Name of the player to be moved.
player="bigmonmulgrew"
#Radius at the world origin, typically 0,0
originRadius=250
#Point of interest Radius
poiRadius=250

targetString=""
moveStep=0

# This function is called when the script is run with the -h option,
# or when an invalid option is given. It displays usage information
# and the current configuration, then exits.
usage() {
  echo "Usage: $0 [-s serverName] [-r originRadius] [-R poiRadius] [-p player] [-t target] [-i moveInterval]"
  echo
  echo "Options:"
  echo "  -s    Minecraft server name (default: $serverName)"
  echo "  -r    origin radius (default: $originRadius)"
  echo "  -R    Point of interest radius (default: $poiRadius)"
  echo "  -p    Player name (default: $player)"
  echo "  -t    Target coordinates as x,z pairs. Multiple pairs should be separated by a semicolon (default: $targetString)"
  echo "  -i    Movement interval (default: $moveInterval)"
  echo "  -h    Display this help message and current configuration"
  echo
  echo "Current Configuration:"
  echo "  Server name: $serverName"
  echo "  Origin radius: $originRadius"
  echo "  POI radius: $poiRadius"
  echo "  Player name: $player"
  echo "  Y height: $yHeight"
  echo "  Targets: $targetString"
  echo "  CPU Threshold: $cpuThreshold"
  echo "  Check Interval: $checkInterval"
  echo "  Move Interval: $moveInterval"
  exit 1
}

getOptions() {
  # Process command line options
  while getopts ":s:r:R:p:t:i:h" opt; do
    case $opt in
      s) serverName="$OPTARG" ;;
      r) originRadius="$OPTARG" ;;
	  R) poiRadius="$OPTARG" ;;
      p) player="$OPTARG" ;;
      t) targetString="$OPTARG" ;;
      i) moveInterval="$OPTARG" ;;
      h) usage ;;
      \?) echo "Invalid option -$OPTARG" >&2; usage ;;
    esac
  done
}

calculateVariables(){
  #Calculate any variables automatically derived from provided options.
  moveStep=$((moveInterval*chunkSize))
}

# Function to print key-value pairs
print_setting() {
    printf "%-18s %s\n" "$1:" "$2"
}

printSettings() {
  # Summarize the settings used
  print_setting 'Server Name' 		$serverName
  print_setting 'Player Name' 		$player
  print_setting 'Origin Radius'     $originRadius
  print_setting 'POI Radius'        $poiRadius
  print_setting 'Target Coordinates' $targetString
  print_setting 'Y Height'      	$yHeight
  print_setting 'CPU Threshold' 	$cpuThreshold
  print_setting 'Check Interval' 	$checkInterval
  print_setting 'Move Interval' 	$moveInterval
}

generateMap() {
  #Loop through target list to generate the map
  
  #Generate the map at the origin (0,0)
  generateTarget "0" "0" "${originRadius}"

  # Convert the targetString to an array
  IFS=";" read -ra target <<< "$targetString"
  
  # Loop through each target coordinate and generate the map at the targets
  for coord in "${target[@]}"; do
    echo "Next Target: $coord"
    IFS="," read -r -a coords <<< "$coord"
  
    generateTarget "${coords[0]}" "${coords[1]}" "${poiRadius}"
  done
}

generateTarget() {
  #Generates the map at the given target.

  local targetX=$1
  local targetZ=$2
  local r=$3
 
  # Loop through each x coordinate in the radius
  for ((x=-r; x<=r; x=x+moveStep)); do
	
    # Loop through each z coordinate in the radius
    for ((z=-r; z<=r; z=z+moveStep)); do
	  
      # Wait until CPU usage falls below the threshold
      waitForCPU

      # Calculate the target coordinates and teleport the player
      local xTarget=$(( targetX + x ))
      local zTarget=$(( targetZ + z ))
	  
	  teleportPlayer  "${xTarget}" "${zTarget}" "${r}"
	        
    done
  done
}

waitForCPU() {
#Checks the CPU usage level and sleeps until it drops low enough
  while true; do
	cpuUsage=$(top -bn2 | grep '^%Cpu' | tail -n 1 | awk '{print $2+$4+$6}')
	checkCPU=$(echo "$cpuUsage > $cpuThreshold" | bc)
	if [ $checkCPU -eq 0 ]; then
	  break
	fi
	echo -ne "CPU usage high, sleeping... : ${cpuUsage}%\r"
	sleep $checkInterval
  done
}

teleportPlayer() {
  #Checks that the teleportation target is within the given radius and if so teleports the player
  local tX=$1
  local tZ=$2
  local r=$3
  
  radial_distance=`echo "scale=2; sqrt(($tX*$tX)+($tZ*$tZ))" | bc`
  
  if [ "$(bc <<< "$radial_distance < $r+($moveStep/2)")" == "1"  ];
  then
    formattedX=$(printf "%5s" $tX)
    formattedZ=$(printf "%5s" $tZ)
    echo "TPing $player to $formattedX :$formattedZ TP radius: $radial_distance"
    sudo msm $serverName cmd tp $player $tX $teleportHeight $tZ > /dev/null
  fi
}

### Program execution Starts here ###

#Get command line options
getOptions

#Calculate any variables derived automatically from options
calculateVariables

#Output the settings to the console.
printSettings

#Generate the map
generateMap
