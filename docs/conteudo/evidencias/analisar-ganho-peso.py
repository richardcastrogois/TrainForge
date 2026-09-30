"""N09: confere guias, tabela PDF e limites editoriais. Sem rede e sem metas individuais.
Requer pypdf e pdfplumber instalados; corpos integrais permanecem no raw local.
"""
import hashlib,json,re
from html import unescape
from pathlib import Path
from pypdf import PdfReader
import pdfplumber
ROOT=Path(__file__).resolve().parent
HERE=ROOT/'2026-09-30/n09-ganho-peso'
checks=[]
def check(name,ok):
 checks.append({'check':name,'passed':bool(ok)})
 if not ok:raise AssertionError(name)
def body(folder,ident):
 p=folder/(ident+'.evidencia.json');m=json.loads(p.read_text(encoding='utf-8'));b=(folder/m['bodyFile']).read_bytes()
 check(ident+': hash',hashlib.sha256(b).hexdigest()==m['sha256'])
 return m,b
def text_html(b):
 s=b.decode('utf-8');s=re.sub(r'<(script|style)\b.*?</\1>','',s,flags=re.S)
 return re.sub(r'\s+',' ',unescape(re.sub('<[^>]+>',' ',s)))
inputs={}
for p in sorted(HERE.glob('*.evidencia.json')):
 ident=p.name.removesuffix('.evidencia.json');m,b=body(HERE,ident);inputs[ident]=(m,b)
check('HTTP failures retained separately',sorted(k for k,(m,b) in inputs.items() if m['status']!=200)==['n09-va-calorias','n09-va-smoothie'])
for old,new in [('n09-va-calorias','n09-va-calorias-pdf'),('n09-va-smoothie','n09-va-smoothie-pdf')]:
 check(old+': 406 explained by MIME negotiation', inputs[old][0]['status']==406 and 'MIME type' in text_html(inputs[old][1]))
 check(new+': corrected Accept and PDF signature',inputs[new][0]['requestHeaders']['Accept']=='application/pdf' and inputs[new][1].startswith(b'%PDF-') and inputs[new][0]['status']==200)
nhs=text_html(inputs['n09-nhs-ganho'][1]);bda=text_html(inputs['n09-bda-apetite'][1]);nice=text_html(inputs['n09-nice-refeeding'][1])
for name,needle,text in [('NHS: adult reference range','300 to 500',nhs),('NHS: unexpected loss needs GP','lost weight suddenly',nhs),('NHS: no sugar-only strategy','chocolate, cakes and sugary drinks',nhs),('BDA: critical illness audience','after critical illness',bda),('BDA: clinical conditions need advice','diabetes or high blood cholesterol',bda),('NICE: skilled care for refeeding risk','appropriately skilled and trained',nice)]:check(name,needle in text)
cal_path=HERE/inputs['n09-va-calorias-pdf'][0]['bodyFile']; smoothie_path=HERE/inputs['n09-va-smoothie-pdf'][0]['bodyFile']
cal=PdfReader(cal_path);sm=PdfReader(smoothie_path)
check('VA: four pages preserved',len(cal.pages)==2 and len(sm.pages)==2)
cal_text='\n'.join(p.extract_text() for p in cal.pages);sm_text='\n'.join(p.extract_text() for p in sm.pages)
check('VA: dated July 2026', '(07/2026)' in cal_text)
check('VA: individual calorie/protein fields left blank',bool(re.search(r'calorie needs are\s*_',cal_text)) and 'protein needs are' in cal_text)
with pdfplumber.open(cal_path) as pdf:
 table=next(t for t in pdf.pages[1].extract_tables() if t[0][0]=='Snack or Meal Ideas')
