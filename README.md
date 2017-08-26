# Set-RDMPereniallyReserved-flag
Set RDM PereniallyReserved Flag via PowerCLI

This script sets the PereniallyReserved flag for RDM datastores that are part of a Microsoft cluster.
Main reason is to lower the boot time or rescan times of the hosts as these are waiting for the datastore 
when booting/rescan.

In a scenario where you have to reboot a host that is participating in for example a Microsoft cluster, 
you will notice slow boot up or rescan times for the host.
This is because the active node will still have scsi reservations on the rdm lun 
which will inadvertently cause the hypervisor to slow down during boot or rescans as it tries
to interrogate each of the devices it is presented, 
including the MSCS RDM’s (which are actually active on other node) LUNs during storage discovery. 
It will fail the reserved/active RDM’s and retries until ESXi gives up and moves along.
With hosts that have a lot of RDM’s this can take a while to finish. Seen times up to 2 hours.

This script connects to the defined cluster and get’s VM’s configured with a shared physical scsi controller 
and that vm’s RAW disks canonical names.
It then connects to all hosts in that cluster and set’s the canonical devices to PereniallyReserved 
(does not make sense, but is configured in this environment. DRS no, HA is for discussion)

Some backgroud is in my blog post: https://pascalswereld.nl/2014/09/03/powercli-collection-setting-rdm-pereniallyreserved-flag-on-rdm-luns-used-by-mscs-nodes-that-take-a-long-time-to-scan-or-boot/.
