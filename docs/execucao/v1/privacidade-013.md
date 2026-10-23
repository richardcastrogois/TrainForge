# V1-013 — autorização, limites e ciclo dos dados

Implementação e testes independentes concluídos em23/10/2026: Go0.4.0,18operaçõesSwagger e APKdebug0.1.3+4. **A história permanece doing:** depende da011Google real e009; o aceite pessoal integrado das operações privadas aguarda o autor. Não iniciar outraV1 antes desse aceite, conforme orientação de23/10. Nenhuma conta/atividade/refeição de fixture entrou na base entregue.

## Contrato real

| Método/rota | Entrada e resultado |
|---|---|
| GET /api/v1/privacy | Política técnica atual, sem login e sem dados pessoais |
| GET /api/v1/me/export | section,limit1–50(default20),cursor vinculado a conta/seção/limite; página limitada a1MiB de itens |
| POST /api/v1/me/deletion-intent | confirmation=EXCLUIR MINHA CONTA; nonce256bits, hashSHA256 noDB, validade5min pelo relógioPostgreSQL |
| DELETE /api/v1/me | Mesma confirmação e challenge da conta/família autorizada; recibo só após commit, comaccountId e dataDB |

Bearer único, conta derivada exclusivamente do token validado; IDs de titular na query/body não são aceitos nessas operações. Acompanhamento de terceiro continua não implementado e não é autorizado por perfil de cuidador. As respostas privadas usam no-store.400/401/409/413/415/426/429/503 são erros seguros; falha de banco não vira401 nem apaga sessão válida.

A sessão de entrada do TrainForge precisa ter sido criada há no máximo15min para emitir/usar confirmação. Isso mede a sessão criada após verificar uma credencialGoogle válida; não comprova nova senha/MFA ou presença física noGoogle. O app oferece nova entradaGoogle e descarta confirmação/exportação anterior. LoginGoogle real e esse fluxo pessoal ainda não foram validados; fixtures não substituem esse aceite.

## Matriz de autorização

| Superfície | Anônimo | Titular autenticado | Outra conta/ID |
|---|---|---|---|
| Política, catálogo, referências alimentares | Consulta permitida conforme revisão/retirada | Igual | Sem dados privados |
| Identidade/me |401 | Própria identidade | Token define titular; nenhum vínculo por e-mail |
| Exportação |401 | Somente linhas próprias e seções da allowlist | Cursor vinculado à conta; troca/owner adicional rejeitado |
| Intenção de exclusão |401 | Sessão recente e confirmação exata | Nonce vinculado a conta/família; outro dispositivo não o usa |
| Exclusão |401 | Nova validação transacional + nonce válido | Mesmas barreiras; nenhuma exclusão de outra conta |
| Refresh/logout | Credencial opaca obrigatória | Família correspondente à credencial | Não selecionável por userId |
| Adesão/atividade/consumo/acompanhamento | Não implementado | Não liberado por este incremento | Sem autorização implícita |

## Consistência e dados

Exportação cobre conta, metadados de sessões de acesso, adesões, agenda, sessões/eventos de atividade, alimentos próprios e consumo. Não exporta tokens/hashes, nonces de exclusão, cache interno de idempotência ou catálogo editorial em massa. Inclui tipo/versão dos programas e campos originais de origem/idioma/permissão dos alimentos próprios, inclusive nulls. É uma consulta paginada por seção e momento, não um backup atômico global.

Um inventário explícito confere tabelas/colunas privadas e FKs de titularidade antes de exportar ou excluir. Tabela/coluna nova exige atualização deliberada: falha em vez de omitir dados silenciosamente. O mecanismo não aprova automaticamente dados/fotos futuros.

Exclusão bloqueia o titular e todas as famílias, revalida sessão/idade/nonce, remove eventos/sessões/agenda/adesões, consumo/alimentos próprios, cache de idempotência, confirmações, credenciais/famílias e usuário em uma transação. Fonte/catálogo/editorial permanecem. Falha tardia desfaz inclusive o registro de exclusão. Refresh concorrente não deixa a credencial vencedora ativa.

Migration00007 cria confirmações/registro mínimo de exclusões, índices de manutenção e guard de titular no consumo. O runtime continua sem DELETE/UPDATE irrestrito em food_versions. FunçãoSQL com search_path fixo apaga somente alimentos privados após revalidar a mesma sessão/nonce; EXECUTE público revogado. O runtime não pode listar UUIDs do registro de exclusões; possui INSERT e leitura da data necessária ao recibo.

## Recursos e proxy

| Recurso | Limite local real |
|---|---|
| ConexõesTCP |1024por processo; liberação no close e parada desbloqueiam Accept |
| Requisições admitidas |128por instância; excedente503 comRetry-After |
| Rate limit |64shards, até4096chaves por processo; expiração sem varrer todo mapa por requisição |
| Taxas |240/min porpeer global; auth10/minlogin e60/minoutros; privacidade3/minintenção e60/minoutros por conta/método |
| Headers/corpo |16KiBheaders,64KiBglobal,8KiBnos corpos de privacidade |
| Tempo |read-header5s/read-write15s/idle60s; contexto default10s configurável1–30s |
| PoolDB |default10conexões, configuração limitada a50 |
| Exportação |até50linhas/1MiBdeitens por página; app20linhas, prévia12000caracteres |

