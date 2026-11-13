# Análise da produção ambulatorial do SUS em Ijuí/RS (SIASUS)

Solução de análise de dados para apoiar a **Secretaria Municipal de Saúde de Ijuí/RS** no planejamento, monitoramento e avaliação dos serviços ambulatoriais. Os dados do **SIASUS** (DATASUS) são armazenados em **MySQL**, processados com **Pandas** e apresentados com **Matplotlib/Seaborn**.

Trabalho T3 da disciplina **Programação para Ciência de Dados** (UNIJUÍ).

> **Pergunta norteadora:** como transformar os dados do SIASUS em informações que permitam compreender a produção ambulatorial, identificar diferenças e possíveis problemas nos serviços de saúde e subsidiar o planejamento e a tomada de decisão da Secretaria Municipal de Saúde de Ijuí?

---

## Fontes e período

| Dado | Arquivo | Origem |
|---|---|---|
| Produção ambulatorial (PA) do RS | `PARS2607.dbc` | DATASUS → SIASUS → Dados → *PA – Produção Ambulatorial* · FTP `ftp.datasus.gov.br/dissemin/publicos/SIASUS/200801_/Dados/` |
| Estabelecimentos (CNES) | `CADGERRS.dbf` | DATASUS → SIASUS → Arquivos auxiliares para tabulação → `TAB_SIA.zip` |
| Ocupações (CBO) | `CBO.dbf` | `TAB_SIA.zip` |
| Diagnósticos (CID-10) | `S_CID.dbf` | `TAB_SIA.zip` |
| Procedimentos (SIGTAP) | `TB_SIGTAW.dbf` | `TAB_SIA.zip` |
| Municípios, regiões de saúde e microrregiões | `tb_municip`, `tb_regsaud`, `tb_micibge` | DATASUS → Base Territorial → `06-base_territorial_jun26.zip` |
| Conversão DBC → DBF → CSV/SQL | TabWin 4.1.5 | DATASUS → Aplicativos → TABWIN |

**Período analisado:** mês de **movimentação julho/2026** (arquivo `PARS2607`), estabelecimentos localizados em **Ijuí** (`pa_ufmun = '431020'`): **68.827 registros**.

O banco é preparado para receber mais meses: basta carregar outros arquivos `PARS` na tabela `pars`. A tabela de tempo (`DIMTEMPO`) e todas as análises do notebook se ajustam automaticamente.

---

## Requisitos

- **MySQL 8.0**, com permissão para `LOAD DATA INFILE`
- **Python 3.10+** (testado com Python 3.14) e Jupyter
- Bibliotecas Python:

```bash
pip install pandas numpy mysql-connector-python matplotlib seaborn
```

Versões testadas: pandas 3.1.1 · numpy 2.5.4 · matplotlib 3.11.2 · seaborn 0.13.2 · mysql-connector-python 26.7.0.

---

## Estrutura do repositório

```
├── README.md
├── 01-cria-tabelas.sql                       # CREATE TABLE da pars e das tabelas auxiliares (DDL gerado pelo TabWin)
├── 02-carga-pars.sql                         # LOAD DATA INFILE do PARS (CSV)
├── 03-carga-auxiliares.sql                   # carga de cadgerrs, cbo, s_cid, procedimentos, tb_municip, tb_regsaud, tb_micibge
├── 04-gera-dimtempo-mysql.sql                # tabela de granularidade temporal DIMTEMPO (mês, bimestre, trimestre, semestre)
├── 05-corrige-s_cid.sql                      # correção de chaves repetidas na s_cid (ver "Validação da carga")
├── view.sql                                  # VIEW pa_ijui: relacionamentos + filtro de Ijuí
└── Etapa 4 - Analises Estrategicas - DBSIA.ipynb   # exploração, limpeza, análises, gráficos e conclusões
```

Os arquivos de dados (`.dbc`, `.dbf`, `.csv`) **não são versionados**: o CSV do PARS do RS tem cerca de 1,8 GB por mês. Eles devem ser baixados do DATASUS conforme o passo a passo abaixo.

---

## Como executar

