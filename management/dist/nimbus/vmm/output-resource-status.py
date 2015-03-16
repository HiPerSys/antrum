#!/usr/bin/python
#
# Created by: Joshua McKee
#
# Outputs resource information to a file
#
# These are the resource metrics provided:
# For memory information:
#  - Total memory (in kB): memory.memtotal
#  - Free memory (in kB):	memory.memfree
# For device information:
#  - Device has battery(s) (0|1): device.hasbattery
# (The following will be provided only if the device has a battery)
#  - Device is plugged in (0|1): device.pluggedin
# For battery information:
#  - For each battery:
#     - Battery status ('full'|'charging'|'discharging'): battery_[bat_no].status
#     - Battery capacity (in %): battery_[bat_no].capacity
#

import os
import re
import time
import glob

COLLECTION_INTERVAL = 30 # seconds
DESTINATION_FILE = "/tmp/resource_info"

if os.listdir("/sys/class/power_supply"):
    dev_hasbattery = 1
else:
    dev_hasbattery = 0

while True:
    f_output = open(DESTINATION_FILE,"w")
    f_meminfo = open("/proc/meminfo", "r")
    if dev_hasbattery:
        path_acinfo = glob.glob("/sys/class/power_supply/A*/online")
        with open(path_acinfo[0], "r") as f_acinfo:
            if f_acinfo.readline():
                dev_pluggedin = 1
            else:
                dev_pluggedin = 0

        f_batteryinfo = dict([])
        for bat in glob.glob("/sys/class/power_supply/BAT[0-9]*/uevent"):
            m = re.match("/sys/class/power_supply/BAT([0-9]*)/uevent", bat)
            if not m:
                continue
            bat_no = m.group(1)
            f_batteryinfo[bat_no] = open("/sys/class/power_supply/BAT%s/uevent" % bat_no, "r")

    # memory information
    f_meminfo.seek(0)
    for line in f_meminfo:
        m = re.match("(\w+):\s+(\d+)\s+(\w+)", line)
        if m and (m.group(1).lower() == 'memtotal' or m.group(1).lower() == 'memfree'):
            f_output.write("memory.%s %s\n" % (m.group(1).lower(), m.group(2)))

    # device information
    f_output.write("device.hasbattery %s\n" % dev_hasbattery)
    if dev_hasbattery:
        f_output.write("device.pluggedin %s\n" % dev_pluggedin)
    
    # battery information (if available)
    if dev_hasbattery:
        for bat_no in f_batteryinfo.keys():
            f = f_batteryinfo[bat_no]
            f.seek(0)
            for line in f:
                m = re.match("POWER_SUPPLY_(\w+)=(\w+)", line)
                if m and (m.group(1).lower() == 'capacity' or m.group(1).lower() == 'status'):
                    f_output.write("battery_%s.%s %s\n" 
                                   % (bat_no, m.group(1).lower(), m.group(2).lower()))
                
    f_output.close()
    time.sleep(COLLECTION_INTERVAL)
