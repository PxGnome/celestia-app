#!/bin/bash

PURPLE='\033[0;35m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

CURRENCY="utia"

# Output files
LOG_FILE="output/distributeFunds.log"
OUTPUT_FILE="output/distributeFunds.out"

# Redirect all output to the log file
exec > >(tee -a "$LOG_FILE") 2>&1

echo -e "${PURPLE}Start distributeFunds: $(date '+%Y-%m-%d %H:%M:%S') ${NC}"

# Load environment variables from .env file
if [[ -f .env ]]; then
    set -a
    . .env
    set +a
fi

# Check if Key is set
if [[ -n $KEY_NAME ]]; then
    echo "KEY_NAME: $KEY_NAME"
    # Get the address from the KEY using the Celestia SDK
    SOURCE_ADDRESS=$(celestia-appd keys show $KEY_NAME -a)
    echo -e "Source Address: ${CYAN}$SOURCE_ADDRESS${NC}"
    echo -e "Transfer Fees: ${GREEN}$TRANSFER_FEES $CURRENCY${NC}"
    # Confirm the source address with user
    echo -e "${YELLOW}Please confirm SOURCE ADDRESS & TRANSFER_FEES is correct (Type \"y\"): ${NC}"
    read -p "" SOURCE_ADDRESS_CONFIRM
    if [[ $SOURCE_ADDRESS_CONFIRM != "y" ]]; then
        echo -e "${RED}ABORTED${NC}"
        exit 1
    fi
else
    echo "KEY_NAME is not set"
    exit 1
fi

# Read the destination wallet addresses from address.csv
DESTINATION_ADDRESSES=($(awk -F',' '{print $1}' addresses.csv))
AMOUNT=($(awk -F',' '{print $2}' addresses.csv))

# Loop through the destination addresses and distribute funds
for index in "${!DESTINATION_ADDRESSES[@]}"
do
    #Skip first line as that is a header
    if [[ $index -eq 0 ]]; then
        continue
    fi
    DESTINATION_ADDRESS="${DESTINATION_ADDRESSES[$index]}"
    AMOUNT="${AMOUNT[$index]}"

    echo -e "=> Send ${GREEN}$AMOUNT $CURRENCY${NC} to ${CYAN}$DESTINATION_ADDRESS${NC}"

    if [[ $AMOUNT != "" ]]; then
        # Confirm the destination address & amount with user
        echo -e "${YELLOW}Please confirm DESTINATION ADDRESS and AMOUNT is correct before broadcasting ${NC}"

        # Add currency to amounts
        AMOUNT_CURRENCY="${AMOUNT}$CURRENCY"
        FEES_CURRENCY="${TRANSFER_FEES}$CURRENCY"

        # Transfer funds from the source wallet to the destination wallet
        # Log the transfer cmd to output file
        echo "$(date '+%Y-%m-%d %H:%M:%S') - celestia-appd tx bank send $SOURCE_ADDRESS ${DESTINATION_ADDRESS}$CURRENCY $AMOUNT_CURRENCY --chain-id celestia" >> "$OUTPUT_FILE"
        TRANSFER_FUND=$(celestia-appd tx bank send $SOURCE_ADDRESS $DESTINATION_ADDRESS $AMOUNT_CURRENCY --chain-id celestia --fees $FEES_CURRENCY)
        echo "$(date '+%Y-%m-%d %H:%M:%S') - $TRANSFER_FUND" >> "$OUTPUT_FILE"
        echo -e "$TRANSFER_FUND" | grep "txhash:"
        echo -e "${GREEN} $(date '+%Y-%m-%d %H:%M:%S') - Transferred $AMOUNT_CURRENCY from $SOURCE_ADDRESS to $DESTINATION_ADDRESS ${NC}"
    else
        echo -e "${RED}Amount is empty for $DESTINATION_ADDRESS${NC}"
    fi

done

echo -e "${PURPLE}Finished distributeFunds: $(date '+%Y-%m-%d %H:%M:%S') ${NC}"
