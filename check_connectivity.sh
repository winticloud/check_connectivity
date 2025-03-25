#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Create results directory if it doesn't exist
RESULTS_DIR="results"
mkdir -p "$RESULTS_DIR"

# Create timestamp for filename (format: YYYY-MM-DD-HHMMSS)
TIMESTAMP=$(date +"%Y-%m-%d-%H%M%S")
OUTPUT_FILE="${RESULTS_DIR}/hosts-check-results-${TIMESTAMP}.txt"

# Function to log output to both terminal and file
log() {
  echo -e "$1"
  echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT_FILE"
}

# Function to log output without newline to both terminal and file
log_n() {
  echo -n -e "$1"
  echo -n -e "$1" | sed 's/\x1b\[[0-9;]*m//g' >> "$OUTPUT_FILE"
}

# Function to check DNS resolution
check_dns() {
  local host=$1
  log_n "DNS Resolution for $host: "
  
  # Check if it's an IP address
  if [[ $host =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log "${YELLOW}Skipped (IP address)${NC}"
    return 0
  fi
  
  # Use 'host' command to resolve DNS and capture the output
  dns_result=$(host "$host" 2>&1)
  if [ $? -eq 0 ]; then
    # Extract IP addresses from the result
    ip_addresses=$(echo "$dns_result" | grep "has address\|has IPv4 address" | awk '{print $NF}')
    if [ -n "$ip_addresses" ]; then
      log "${GREEN}Success${NC}"
      log "Resolved IP(s):"
      echo "$ip_addresses" | while read -r ip; do
        log "  ${GREEN}→ $ip${NC}"
      done
    else
      log "${YELLOW}Resolved but no IPv4 address found${NC}"
    fi
    return 0
  else
    log "${RED}Failed${NC}"
    return 1
  fi
}

# Function to check ICMP connectivity
check_ping() {
  local host=$1
  log "ICMP Connectivity for $host: "
  
  # Run ping and capture output
  ping_output=$(ping -c 2 -W 2 "$host" 2>&1)
  ping_status=$?
  
  if [ $ping_status -eq 0 ]; then
    log "${GREEN}Success${NC}"
    # Display the ping output with proper indentation
    echo "$ping_output" | while IFS= read -r line; do
      log "  $line"
    done
    return 0
  else
    log "${RED}Failed${NC}"
    # Display the error output with proper indentation
    echo "$ping_output" | while IFS= read -r line; do
      log "  $line"
    done
    return 1
  fi
}

# Function to check port reachability
check_port() {
  local host=$1
  local port=$2
  log_n "Port $port Reachability for $host: "
  
  if nc -z -G 3 "$host" "$port" > /dev/null 2>&1; then
    log "${GREEN}Success${NC}"
    return 0
  else
    log "${RED}Failed${NC}"
    return 1
  fi
}

# Main execution
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 input_file.txt"
  echo "Format of input file: service_name,hostname_or_ip,port1 port2 port3..."
  echo "Example: Messerli Server,example.com,80 443 8080"
  echo "Output will be saved to the '${RESULTS_DIR}' directory"
  exit 1
fi

input_file=$1

if [ ! -f "$input_file" ]; then
  echo "Error: File $input_file not found!"
  exit 1
fi

# Initialize the output file with a header
echo "=== Host Connectivity Check Results ===" > "$OUTPUT_FILE"
echo "Date and Time: $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT_FILE"
echo "Input File: $input_file" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

log "=== Starting connectivity checks ==="
log "Output is being saved to: $OUTPUT_FILE"
log ""

while IFS=, read -r service host ports || [[ -n "$service" ]]; do
  # Remove whitespace from service and host
  service=$(echo "$service" | xargs)
  host=$(echo "$host" | xargs)
  # Trim leading/trailing spaces from ports but keep internal spaces
  ports=$(echo "$ports" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
  
  log "${BLUE}${BOLD}Service: $service${NC}"
  log "Testing $host"
  log "----------------------------------------"
  
  # Run DNS and ping checks only once per host
  check_dns "$host"
  check_ping "$host"
  
  # Check each port
  for port in $ports; do
    check_port "$host" "$port"
  done
  
  log "----------------------------------------"
  log ""
done < "$input_file"

log "=== Connectivity checks complete ==="
log "Full results saved to: $OUTPUT_FILE"

# Tell the user where the results are stored
echo
echo "Full results have been saved to: $OUTPUT_FILE"