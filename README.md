# Game Simulador Pecuário

Jogo sandbox 2D de gestão pecuária, ambientado inicialmente no Sertão nordestino, no bioma Caatinga.

As fases 0.1 até 0.7.3 estão concluídas e a Fase 0.8 foi iniciada. A agricultura existe somente como suporte à alimentação do rebanho.

## Estado atual

O protótipo possui ciclo produtivo, financeiro, nutricional, hídrico natural, agrícola-forrageiro e de manejo das pastagens, validado por testes automáticos e exportado para Web. Contas e partidas na nuvem usam um projeto Supabase exclusivo na região de São Paulo.

## Contas e partidas na nuvem

- Cadastro e login usam e-mail e senha pelo Supabase Auth.
- Cada conta possui três slots.
- O jogo salva primeiro em `user://cloud_cache/<user_id>/slot_N.json` e sincroniza depois.
- Sessão, pendências offline, conflitos e exclusões pendentes são mantidos no dispositivo.
- Ao entrar em outro navegador, as partidas da nuvem são baixadas novamente.
- `users.json`, `fazenda_save.json` e saves antigos não são importados nem apagados.
- A chave `service_role` nunca é usada no jogo.

Para criar e configurar o ambiente, siga [docs/SUPABASE.md](docs/SUPABASE.md).

## Objetivo do jogo

Administrar uma propriedade pecuária com liberdade para comprar, criar, manejar e vender bovinos. As decisões do jogador afetam o rebanho, as pastagens, a água e o resultado financeiro da fazenda.

## Escopo concluído do protótipo 0.1

- Mapa 2D pequeno.
- Bioma Caatinga e clima semiárido básico.
- Propriedade inicialmente sem cerca, exigindo a construção do perímetro.
- Delimitação dos pastos pelo jogador com cercas internas compartilhadas.
- Dez bovinos com peso, fome, sede e saúde.
- Um lote transferível entre pastos.
- Um açude natural em cada pasto, sem medição exata de volume nesta etapa.
- Compra e venda de animais.
- Salvamento e carregamento local da partida.
- Interface de gerenciamento com header, menu lateral e fazenda central.

## Escopo concluído da Fase 0.2

- Caixa inicial de R$ 50.000.
- Compra de animais com desconto no caixa.
- Venda de animais com entrada no caixa.
- Bloqueio de compras sem saldo suficiente.
- Histórico das movimentações financeiras.
- Salvamento e carregamento dos dados financeiros.

Os custos operacionais são discriminados por origem. Não há desconto genérico por bovino.

## Escopo concluído da Fase 0.3

- Capacidade de suporte calculada conforme o tamanho de cada pasto.
- Superlotação e degradação da pastagem.
- Recuperação do pasto durante o descanso e o período favorável.
- Qualidade nutricional da forragem.
- Ganho ou perda de peso conforme a alimentação.
- Compra, estoque e consumo de sal mineral.
- Compra, estoque e consumo de suplemento.
- Custos nutricionais identificados no histórico financeiro.
- Salvamento da condição dos pastos e dos estoques.

## Sistema integrado de vegetação 0.8.2

- Biomassa em kg de matéria seca por hectare, cobertura do solo, vigor e qualidade.
- Caatinga nativa, capim-buffel, capim-massai e capim-andropogon com respostas próprias.
- Consumo calculado pelo peso vivo do lote e reduzido pelo fornecimento de reserva.
- Capacidade estimada pela área, espécie, biomassa aproveitável e condição da vegetação.
- Crescimento conectado à chuva, seca, calor, umidade, fertilidade, compactação e erosão.
- Cinco estágios graduais: saudável, atenção, degradada, severamente degradada e solo exposto.
- Descanso, formação, reforma, correção do solo e recuperação assistida com custo e duração.
- Relevo e solo calculados pela posição real de cada área cercada.
- Mudança gradual da aparência do pasto conforme cobertura e degradação.
- Salvamento na versão 18 com migração automática das partidas anteriores.

## Escopo concluído da Fase 0.4

- Açude natural em cada pasto.
- Rio intermitente com variação entre chuva, transição e estiagem.
- Consumo de água do açude pelo rebanho.
- Uso do rio quando o açude está seco e o lote possui acesso.
- Falta de água afetando sede e saúde.
- Variação visual dos açudes e do rio.
- Custos identificados para cerca externa, cerca interna e porteira.
- Salvamento do nível do rio e dos açudes.