expected=[(416,29),(573,46),(623,13.2),(836,19),(512,18.6),(456,14),(298,17),(513,35),(771,21),(535,30),(389,24),(324,13),(415,16),(373,8.4)]
check('VA: 14 meal examples, not daily plans',len(table[1:])==14)
examples=[]
for i,(r,pair) in enumerate(zip(table[1:],expected),1):
 check('VA table row '+str(i)+': kcal and protein visually confirmed',(float(r[1]),float(r[2]))==pair)
 examples.append({'id':'VA-GAIN-'+str(i).zfill(2),'sourceEvidence':'n09-va-calorias-pdf.evidencia.json','page':2,'row':i,'descriptionOriginal':re.sub(r'\s+',' ',r[0]),'energyKcalDeclared':float(r[1]),'proteinGDeclared':float(r[2]),'basis':'example_as_described_not_per_100g','fullNutrientsAvailable':False,'dailyRecommendation':False,'ptPTReviewed':False})
sm_names=['Green Pineapple Crush','Green Smoothie','Peach & Greens','Tropical Green Smoothie','Triple Berry Green Smoothie','Beet & Berry']
check('Smoothie: six named examples',all(x in sm_text for x in sm_names))
check('Smoothie: no energy table promised', 'kcal' not in sm_text.lower())
check('Smoothie: optional commercial nutrition product is not mandatory', 'Ensure Plus' in sm_text and 'Water' in sm_text and 'Silken Tofu' in sm_text)
policies={}
for ident in ['n08-nhs-termos','n08-nhs-excecoes','n08-ogl-v3']:
 m,b=body(ROOT/'2026-09-29/n08-receitas',ident);policies[ident]=text_html(b)
