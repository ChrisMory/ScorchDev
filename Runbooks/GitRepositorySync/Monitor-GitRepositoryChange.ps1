﻿#requires -Version 3
<#
.Synopsis
    Check GIT repository for new commits. If found sync the changes into
    the current SMA environment

.Parameter RepositoryName
#>
Workflow Monitor-GitRepositoryChange
{
    Param(
    )
    $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
    
    $GlobalVars = Get-BatchAutomationVariable -Prefix 'Global' `
                                              -Name 'AutomationAccountName',
                                                    'SubscriptionName',
                                                    'SubscriptionAccessCredentialName',
                                                    'RunbookWorkerAccessCredentialName',
                                                    'ResourceGroupName'
    do
    {
        $NextRun = (Get-Date).AddSeconds(30)
        
        $RepositoryInformationJSON = Get-AutomationVariable -Name 'ContinuousIntegration-RepositoryInformation'
        $SubscriptionAccessCredential = Get-AutomationPSCredential -Name $GlobalVars.SubscriptionAccessCredentialName
        $RunbookWorkerAccessCredential = Get-AutomationPSCredential -Name $GlobalVars.RunbookWorkerAccessCredentialName
        
        $RepositoryInformation = $RepositoryInformationJSON | ConvertFrom-Json | ConvertFrom-PSCustomObject
        Foreach($RepositoryName in $RepositoryInformation.Keys -as [array])
        {
            Try
            {
                $UpdatedRepositoryInformation = Sync-GitRepositoryToAzureAutomation -RepositoryInformation $RepositoryInformation.$RepositoryName `
                                                                                   -AutomationAccountName $GlobalVars.AutomationAccountName `
                                                                                   -SubscriptionName $GlobalVars.SubscriptionName `
                                                                                   -SubscriptionAccessCredential $SubscriptionAccessCredential `
                                                                                   -RunbookWorkerAccessCredenial $RunbookWorkerAccessCredential `
                                                                                   -RepositoryName $RepositoryName `
                                                                                   -RepositoryInformationJSON $RepositoryInformationJSON `
                                                                                   -ResourceGroupName $GlobalVars.ResourceGroupName

                Set-AutomationVariable -Name 'ContinuousIntegration-RepositoryInformation' `
                                       -Value $UpdatedRepositoryInformation
            }
            Catch
            {
                Write-Exception -Stream Warning -Exception $_
            }
        }

        do
        {
            Start-Sleep -Seconds 5
            Checkpoint-Workflow
            $Sleeping = (Get-Date) -lt $NextRun
        } while($Sleeping)
    }
    while($true)
}
