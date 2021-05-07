<#
Script to deploy the neccesary Azure services to host a network admin control panel. 
Created: 5/6/2021
Author: Joshua Bright 
https://github.com/josh-bright/NetAdminCP
#>

## Set variables (DO NOT REMOVE GET-RANDOM COMMANDS)
$resourceGroup = "rg-NetAdminCP"
$location = "EastUS"
$workspaceName = "log-analytics-" + (Get-Random -Maximum 999999)
$automationAccountName = "automation-account-" + (Get-Random -Maximum 999999)
$runbookName = "ConfigurePortSecurity"
$webhookName = "ConfigurePortSecurity-Webhook"
$webhookExpiryTime = "5/7/2025"
$webAppName = "NetAdminCP-" + (Get-Random -Maximum 999999)


## Create Resource Group
New-AzResourceGroup -Name $resourceGroup -Location $location

## Create Log Analytics workspace
New-AzOperationalInsightsWorkspace -Location $Location -Name $workspaceName -Sku Standalone -ResourceGroupName $resourceGroup

## Enable the Azure Automation solution in your Log Analytics workspace 
Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $resourceGroup -WorkspaceName $workspaceName -IntelligencePackName "AzureAutomation" -Enabled $True

#### Pause to install log analytics agent on Linux VM
Read-Host "Please refer to step 4. Once finished, press ENTER to continue"

## Create Azure Automation Account
New-AzureRmAutomationAccount -Name $automationAccountName -Plan Basic -Location $location -ResourceGroupName $resourceGroup

#### Pause to add machine to Hybrid Runbook Worker group (which also creates it) & turn off signature validation
Read-Host "Please refer to step 5. Once finished, press ENTER to continue"

## Get name of Hybrid Worker Group specified during manual VM configuration
$hybridWorkerGroupName = (Get-AzureRMAutomationHybridWorkerGroup -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName).Name

## Clone the GitHub repo into a local directory for easy access
git clone https://github.com/josh-bright/NetAdminCP.git ./NetAdminCP

## Import python3 runbook
Import-AzAutomationRunbook -Path ./NetAdminCP/ConfigurePortSecurity.py -Name $runbookName -Type Python3 -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName

## Publish the newly imported runbook
Publish-AzureRMAutomationRunbook -Name $runbookName -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName

## Create Webhook for the previously imported runbook
New-AzAutomationWebhook -Name $webhookName -IsEnabled $True -ExpiryTime $webhookExpiryTime -RunbookName $runbookName -ResourceGroupName $resourceGroup -AutomationAccountName $automationAccountName -RunOn $hybridWorkerGroupName

#### Pause to give user time to copy the webhook URL (it is only able to be retrieved upon creation)
Read-Host "Please refer to step 6. Once finished, press ENTER to continue"
Read-Host "Are you sure you finished step 6? Press ENTER to continue"

## Change directory to web app root
cd ./NetAdminCP/azwebapp/

## Deploy Azure Web App in App Service
az webapp up --resource-group $resourceGroup --location $location --name $webAppName --html

## Notify user that deployment has finished
Write-Output "Automatic deployment finished. You may close this Cloud Shell session."

