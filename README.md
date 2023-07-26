# MinecraftTerrainGenerator
# Minecraft World Generation Script
Script used to generate a minecraft map, can also generate around points of interest.

## Description

This repository contains a Bash script to automate Minecraft world generation. The script works by continuously teleporting the player across the map to trigger chunk generation. 
The script leverages the Minecraft Server Manager (MSM) to send commands to the server, but can easily be adapted to work with any server that accepts command line instructions.

## Prerequisites

- A working Minecraft Server (Script has been tested on Minecraft Java Edition Servers)
- Ability to send commands to the Minecraft server from command line (this script uses Minecraft Server Manager)
- `sudo` access (for certain server operations)
- `bc` utility (for certain mathematical operations)
- The Minecraft server needs to be run in a GNU Screen session or some alternatve that allows you to send command line argumetns to it.

## Usage

1. Clone this repository:
git clone https://github.com/bigmonmulgrew/MinecraftTerrainGenerator.git

2. Navigate to the directory:
cd MinecraftTerrainGenerator

3. Make the script executable:
chmod +x MCmapGenerator.sh

4. Modify the `MCmapGenerator.sh` script as necessary, making sure to update the `serverName`, `player`, `moveStep`, `yHeight`, and `worldRadius` variables to suit your requirements. Alternatively you can specify -h to get a list of commadn line switches

5. Run the script:
./MCmapGenerator.sh
Additional Example ./MCmapGenerator.sh -s MyServer -r 250 -R 250 -p MyPlayer -t "1000,1000;2000,2000" -i 5 

## How it Works

The script uses the `/tp` command to teleport the player around the world, generating new chunks as the player moves. The player is moved in a grid pattern, ensuring that all parts of the world within the specified radius get generated.

The teleportation is done in increments (`moveStep`), and the player is teleported to a new location only if the CPU usage of the server is below a certain threshold.

## Contributing

Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License

This project is licensed under the GNU General Public License (GPL) v3. See the LICENSE file for details.