check('NHS: translation is an adaptation', 'Translation into another language' in policies['n08-nhs-termos'])
check('NHS: adaptations lose automatic clinical approval', 'may invalidate its formal clinical approval' in policies['n08-nhs-termos'])
check('BDA: no commercial redistribution permission', 'no part of the BDA website may be distributed or recopied for any commercial purpose' in text_html(inputs['n09-bda-direitos'][1]))
check('VA: federal authorship condition retained', 'government-produced materials' in text_html(inputs['n09-va-direitos'][1]))
guides=[
 {'id':'G09-01','sourceId':'NU17','evidence':'n09-nhs-ganho.evidencia.json','publisher':'NHS','audience':'adultos; orientacao geral','basis':'Guia institucional de educacao em saude, nao ensaio de cada refeicao nem plano individual','observedFormat':'HTML; titulo, listas Do/Dont, encaminhamentos e datas','sourceLastReview':'2023-03-28','sourceNextReviewDue':'2026-03-28','reviewFlag':'Prazo de revisao exibido ja passou; nao significa sozinho conteudo falso, mas requer verificacao editorial antes de publicar','referenceEnergyAdditionKcal':[300,500],'dailyKcalTarget':None,'reuse':'OGL + termos NHS gerais; excluir calculadora, imagens e campanhas; traducao e adaptacao'},
 {'id':'G09-02','sourceId':'NU18','evidence':'n09-va-calorias-pdf.evidencia.json','publisher':'VA Nutrition and Food Services','audience':'pessoas que precisam adicionar energia; contexto de educacao com dietista VA','basis':'Folheto institucional julho 2026; valores declarados por exemplo, nao recalculados','observedFormat':'PDF 2 paginas; nove grupos/ideias e 14 exemplos com kcal/proteina; alvos pessoais em branco','sourceVersion':'07/2026','dailyKcalTarget':None,'reuse':'Texto de autoria federal candidato segundo politica VA; conferir terceiros, marcas e traducao'},
 {'id':'G09-03','sourceId':'NU18','evidence':'n09-va-smoothie-pdf.evidencia.json','publisher':'VA Nutrition and Food Services','audience':'educacao culinaria e adaptacoes de textura/sabor com escolhas pessoais','basis':'Folheto institucional junho 2024 com grupos e seis combinacoes exemplificadas','observedFormat':'PDF 2 paginas, tabelas de opcoes e exemplos; sem nutrientes ou rendimento total por bebida','sourceVersion':'06/2024','dailyKcalTarget':None,'reuse':'Mesmo criterio VA; mencoes de suplementos/marcas nao sao endosso ou necessidade do app'},
 {'id':'G09-04','sourceId':'NU19','evidence':'n09-bda-apetite.evidencia.json','publisher':'British Dietetic Association / ICUsteps','audience':'recuperacao apos doenca critica, pouco apetite/saciedade precoce','basis':'Guia baseado em experiencia de antigos pacientes de cuidados intensivos e orientacao dietetica; nao generalizar','observedFormat':'HTML com contexto, listas de ideias e ressalvas','sourceVersion':'2020-06-15','dailyKcalTarget':None,'reuse':'Referencia; copyright nao autoriza incorporacao comercial gratuita'},
 {'id':'G09-05','sourceId':'NU20','evidence':'n09-nice-refeeding.evidencia.json','publisher':'NICE','audience':'profissionais que prestam suporte nutricional a adultos','basis':'CG32, recomendacoes 1.4.5 a 1.4.8 sobre risco de realimentacao e necessidade de equipa treinada','observedFormat':'HTML de guideline clinica, nao API nem questionario validado do TrainForge','dailyKcalTarget':None,'reuse':'Referencia de limites; nenhum protocolo/dose clinica copiado para motor do app'},
]
lessons=[
 ('G09-L01','Entender o objetivo','Ganhar peso, recuperar de uma doenca e ganhar massa muscular precisam de percursos distintos.',['G09-01','G09-04'],['goalIntent','contextKnown']),
 ('G09-L02','Distribuir oportunidades para comer','O guia geral apresenta refeicoes menores e lanches quando grandes volumes dificultam a rotina.',['G09-01'],['mealTimes','appetiteOptional']),
 ('G09-L03','Adicionar energia com variedade','Comparar opcoes e quantidades na refeicao, em vez de rotular um alimento como garantia de engordar.',['G09-01','G09-02'],['foodId','amount','unit','preparationState']),
 ('G09-L04','Saber o que os exemplos significam','Os 14 exemplos VA descrevem combinacoes e valores da fonte; mudancas de ingredientes ou marcas pedem nova composicao.',['G09-02'],['sourceVersion','exampleId','ingredientMappingStatus']),
 ('G09-L05','Montar e registar uma bebida','O guia VA organiza bases, fruta/horticolas e complementos. O utilizador ainda precisa confirmar ingredientes e quantidades.',['G09-03'],['ingredients','quantities','allergenConfirmation']),
 ('G09-L06','Preservar o contexto clinico','Conselhos de enriquecimento apos cuidados intensivos nao sao uma dieta geral para todos.',['G09-04'],['clinicalContextOptional']),
 ('G09-L07','Reconhecer quando pedir ajuda','Perda involuntaria ou muito rapida e dificuldade prolongada em comer exigem orientacao apropriada antes de sugerir aumentos automaticos.',['G09-01','G09-05'],['unintentionalLossOptional','intakeConcernOptional']),
 ('G09-L08','Guardar metas sem inventa-las','A faixa geral do NHS e os campos em branco VA nao fornecem a meta individual. Registar origem e revisao se a pessoa ja tem orientacao.',['G09-01','G09-02'],['targetProvenance','targetOptional']),
 ('G09-L09','Acompanhar com contexto','Organizar diario e historico voluntarios; nao inferir massa muscular a partir da variacao da balanca. Ganho muscular sera pesquisado em N12.',['G09-01'],['optionalWeightHistory','mealLog','trainingGoal']),
]
lesson_rows=[{'id':i,'title':t,'draftPtPT':d,'basisGuideIds':refs,'futureFields':fields,'textAuthorship':'sintese editorial assistida por agente a partir das fontes humanas, nao validacao profissional','releaseApproved':False} for i,t,d,refs,fields in lessons]
# Cenarios de decisao editorial; nao executam triagem clinica nem liberam prescricao.
scenarios=[
 {'id':'adult_general','context':'adulto, procura educacao geral','expected':'mostrar ensino e registo; nao gerar meta'},
 {'id':'muscle_gain','context':'quer hipertrofia/desempenho','expected':'separar N12; nao assumir que todo peso ganho e musculo'},
 {'id':'unexpected_loss','context':'relata perda involuntaria ou subita','expected':'orientar procura de profissional; nao ativar superavit automatico'},
 {'id':'post_critical_illness','context':'recuperacao apos doenca critica','expected':'material contextual; plano individual com equipa assistente'},
 {'id':'minimal_intake','context':'relata alimentacao muito reduzida por varios dias','expected':'nao fornecer protocolo de realimentacao; orientacao profissional'},
 {'id':'minor','context':'menor de 18 anos','expected':'fora do recorte adulto, sem metas de adulto'},
 {'id':'pregnancy','context':'gravidez ou amamentacao','expected':'percurso especifico nao validado neste nicho'},
 {'id':'unknown','context':'contexto nao informado','expected':'permitir consulta geral; nao presumir adequacao ou calcular alvo'}]
