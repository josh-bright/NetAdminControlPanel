# Overview

This repository contains a proof of concept network admin control panel that makes it easy to configure an on-premises Cisco switch using a cloud-hosted web interface. This project can be evolved to include many different configuration options in a multi-vendor environment. 

Please note, I created this for a college course as a final project with limited time. There are definitely ways this could be improved -- please see the [Future Revisions](https://github.com/josh-bright/NetAdminCP#future-revisions) section for further information on this.

# Table of Contents

 1. [Logical Diagram](https://github.com/josh-bright/NetAdminCP#logical-diagram)
 2. [Data Flow Diagram](https://github.com/josh-bright/NetAdminCP#data-flow-diagram)
 3. [Services Used](https://github.com/josh-bright/NetAdminCP#services-used)
 4. [5 Pillars of Azure Well-Architected Framework](https://github.com/josh-bright/NetAdminCP#5-pillars-of-azure-well-architected-framework)
 5. [Deployment](https://github.com/josh-bright/NetAdminCP#deployment)
 6. [Future Revisions](https://github.com/josh-bright/NetAdminCP#future-revisions)

# Logical Diagram
![Logical Diagram](https://github.com/josh-bright/NetAdminCP/blob/main/images/logicaldiagram.jpg)
# Data Flow Diagram
![Data Flow Diagram](https://github.com/josh-bright/NetAdminCP/blob/main/images/dataflowdiagram.jpg)

# Services Used
## Azure

 - Log Analytics
	 - Enables Azure to connect with the on-premises device in order to use the hybrid runbook worker.
 - Automation Account
	 - Manages the hybrid runbook worker and Python runbook.
 - Hybrid Runbook Worker
	 - Receives jobs from the Azure Automation Account and executes them on the local machine. This allows for the configuration of on-premises networking devices.
 - Python 3 Runbook
	 - Holds the script necessary to configure on-premises networking devices. Receives data from a webhook that contains specific configurations.
 - App Service
	 - Hosts the public-facing web panel, enabling the user to input configuration parameters to be passed via webhook to the on-premises device.

## On-Premises
- Ubuntu Server 18.04 VM
	- Acts as an intermediary between the Azure resources and on-premises networking devices.
- Python 3
	- Netmiko module
		- Enables Python scripts to connect to networking devices using SSH and pass configuration commands.

# 5 Pillars of Azure Well-Architected Framework
## Cost Optimization
This deployment, by default mainly utilizes free and pay-as-you-go plans in order to minimize the cost of such a simple application. These options can be easily changed if a more robust solution is necessary.
## Operational Excellence
By allowing less knowledgeable network administrators or lower-level systems administrators to change network device configurations using a web panel, this application promotes operational excellence in the workplace.  
## Performance Efficiency
As configured, this application utilizes mainly PaaS cloud infrastructure. Azure PaaS solutions use a shared pool of resources and are never limited to a single instance. This enables the user to focus more of their efforts towards the on-premises devices.
## Reliability
As previously mentioned, this application is built using Azure PaaS solutions. Since these services are never limited to a single device, the application is more reliable than one built using on-premises resources. If a user sees fit, there is the possibility to increase the redundancy of the on-premises server and networking devices in order to minimize the possibility of downtime.
## Security
This application requires the user to authenticate twice. Once to access the web panel, and once when submitting configuration changes over SSH. The second authentication ensures that even if the web panel authentication is circumvented, the user must have valid SSH credentials before configuring a network device. 

# Deployment
Since this project involves on-premises resources, some manual configuration is required. Throughout the Azure PowerShell deployment script ([autodeployment.ps1](https://github.com/josh-bright/NetAdminCP/blob/main/autodeployment.ps1)) it will pause to allow you to configure the necessary on-premises resource before continuing.

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
PowerShell core is necessary to enable the hybrid runbook worker (which will be configured later) to execute the Python script.

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

## Step 6 - Save the Webhook URI
Once the webhook URI has been shown in the terminal, copy it and save it in a secure location. 

**It is important that you do not lose this, as there is no way to view it after this point.**

After you have ensured it has been saved, return to the Azure Cloud Shell and press ENTER to continue the configuration.

## Step 7 - Paste in the Webhook URI
After the automatic deployment of Azure resources has finished, you must configure the webhook URI on the PortSecurity.html page. To do this, access the App Service Editor by navigating to it in the Azure Portal. It can be found in the newly created App Service, under Development Tools -> App Service Editor (Preview).

Using the panel on the right side, navigate to the ``portsecurity.html`` file. Once opened, use CTRL+F to find the string ``ENTER_WEBHOOK_URI_HERE``. Replace this test with the previously saved webhook URI. This change is automatically saved and you may close the window.

## Step 8 - Access the Web Panel
To access the web panel, navigate to the App Service created by the script. Under the essentials header in the middle of the screen, click on the URL (ending in .azurewebsites.net). This will take you to the login page. The default credentials are as follows.
Username: ``net_admin``
Password: ``P@ssw0rd!123``

## Step 9 - Handoff
Configuration of network device information can be changed in the Python runbook and HTML of the page. Login credentials may be configured in the ``login-page.js`` file. As this is a proof of concept, it will require additional configuration to work for your specific needs like adding the details of your network devices into ``ConfigurePortSecurity.py``.

# Future Revisions
- Change the method of authentication to be more secure, potentially using Azure AD, and allow for more users.
- Allow easier modification of the network devices that can be configured.
- Enable logging of commands issued using the web panel.
- Create a more redundant configuration of Azure and on-premises resources.
- Add a template page to make it easier for users to adapt this project to their own needs with minimal knowledge.
