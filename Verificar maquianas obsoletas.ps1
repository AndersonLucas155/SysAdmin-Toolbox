# --- CONFIGURAÇÕES ---
$DiasInatividade = 90
$DataLimite = (Get-Date).AddDays(-$DiasInatividade)

# Caminhos (AD)
$DomainDN = (Get-ADRootDSE).defaultNamingContext
$Origem   = "CN=Computers,$DomainDN"
$Destino  = "OU=Computadores Desativados,OU=Computers IRON,OU=Iron Studios INC,$DomainDN"

# Limpa tela e inicia
Clear-Host
Write-Host "--- LIMPEZA SEGURA DE MAQUINAS ($DiasInatividade+ dias sem logon) ---" -ForegroundColor Cyan
Write-Host "Origem:  $Origem"
Write-Host "Destino: $Destino"
Write-Host "Regra:   Se responder Ping, NAO MOVE.`n" -ForegroundColor Yellow

# Contadores
$Movidas = 0
$Zumbis  = 0
$Erros   = 0

try {
    # 1. Buscar Candidatas
    $Candidatas = Get-ADComputer -Filter { LastLogonDate -lt $DataLimite -and Enabled -eq $true } -SearchBase $Origem -Properties LastLogonDate -ErrorAction Stop
    
    if ($Candidatas.Count -eq 0) {
        Write-Host "Nenhuma maquina inativa encontrada na origem." -ForegroundColor Green
        return
    }

    Write-Host "Encontradas $($Candidatas.Count) maquinas inativas. Iniciando triagem...`n" -ForegroundColor Gray

    # 2. Loop de Verificação e Ação
    foreach ($PC in $Candidatas) {
        
        # Teste de Vida (Ping rápido)
        # -Count 2 (tenta 2 vezes)
        # -Quiet (retorna True ou False direto)
        $EstaViva = Test-Connection -ComputerName $PC.Name -Count 2 -Quiet -ErrorAction SilentlyContinue

        if ($EstaViva) {
            # --- CENÁRIO ZUMBI (Não Mover) ---
            Write-Host "[PULADO] $($PC.Name)" -NoNewline -ForegroundColor Red
            Write-Host " -> Respondeu ao Ping (Zumbi/DNS Sujo). Mantido no lugar." -ForegroundColor Gray
            $Zumbis++
        }
        else {
            # --- CENÁRIO MORTO (Mover) ---
            Write-Host "[MOVENDO] $($PC.Name)" -NoNewline -ForegroundColor Green
            Write-Host " -> Offline. Movendo..." -NoNewline -ForegroundColor Gray
            
            try {
                # O COMANDO REAL (Remova -WhatIf para executar)
                Move-ADObject -Identity $PC.DistinguishedName -TargetPath $Destino -ErrorAction Stop -WhatIf
                
                Write-Host " [SUCESSO]" -ForegroundColor Green
                $Movidas++
            }
            catch {
                Write-Host " [ERRO]" -ForegroundColor Red
                Write-Host "   Detalhe: $_" -ForegroundColor DarkRed
                $Erros++
            }
        }
    }

    # 3. Resumo Final
    Write-Host "`n----------------------------------------"
    Write-Host "RESUMO DA OPERACAO" -ForegroundColor Cyan
    Write-Host "Movidas para Desativados: $Movidas" -ForegroundColor Green
    Write-Host "Zumbis (Pulos de Seguranca): $Zumbis" -ForegroundColor Red
    Write-Host "Erros de Movimentacao:    $Erros" -ForegroundColor Yellow
    Write-Host "----------------------------------------"
}
catch {
    Write-Host "ERRO FATAL: $_" -ForegroundColor Red
    Write-Host "Verifique se a OU de destino existe exatamente com esse nome." -ForegroundColor Yellow
}