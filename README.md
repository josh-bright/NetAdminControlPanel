# Network Admin Control Panel

This repository contains a proof of concept network admin control panel that makes it easy to configure an on-premises Cisco switch using a web interface. This project can be evolved to include many different configuration options in a multi-vendor environment.

# Logical Diagram
![Logical Diagram](https://github.com/josh-bright/NetAdminCP/blob/main/images/logicaldiagram.jpg)
# Data Flow Diagram
![Data Flow Diagram](https://github.com/josh-bright/NetAdminCP/blob/main/images/dataflowdiagram.jpg)

# Services Used
## Azure

 - Log Analytics Workspace
 - Log Analytics Agent
 - Automation Account
 - Hybrid Runbook Worker
 - Python 3 Runbook
 - App Service

## On-Premises
- Ubuntu Server 18.04 VM
- Python 3
	- Netmiko module

# Pillars of Azure Well Architected Framework
## Cost Optimization
## Operational Excellence
## Performance Efficiency
## Reliability
## Security

# Deployment
Since this project involves on-premises resources, some manual configuration is required. Throughout the Azure PowerShell deployment script ([autodeployment.ps1](https://github.com/josh-bright/NetAdminCP/blob/main/autodeployment.ps1)) it will pause to allow you to configure the neccesary on-premises resource before continuing.

**Note: You MUST follow the process exactly as detailed below. If you do not, the Azure environment will not be configured correctly!**

## Requirements & Prerequisites
- Virtual machine running [Ubuntu Server 18.04 LTS](https://releases.ubuntu.com/18.04.5/ubuntu-18.04.5-live-server-amd64.iso)
- Cisco switch connected to the network
- Internet connection

## Step 1 - Configure Local Machine
### Before beginning this step, ensure you are executing commands as the root user

    su
OR

    sudo bash

### Update and Refresh Repository Lists

    sudo apt update

### Install Python 3
    sudo apt install python3

### Install Python-pip

    sudo apt install python3-pip

### Install Netmiko

    pip3 install netmiko

### [Install PowerShell Core](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1#ubuntu-1804)
PowerShell core is neccesary to enable the hybrid runbook worker (which will be configured later) to execute the python script.

    # Install pre-requisite packages.
    sudo apt-get install -y wget apt-transport-https software-properties-common
    
    # Download the Microsoft repository GPG keys
    wget -q https://packages.microsoft.com/config/ubuntu/18.04/packages-microsoft-prod.deb
    
    # Register the Microsoft repository GPG keys
    sudo dpkg -i packages-microsoft-prod.deb
    
    # Update the list of products
    sudo apt-get update
    
    # Enable the "universe" repositories
    sudo add-apt-repository universe
    
    # Install PowerShell
    sudo apt-get install -y powershell

## Step 2 - Configure the Auto Deployment Script Variables
Copy the [autodeployment.ps1](https://github.com/josh-bright/NetAdminCP/blob/main/autodeployment.ps1) file into a text editor of your choice. Configure the variables at the top of the file to meet your naming and location needs.

## Step 3 - Run the Auto Deployment Script
After configuring the variables, open Cloud Shell in the Azure Portal. *If you do not already have a storage account configured to use Cloud Shell, follow the onscreen prompt to create one.*

Ensure you have selected a PowerShell Cloud Shell session. Copy and paste the contents of the modified file into the terminal. The configuration will begin immediately. **When the script pauses and asks for input, refer back to this guide with the step number it provides!**

## Step 4 - Install the Log Analytics Agent
If you do not have the Azure Portal open, do so and navigate to the newly created Log Analytics Workspace inside of the newly created resource group. You must obtain the workspace ID and key. These can be found under Agents Management -> Linux Servers. 

Replace the placeholders in the following command with those two pieces of information. After editing the command, run it on your on-prem server.

    wget https://raw.githubusercontent.com/Microsoft/OMS-Agent-for-Linux/master/installer/scripts/onboard_agent.sh && sh onboard_agent.sh -w <YOUR WORKSPACE ID> -s <YOUR WORKSPACE PRIMARY KEY>

Once the command finishes installing the Log Analytics Agent, return to the Azure Cloud Shell and press ENTER to continue the configuration.

*[For additional references, please see this quickstart.](https://docs.microsoft.com/en-us/azure/azure-monitor/vm/quick-collect-linux-computer#install-the-agent-for-linux)*

## Step 5 - Connect to Hybrid Runbook Worker Group & Disable Signature Validation

Run the following command to add your machine to the hybrid runbook worker group, specifying the values for the `-w`, `-k`, `-g`, and `-e` parameters.

To get the values for `-k` and `-e` open the newly created Automation Account in the Azure Portal. Select Keys under the Account Settings header on the left-side navigation menu. These values will be displayed to the right.

The `-w` option is the same Log Analytics Workspace ID used in step 4. Refer to that step for directions on retrieving it.

For the `-g` parameter, please specify the name of the Hybrid Worker Group to be created. This can be anything you like.

    sudo python /opt/microsoft/omsconfig/modules/nxOMSAutomationWorker/DSCResources/MSFT_nxOMSAutomationWorkerResource/automationworker/scripts/onboarding.py --register -w <logAnalyticsworkspaceId> -k <automationSharedKey> -g <hybridGroupName> -e <automationEndpoint>

After the above command finishes, you must disable signature validation. To do this enter the following command on the on-prem machine **after** replacing the second parameter with your Log Analytics Workspace ID.

    sudo python /opt/microsoft/omsconfig/modules/nxOMSAutomationWorker/DSCResources/MSFT_nxOMSAutomationWorkerResource/automationworker/scripts/require_runbook_signature.py --false <logAnalyticsworkspaceId>

Once this has finished, return to the Azure Cloud Shell and press ENTER to continue the configuration.

## Step 6 - Save the Webhook URL
Once the webhook URL has been shown in the terminal, copy it and save it in a secure location. 

**It is important that you do not lose this, as there is no way to view it after this point.**

After you have ensured it has been saved, return to the Azure Cloud Shell and press ENTER to continue the configuration.

