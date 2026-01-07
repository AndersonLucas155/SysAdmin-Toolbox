<#
.SYNOPSIS
    Relatório de Auditoria de Computadores Inativos (Caça-Fantasmas do AD).
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Cole o caminho DN da OU aqui (Ex: OU=Computers,DC=empresa,DC=com)")]
    [string]$TargetOU,

    [Parameter(Mandatory = $false)]
    [int]$DiasInativo = 120
)

# Verifica se o módulo existe antes de tentar importar
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Error "O módulo ActiveDirectory não foi encontrado nesta máquina."
    return
}
Import-Module ActiveDirectory

$DataCorte = (Get-Date).AddDays(-$DiasInativo)
Write-Host "`n--- INICIANDO AUDITORIA ---" -ForegroundColor Cyan
Write-Host "Alvo: $TargetOU" -ForegroundColor Gray
Write-Host "Corte: Máquinas sem login desde $DataCorte ($DiasInativo dias)" -ForegroundColor Gray

try {
    $Computadores = Get-ADComputer -Filter * -SearchBase $TargetOU -Properties LastLogonDate, IPv4Address, Description -ErrorAction Stop
}
catch {
    Write-Error "Erro ao acessar a OU. Verifique se o caminho DN está correto e se você tem permissão."
    Write-Host "Detalhe: $($_.Exception.Message)" -ForegroundColor Red
    return
}

# Processamento e Saída na Tela
foreach ($PC in $Computadores) {
    
    if ($null -eq $PC.LastLogonDate) {
        $Status = "ZUMBI"
        $Cor = "Red"
    }
    elseif ($PC.LastLogonDate -lt $DataCorte) {
        $Status = "OBSOLETO"
        $Cor = "Yellow"
    }
    else {
        $Status = "OK"
        $Cor = "Green"
    }

    # Mostra na tela imediatamente
    Write-Host "[$Status] $($PC.Name) - $($PC.LastLogonDate)" -ForegroundColor $Cor
}

Write-Host "`n--- FIM DA AUDITORIA ---" -ForegroundColor Cyan