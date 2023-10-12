#!/bin/bash

######################
# amount of time to wait in between loops
SLEEP_TIME=3
#interface to check for connectivity, wlan0 for default newracom configuration
INTERFACE_NAME=wlan0
# the URL or IP to ping, if ping returns good yellow light is lit, if it doesnt then it is not lit
YELLOW_LED_CHECK_URL="8.8.8.8"
# path to NRC cli app
CLI_APP="/home/pi/nrc_pkg/script/cli_app"
# maximum time to wait for a yellow light ping, minimun 1 second
MAX_PING_TIME=1
######################



# bit flipper for blinking function
oscillate=0

# run led code only after module has been loaded, shouldn't be needed if started via systemd
if [[ $(lsmod | grep "nrc") -eq 0 ]];
then
  echo "nrc kernel module not present!"
  exit
fi

    
# set the correct pin directions, must run before a write
$CLI_APP gpio direction 3 1
$CLI_APP gpio direction 2 1

# pin 3 = red led (RX)
# pin 2 = yellow red (TX)

# a cleanup script run upon any exit (like ctrl^c), to turn the lights off and not leave them on and unresponsive.  Should run before module is unloaded.
trap cleanup EXIT
cleanup() {
    $CLI_APP gpio write 3 0
    $CLI_APP gpio write 2 0
}

while true;
do
    sleep "$SLEEP_TIME"s
    # find gaetway
    #gateway=$(ip route show 0.0.0.0/0 dev $INTERFACE_NAME | cut -d\  -f3)
    # check gateway for ip being given
    gateway_connect=$(ip a s $INTERFACE_NAME | grep "inet")
    if [[ -n $gateway_connect ]];
    then 
        $CLI_APP gpio write 3 1 >> /dev/null
    else
        oscillate=$((1-$oscillate))
        $CLI_APP gpio write 3 $oscillate >> /dev/null
        continue
    fi
    
    # check custom url for connectivity, if packet recieved then write to led
    gateway_connect=$(ping -c1 -I $INTERFACE_NAME -q -w $MAX_PING_TIME $YELLOW_LED_CHECK_URL | grep "1 received")
    if [[ -n $gateway_connect ]];
    then 
        $CLI_APP gpio write 2 1 >> /dev/null
    else
        $CLI_APP gpio write 2 0 >> /dev/null
    fi
done