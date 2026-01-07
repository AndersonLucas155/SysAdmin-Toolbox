<#
.SYNOPSIS
    Atualiza o sufixo UPN de usuários no Azure AD em massa.
.DESCRIPTION
    Script útil para migrações de domínio ou correções de sincronização (AD Connect).
    Substitui o domínio antigo (ex: onmicrosoft.com) pelo novo domínio verificado.
.PARAMETER OldDomain
    O domínio que deve ser removido (Ex: empresa.onmicrosoft.com).
.PARAMETER NewDomain
    O domínio correto (Ex: empresa.com).
.PARAMETER UserList
    Array de UPNs ou ObjectIDs que devem ser processados.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$OldDomain,

    [Parameter(Mandatory=$true)]
    [string]$NewDomain,

    [Parameter(Mandatory=$true)]
    [string[]]$UserList
)

# Verifica conexão
try { Get-AzureADTenantDetail -ErrorAction Stop | Out-Null }
catch { Connect-AzureAD }

foreach ($UPN in $UserList) {
    try {
        $User = Get-AzureADUser -ObjectId $UPN -ErrorAction Stop
        
        if ($User.UserPrincipalName -like "*$OldDomain") {
            $NewUPN = $User.UserPrincipalName.Replace($OldDomain, $NewDomain)
            
            Set-AzureADUser -ObjectId $User.ObjectId -UserPrincipalName $NewUPN
            Write-Host "[SUCESSO] $UPN alterado para $NewUPN" -ForegroundColor Green
        }
        else {
            Write-Host "[SKIP] $UPN não contém o domínio antigo ($OldDomain)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[ERRO] Falha ao processar $UPN : $($_.Exception.Message)" -ForegroundColor Red
    }
}