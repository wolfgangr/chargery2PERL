DEVICE="-F $1"
DEVICE="-F /dev/ttyChargery"
stty $DEVICE -a
echo "------ apply changes -----"
stty $DEVICE 115200 raw
stty $DEVICE time 2
stty $DEVICE -echo -echoe -echok -echoctl -echoke
echo "------ done -------"
stty $DEVICE -a

echo "----- simple output -----"
stty $DEVICE