Forwarded e X-Forwarded-* de peers não confiáveis não definem IP/TLS. TF_TRUSTED_PROXY_CIDRS configura até16CIDRs explícitos, sem /0. Somente peer confiável permite X-Forwarded-For/proto estritos; cadeia é percorrida da direita, interrompendo no primeiro salto não confiável. Proxy precisa substituir cabeçalhos recebidos do cliente. Produção exige TLS verificado ou essa fronteira explicitamente configurada; não há autodetecção.

Objetivo de grande escala preservado. Esses limites protegem uma instância e não demonstram milhões simultâneos. Balanceamento, limites distribuídos, pooler/dimensionamento, replicação, SLO e carga pertencem à validação de infraestrutura/desempenho. Não houve contratação ou deploy.

## Flutter e fidelidade

Política pública na entrada; ações privadas somente na conta conectada. Exportação por seção, vazio/erro/paginação e cópiaJSON explicitamente solicitada. A cópia preserva o corpoJSON exato daAPI, sem arredondar decimais pelo parserDart. Processamento de páginas grandes usa compute; a prévia de tela é limitada, a cópia contém a página completa.

Exclusão exige leitura dos limites, solicitação temporária e frase exata; nenhum DELETE é disparado pelo carregamento da tela. PopScope evita sair no meio de uma ação. Após resposta confirmada, falha de limpeza local não vira relato falso de conta preservada nem repete DELETE. A limpeza compara o token realmente usado; resposta antiga não remove credenciais de outro login. Cache de exportação é descartado na reentrada/troca/saída; identidade antiga não é restaurada por resposta atrasada após exclusão. Cópias externas/clipboard feitas pelo usuário não são apagadas automaticamente.

## Retenção, manutenção e restore

Dados correntes são apagados após confirmação. Registro mínimo deUUIDinterno+data permite impedir reaparecimento em restore; não contém e-mail/nome/provedor/token, mas é pseudônimo técnico, não anonimização garantida. A contaGoogle permanece independente.

tools/manter_privacidade_local.py apenas mostra candidatos por padrão. --apply remove um lote de até500por classe: confirmações/idempotência expiradas, acessos expirados há mais de um dia, famílias criadas há31dias sem refresh/access válidos. Hashes consumidos de refresh de famílias ainda válidas permanecem para detectar reuso. Não remove contas, registro de exclusões, fontes ou backups. A rotina não foi agendada; somente prévia foi executada na base entregue.

cmd/privacy-restore aceita somente alvo local separado trainforge_v1_privacy_restore_<12hex>, fonte do registro atual local dev/fixture e lotes500. Reaplica exclusões, preserva outros titulares/editorial, verifica que o registro não mudou durante a leitura e nunca promove o alvo. Antes de promoção real, pausar exclusões na origem para o corte final e revalidar. Sem registro atual disponível, manter recuperação privada bloqueada.

O wrapper tools/aplicar_exclusoes_restore.py --target-database trainforge_v1_privacy_restore_<12hex> faz prévia por padrão; --apply aplica o gate. Recusa alvo fora do padrão, base ausente, conexões ativas ou migration ausente; não cria/migra/promove automaticamente. A checagem operacional não substitui manter o alvo inacessível ao runtime e pausar exclusões na origem para o corte final.

Backups existentes foram preservados. Expiração operacional de cópias e replicação independente do registro de exclusões ainda não estão implantadas/validadas para produção; nenhuma promessa de apagamento instantâneo de cópias históricas. Fotos/uploads/cache pessoal persistente não existem nesta versão além das credenciais locais; introduzi-los exige expandir inventário/política. Os backups de fundação/alimentos foram feitos antes da primeira conta real, sem fixtures entregues.

## Evidência

- [PostgreSQL/restore descartáveis](privacy-local-verification.json): duas contas, corpo/owner/cursor, nonce expirado/outra família, sessão antiga, store desconhecido, falha tardia/rollback, corrida refresh/delete, privilégios editoriais, manutenção/replay; uma conta reaparecia no backup antigo e foi removida pelo filtro; reaplicação idempotente. Alvos e dump de fixture removidos.
- [HTTP real](privacy-http-verification.json): política200/no-store, export/intenção/delete anônimos401,18operações,73metadados/6369alimentos preservados e0contas criadas/excluídas.
- Flutter:48testes e analyze0issues, incluindo confirmação, cache após troca de conta, limpeza pendente, precisãoJSON, tela320x568/texto2x e regressões anteriores.
- [APK e ambiente](android-auth-checkpoint.json): assinatura/hash/fontes/configuração/instalação conferidos, política pública inspecionada. Telas privadas: widgets/fixtures apenas, sem alegar loginGoogle ou aceite pessoal. iOS/release/HTTPS continuam pendentes.

[Retomar avaliação](avaliacao-android.md). Repetir somente validações afetadas por mudança relevante. Nenhuma nova coleta de fornecedores ou integração paga faz parte desta história.
