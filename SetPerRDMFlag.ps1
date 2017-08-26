# This script sets the PereniallyReserved flag for RDM datastores that are part of a Microsoft cluster.
# Main reason is to lower the boot time or rescan times of the hosts as these are waiting for the datastore when booting/rescan.

# In a scenario where you have to reboot a host that is participating in a Microsoft cluster, you will notice slow boot up or rescan times for the host.
# This is because the active node will still have scsi reservations on the rdm lun which will inadvertently cause the hypervisor to slow down during boot or rescans as it tries
# to interrogate each of the devices it is presented, including the MSCS RDM’s (which are actually active on other node) LUNs during storage discovery. It will fail the reserved/active RDM’s and retries until ESXi gives up and moves along.
# With hosts that have a lot of RDM’s this can take a while to finish. Seen times up to 2 hours.

# This script connects to the defined cluster and get’s VM’s configured with a shared physical scsi controller and that vm’s RAW disks canonical names.
# It then connects to all hosts in that cluster and set’s the canonical devices to PereniallyReserved (does not make sense, but is configured in this environment. DRS no, HA is for discussion)

# See KB 1016106 for details (http://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=1016106&src=vmw_so_vex_pheld_277)

# Settings
$vCenter = “<vcenter fqdn>” # vCenter hosts name, the user that is running needs access to the vCenter instance.

$Cluster = “<clustername as shown in inventory>” # Cluster to connect to

# Connect to vCenter
Connect-VIServer -Server $vCenter

# Get the hosts from the cluster
$VMhosts = Get-Cluster $Cluster | Get-VMHost

# We need VM’s with RDM’s with SCSI Bus Sharing on Physical (as per vSphere MSCS guide/checklist)
# Check with OldVM and VM’s is added to filter out VM’s with more than one vscsi controller.
Get-VM -Location $Cluster | Get-ScsiController | Where-Object {$_.BusSharingMode -eq “Physical”} | ForEach {
	$VMs=$_.Parent.Name
	# Get RDM Disk of these VM’s
	# RDM’s can be either Virtual or Physical, look for both types.
	# We want an export of the disk information found, comment out the line with Export-CSV when you don’t need or takes a long time.
	If ($VMs -ne $OldVM){
		Get-VM -Name $VMs | Get-HardDisk -DiskType “RawPhysical”,”RawVirtual” | Select-Object -Property Parent, Name, DiskType, FileName, CapacityGB, ScsiCanonicalName | Export-CSV D:\Scripts\MSCSRDMs\RDM-List-$VMs.csv
		$RDMs = Get-VM -Name $VMs | Get-HardDisk -DiskType “RawPhysical”,”RawVirtual” | Select-Object -Property ScsiCanonicalName

		# Get EsxCli for each host in the cluster
		ForEach($hostName in $VMhosts) {
			$esxcli=Get-EsxCli -VMHost $hostName
			# And set each RDM disk found to PereniallyReserved
			ForEach($RDM in $RDMs) {
				# Set the configuration to “PereniallyReserved”.
				$esxcli.storage.core.device.setconfig($false, ($RDM.ScsiCanonicalName), $true)
			}
		}
	} 
	$OldVM= $VMs
}

# Disconnect all the connection objects as we are finished.
Disconnect-VIServer * -Confirm:$false