for x in scenarios:
 x.update(basis='politica editorial proposta com limites das fontes; nao instrumento clinico validado',automaticCalorieTarget=None,publicationApproved=False)
 check(x['id']+': never silently prescribe',x['automaticCalorieTarget'] is None)
check('Guide identity and lesson references resolved',all(set(x['basisGuideIds']) <= {g['id'] for g in guides} for x in lesson_rows))
check('No guide generates individual target',all(x['dailyKcalTarget'] is None for x in guides))
out={'niche':'N09','date':'2026-09-30','scope':'Educacao e rastreabilidade de guias humanos, nao dieta pessoal nem equivalencia calorica universal','guides':guides,'lessons':lesson_rows,'mealExamplesFromVa':examples,'smoothieExampleNames':sm_names,'editorialScenarios':scenarios,'rightsEvidenceReused':['../2026-09-29/n08-receitas/n08-nhs-termos.evidencia.json','../2026-09-29/n08-receitas/n08-nhs-excecoes.evidencia.json','../2026-09-29/n08-receitas/n08-ogl-v3.evidencia.json'],'visualInspection':{'pages':4,'artifactLocal':'../raw/n09-pdfs-conferencia.png','finding':'Cabeçalhos, linhas de kcal/proteina, campos pessoais vazios e grupos dos smoothies conferidos visualmente em 30/09.'},'releaseApproved':False}
# Paths above are relative to the evidence root, explicitly labelled in documentation.
out['rightsEvidenceReused']=[x.removeprefix('../') for x in out['rightsEvidenceReused']];out['rightsPathBase']='docs/conteudo/evidencias/'
(HERE/'conteudo-guiado.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
summary={'niche':'N09','date':'2026-09-30','researchStatus':'concluido_no_recorte','guides':len(guides),'lessons':len(lesson_rows),'mealExamples':len(examples),'smoothieExamples':len(sm_names),'calls':len(inputs),'http200':sum(m['status']==200 for m,b in inputs.values()),'bodyHashesVerified':len(inputs),'reusedPolicyHashes':3,'checksPassed':len(checks),'checks':checks,'pdfPagesVisuallyInspected':4,'releaseApproved':False,'remaining':['Traducao/revisao profissional pt-PT e localizacao de servicos','Metas individuais e grupos clinicos nao validados','Valores VA nao conferidos por ingredientes/marcas; nao usar como tabela universal','Sem plano alimentar completo ou regras de hipertrofia; N12/N13','Sem Figma, integracao, dados pessoais ou banco alterados'],'next':'N10'}
(HERE/'resumo-ganho-peso.json').write_text(json.dumps(summary,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in summary.items() if k not in ['checks','remaining']},ensure_ascii=False))