Poço artesiano, bomba solar, reservatório, tubulação e bebedouros foram reservados para a versão 1.0.

## Escopo concluído da Fase 0.5

- Talhão forrageiro dentro da propriedade.
- Milho e sorgo para silagem.
- Capiaçu e palma forrageira.
- Capim destinado à produção de feno.
- Preparo do solo e custos de plantio.
- Crescimento das culturas pelo calendário.
- Colheita e armazenamento por tipo de alimento.
- Programação de alimentação do lote por sete dias.
- Redução do consumo do pasto durante o fornecimento da reserva.
- Salvamento da cultura, do estoque e do trato programado.
- Produção agrícola sem opção de venda.

## Escopo concluído da Fase 0.6

- Rebanho separado por sexo e categoria de idade.
- Estação de monta entre novembro e abril.
- Monta natural com presença de touro.
- Inseminação artificial com custo identificado no caixa.
- Fertilidade influenciada pela genética e condição corporal.
- Gestação de 285 dias, nascimento e desmama.
- Herança de adaptação ao calor, resistência a parasitas e ganho de peso.
- Herança de fertilidade, facilidade de parto e habilidade materna.
- Seleção da genética dos descendentes após a desmama.
- Salvamento do ciclo reprodutivo e dos indicadores genéticos.

## Revisão de UI/UX 0.6.1

- Navegação lateral organizada por módulos.
- Dashboard identificado como funcionalidade futura.
- Módulos Fazenda, Estruturas, Loja Rural, Rebanho, Produção, Mercado e Financeiro.
- Fazenda permanentemente visível na área central.
- Loja Rural com preços individuais por estrutura.
- Cercas de arame farpado, arame liso e elétrica.
- Construção livre de cercas por múltiplos pontos no mapa.
- Finalização da cerca por duplo clique, `Enter`, botão direito ou botão de confirmação.
- Cercas fechadas reconhecidas como pastos.
- Porteiras instaladas sobre cercas e com abertura visual.
- A propriedade inteira cercada funciona como área geral para o primeiro rebanho; a porteira continua obrigatória para a entrada dos animais.
- Divisões internas em pastos são opcionais no início e ampliam as opções de manejo.
- Mercado clicável com orientação clara sobre a estrutura que ainda falta.
- Curral posicionado livremente.
- Balança instalada somente dentro do curral.
- Prévia da construção, custo estimado e cancelamento sem cobrança.
- Salvamento e carregamento das estruturas construídas.

## Áreas de trabalho dos módulos

- O menu lateral permanente ocupa somente 128 px.
- Fazenda e Loja Rural mantêm o mapa visível com ferramentas flutuantes recolhíveis.
- Dashboard, Estruturas, Rebanho, Produção, Mercado e Financeiro usam a área completa.
- O Rebanho pode abrir o mapa temporariamente para visualizar o lote ou selecionar um animal.
- O botão “Voltar ao mapa” restaura o último módulo cartográfico utilizado.

## Representação dos bovinos 0.6.3 e 0.6.4

- Cada bovino possui identificação, sexo, idade, categoria, peso, genética e raça.
- Não existe limite artificial para o tamanho do rebanho.
- Movimento visual atualizado em grupos para preservar desempenho.
- Sprites superiores próprios para Nelore, Nelore Pintado, Guzerá, Brahman, Tabapuã, Sindi, Angus, Hereford, Brangus, Braford e Senepol.
- Diferenças visuais de porte, pelagem, cupim, chifres e orelhas.
- Escolha da raça do lote no Mercado.
- Nascimentos preservam a raça materna.

### Fluxo para comprar o primeiro rebanho

1. Abra a Loja Rural.
2. Cerque toda a propriedade ou desenhe uma área fechada.
3. Aguarde a equipe concluir a construção.
4. Compre uma porteira e instale-a sobre a cerca.
5. Abra o módulo Mercado e compre os animais.

Se alguma estrutura estiver faltando, o Mercado informa o próximo passo sem bloquear silenciosamente o botão de compra.

## Etapa atual

- Fase 0.8: operação pecuária automática.

## Clima semiárido 0.7.1

- Chuvas diárias irregulares.
- Temperatura máxima e sequência de dias secos.
- Recarga e evaporação dos açudes e do rio intermitente.
- Crescimento da pastagem afetado por chuva, calor e seca prolongada.
- Estresse térmico ligado à adaptação genética do rebanho.
- Clima diário incluído no salvamento da partida.

