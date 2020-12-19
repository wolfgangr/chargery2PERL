#!/usr/bin/perl

#### this is just an enpty stub
#
# try to conifgure serial line for proper RS485
#
# https://perldoc.perl.org/functions/ioctl
#
# https://www.kernel.org/doc/html/latest/driver-api/serial/serial-rs485.html


require "sys/ioctl.ph";


# my $retval = ioctl(...) || -1;
# printf "System returned %d\n", $retval;


# print $ER_RS485_ENABLED;


# /* Open your specific device (e.g., /dev/mydevice): */
# int fd = open ("/dev/mydevice", O_RDWR);
# if (fd < 0) {
#         /* Error handling. See errno. */
# }

# struct serial_rs485 rs485conf;

# /* Enable RS485 mode: */
# rs485conf.flags |= SER_RS485_ENABLED;

# /* Set logical level for RTS pin equal to 1 when sending: */
# rs485conf.flags |= SER_RS485_RTS_ON_SEND;
# /* or, set logical level for RTS pin equal to 0 when sending: */
# rs485conf.flags &= ~(SER_RS485_RTS_ON_SEND);

# /* Set logical level for RTS pin equal to 1 after sending: */
# rs485conf.flags |= SER_RS485_RTS_AFTER_SEND;
# /* or, set logical level for RTS pin equal to 0 after sending: */
# rs485conf.flags &= ~(SER_RS485_RTS_AFTER_SEND);

# /* Set rts delay before send, if needed: */
# rs485conf.delay_rts_before_send = ...;

# /* Set rts delay after send, if needed: */
# rs485conf.delay_rts_after_send = ...;

# /* Set this flag if you want to receive data even while sending data */
# rs485conf.flags |= SER_RS485_RX_DURING_TX;

# if (ioctl (fd, TIOCSRS485, &rs485conf) < 0) {
#         /* Error handling. See errno. */
# }

