import 'package:flutter/material.dart';
import 'package:trainforge/features/catalog/presentation/catalog_page.dart';
import 'package:trainforge/features/food_reference/presentation/food_page.dart';
import 'figma_components.dart';
import 'flow_components.dart';

enum EvaluationTopic { firstAccess, activity, devices, profile, help }

/// Explains current capability boundaries; never collects a fake configuration.
class EvaluationGuidePage extends StatelessWidget {
  final EvaluationTopic topic;
  const EvaluationGuidePage({super.key, this.topic = EvaluationTopic.help});
  @override
  Widget build(BuildContext context) {
    final title = switch (topic) {
      EvaluationTopic.firstAccess => 'O teu ponto de partida',
      EvaluationTopic.activity => 'Atividade e evolução',
      EvaluationTopic.devices => 'Dispositivos e permissões',
      EvaluationTopic.profile => 'Conta e preferências',
      EvaluationTopic.help => 'Ajuda nesta versão',
    };
    return FigmaRouteFrame(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          FigmaPageHeading(
            title: title,
            subtitle: 'VERSÃO DE AVALIAÇÃO · DISPONIBILIDADE REAL',
          ),
          if (topic == EvaluationTopic.firstAccess) ...[
            const FlowStatus(
              announce: false,
              title: 'Podes explorar sem configurar',
              message:
                  'A biblioteca de movimentos e a composição alimentar já podem ser consultadas. Para teus registros particulares de alimentação, entra com Google.',
            ),
            const FlowSectionTitle('Configuração ainda não disponível'),
            const FigmaSection(
              child: Text(
                'Áreas, objetivos, ambientes, experiência, rotina e revisão ainda não são salvos nesta versão. Nenhuma dessas escolhas foi inferida da conta Google. Não há configuração obrigatória simulada para liberar a navegação.',
              ),
            ),
            const SizedBox(height: 12),
            const FigmaSection(
              child: Text(
                'Casa, praça e academia continuam no escopo. Pessoas idosas e cuidadores também: quem pratica e quem recebe apoio precisam ser tratados separadamente. A biblioteca não determina adequação clínica ou elegibilidade.',
              ),
            ),
          ],
          if (topic == EvaluationTopic.activity ||
              topic == EvaluationTopic.devices) ...[
            const FlowStatus(
              announce: false,
              title: 'Ainda sem registro de atividade',
              message:
                  'Iniciar, pausar, encerrar e consultar uma atividade dependem do serviço de registro. Esta versão não cria séries, dose, sessão, percurso, gasto ou conclusão de treino.',
            ),
            const FlowSectionTitle('Permissões e dispositivos'),
            const FigmaSection(
              child: Text(
                'GPS, sensores, Health Connect e câmera não estão integrados. Esta tela não solicita permissões nem coleta localização, imagens ou dados de dispositivos. Registro por imagem e OCR também não estão disponíveis.',
              ),
            ),
            const FlowSectionTitle('Histórico e evolução'),
            const FigmaSection(
              child: Text(
                'Gráficos, períodos de atividade, medidas e objetivos aguardam registros e cálculo próprios. Ausência de implementação não significa zero de atividade. O histórico alimentar confirmado continua acessível pelo Diário.',
              ),
            ),
          ],
          if (topic == EvaluationTopic.profile) ...[
            const FlowStatus(
              announce: false,
              title: 'Identidade vinda do Google',
              message:
                  'Nome e e-mail são os confirmados no login. A edição desses dados no TrainForge ainda não está disponível. Confirmação de conexão, saída de sessão, exportação e exclusão têm ações próprias no perfil.',
            ),
            const FlowSectionTitle('Preferências do aparelho'),
            const FigmaSection(
              child: Text(
                'Claro, escuro e seguir o aparelho já estão disponíveis em Preferências. A escolha fica neste aparelho e é separada da conta. Unidades, idioma, medidas e objetivos ainda não têm edição persistida. Os alimentos mantêm nome, idioma, base e unidades da fonte.',
              ),
            ),
          ],
          if (topic == EvaluationTopic.help) ...[
            const FlowStatus(
              announce: false,
              title: 'O que já podes testar',
              message:
                  'Entrar com Google, consultar movimentos e alimentos, cadastrar alimento particular e registrar o que consumiste. O Diário permite conferir origem, corrigir e excluir consumo; Privacidade permite consultar e copiar páginas dos teus dados.',
            ),
            const FlowSectionTitle('Perguntas frequentes'),
            const FigmaSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Por que há nomes em francês e inglês?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'São nomes originais de Ciqual e CoFID. Não criamos traduções que possam trocar a identidade do alimento.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Um traço ou valor desconhecido significa zero?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Não. Base ausente, valor desconhecido, limite e métodos diferentes continuam explícitos. Quantidade estimada também é identificada.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'A biblioteca já orienta meu treino?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Ainda não. Os metadados são somente para consulta; não há programa, dose, instrução ou mídia liberados para prática.',
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Como relatar um problema?',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Anota a tela, a ação e o resultado esperado para a avaliação. Antes de compartilhar capturas, oculta e-mail, dados pessoais e registros. O envio de feedback pelo aplicativo ainda não está implementado.',
                  ),
                ],
              ),
            ),
            const FlowSectionTitle('Condições desta avaliação'),
            const FigmaSection(
              child: Text(
                'A política de dados efetiva está em Privacidade e dados e vem da API. Termos de produção e canal de suporte ainda precisam ser definidos; este texto não substitui esses documentos. Não há prescrição, reconhecimento de alimento por foto ou meta automática.',
              ),
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const CatalogPage()),
            ),
            child: const Text('Consultar biblioteca'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push<void>(
              context,
              MaterialPageRoute(builder: (_) => const FoodPage()),
            ),
            child: const Text('Consultar alimentos'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.maybePop(context),
            child: const Text('Voltar'),
          ),
        ],
      ),
    );
  }
}

void openEvaluationGuide(BuildContext context, EvaluationTopic topic) {
  FocusManager.instance.primaryFocus?.unfocus();
  Navigator.push<void>(
    context,
    MaterialPageRoute(builder: (_) => EvaluationGuidePage(topic: topic)),
  );
}
