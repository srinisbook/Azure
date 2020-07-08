Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $VirtualMachineName,
    [string] [Parameter(Mandatory=$False)] $VirtualNetworkName,
    [switch] $DeleteOSDisk
)

$ErrorActionPreference = 'Stop'

if ( $null -eq (Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Verbose -ErrorAction SilentlyContinue) )
{
    Write-Host "Virtual Machine with name $VirtualMachineName is not found."
}
else {

    $vm = Get-AzVm -Name $VirtualMachineName -ResourceGroupName $ResourceGroupName
    
    $Os_Disk_Name = $vm.StorageProfile.OsDisk.Name
    $NIC_Name = $vm.NetworkProfile.NetworkInterfaces.ID.Split('/')[-1]
    
    $NIC = Get-AzNetworkInterface   -Name $NIC_Name `
                                     -ResourceGroupName $ResourceGroupName
    
    $PublicIPAddress_ID = $NIC.IpConfigurations.PublicIpAddress.Id
    $PublicIPAddress_Name = $PublicIPAddress_ID.Split('/')[-1]

    Write-Host "`nDelete Virtual Machine $VirtualMachineName."
    Remove-AzVM -ResourceGroupName $ResourceGroupName `
                -Name $VirtualMachineName `
                -Force `
                -Confirm:$False `
                -Verbose `
                -ErrorVariable ErrorMessage
    
    if ($ErrorMessage) {
        Write-Host '', 'Deleting Virtual Machine failed with following errors:', @(@($ErrorMessage) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }

    Write-Host "Delete Network interface $NIC_Name.`n"
    Remove-AzNetworkInterface   -ResourceGroupName $ResourceGroupName `
                                -Name $NIC_Name `
                                -Force `
                                -Confirm:$False `
                                -Verbose `
                                -ErrorVariable ErrorMessage
    if ($ErrorMessage) {
        Write-Host '', 'Deleting Network interface failed with following errors:', @(@($ErrorMessage) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }

    Write-Host "`nDelete Public IP $PublicIPAddress_Name."
    Remove-AzPublicIpAddress    -Name $PublicIPAddress_Name `
                                -ResourceGroupName $ResourceGroupName `
                                -Force `
                                -Verbose 


    if($DeleteOSDisk) {

        Write-Host "`nDelete Disk $Os_Disk_Name."
        Remove-AzDisk   -ResourceGroupName $ResourceGroupName `
                        -DiskName $Os_Disk_Name `
                        -Force `
                        -Confirm:$False `
                        -Verbose `
                        -ErrorVariable ErrorMessage
    }
}

if($VirtualNetworkName) {

    $NSG_ID = ( Get-AzVirtualNetwork -Name $VirtualNetworkName -ResourceGroupName $ResourceGroupName ).Subnets.NetworkSecurityGroup.Id
    $NSG_Name = $NSG_ID.Split('/')[-1]

    Write-Host "`nDelete VirtualNetwork $VirtualNetworkName."
    
    Remove-AzVirtualNetwork     -ResourceGroupName $ResourceGroupName `
                                -Name $VirtualNetworkName `
                                -Force `
                                -Confirm:$False `
                                -Verbose `
                                -ErrorVariable ErrorMessage
    
    if ($ErrorMessage) {
        Write-Host '', 'Deleting VirtualNetwork failed with following errors:', @(@($ErrorMessage) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
    
    Write-Host "`nDelete Network security group $NSG_Name."

    Remove-AzNetworkSecurityGroup   -Name $NSG_Name `
                                    -ResourceGroupName $ResourceGroupName `
                                    -Force `
                                    -Verbose 

    if ($ErrorMessage) {
        Write-Host '', 'Deleting network security group failed with following errors:', @(@($ErrorMessage) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }
}