### 1. Obter e converter os dados

1. Baixe o `PARS2607.dbc` pelo **link FTP** do DATASUS e o `TAB_SIA.zip` (arquivos auxiliares).
2. Converta `.dbc` → `.dbf` arrastando o arquivo sobre o `dbf2dbc.exe` (pasta do TabWin).
3. Abra o `.dbf` no **TabWin** (*Arquivo → Ver arquivo DBF*) e use os botões **csv** (exportar dados) e **sql** (gerar o `CREATE TABLE`).

### 2. Criar e carregar o banco `dbsia`

Execute os scripts **na ordem**, pelo cliente de linha de comando do MySQL (como administrador). O `LOAD DATA` costuma falhar pelo Workbench por causa das permissões.

```sql
CREATE DATABASE dbsia;
USE dbsia;
SOURCE 01-cria-tabelas.sql;
SOURCE 02-carga-pars.sql;
SOURCE 03-carga-auxiliares.sql;
SOURCE 05-corrige-s_cid.sql;
```

O CSV do PARS deve estar na pasta de upload do MySQL (`SHOW VARIABLES LIKE 'secure_file_priv';`). Exemplo de carga:

```sql
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PARS2607.csv'
INTO TABLE pars CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n' IGNORE 1 ROWS;
```

**Recomendado:** índice no filtro da VIEW, que reduz bastante o tempo das consultas:

```sql
CREATE INDEX ix_pars_ufmun ON pars (pa_ufmun);
```

### 3. Executar o notebook

Abra `Etapa 4 - Analises Estrategicas - DBSIA.ipynb` **na mesma pasta dos scripts `.sql`** e execute as células em ordem. Usuário e senha do MySQL são solicitados **uma única vez**, em tempo de execução, e não ficam gravados em nenhum arquivo.

Ao carregar os dados, o notebook:

1. cria a tabela `DIMTEMPO` (executando `04-gera-dimtempo-mysql.sql`) se ela ainda não existir;
2. cria ou atualiza a VIEW `pa_ijui` (executando `view.sql`) se faltar alguma coluna;
3. valida a carga, comparando os registros da VIEW com os da `pars` e procurando chaves repetidas nas tabelas auxiliares.

---

## Modelo de dados

A VIEW `pa_ijui` relaciona a produção (`pars`) com as tabelas descritivas e filtra os estabelecimentos de Ijuí:

| Relacionamento | Chave |
|---|---|
| `pars` → `cadgerrs` (estabelecimento) | `pa_coduni = cnes` |
| `pars` → `procedimentos` (SIGTAP) | `pa_proc_id = ip_cod` |
| `pars` → `cbo` (ocupação) | `pa_cbocod = cbo` |
| `pars` → `s_cid` (diagnóstico) | `pa_cidpri = cd_cod` |
| `pars` → `tb_municip` (município do estabelecimento e do paciente) | `pa_ufmun` / `pa_munpcn = co_municip` |
| `pars` → `DIMTEMPO` (mês de movimentação) | `pa_mvm = anomes` |

Além das descrições, a VIEW expõe os códigos usados nas análises: procedimento SIGTAP (`CodProcedimento`), tipo de unidade do CNES (`TipoUnidade`), instrumento de registro (`Instrumento`), número da APAC (`NumAutorizacao`) e competência do atendimento (`Competencia`).

---

## Validação da carga

A validação comparou os registros da VIEW com os da tabela `pars` e encontrou um problema: a VIEW devolvia **70.377 registros**, contra **68.827** na `pars`.

- **Causa:** o arquivo `S_CID` do DATASUS contém **14 códigos em minúsculo** (`j450`, `m050`, `n63`…, descrição "CID NÃO IDENTIFICADO"). A collation padrão do MySQL não diferencia maiúsculas de minúsculas, então `J450` = `j450` no `JOIN`, e cada registro com um desses CIDs voltava duas vezes.
- **Impacto:** +1.550 registros e cerca de **+R$ 682 mil** no valor aprovado de Ijuí (asma, artrite reumatoide e doenças da mama).
- **Correção** (`05-corrige-s_cid.sql`): remoção das 14 linhas e criação da `PRIMARY KEY (cd_cod)`. A Seção 1.0 do notebook repete essa validação a cada execução.

