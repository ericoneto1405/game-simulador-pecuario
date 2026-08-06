# Roadmap — Game Simulador Pecuário

Este documento apresenta as próximas fases projetadas para o jogo. A ordem pode ser ajustada conforme os testes e as necessidades do projeto.

## Diretrizes do projeto

- Jogo sandbox 2D de gestão pecuária.
- Ambientação inicial no Sertão nordestino e na Caatinga.
- Agricultura usada somente para alimentar o rebanho.
- Decisões com custos e consequências reais.
- Plataforma alvo: Web para desktops, MacBooks e notebooks.
- Celulares e tablets não fazem parte do suporte planejado.

## Fase 0.1 — Protótipo jogável

**Status: concluída**

- Mapa 2D e interface de gerenciamento.
- Cerca externa e divisão interna dos pastos.
- Porteira funcional.
- Primeiro rebanho comprado no Mercado.
- Peso, fome, sede e saúde.
- Pastagem com crescimento e consumo.
- Açude natural em cada pasto.
- Compra, venda e transferência de animais.
- Salvamento local.
- Exportação Web.

## Fase 0.2 — Economia básica

**Status: concluída**

**Objetivo:** criar o primeiro ciclo financeiro da fazenda.

- Saldo disponível em caixa.
- Custos de compra dos animais.
- Receita com venda dos animais.
- Histórico simples de entradas e saídas.
- Impedimento de compras sem saldo suficiente.
- Salvamento dos dados financeiros.

**Conclusão da fase:** o jogador consegue comprar, manejar e vender animais sem deixar o caixa negativo.

## Fase 0.3 — Pastagem e nutrição

**Status: concluída**

**Objetivo:** aprofundar a relação entre alimento, desempenho e lotação.

- Capacidade de suporte de cada pasto.
- Superpastejo e degradação.
- Recuperação da pastagem.
- Qualidade nutricional da forragem.
- Sal mineral e suplementação.
- Ganho ou perda de peso conforme a alimentação.
- Condição corporal do rebanho.

**Conclusão da fase:** o manejo inadequado causa perda de produtividade e degradação do pasto.

## Fase 0.4 — Água natural e infraestrutura básica

**Status: concluída**

**Objetivo:** fazer as fontes naturais de água afetarem o rebanho.

- Variação visual dos açudes durante chuva e seca.
- Rio intermitente com variação de vazão.
- Consumo dos açudes pelo rebanho.
- Acesso direto ao rio quando o pasto permitir.
- Falta de água afetando sede e saúde.
- Cercas e porteiras com custo de construção.

**Conclusão da fase:** a disponibilidade natural de água afeta o manejo e a saúde do rebanho.

## Fase 0.5 — Agricultura para alimentação animal

**Status: concluída**

**Objetivo:** permitir a produção de alimento dentro da fazenda.

- Milho e sorgo para silagem.
- Capiaçu, palma e capim para feno.
- Preparo do solo, plantio e colheita.
- Produção e armazenamento de silagem e feno.
- Estoque de alimento para a seca.
- Distribuição do alimento ao rebanho.

A produção agrícola não poderá ser vendida como produto final.

**Conclusão da fase:** o jogador consegue produzir e armazenar alimento para reduzir o risco nutricional na seca.

## Fase 0.6 — Reprodução e genética

**Status: concluída**

**Objetivo:** permitir a evolução do rebanho ao longo das gerações.

- Machos, fêmeas e categorias por idade.
- Estação de monta.
- Gestação, nascimento e desmama.
- Monta natural e inseminação.
- Fertilidade e facilidade de parto.
- Herança de características dos pais.
- Adaptação ao calor e resistência a parasitas.
- Potencial de ganho de peso e habilidade materna.

**Conclusão da fase:** os descendentes apresentam características herdadas e o jogador pode selecionar sua genética.

## Fase 0.6.1 — Revisão de UI/UX e construção livre

**Status: concluída**

**Objetivo:** transformar a construção em parte do gameplay, eliminando a sequência rígida de botões.

- Interface organizada por módulos.
- Dashboard reservado como funcionalidade futura.
- Módulos Estruturas da Fazenda e Loja Rural.
- Construção livre no mapa.
- Tipos de cerca com custos diferentes.
- Custo de cerca calculado pelo comprimento.
- Finalização da cerca por duplo clique, `Enter`, botão direito ou confirmação na interface.
- Porteira instalada sobre cercas.
- Área geral cercada e porteira como requisitos para comprar animais.
- Mercado com orientação sobre requisitos ainda não atendidos.
- Curral e balança posicionáveis.
- Formação de pastos por cercas fechadas.
- Cancelamento de construção sem cobrança.
- Salvamento das estruturas.

**Conclusão da fase:** o jogador decide onde e como construir, com custo e consequência.

