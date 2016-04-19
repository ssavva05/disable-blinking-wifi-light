#! /usr/bin/env bash

if ! id | grep sudo > /dev/null
then
    printf "Error: you do not have sudo privileges.\n"
    exit 1
fi

# Turn off blinking wifi light.
# https://askubuntu.com/questions/12069/how-to-stop-constantly-blinking-wifi-led/

if ! test -d /etc/modprobe.d
then
    if ! sudo mkdir -p '/etc/modprobe.d/'
    then
        printf "Error: could not create directory /etc/modprobe.d/\n"
        exit 1
    fi
fi

config_file='/etc/modprobe.d/iwled.conf'

if ! test -f "$config_file"
then
    if ! sudo touch "$config_file"
    then
        printf "Error: could not create $config_file\n"
        exit 1
    fi
fi

for i in {0..9}
do
    if test -e "/sys/class/net/wlan$i/device/driver"
    then
        module="$(basename $(readlink /sys/class/net/wlan$i/device/driver))"
        break
    fi
done


if test -z $module
then
    printf "Error: Could not detect wifi driver name.\n"
    exit 1
fi

if ! test -f "/sys/module/$module/parameters/led_mode"
then
    printf "Error: driver ‘$module’ does not have ‘led_mode’ parameter.\n"
    exit 1
fi
# TODO: make it work with these as well:
# options ipw2200 led=0
# options ath9k blink=0


if ! test '1' -eq $(cat /sys/module/$module/parameters/led_mode)
then
    if ! sudo cp 'iwled.conf' "$config_file"
    then
        printf "Error: could not write to $config_file\n"
        exit 1
    else
        if sudo modprobe --remove "$module"
        then
            if sudo modprobe "$module"
            then
                exit 0
            else
                printf "Could not add module $module. Try rebooting to make changes.\n"
            fi
        else
            printf "Could not remove module $module. Try rebooting to make changes.\n"
            exit 1
        fi
    fi
fi