---

## Decisões de limpeza e preparação

| Tema | Decisão | Justificativa |
|---|---|---|
| Valores nulos | Preenchidos com **"Não informado"** | Apagar linhas eliminaria procedimentos e valores reais pagos pelo SUS |
| Sexo `0`, idade inválida, CID `0000` | Tratados como "Não informado" e explicados pelo instrumento de registro | Os 2.790 registros com sexo `0` são todos de **BPA consolidado**, que não identifica o paciente |
| Duplicações criadas na carga | **Removidas na origem** (`s_cid`) | Eram erro de carga, não do dado |
| Linhas idênticas no PARS | **Mantidas** | O arquivo público não tem data nem identificação do paciente, então atendimentos repetidos (sessões, retornos) geram linhas iguais. Removê-las apagaria cerca de 39% dos registros e não bateria com os totais oficiais |
| Área do procedimento | Hierarquia oficial **SIGTAP** (grupo/subgrupo do `pa_proc_id`) | Classificação exata; só saúde mental usa também a ocupação (CBO) e o tipo de unidade CAPS |
| Tipo de estabelecimento | Tipo de unidade do **CNES** (`pa_tpups`) | Classificação oficial, independente do nome |

---

## Análises realizadas

1. **Validação e exploração:** dimensão, tipos, estatísticas descritivas, ausentes e inválidos por instrumento de registro
2. **Limpeza e preparação:** tratamento de ausentes e de duplicados
3. **Volume e perfil:** último mês, bimestre e trimestre (DIMTEMPO), distribuição por área SIGTAP, evolução temporal e competência × movimentação
4. **Estabelecimentos:** ranking, tipo de unidade e aprovados × produzidos
5. **Perfil demográfico e epidemiológico:** pirâmide etária, área × faixa etária, capítulos da CID-10 e doenças crônicas
6. **Fluxos regionais:** municípios de origem e participação de não residentes por área
7. **Recursos financeiros:** valor aprovado × produzido, diferenças por estabelecimento e gasto médio por procedimento
8. **Áreas críticas:** oncologia (quimioterapia × radioterapia, APACs), saúde mental (CAPS, psiquiatria, psicologia) e atenção básica (UBS cadastradas × produção no SIA)

### Principais resultados (jul/2026)

- **68.827 registros**: 461.059 procedimentos produzidos e **364.679 aprovados** (79,1%). Em valor, R$ 6.272.060,94 produzidos e **R$ 6.158.024,69 aprovados** (98,2%): as glosas recaem sobre procedimentos de baixo custo.
- A **17ª CRS** lidera em quantidade, toda em **dispensação de medicamentos**. O **Hospital de Clínicas** concentra mais da metade do valor aprovado.
- **Oncologia** (toda no HCI): cerca de **R$ 2,0 milhões**, um terço do valor do município. Cerca de 80% dos pacientes vêm de outros municípios.
- Cerca de **73% do valor aprovado** atende **moradores de outros municípios**: Ijuí funciona como polo regional.
- **Hospital Bom Pastor:** 53% da quantidade aprovada, mas valor aprovado acima do produzido (ponto de atenção para o faturamento).
- **Nenhuma UBS/ESF** de Ijuí tem produção no SIA: a atenção básica é registrada em outro sistema (SISAB / e-SUS APS).

---

## Limitações

- **Um único mês de movimentação:** não permite analisar tendência, sazonalidade, picos e quedas. O notebook se ajusta automaticamente quando mais meses são carregados.
- **Registros ≠ pacientes:** o arquivo público não identifica o paciente (LGPD). Na oncologia, as APACs distintas aproximam o número de pacientes.
- **Diagnóstico (CID):** só cerca de um terço dos registros traz CID válido, quase todos de APAC (alta complexidade).
- **Atenção básica:** a produção das UBS/ESF não está no SIASUS. A análise de hipertensão e diabetes na APS depende de dados do SISAB, que não fazem parte deste trabalho.
