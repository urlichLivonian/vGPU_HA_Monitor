#PowerCLI vGPU HA Monitor
#v1.00

function Main {

Add-PSSnapin "VMware.VimAutomation.Core" | out-null


######################################  Start User Parameters ##########################################

#Logging
$logFileLocation = $startupScriptPath + "\loggong.log"

#Email Notifications
$sendAlerts = $true
$fromaddress = "v.ivanitski@vrweartek.com" 
$toaddress = "v.ivanitski@vrweartek.com" 
$smtpserver = "mail.vrweartek.com"

#FQDN of the vCenter Server
$vCenter = "vcenter.vrweartek.com"

#Name of cluster containing vGPU ESXi Hosts
$clusterName = "Cluster" 

#Login for SSH/local access to ESXi servers 
$viHostUser = "root"
$viHostPassword = "SecretPassowrd"

#Amount of RAM in MB used per vGPU profile
#This number is used to determine available capacity on remaining vGPU Enabled ESXi hosts in realtime during a failover
$vGPUMemPerVM_In_MB = 512

#Num Min to wait between checking for host failure
$numMin = 1

}

Main