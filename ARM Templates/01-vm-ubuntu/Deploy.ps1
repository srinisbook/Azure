Param(
    [string] [Parameter(Mandatory=$true)] $ResourceGroupName,
    [string] [Parameter(Mandatory=$true)] $Location,
    [string] $TemplateFile = 'template.json',
    [string] $ParametersFile = 'template.parameters.json',
    [switch] $ValidateOnly
)

$ErrorActionPreference = 'Stop'

$TemplateFile = [IO.Path]::Combine($PSScriptRoot, $TemplateFile)
$ParametersFile = [IO.Path]::Combine($PSScriptRoot, $ParametersFile)

# Create the resource group only when it doesn't already exist
if ( $null -eq (Get-AzResourceGroup -Name $ResourceGroupName -Location $Location -Verbose -ErrorAction SilentlyContinue)) 
{
    New-AzResourceGroup -Name $ResourceGroupName `
                        -Location $Location `
                        -Verbose `
                        -Force `
                        -ErrorAction Stop
}

if ($ValidateOnly) {
    
    $ErrorMessages = Test-AzResourceGroupDeployment     -ResourceGroupName $ResourceGroupName `
                                                        -TemplateFile $TemplateFile `
                                                        -TemplateParameterFile $ParametersFile
    if ($ErrorMessages) {
        Write-Host '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Host '', 'Template is valid.'
    }
}

else {
    
    $DeploymentName = "Create-Ubuntu-VM-" +(Get-Date).ToString("yyyy-MM-dd-HHmm")
    New-AzResourceGroupDeployment   -Name $DeploymentName `
                                    -ResourceGroupName $ResourceGroupName `
                                    -TemplateFile $TemplateFile `
                                    -TemplateParameterFile $ParametersFile `
                                    -Mode "Incremental" `
                                    -Force `
                                    -Verbose `
                                    -ErrorVariable ErrorMessages

    if ($ErrorMessages) {
        Write-Host '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
    }     
}