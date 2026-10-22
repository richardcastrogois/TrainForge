# Da máquina local ao arquivo Android

Roteiro futuro, ligado às histórias031–039. Nenhum servidor cloud, chave release ou APK V1 foi criado nesta entrega. O notebook não precisa ficar ligado para a esposa usar o app depois que API/banco estiverem implantados.

## Ambientes e autorização

| Ambiente | Uso | Dados/configuração |
|---|---|---|
| Local Windows/Android emulador | Desenvolvimento | Go/Postgres isolados, SDK/ADB/emulador existentes; API em `10.0.2.2:<porta>` ou `adb reverse` explicitamente validado |
| Staging/piloto | APK da esposa fora da rede local | API pública HTTPS, DB protegido, lote real aprovado e contas reais de teste; orçamento e retenção definidos |
| Produção futura | Distribuição maior | Identidades, segredos, backups, limites e domínio próprios; não confundir com staging |

Fornecedor ainda **pendente**. Em031 comparar container Go+Postgres gerenciado com VPS, consultar preços/quotas/região/sleep/backups atuais e apresentar a opção concreta para aprovação. Não afirmar que uma oferta gratuita basta permanentemente, não criar cobrança/cartão/recurso sem essa decisão. Reutilizar conta/infra existente que for adequada. O plano define a rota completa sem inventar uma conta, domínio ou URL pública que não existe.

## Sequência operacional

1. Validar recursos/portas locais e ferramentas existentes; instalar apenas lacunas aprovadas. Fixar versão Go/Postgres suportada e dependências com lock/versionamento apropriados.
2. Criar serviço em `services/api`, contrato e migrations em DB isolado. Fazer backup/restauração de ensaio. Não executar scripts de reset ou apagar volumes.
3. Importar manifestos aprovados via dry run/transação. Configurar login Google real e cliente Android de desenvolvimento. Validar biblioteca→registro→consulta local.
4. Pipeline analisa/testa, constrói imagem não root com commit/digest e valida migrations/importações num banco separado. Segredos não aparecem em log nem ficam disponíveis para PR não confiável.
5. Após aprovação da031: provisionar DB/rede/API/TLS/DNS, configurar segredos, pool/limites, executar migrations uma vez e importar lote revisado. Smoke de login/refresh/leitura/escrita pelo endpoint HTTPS. Registrar restore/rollback/custo.
6. Configurar applicationId estável, versão e keystore release com backup seguro fora do Git. Client ID público não é segredo; senha/chave privada são. Cadastrar fingerprint do certificado release no OAuth.
7. Conferir permissões Android, INTERNET e endpoint por configuração; build release usa HTTPS sem debug logging. Rodar roteiro035 no APK assinado, além dos testes automatizados.
8. Gerar APK (`flutter build apk --release` com o flavor/configuração que a021 implementar), verificar certificado via `apksigner verify --print-certs`, produzir SHA256 com `Get-FileHash`, registrar commit/versionCode/manifesto/schema/API. Os comandos de flavor/define serão concretizados na história; não funcionam no app atual de base URL fixa por mágica.
9. Disponibilizar arquivo privado/link autorizado, notas e roteiro. A autorização para gerar/disponibilizar arquivo não autoriza enviar e-mail ou mensagem à esposa. Confirmar recebimento/instalação somente por evidência real.

## Roteiro que acompanhará o APK

Conforme [direção do piloto](decisoes-piloto.md), entregar também APKs intermediários de avaliação ao longo do desenvolvimento, sem esperar todo o produto pronto. Cada build declara versão, ambiente, cenários habilitados, limitações e pendências. Usar a matriz completa do app para explorar um cenário de cada vez; ainda não implementado não pode aparentar funcionalidade. Os controles de assinatura, identidade/configuração, acesso e dados reais dos fluxos habilitados se aplicam também a esses checkpoints. Um APK intermediário não conclui as histórias de aceite integral/distribuição da V1.

Instruções finais dependem da versão/aparelho Android da testadora. Usar o arquivo/link fornecido; ao abrir o APK, se o Android bloquear, permitir **somente a origem usada para esse arquivo** nas configurações exibidas e retirar essa permissão depois da instalação. Não orientar desativar proteções gerais nem contornar bloqueio de segurança.

Informar versão, checksum, conta própria para login e finalidade dos dados. Testar: abrir→entrar→ver biblioteca e origem→consultar item permitido→registrar ação real→ver histórico→registrar alimento real→fechar/reabrir→logout. Não executar material que exija apoio/condições não presentes. Feedback: tela/ação, esperado, ocorrido, versão e requestId se houver; sem token, fotografia pessoal ou dados de saúde em log compartilhado.

Atualização deve usar mesma identidade/chave e versionCode maior. Não pedir desinstalação que apaga dados como caminho normal de update.035 deve verificar instalação e atualização antes da entrega.037 inventaria e exclui temporários, contas e recursos que deixarem de ser usados, preservando dados necessários e evidências de autoria.

## iOS e lojas

Reutilizar Flutter/domínio/API.038 obtém ambiente Apple compatível, configura Bundle ID/Keychain/OAuth e testa paridade real.039 verifica custos e requisitos atuais das contas Apple/Google, TestFlight/teste interno, privacidade e políticas. Publicar só quando houver pedido/autorização correspondente. Não é necessário Play Store para o primeiro APK Android privado. Referências: [Android assinatura](https://developer.android.com/studio/publish/app-signing), [Flutter release Android](https://docs.flutter.dev/deployment/android), [Flutter release iOS](https://docs.flutter.dev/deployment/ios).