## Sanidade 0.7.2

- Pressão parasitária individual em cada bovino.
- Risco influenciado pelo clima, lotação, pasto e genética.
- Estados saudável, sob atenção e parasitose clínica.
- Controle parasitário do lote com custo e proteção temporária.
- Medicamento aplicado somente nos bovinos em estado clínico, com período de recuperação.
- Vacinação de bezerras entre três e oito meses contra brucelose.
- Vacinação anual individual contra clostridioses.
- Protocolo vitamínico-mineral de apoio por 30 dias.
- Suplemento proteico e sal mineral mantidos separadamente no módulo Produção.
- Perda gradual de desempenho antes de situações críticas.
- Mortalidade sanitária somente em quadro extremo sem tratamento.
- Custos e protocolos sanitários incluídos no caixa e no salvamento da partida.

## Relevo e solo 0.7.3

- Baixada com solo mais profundo, úmido e fértil.
- Área alta com solo raso, pedregoso e drenagem mais rápida.

- Umidade, fertilidade, compactação e erosão por pasto.
- Infiltração e escoamento da chuva conforme o tipo de solo.
- Recarga dos açudes influenciada pelo escoamento superficial.
- Crescimento e perda da pastagem influenciados pelo solo e pelo relevo.
- Compactação gradual conforme a lotação do pasto.
- Pressão parasitária influenciada pela umidade local.
- Produtividade forrageira reduzida em solo muito seco, erodido ou pouco fértil.
- Relevo integrado à ilustração 2D por cores, texturas, luz e sombra.
- Áreas altas mais secas e pedregosas e baixadas visualmente mais úmidas.
- Opção de informações do terreno ao passar o mouse sobre a propriedade.
- Tooltip com elevação relativa, relevo, tipo de solo e umidade.
- Condições do solo incluídas no salvamento da partida.

## Tempo e calendário 0.7.4

- Relógio central no header.
- Calendário real, com meses de duração correta e anos bissextos.
- Data inicial definida pelo horário oficial no fuso `America/Bahia`.
- Controles no header para pausar, jogar e acelerar.
- No modo Play, um segundo real representa um dia no jogo.
- No modo Acelerar, um segundo real representa sete dias no jogo.
- Clima, pastagens, água, bovinos, serviços e obras seguem o mesmo relógio da partida.
- O período fechado avança no ritmo Play, limitado a 30 dias por retorno.
- Ao retornar, o jogador recebe um resumo das mudanças ocorridas offline.
- Eventos críticos pausam o tempo automaticamente e geram um alerta.
- Obras em andamento pausam e aceleram junto com a fazenda.
- Salvamento automático a cada 60 segundos e ao fechar ou suspender o jogo.
- Partidas antigas de 360 dias são convertidas automaticamente.

### Horário oficial e evolução offline — Passos 2 e 3

- A versão Web consulta `GET /api/time` no mesmo servidor do jogo.
- O servidor armazena o horário em UTC e entrega a representação de `America/Bahia`.
- O servidor define a data inicial e mede o período fechado sem usar a data do computador.
- O header exibe a data simulada em `DD/MM/AAAA HH:MM`.
- O salvamento registra o timestamp do jogo, o modo selecionado e o UTC oficial.
- O horário é sincronizado novamente a cada cinco minutos.
- A fazenda recupera até 30 dias em blocos para não travar o navegador.

## Operação pecuária automática 0.8.1

