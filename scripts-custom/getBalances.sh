#!/bin/bash

PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Output files
OUTPUT_FILE="output/getBalances.csv"

# Delete the existing file if it exists
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
fi

# Create a new file
touch "$OUTPUT_FILE"

# Read the destination wallet addresses from address.csv
DESTINATION_ADDRESSES=($(awk -F',' '{print $1}' addresses.csv))

echo -e "${PURPLE}Start getBalances: $(date '+%Y-%m-%d %H:%M:%S') ${NC}"

# Loop through the destination addresses and get the balance
for index in "${!DESTINATION_ADDRESSES[@]}"
do
    #Skip first line as that is a header
    if [[ $index -eq 0 ]]; then
        continue
    fi    
    DESTINATION_ADDRESS="${DESTINATION_ADDRESSES[$index]}"
    BALANCE=$(celestia-appd query bank balances "$DESTINATION_ADDRESS" | grep amount | awk '{print $3}') 
    echo "Balance of $DESTINATION_ADDRESS: $BALANCE"
    echo "$DESTINATION_ADDRESS,$BALANCE" >> "$OUTPUT_FILE"
done

echo -e "${PURPLE}Finished getBalances: $(date '+%Y-%m-%d %H:%M:%S') ${NC}"
