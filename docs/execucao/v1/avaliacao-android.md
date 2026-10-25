# Retomar a avaliação Android

**Checkpoint atual24/10:** Grafite e lima e rolagemAndroid semesticar noAPKdebug0.2.1+12,90testesFlutter/analyze0issues. [Recibo atual](frontend-dark-scroll-verification.json), [ajuste e limites](frontend-fidelidade-figma.md). Preserva conta, consumo e física iOS porplataforma; iOS27 nãoexecutado.

**Checkpoint anterior23/10:** APKdebug0.2.0+11, frontend pontos01–06 implementados tecnicamente: identidade/splash, inicialização, Hoje real, loaders, transições e aparência claro/escuro/sistema persistida.85testesFlutter/analyze0issues. [Recibo](android-frontend-checkpoint.json), [etapa e limites](frontend-fidelidade-figma.md). Direção aberturaTF/dark confirmada peloautor; pontos01–06 concluídos noAndroid, iOS nãoexecutado. Conta/consumo reais preservados, sem novo consentimentoGoogle automatizado. Snapshots e roteiros anteriores abaixo são históricos.

**Aparência:** avatar → Preferências → Aparência (ou Aparência naentrada). **CalendárioHoje:** toque nodia para abrir o diário alimentar nessa data; não marca treino nem cria consumo.


Checkpoint atual de23/10/2026: **APKdebug0.1.5+8**,Go0.5.1/25operações e bancoV1local. Alimentação particular/consumo/histórico entregues; titular confirmou consumo real. [Buildatual](android-nutrition-checkpoint.json), [aceite](nutrition-real-android-verification.json). A prioridade agora é [frontend completo fiel aoFigma](frontend-fidelidade-figma.md); tema/marca iniciais não encerram esse trabalho. Nenhum deploy.

## Testar agora no notebook

No terminal PowerShell do VSCode:

```powershell
cd C:\dev\TrainForge\trainforge
.\tools\avaliar-android.ps1
```

O comando inicia somente o cluster deste clone, a API Go e o emulador existente TrainForge_Benchmark, configura a porta reversa e abre o app. Reutiliza o APK se fonte/configuração/checksum coincidirem; reinstala com preservação de dados somente se necessário. Não instala ferramentas, recria banco, importa novamente, limpa o emulador ou altera OAuth. Se8082 estiver ocupada por serviço desconhecido/indisponível, interrompe com diagnóstico.

1. Toque **Consultar biblioteca sem entrar**. Deve mostrar73movimentos e0programas. Busque pelo nome original, filtre pelos valores reais da fonte e abra um detalhe.
2. Confira autoria, contribuição, licença, links, versão e requisitos desconhecidos. Não há treino executável, instrução, dose, foto ou vídeo liberados nesta build.
3. Abra **Privacidade e dados** na entrada. Confira os limites de exclusão, registros temporários e backups; essa tela é pública.
4. Volte e toque **Consultar alimentos sem registrar consumo**. Deve mostrar6369referências (3484Ciqual/2885CoFID) e3sem base confirmada. Busque no idioma da fonte, filtre a fonte e abra a composição; confira licença, base por célula e distinção entre zero/ausência/traço/limite. Cadastro próprio, consumo e subtotais agora estão disponíveis após login em Minha alimentação e consumo.
5. Volte à entrada e toque **Entrar com Google**. Faça pessoalmente a entrada na sua contaGoogle; o login básico não exige pertencer aos Testusers. Ver exceção e limites no guiaOAuth. Senha,2FA e consentimento ficam somente no Google; não enviar tokens/senhas ao chat.
6. Abra Minha alimentação e consumo para pesquisar, cadastrar alimento particular e registrar somente dados reais. Cadastro não registra consumo sozinho. Consumo real já foi confirmado pelo autor; não repetir testesGoogle/restore históricos sem motivo.
7. Confirme Conta conectada, feche/reabra, teste retomada de conexão e sair/entrar. Registre o resultado sem divulgar e-mail/token. Reabertura/rede/refresh/logout/reentrada passaram.

Se o login falhar, a tela apresenta erro seguro e permite tentar novamente; offline/timeout/429/5xx não apagam a sessão. O backend precisa estar ativo; o APK debug usa loopback via ADB, não é uma entrega remota autônoma.

Depois de validar a sessão, **Meus dados e privacidade** permite consultar/copiar páginas próprias e solicitar exclusão. O agente executou a exclusão da contaTrainForge deavaliação após autorização explícita do titular; confirmação, banco e reabertura foram conferidos. Para escolher testar: leia os limites, confirme uma entrada recente e digite a frase exata. ContaGoogle permanece independente. Se a limpeza local falhar após confirmação do servidor, use Concluir limpeza local; não é necessário repetir DELETE. Essa jornada passou com a conta real deavaliação. Entrar novamente após a exclusão cria uma nova contaTrainForge, sem reativar a antiga. [V1-013](privacidade-013.md).

## OAuth release: cadastro confirmado

O autor criou o cliente Android **TrainForge avaliação release** no projeto bootcamp-treinos-ia em23/10. Pacote com.example.trainforge e SHA-1 24:EF:27:3C:82:50:DC:FE:15:8A:E6:45:42:BA:8D:D4:0F:02:17:6D correspondem ao certificado dedicado local. [Recibo](oauth-release-verification.json). O clientWeb continua na configuração doFlutter e daAPI.

Para este pacote/certificado, o cadastro está concluído. O próximo teste exige APIHTTPS deavaliação e APKrelease próprios; o ambiente atual éHTTPloopback/debug. Oautor adiou hospedagem. Esse gate futuro não impede usar oAPKdebug local nem desenvolver aspróximas funções; nenhuma informação adicional sobre hospedagem énecessária agora. Preservar os três clientes existentes; não publicar o projeto para contornar gates. [Guia técnicoOAuth](oauth-android.md).

## Parar e consultar

```powershell
.\tools\avaliar-android.ps1 -Action status
.\tools\avaliar-android.ps1 -Action stop
```

Stop encerra somente recursos registrados como iniciados pelo helper e confere a identidade do emulador. Dados, credenciais e chave de assinatura permanecem locais. Serviços já ativos e reutilizados não são assumidos como pertencentes ao helper.

Arquivo: `build/app/outputs/flutter-apk/app-debug.apk`. SHA-256: `57c51e6bf523a8eb163cf2d66380a8773228dd42d82fc157728680ac622fce34`. [Recibo de build/instalação atual](android-nutrition-checkpoint.json).

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

V1-014 encerra a leitura do catálogo. V1-011/012/013 concluídas no aceite local; V1-012/021/022/020/025 têm preparação parcial, sem aceite indevido. O roteiro completo continua na [matriz de cenários](matriz-cenarios.md).

Falha doGooglePlayServices foi observada no emulador e dispensada durante inspeção pública. Não houve validação de sua resolução ou de login real; não limpar contas/dados automaticamente. [Consulta alimentar e testes](alimentacao-consulta.md).

## Prioridade confirmada pelo autor

Teste noemulador e desenvolvimento local agora. A biblioteca foi aberta com73movimentos/0programas,APIpronta e APKatual. Não pedir hospedagem para iniciar esse teste. [Critérios locais concluídos](auth-local-fechamento.md); HTTPSstaging/release/iOS permanecem nas histórias próprias.