- Ordens sanitárias iniciadas pelos mesmos botões de manejo.
- Vaqueiro conduzindo o lote ao curral sem distribuição manual de tarefas.
- Curral obrigatório para vacinação e tratamentos do lote.
- Veterinário acionado automaticamente quando o manejo exige aplicação clínica.
- Conclusão do serviço no próximo dia da fazenda.
- Abastecimento automático dos cochos pelo vaqueiro quando há estoque.
- Figura 2D do vaqueiro acompanhando a operação no mapa.
- Ordens em andamento incluídas no salvamento da partida.
- Cercas continuam planejadas pelo jogador e são registradas como executadas pela equipe rural.
- Loja Rural com opção de cercar automaticamente todo o perímetro da fazenda.
- Cerca externa cobrada pelo comprimento e separada das divisões internas dos pastos.
- Equipe rural em `AnimatedSprite2D`, com caminhada até a obra e 24 quadros desenhados para andar, martelar, carregar e fincar mourões e cavar enquanto a cerca surge progressivamente em aproximadamente 21 segundos.
- Vaqueiro e equipe rural com sprites isométricos originais em acabamento 3D pré-renderizado, sombras e animações de caminhada e trabalho.
- Trabalhadores diferenciados visualmente por roupa, ferramenta e função executada.
- Bovinos e trabalhadores com escala visual ampliada em 50% para melhorar a leitura na visão geral da fazenda, preservando as diferenças entre categorias.
- Estruturas com o preço total separado entre materiais e mão de obra.
- Medicamentos, vacinas e suplementos com custos separados entre insumos e serviço profissional.
- A separação contábil não altera os preços totais já praticados no jogo.
- Cercas manuais, porteiras, currais e balanças são executados pela equipe rural após a confirmação. Cercas maiores exigem mais tempo; cancelar ou trocar de módulo antes da conclusão interrompe a obra sem cobrança.
- A propriedade possui 595 tarefas baianas: 2.591.820 m² ou 259,182 hectares. No mapa de 3.200 × 1.800 unidades, cada unidade representa aproximadamente 0,671 metro.
- O módulo Fazenda identifica a Fazenda Santo Antônio, diferencia operação normal, atenção e estado crítico, mostra lotação atual versus capacidade estimada e resume todas as porteiras instaladas.
- Escala visual estratégica: bovinos adultos são a referência; novilhas e garrotes aparecem menores, bezerros têm cerca de 60% do porte adulto e pessoas mantêm proporção compatível. Animais e pessoas recebem ampliação visual controlada para continuarem identificáveis, enquanto estradas, cercas, mourões, porteiras, currais e balanças seguem a escala territorial.
- Bovinos e funcionários usam aproximadamente 6,8 vezes o tamanho territorial literal para permanecerem legíveis. Essa ampliação não altera a proporção entre as categorias nem os cálculos da fazenda.
- Tratorista e gestão agrícola de funcionários permanecem fora desta fase pecuária.

## Tecnologias

### Engine e linguagem

- Engine: Godot 4.7.1.
- Linguagem: GDScript.
- SDK: recursos nativos da Godot.
- Bibliotecas externas: nenhuma inicialmente.

### Plataforma e renderização

- Plataforma alvo: Web para computadores.
- Modo de renderização: Compatibility.
- Responsividade: limitada a desktops, MacBooks e notebooks.
- Celulares e tablets não fazem parte do suporte planejado.
- Persistência: salvamento local no navegador.
- Banco de dados: não utilizado no protótipo 0.1.
- API: não utilizada no protótipo 0.1.

> **Observação:** a stack pode evoluir nas próximas versões conforme a necessidade do projeto.

## Instalação

1. Instale o Godot 4.7.1 Standard.
2. Abra o Godot.
3. Importe o arquivo `project.godot` localizado na raiz deste projeto.

## Como executar

1. Abra o projeto no Godot.
2. Pressione `F6` para executar a cena atual ou `F5` para executar o projeto.

A configuração de exportação Web está preparada e a primeira versão para navegador já foi gerada em `builds/web`.

### Executar a versão Web

No terminal aberto na pasta do projeto, execute:

```bash
make serve
```

Depois, abra `http://localhost:8080` no Safari ou Chrome.

Não abra o arquivo `index.html` diretamente, pois o navegador precisa carregar os arquivos Web por meio de um servidor local.

### Comandos de desenvolvimento

```bash
make test
make web
make check
make serve
make restart
make stop
make status
```

- `make test`: executa os testes automáticos.
- `make web`: gera a versão Web.
- `make check`: testa e gera a versão Web.
- `make serve`: gera e inicia o servidor local com o endpoint `/api/time`.
- `make restart`: encerra e inicia novamente o servidor.
- `make stop`: encerra o servidor iniciado pelo Makefile.
- `make status`: informa se o servidor está ativo.

Para usar outra porta:

```bash
make serve PORT=8081
```

## Validação

O teste automático verifica cerca externa, divisão dos pastos, porteira, lote, calendário, água natural, espécies forrageiras, biomassa, degradação, recuperação, nutrição, agricultura forrageira, compra, venda, transferência dos animais, custos, saldo, estoques e histórico financeiro.

## Como jogar

O ciclo principal planejado é:

**manejar pastos → alimentar o rebanho → acompanhar o peso → vender animais → reinvestir na propriedade.**

## Contribuição

As regras de contribuição serão definidas após a criação da estrutura inicial do projeto.

## Licença

A licença do projeto ainda não foi definida.
