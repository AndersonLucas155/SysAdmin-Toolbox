# Importa módulo AD
Import-Module ActiveDirectory

# Caminho da OU problemática
$TargetOU = "OU=Nao_Identificado,OU=Computers IRON,OU=Iron Studios INC,DC=ironstudiosinc,DC=com"

# Define o limite de dias para considerar "Lixo" (Ex: 120 dias / 4 meses)
$DiasLimite = 120
$DataCorte = (Get-Date).AddDays(-$DiasLimite)

Write-Host "Analisando máquinas na OU: $TargetOU" -ForegroundColor Cyan

# Busca computadores com propriedades estendidas
$Computadores = Get-ADComputer -Filter * -SearchBase $TargetOU -Properties LastLogonDate, whenChanged, Description, IPv4Address

$Relatorio = New-Object System.Collections.Generic.List[PSCustomObject]

foreach ($PC in $Computadores) {
    
    # Determina o status baseado no LastLogonDate
    if ($null -eq $PC.LastLogonDate) {
        $Status = "ZUMBI (Nunca logou ou muito antigo)"
        $DiasInativo = "N/A"
        $Cor = "Red"
    }
    elseif ($PC.LastLogonDate -lt $DataCorte) {
        $TimeSpan = New-TimeSpan -Start $PC.LastLogonDate -End (Get-Date)
        $DiasInativo = $TimeSpan.Days
        $Status = "OBSOLETO ($DiasInativo dias off)"
        $Cor = "Yellow"
    }
    else {
        $TimeSpan = New-TimeSpan -Start $PC.LastLogonDate -End (Get-Date)
        $DiasInativo = $TimeSpan.Days
        $Status = "ATIVO"
        $Cor = "Green"
    }

    # Joga na tela colorido para facilitar visualização imediata
    Write-Host "$($PC.Name) -> $Status" -ForegroundColor $Cor

    $Relatorio.Add([PSCustomObject]@{
        Nome = $PC.Name
        UltimoLogin = $PC.LastLogonDate
        DiasInativo = $DiasInativo
        Status = $Status
        IP_Registrado = $PC.IPv4Address
        ModificadoEm = $PC.whenChanged # Só para curiosidade
    })
}

# Exibe tabela final ordenada pelos mais antigos
Write-Host "`n--- RELATÓRIO DE MÁQUINAS OBSOLETAS ---" -ForegroundColor Cyan
$Relatorio | Sort-Object LastLogonDate | Format-Table -AutoSize

# Dica: Se quiser exportar para mostrar pro chefe
# $Relatorio | Export-Csv "C:\Temp\Relatorio_Lixo_AD.csv" -NoTypeInformation -Encoding UTF8