## Fase 0.6.3 — Representação individual dos bovinos

**Status: concluída**

- Registros individuais sem limite artificial de rebanho.
- Categorias por sexo e idade.
- Movimento automático, pastejo, consumo de água e descanso.
- Seleção de lote ou animal.
- Atualização visual em grupos e reutilização de sprites.

## Fase 0.6.4 — Identidade visual das raças

**Status: concluída**

- Sprites superiores próprios para onze raças.
- Diferenças de pelagem, cupim, chifres, orelhas e porte.
- Raça registrada em cada bovino e preservada nos nascimentos.
- Seleção da raça do lote no Mercado.
- Diferenças de escala por idade, categoria e raça.

## Fase 0.7 — Ambiente, sanidade e adaptação

**Status: concluída**

**Objetivo:** aumentar o impacto do ambiente sobre a produção.

- Calendário climático semiárido. **Concluído em 0.7.1**
- Chuvas irregulares e secas prolongadas. **Concluído em 0.7.1**
- Temperatura e estresse térmico. **Concluído em 0.7.1**
- Parasitas e doenças regionais. **Concluído em 0.7.2**
- Vacinação, medicamentos e tratamentos. **Concluído em 0.7.2**
- Mortalidade em situações críticas. **Concluído em 0.7.2**
- Relevo, umidade e fertilidade do solo. **Concluído em 0.7.3**
- Infiltração, escoamento, compactação e erosão. **Concluído em 0.7.3**
- Diferenças de adaptação entre raças e cruzamentos. **Concluído**

**Conclusão da fase:** clima, relevo, solo, sanidade e genética produzem consequências combinadas na fazenda e no rebanho.

### Fase 0.7.1 — Clima semiárido

**Status: concluída**

- Chuva diária irregular dentro dos períodos climáticos.
- Temperatura máxima diária.
- Contagem de dias consecutivos sem chuva.
- Evaporação e recarga dos açudes e do rio.
- Crescimento da pastagem conforme chuva, calor e seca prolongada.
- Estresse térmico reduzido pela adaptação genética.
- Consequências moderadas sobre peso, condição corporal e saúde.

### Fase 0.7.2 — Sanidade

**Status: concluída**

- Pressão parasitária individual e média do rebanho.
- Influência da chuva, degradação, lotação e resistência genética.
- Parasitose clínica com perda gradual de peso e saúde.
- Controle parasitário pago com proteção por 30 dias.
- Tratamento medicamentoso dos bovinos em estado clínico.
- Vacinação de bezerras entre três e oito meses contra brucelose.
- Vacinação individual contra clostridioses com validade de 365 dias.
- Protocolo vitamínico-mineral de apoio por 30 dias.
- Custos separados para medicamentos, vacinas e suplementação sanitária.
- Registro sanitário individual e salvamento.
- Mortalidade somente após quadro crítico sem controle.

### Fase 0.7.3 — Relevo e solo

**Status: concluída**

- Baixada e área alta representadas por perfis ambientais diferentes.
- Solo de baixada e solo raso e pedregoso.
- Umidade, fertilidade, compactação e erosão por pasto.
- Chuva dividida entre infiltração e escoamento superficial.
- Recarga dos açudes influenciada pelo relevo e pelo escoamento.
- Crescimento da pastagem influenciado pela umidade e fertilidade.
- Perda de pastagem ampliada em solo seco e área alta.
- Compactação influenciada pela pressão de lotação.
- Erosão influenciada por chuva, declive e cobertura vegetal.
- Produtividade da agricultura forrageira reduzida em condições críticas.
- Relevo integrado à ilustração 2D, sem linhas cartográficas sobre o mapa.
- Áreas altas, encostas e baixadas diferenciadas por textura, cor, luz e sombra.
- Painel de solo no módulo Fazenda.
- Consulta por mouse com elevação relativa, relevo, solo e umidade.
- Salvamento e compatibilidade com partidas anteriores.

### Etapa atual: Fase 0.8 — Operação pecuária automática

## Fase 0.7.4 — Tempo e calendário

**Status: concluída**

- Calendário real, com meses corretos, anos bissextos e formato `DD/MM/AAAA HH:MM`.
- Fonte oficial de data e hora no servidor Web, armazenada em UTC.
- Exibição e processamento no fuso `America/Bahia`.
- Tempo contínuo, sem pausa ou aceleração pelo jogador.
- Relógio único para calendário, ambiente, bovinos, funcionários e obras.
- Processamento da evolução da fazenda durante o período offline.
- Relatório de retorno com mudanças no rebanho, peso, pastagens e água.
- Obras retomadas ou concluídas conforme o horário oficial registrado.
- Salvamento automático a cada 60 segundos, ao fechar e ao suspender o jogo.
- Eventos críticos geram alertas sem interromper o calendário.
- Migração automática dos salvamentos criados no calendário anterior de 360 dias.

