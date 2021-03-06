#!/bin/bash
echo "ENABLING GPRS CONNECTION ........"
# enable UART pins that you are going to use on Olemexino Nano gsm module, uncomment the line below
#https://learn.adafruit.com/fona-tethering-to-raspberry-pi-or-beaglebone-black/wiring
#UART1 RX=P9_26, TX=P9_24,CTS=P9_20, RTS=P9_19 /dev/ttyO1
#UART2 RX=P9_22, TX=P9_21,                     /dev/ttyO2
#UART4 RX=P9_11, TX=P9_13,CTS=P9_35, RTS=P9_33 /dev/ttyO4
#UART5 RX=P9_38, TX=P9_37,CTS=P9_31, RTS=P9_32 /dev/ttyO5

# add line below in  /boot/uEnv.tx #i used the duplacate file thar i create in order to keep the orginal file safe (uEnv_cp.txt)
# to  enabled UART port1, 2,4, and 5 ;UART3 is a transmit only UART

cd /boot
fileuEnv=uEnv.txt

uart_ports=`grep -c "cape_enable=capemgr.enable_partno=BB-UART1,BB-UART2,BB-UART4,BB-UART5" "$fileuEnv"`

if [ $uart_ports -eq 1 ]
then
        echo "UART ports 1,2,4 and 5 are already enabled"
else
        echo "UART ports 1,2,4 and 5 are now enabled"
        # ttyO4 will be installed by gprs code
        sudo echo "cape_enable=capemgr.enable_partno=BB-UART1,BB-UART2,BB-UART5" >> /boot/uEnv.txt
fi

echo "connect Olimexino nano GSM module RX to TX of bbb"
echo "connect Olimexino nano GSM module Tx to Rx of bbb"
echo "connect Olimexino nano GSM module GND to GND of bbb"
echo "connect Olimexino nano GSM module CON1_2 to - of external Battery"
echo "connect Olimexino nano GSM module CON1_6 to + of external Battery"
#Software setup
#Install and setup the ppp(Point-to-Point Protocol) software
#You can ignore any warnings about software already being installed.
sudo apt-get update
if [ -d /etc/ppp/peers ]
then
        echo "peers Directory is available, install the ppp config"
else
        sudo apt-get install ppp screen elinksa
        echo "Point to point protocol is installed"
fi

#in case you need to test whether the GPRS module is well connected
#echo TYPE  AT in Blank window TO CHECK WETHER FONA IS RESPONDING,you might not see the AT characters echoed back as you type, don't worry that's ok.
#If you see the OK response then communication with FONA is working great if not check wiring, To close screen press Ctrl-A and type :quit and press enter.
#uncomment the line below but it will stop your automatic installation and wait your responce
# ttyO2 is your selected UART pin
#screen /dev/ttyO2 115200


#PPP Configuration
#cd /etc/ppp/peers/
if [ -f /etc/ppp/peers/fona ]
then
        echo "fona configuration file already installed"
else
        cd /etc/ppp/peers/
        #download this configuration file inside this peers directory which define how each ppp connection is setup and rename it fona
        sudo wget --no-check-certificate https://raw.githubusercontent.com/adafruit/FONA_PPP/master/fona
        echo "fona configuration file is installed"

        # Edit this configuration file on APN, we use internet.mtn and serial port to use is ttyO4
        #let use sed to replace default APN "****" to "internet.mtn".
        sudo  sed -i "s/\*\*\*\*/internet.mtn/g" /etc/ppp/peers/fona
        sudo echo "/dev/ttyO4" >> /etc/ppp/peers/fona
fi

#Automatic PPP Connection On Boot
#Edit the /etc/network/interfaces file
# add lines below at the bottom of the file.
#i used to duplicate the interfaces file so that i keep the orginal safely but it does not work
# it does not boot on the copy of the interfaces file.


#---------------useful to enable gprs connection on boot----
#___we don't need this bcz we will use command to enable and disable gprs connection
#cd /etc/network/
#file=interfaces
#fonaauto=`grep -c "auto fona" "$file"`
#fonaiface=`grep -c "iface fona inet ppp" "$file"`
#fonaprovider=`grep -c "provider fona" "$file"`

#if [ $fonaauto -eq 1 ] && [ $fonaiface -eq 1 ] &&  [ $fonaprovider -eq 1 ]
#then
#        echo "auto ppp connection files are already added"
#else
#        echo "auto ppp connection files are added"
#        sudo echo "auto fona
#        iface fona inet ppp
#        provider fona" >>  /etc/network/interfaces
#fi

#*******************************************************************************************************************************************
#Set up emonTx baud rate
#update emonTx firmware, http://openenergymonitor.org/emon/buildingblocks/installing-arduino-libraries
#http://openenergymonitor.org/emon/buildingblocks/uploading-arduino-firmware
#After to upload this firmware, connect the UART  EmonTx programming header to beaglebone
###### we should keep using this UART2 for emonTx due to github file
#- Pin 1 (GND) of EmonTx programming header  to GND of BeagleBone (P9_1)
#- Pin 2  of EmonTx , not connected
#- Pin 3 (Vcc) of EmonTx to 5V DC of BeagleBone (P9_4)
#- Pin 4 (TX: written on the board) of EmonTx to TX of BeagleBone (P9_21)
#- Pin 5 (RX: written on the board) of EmonTx to RX of BeagleBone (P9_22)
#- Pin 6 RST of EmonTx, not connected

stty -F /dev/ttyO2 9600

echo "COMMUNICATION BETWEEN BEAGLEBONE AND GPRS Module ESTABLISHED, use uart4: RX=P9_11, TX=P9_13"
echo "SERIAL COMMUNICATION THROUGH ttyO2 IS SET TO  9600 baud rate, use uart2: RX=P9_22, TX=P9_21"

echo "Please, Reboot the bbb to save configuration"

