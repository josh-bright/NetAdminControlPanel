#!/usr/bin/env python3

import os
import sys
import re
import netmiko

## WEBHOOK DATA EXTRACTION ##

# Capture webhook data and place into a string
webhook_data = str(sys.argv[1])

# Regex parameters to extract info from webhook message body
webhook_search = re.compile("net[^\']+")

# Search the webhook data using the previously declared regex
webhook_body = webhook_search.search(webhook_data)

# Transform extracted data into a list
webhook_body = webhook_body.group()

# Split the single string into multiple list entries at each comma
webhook_body = webhook_body.split('&')

# Remove HTML form input variables
webhook_body[0] = webhook_body[0].replace("networkdevice=", "")
webhook_body[1] = webhook_body[1].replace("deviceport=", "")
webhook_body[2] = webhook_body[2].replace("macaddress=", "")
webhook_body[3] = webhook_body[3].replace("username=", "")
webhook_body[4] = webhook_body[4].replace("password=", "")

# Replace URL encoded interface with correct form for interface
webhook_body[1] = webhook_body[1].replace("%2F", "/")

# Set variables containing the user's input parameters
hostname = webhook_body[0]
interface = webhook_body[1]
macaddress = webhook_body[2]
username = webhook_body[3]
password = webhook_body[4]

# Determine networking device to be configured
if (hostname == "IT_IDF1_SWT1"):
    net_device = {
        'device_type': 'cisco_ios',
        'host': '172.16.100.1',
        'username': username,
        'password': password,
        'secret': 'enablepassword',
        'port': 20022
    }
elif (hostname == "IT_IDF2_SWT1"):
    net_device = {
        'device_type': 'cisco_ios',
        'host': '172.16.200.1',
        'username': username,
        'password': password,
        'secret': 'enablepassword',
        'port': 20022
    }

## NETMIKO DEVICE CONNECTION ##
# Initialize variables
command = ''

# Establish SSH connection to specified device
ssh_connection = netmiko.ConnectHandler(**net_device)

# Enter enable mode
ssh_connection.enable()

# Enter configuration mode
ssh_connection.config_mode()

# Enter configuration-if mode of the specified interface (e.g. FastEthernet0/1)
command = 'interface ' + interface
ssh_connection.send_command(command)

# Remove any previously configured sticky MAC address
command = 'no switchport port-security mac-address sticky'
ssh_connection.send_command(command)

# Set new MAC address allowed to communicate on the above specified port (MAC address format: 0000.0000.0000)
command = 'switchport port-security mac-address sticky'
ssh_connection.send_command(command)

command = 'switchport port-security mac-address sticky ' + macaddress
ssh_connection.send_command(command)

# Disable the prompt to accept the copy run start filename
ssh_connection.config_mode()
command = 'file prompt quiet'
ssh_connection.send_command(command)

# Copy the running configuration to the startup configuration in order to save the changes made
ssh_connection.exit_config_mode()
command = 'copy running-config startup-config'
ssh_connection.send_command(command)

# Re-enable the prompt to accept the copy run start filename
ssh_connection.config_mode()
command = 'file prompt alert'
ssh_connection.send_command(command)

# End the SSH connection
ssh_connection.disconnect()