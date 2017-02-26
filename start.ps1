#PowerCLI vGPU HA Monitor
#v0.10

function Main {

    Add-PSSnapin "VMware.VimAutomation.Core" | out-null
    $startupScriptPath = Get-Location

<######################################  Start User Parameters ##########################################>

    #Logging
    $logFileLocation = $startupScriptPath + "\vGPU_HA_Monitor.log"

    #Email Notifications
    $fromAddress = "v.ivanitski@vrweartek.com" 
    $toAddress = "v.ivanitski@vrweartek.com" 
    $smtpServer = "mail.vrweartek.com"

    #FQDN of the vCenter Server
    $vCenter = "vcenter.vrweartek.com."

    #Name of cluster containing vGPU ESXi Hosts
    $clusterName = "Cluster" 

    #Login for SSH/local access to ESXi servers 
    $viHostUser = "root"
    $viHostPassword = "SecretPassowrd"

    #Amount of RAM in MB used per vGPU profile
    #This number is used to determine available capacity on remaining vGPU Enabled ESXi hosts in realtime during a failover
    #k220q = 512 k240q = 1024
    $vGPUMemPerVM_In_MB = 512

    #Num Min to wait between checking for host failure
    $numMin = 1

<######################################  End User Parameters ##########################################>


    Stop-Transcript | out-null
    Start-Transcript -path $logFileLocation -append

    Write-Host  $(Get-Date): "Script Initialized..."
    Write-Host  $(Get-Date): "Current vGPU Cluster Stats:"

    #Connect to vCenter. You have do this every time in case the vCenter server was rebooted.
    $vCenterSession = Connect-ViServer -Server $vCenter -WarningAction SilentlyContinue | out-null
	
    $vGPUStats=Get-vGPUClusterStats -vCenter $vCenter -ClusterName $clusterName -vGPUMemPerVM_In_MB $vGPUMemPerVM_In_MB 

    Write-Host  $(Get-Date): "Will sleep every $numMin minutes until next host failure check..."
    Write-Host  $(Get-Date): "Nothing new will be logged until a host failure occurs in cluster $clusterName"



    #Loop indefinitely and sleep the specified number of minutes between loops 
    #before checking for a failure to have been registered in vCenter	
    while ($true){

        $time = (Get-Date).AddMinutes(-$numMin)

        #Connect to vCenter. You have do this every time in case the vCenter server was rebooted.
        $vCenterSession = Connect-ViServer -Server $vCenter -WarningAction SilentlyContinue | out-null

        #Query vCenter for any not responding events 
        $events = Get-VIEvent -Start $time -Type Error -Server $vCenter | Where {$_.FullFormattedMessage -match "responding"}  | Select-Object CreatedTime,Host

        Foreach ($event in $events){
            

        }





}



}

Function Get-vGPUClusterStats {
    Param ($vCenter, $clusterName,$vGPUMemPerVM_In_MB)
	$vmHosts = Get-Cluster -Server $vCenter -Name $clusterName | Get-VMHost
	$objs=@()
	foreach ($vmhost in ($vmhosts)) { 


		$vGPU_MemoryMaxKB_OnHost =(($vmhost.ExtensionData.Config.GraphicsInfo | Where-Object {$_.GraphicsType -eq 'shared'}) | Measure-Object -Property MemorySizeInKB -sum).Sum
		$vGPU_MemoryNeededKB_PerVM = $vGPUMemPerVM_In_MB*1KB
		$vGPU_MaxVMsAllowed_OnHost = [math]::ceiling($vGPU_MemoryMaxKB_OnHost/$vGPU_MemoryNeededKB_PerVM)
		$vGPU_CurrentVMs_OnHost = ($vmhost.ExtensionData.Config.GraphicsInfo | Where-Object {$_.GraphicsType -eq 'shared'}).Vm.Value.Count

		$obj = new-object psobject -Property @{
						   HostName = $vmhost.Name
						   ConnectionState = $vmHost.ConnectionState
						   MaxVgpuVMsAllowed = $vGPU_MaxVMsAllowed_OnHost
						   NumVgpuVMsRunning  = $vGPU_CurrentVMs_OnHost
						   AvailableVgpuVms  = $vGPU_MaxVMsAllowed_OnHost - $vGPU_CurrentVMs_OnHost
						   Utilization = [string]($vGPU_CurrentVMs_OnHost / $vGPU_MaxVMsAllowed_OnHost * 100 ) + '%'
					   }
		$objs+=$obj
	}

    $objs|ft -AutoSize HostName,ConnectionState,MaxVgpuVmsAllowed,NumVgpuVmsRunning,AvailableVgpuVms,Utilization | Out-Host

    return $objs

}

#Call the Main Function to  start script
Main