# check_connectivity

I wrote this script while preparing for a network hardware switch from some vendor x to FortiGate firewalls, FortiSwitches and FortiAPs. To ensure all important services are running as before the change, you can run the script as follows:

Usage: ./check_connectivity.sh input_file.txt

Format of input file: service_name,hostname_or_ip,port1 port2 port3...

Example: Website,www.winticloud.ch,80 443

Output will be saved to the 'results' directory