**Conclusão da fase:** a fazenda acompanha a data real e continua evoluindo mesmo quando o jogador está offline.

### Passo 2 — Fonte oficial de data e hora

**Status: concluído**

- Endpoint `GET /api/time` no mesmo servidor da versão Web.
- Timestamp armazenado em UTC.
- Exibição no fuso `America/Bahia`.
- Sincronização periódica sem utilizar o relógio do dispositivo do jogador.
- Timestamp oficial incluído no salvamento da partida.

### Passo 3 — Evolução persistente

**Status: concluído**

- Dias offline processados em lotes para preservar o desempenho.
- Resumo das consequências apresentado ao retornar.
- Obras em andamento persistidas com horário oficial de conclusão.
- Controles antigos de pausa, 1x, 8x e avanço manual removidos.

## Fase 0.8 — Operação pecuária automática

**Status: em andamento — 0.8.1 e 0.8.2 concluídas**

**Objetivo:** automatizar o trabalho pecuário sem criar microgerenciamento.

- Ordens de serviço criadas automaticamente pelas decisões do jogador. **Concluído em 0.8.1**
- Vaqueiro conduzindo e prendendo o lote para manejo. **Concluído em 0.8.1**
- Veterinário acionado automaticamente para vacinas e medicamentos. **Concluído em 0.8.1**
- Abastecimento automático de cochos e suplementos pelo vaqueiro. **Concluído em 0.8.1**
- Execução de cercas, porteiras, currais e balanças pela equipe rural após o planejamento do jogador. **Concluído**
- Opção automática para cercar todo o perímetro, sem formar pasto interno. **Concluído em 0.8.1**
- Custos de mão de obra pecuária separados dos materiais e insumos. **Concluído**
- Pesagem automática quando houver curral e balança.
- Rotinas recorrentes configuradas por objetivo, sem lista de pequenas tarefas.

### Fase 0.8.2 — Vegetação e manejo das pastagens

**Status: concluída**

- Motor único para Caatinga e pastagens cultivadas.
- Biomassa, cobertura, vigor, qualidade e degradação por área.
- Buffel, massai e andropogon com perfis produtivos distintos.
- Consumo de matéria seca conforme o peso vivo do lote.
- Capacidade de suporte dinâmica e pressão de pastejo.
- Relevo e solo derivados da posição real do polígono cercado.
- Descanso, formação, reforma, adubação e recuperação assistida.
- Serviços com duração, custo e evolução durante o período offline.
- Visual gradual e salvamento compatível com partidas anteriores.

Tratorista, máquinas agrícolas e gerenciamento de produção agrícola por funcionários não fazem parte desta fase. O foco permanece na pecuária.

**Conclusão da fase:** o jogador decide o manejo e os profissionais executam a operação pecuária.

## Fase 0.9 — Expansão e balanceamento

**Objetivo:** preparar o jogo para a versão 1.0.

- Compra e expansão de terras.
- Construção livre da propriedade.
- Mais lotes e pastos.
- Especialização em cria, recria ou engorda.
- Mercado com variação de preços.
- Indicadores de produtividade e rentabilidade.
- Tutorial e melhorias de usabilidade.
- Otimização para propriedades maiores.
- Balanceamento econômico e produtivo.

**Conclusão da fase:** o ciclo sandbox permanece estável durante partidas longas.

## Versão 1.0 — Lançamento inicial

**Objetivo:** entregar uma experiência completa de gestão pecuária.

- Ciclo produtivo e financeiro integrado.
- Custos operacionais discriminados por origem:
  - Alimentação e suplementação.
  - Sanidade e medicamentos.
  - Funcionários e serviços.
  - Água e energia.
  - Combustível e máquinas.
  - Cercas, porteiras e outras infraestruturas.
- Cada custo será gerado pelo consumo, serviço ou evento correspondente, sem cobrança genérica por bovino.
- Poço artesiano.
- Bomba alimentada por energia solar off-grid.
- Reservatório de água.
- Tubulação e bebedouros.
- Construção de infraestrutura sobre uma grade 2D.
- Pecuária, pastagem, água, nutrição e genética conectadas.
- Agricultura exclusiva para alimentação animal.
- Progressão por patrimônio, eficiência e qualidade do rebanho.
- Interface final para computadores.
- Salvamento estável.
- Exportação Web otimizada.
- Testes e correção de erros.

## Fora do escopo inicial

- Controle em primeira pessoa.
- Controle direto de um personagem.
- Venda de produtos agrícolas.
- Suporte para celulares e tablets.
- Multiplayer.
- Banco de dados ou servidor online.
