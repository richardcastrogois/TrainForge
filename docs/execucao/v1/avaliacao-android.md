# Retomar a avaliação Android

Checkpoint de23/10/2026: **APK debug 0.1.3+4**, backend Go0.4.0 e banco V1 local. Biblioteca e composição alimentar já podem ser consultadas sem Google. LoginGoogle real Androiddebug, reabertura, falha/retomada deconexão, refreshnatural e logout validados em23/10. Reentrada na mesma conta e exclusão autorizada passaram; OAuthrelease/HTTPS pendentes. [Resultados reais](auth-real-android-verification.json). Publicação dos incrementos noGitHub autorizada em23/10; nenhum deploy.

## Quando voltar ao notebook

No terminal PowerShell do VSCode:

```powershell
cd C:\dev\TrainForge\trainforge
.\tools\avaliar-android.ps1
```

O comando inicia somente o cluster deste clone, a API Go e o emulador existente TrainForge_Benchmark, configura a porta reversa e abre o app. Reutiliza o APK se fonte/configuração/checksum coincidirem; reinstala com preservação de dados somente se necessário. Não instala ferramentas, recria banco, importa novamente, limpa o emulador ou altera OAuth. Se8082 estiver ocupada por serviço desconhecido/indisponível, interrompe com diagnóstico.

1. Toque **Consultar biblioteca sem entrar**. Deve mostrar73movimentos e0programas. Busque pelo nome original, filtre pelos valores reais da fonte e abra um detalhe.
2. Confira autoria, contribuição, licença, links, versão e requisitos desconhecidos. Não há treino executável, instrução, dose, foto ou vídeo liberados nesta build.
3. Abra **Privacidade e dados** na entrada. Confira os limites de exclusão, registros temporários e backups; essa tela é pública.
4. Volte e toque **Consultar alimentos sem registrar consumo**. Deve mostrar6369referências (3484Ciqual/2885CoFID) e3sem base confirmada. Busque no idioma da fonte, filtre a fonte e abra a composição; confira licença, base por célula e distinção entre zero/ausência/traço/limite. Cadastro próprio/refeições/totais ainda não entregues.
5. Volte à entrada e toque **Entrar com Google**. Faça pessoalmente a entrada numa conta cadastrada em Test users. Senha,2FA e consentimento ficam somente no Google; não enviar tokens/senhas ao chat.
6. Confirme Conta conectada, feche/reabra, teste retomada de conexão e sair/entrar. Registre o resultado sem divulgar e-mail/token. Reabertura/rede/refresh/logout/reentrada passaram.

Se o login falhar, a tela apresenta erro seguro e permite tentar novamente; offline/timeout/429/5xx não apagam a sessão. O backend precisa estar ativo; o APK debug usa loopback via ADB, não é uma entrega remota autônoma.

Depois de validar a sessão, **Meus dados e privacidade** permite consultar/copiar páginas próprias e solicitar exclusão. O agente executou a exclusão da contaTrainForge deavaliação após autorização explícita do titular; confirmação, banco e reabertura foram conferidos. Para escolher testar: leia os limites, confirme uma entrada recente e digite a frase exata. ContaGoogle permanece independente. Se a limpeza local falhar após confirmação do servidor, use Concluir limpeza local; não é necessário repetir DELETE. Essa jornada passou com a conta real deavaliação. Entrar novamente após a exclusão cria uma nova contaTrainForge, sem reativar a antiga. [V1-013](privacidade-013.md).

## OAuth release: próxima ação manual

Debug já tem pacote/SHA conferidos. Para a variante release, abrir [clientes do projeto correto](https://console.cloud.google.com/auth/clients?project=bootcamp-treinos-ia), criar cliente OAuth do tipo **Android**, nome **TrainForge avaliação release**, pacote `com.example.trainforge` e SHA-1:

`24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D`

Preservar os clientes debug/Web existentes. Não é necessário enviar client secret. Depois confirmar cadastro; APK release também depende de API HTTPS. O debug já pode ser testado sem concluir esse cadastro. Os avisos de inatividade dos clientes existentes precisam ser conferidos após uso real. [Guia técnico OAuth](oauth-android.md).

## Parar e consultar

```powershell
.\tools\avaliar-android.ps1 -Action status
.\tools\avaliar-android.ps1 -Action stop
```

Stop encerra somente recursos registrados como iniciados pelo helper e confere a identidade do emulador. Dados, credenciais e chave de assinatura permanecem locais. Serviços já ativos e reutilizados não são assumidos como pertencentes ao helper.

Arquivo: `build/app/outputs/flutter-apk/app-debug.apk`. SHA-256: `aee2e72f49e82984357d3def33559083998b70405def21a6117f0700d788a585`. [Recibo de build/instalação](android-auth-checkpoint.json).

## Celular depois do emulador

Com o notebook disponível: ativar opções de desenvolvedor/depuração USB no celular, conectar por USB e aceitar a chave do computador na tela do aparelho. Usar `adb devices` para conferir o serial e então `.\tools\avaliar-android.ps1 -Serial SERIAL_CONFIRMADO`. O helper não escolhe celular automaticamente. Não desinstalar o app para resolver assinatura: debug e release usam certificados distintos. A orientação pode ser feita passo a passo quando o autor tiver o aparelho.

## Cobertura e lacunas

| Capacidade | Estado nesta build |
|---|---|
| Google, sessão, refresh/logout | LoginGoogle Androiddebug, refreshnatural, logout e reentrada reais validados; release/HTTPS pendentes |
| Biblioteca de referência |73metadados reais, busca/filtros, paginação e detalhes; testada com API/DB/emulador |
| Programas completos/coleções |0disponíveis; vazio explícito |
| Idosos, cuidadores, casa, praça e academia | Preservados no produto e nos registros; não inferidos nos metadados sem indicação da fonte |
| Prática, adesão, atividade e histórico | Ainda não integrados; nenhuma execução fictícia |
| Consulta alimentar e nutrientes |6369referências reais, busca/fonte/paginação/detalhe e bases/estados/créditos; API/DB/emulador verificados |
| Privacidade da conta | Consulta e exclusão explicitamente autorizada validadas comGoogle real/debug; banco/limpeza/catálogos conferidos |
| Cadastro próprio, quantidade e consumo | Pendentes; nenhuma refeição/valor inventado |
| Release/HTTPS e iOS | Pendentes de infraestrutura/configuração/testes próprios |

V1-014 encerra a leitura do catálogo. V1-011 permanece doing; V1-012/021/022/020/025 têm preparação parcial, sem aceite indevido. O roteiro completo continua na [matriz de cenários](matriz-cenarios.md).

Falha doGooglePlayServices foi observada no emulador e dispensada durante inspeção pública. Não houve validação de sua resolução ou de login real; não limpar contas/dados automaticamente. [Consulta alimentar e testes](alimentacao-consulta.md).
