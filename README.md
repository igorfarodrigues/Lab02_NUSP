# Lab02_NUSP — Transformação de Dados com DBT

Este repositório implementa o **Laboratório 02** da disciplina de Engenharia de Dados, aplicando transformações com **dbt (Data Build Tool)** sobre dados da camada Silver (PostgreSQL) para gerar a camada Gold.

---

## 📋 Sumário

1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)
2. [Pré-requisitos](#pré-requisitos)
3. [Passo 01 — Camada Silver (PostgreSQL via Docker)](#passo-01--camada-silver-postgresql-via-docker)
4. [Passo 02 — Instalação e Configuração do DBT](#passo-02--instalação-e-configuração-do-dbt)
5. [Passo 03 — Sources](#passo-03--sources)
6. [Passo 04 — Models](#passo-04--models)
7. [Passo 05 — Macros](#passo-05--macros)
8. [Passo 06 — Testes](#passo-06--testes)
9. [Passo 07 — Documentação DBT](#passo-07--documentação-dbt)
10. [Visualização de Dados (BI)](#visualização-de-dados-bi)
11. [Estrutura do Projeto](#estrutura-do-projeto)

---

## 🏗️ Visão Geral da Arquitetura

```
[PostgreSQL - Schema: bookings]  ←→  [DBT]  ←→  [PostgreSQL - Schema: analytics]
        (Camada Silver / Raw)                          (Camada Gold / Marts)
                                                              ↕
                                                    [BI: Metabase / Superset]
```

**Modelo de Dados (Lineage)**

```
booking_sources.bookings ──┐
                           ├──► fact_ticket_flight (mart)
booking_sources.tickets ───┤
booking_sources.flights ───┘

booking_sources.airports ──┐
                           └──► dim_airports (mart)
booking_sources.flights ───┘
```

---

## ✅ Pré-requisitos

- Docker e Docker Compose instalados
- Python 3.8+
- pip

---

## Passo 01 — Camada Silver (PostgreSQL via Docker)

### 1.1 Subir o banco de dados

Na raiz do repositório, execute:

```bash
docker-compose up -d
```

Isso irá:
- Criar um container PostgreSQL na porta `5432`
- Criar o banco `dbt_lab2`
- Criar o schema `bookings` e todas as tabelas com dados de exemplo (script `init_scripts/01_init_bookings.sql`)

### 1.2 Verificar os dados carregados

```bash
docker exec -it lab02_postgres psql -U postgres -d dbt_lab2 -c "\dt bookings.*"
```

Tabelas disponíveis:
| Tabela | Descrição |
|---|---|
| `bookings.bookings` | Reservas de passageiros |
| `bookings.tickets` | Bilhetes emitidos |
| `bookings.ticket_flights` | Segmentos de voo por bilhete |
| `bookings.flights` | Voos programados/realizados |
| `bookings.airports` | Cadastro de aeroportos |
| `bookings.aircrafts` | Cadastro de aeronaves |

---

## Passo 02 — Instalação e Configuração do DBT

### 2.1 Instalação

```bash
pip install dbt-core dbt-postgres
dbt --version
```

### 2.2 Configuração do profile

Copie o arquivo de exemplo e configure as credenciais:

```bash
cp dbt-demo/dbt_project/profiles.yml.example ~/.dbt/profiles.yml
```

Edite `~/.dbt/profiles.yml` com as credenciais corretas (usuário, senha, host, database).

### 2.3 Navegar para o projeto DBT

```bash
cd dbt-demo/dbt_project
```

### 2.4 Validar a conexão

```bash
dbt debug
```

Saída esperada: `All checks passed!`

### 2.5 Instalar dependências (dbt_utils)

```bash
dbt deps
```

Este comando instala o pacote `dbt-labs/dbt_utils` definido no `packages.yml`.

### 2.6 Testar a execução

```bash
dbt run
```

---

## Passo 03 — Sources

As **sources** definem a origem dos dados brutos (camada Silver) e habilitam:
- Rastreamento de linhagem de dados
- Testes de validação *a priori*
- Documentação automática

**Arquivo:** `models/staging/booking_sources.yml`

```yaml
sources:
  - name: booking_sources
    database: dbt_lab2
    schema: bookings
    tables:
      - name: bookings
      - name: tickets
      - name: ticket_flights
      - name: flights
      - name: airports
      - name: aircrafts
```

**Referência nos modelos SQL:**

```sql
-- ✅ Com source (rastreável e documentado)
SELECT * FROM {{ source('booking_sources', 'flights') }}

-- ❌ Sem source (hardcoded, difícil de manter)
SELECT * FROM dbt_lab2.bookings.flights
```

---

## Passo 04 — Models

O projeto possui **2 modelos** na camada Marts (Gold):

### 4.1 `fact_ticket_flight` — Tabela Fato de Vendas de Passagens

**Arquivo:** `models/marts/fact_ticket_flight.sql`

Consolida informações de bilhetes, voos e reservas, incluindo:
- Dados do bilhete (`ticket_no`, `fare_conditions`, `amount`)
- Dados do voo (`flight_id`, `aircraft_code`, horários)
- Referência da reserva (`book_ref`)
- Duração calculada via macro (planejada e real)

```bash
dbt run --select fact_ticket_flight
```

### 4.2 `dim_airports` — Dimensão de Aeroportos

**Arquivo:** `models/marts/dim_airports.sql`

Enriquece o cadastro de aeroportos com métricas de operação:
- Total de partidas (`total_departures`)
- Total de chegadas (`total_arrivals`)
- Total de operações (`total_operations`)

```bash
dbt run --select dim_airports
```

### 4.3 Executar todos os modelos

```bash
dbt run
```

---

## Passo 05 — Macros

**Arquivo:** `macros/get_flight_duration.sql`

A macro `get_flight_duration` calcula a duração de um voo em minutos a partir de duas colunas de timestamp:

```sql
{% macro get_flight_duration(departure_column, arrival_column) %}
    CASE
        WHEN {{ departure_column }} IS NOT NULL AND {{ arrival_column }} IS NOT NULL
        THEN EXTRACT(EPOCH FROM ({{ arrival_column }} - {{ departure_column }})) / 60
        ELSE NULL
    END
{% endmacro %}
```

**Uso no modelo `fact_ticket_flight`:**

```sql
-- Duração planejada do voo
{{ get_flight_duration('f.scheduled_departure', 'f.scheduled_arrival') }} as scheduled_duration_minutes,

-- Duração real do voo (pode ser NULL)
{{ get_flight_duration('f.actual_departure', 'f.actual_arrival') }} as actual_duration_minutes
```

---

## Passo 06 — Testes

### 6.1 Testes Genéricos (YAML)

Definidos em `models/marts/generic_tests.yml` e `models/staging/booking_sources.yml`.

**Tipos de testes aplicados:**

| Teste | Descrição |
|---|---|
| `unique` | Garante unicidade de uma coluna |
| `not_null` | Garante que não há valores nulos |
| `accepted_values` | Valida conjunto de valores permitidos |
| `relationships` | Validação de integridade referencial (FK) |
| `dbt_utils.accepted_range` | Valida intervalo numérico (ex: amount >= 0) |

**Exemplo:**

```yaml
- name: fare_conditions
  tests:
    - not_null
    - accepted_values:
        values: ['Economy', 'Comfort', 'Business']
```

### 6.2 Testes Singulares (SQL)

Localizados em `tests/`. Um teste singular falha se retornar **qualquer linha** — portanto, as queries buscam exceções/violações de regras de negócio.

**`tests/verificar_chegada_apos_saida.sql`** — Verifica se algum voo tem chegada agendada antes ou igual à partida:

```sql
select flight_id, scheduled_departure, scheduled_arrival
from {{ ref('fact_ticket_flight') }}
where scheduled_arrival <= scheduled_departure
```

**`tests/verificar_valor_positivo_passagem.sql`** — Verifica se há passagens com valor zero ou negativo:

```sql
select ticket_no, flight_id, fare_conditions, amount
from {{ ref('fact_ticket_flight') }}
where amount <= 0
```

### 6.3 Executar os testes

```bash
# Todos os testes
dbt test

# Apenas testes de um model específico
dbt test --select fact_ticket_flight

# Apenas testes de sources
dbt test --select source:booking_sources
```

---

## Passo 07 — Documentação DBT

### 7.1 Gerar a documentação

```bash
dbt docs generate
```

Este comando compila o projeto e gera o arquivo `target/catalog.json` com os metadados do banco de dados.

### 7.2 Visualizar a documentação

```bash
# Porta padrão: 8080
dbt docs serve

# Ou em uma porta alternativa:
dbt docs serve --port 8001
```

Acesse no navegador: `http://localhost:8080` (ou `http://localhost:8001` se usar `--port 8001`)

A documentação gerada inclui:
- **Catálogo de modelos e sources** com descrições e metadados
- **Lineage Graph** (DAG) mostrando as dependências entre modelos
- **Testes configurados** para cada coluna
- **SQL compilado** de cada modelo

> 📸 **Screenshot do Lineage Graph do DBT:**
> O lineage graph mostra o fluxo de dados desde as tabelas de origem (`booking_sources`) até os modelos da camada Gold (`fact_ticket_flight` e `dim_airports`), passando pela camada de staging.

---

## 📊 Visualização de Dados (BI)

Conecte sua ferramenta de BI preferida ao PostgreSQL para visualizar os dados da camada Gold.

### Configuração de Conexão

| Parâmetro | Valor |
|---|---|
| Host | `localhost` |
| Porta | `5432` |
| Database | `dbt_lab2` |
| Schema | `dbt_project_analytics` |
| Usuário | `postgres` |
| Senha | `postgres` |

### Tabelas disponíveis na camada Gold

- `dbt_project_analytics.fact_ticket_flight` — Fatos de vendas de passagens
- `dbt_project_analytics.dim_airports` — Dimensão de aeroportos

### Sugestões de Visualizações

1. **Gráfico de Barras** — Distribuição de passagens por classe (`fare_conditions`)
2. **Gráfico de Barras Empilhado** — Total de operações por aeroporto (`dim_airports`)
3. **Scatter Plot (Dispersão)** — Duração planejada vs. duração real do voo
4. **Série Temporal** — Volume de voos por data de partida agendada
5. **Mapa** — Localização dos aeroportos com volume de operações

### Conectando o Metabase (exemplo)

```bash
docker run -d \
  -p 3000:3000 \
  --name metabase \
  metabase/metabase
```

Acesse `http://localhost:3000` e configure a conexão com o PostgreSQL local.

---

## 📁 Estrutura do Projeto

```
Lab02_NUSP/
├── docker-compose.yml              # Configuração do PostgreSQL via Docker
├── init_scripts/
│   └── 01_init_bookings.sql        # Script de criação de tabelas e dados de exemplo
├── README.md                       # Este arquivo
└── dbt-demo/
    └── dbt_project/
        ├── dbt_project.yml         # Configuração principal do projeto DBT
        ├── packages.yml            # Dependências (dbt_utils)
        ├── profiles.yml.example    # Exemplo de configuração de conexão
        ├── models/
        │   ├── staging/
        │   │   └── booking_sources.yml   # Definição das sources
        │   └── marts/
        │       ├── fact_ticket_flight.sql # Model: Fato de Passagens
        │       ├── dim_airports.sql       # Model: Dimensão de Aeroportos
        │       └── generic_tests.yml      # Testes genéricos dos models
        ├── macros/
        │   └── get_flight_duration.sql   # Macro: calcula duração do voo
        └── tests/
            ├── verificar_chegada_apos_saida.sql        # Teste singular
            └── verificar_valor_positivo_passagem.sql   # Teste singular
```

---

## 🚀 Execução Completa (Passo a Passo)

```bash
# 1. Subir o banco de dados
docker-compose up -d

# 2. Instalar o DBT
pip install dbt-core dbt-postgres

# 3. Configurar o profile
cp dbt-demo/dbt_project/profiles.yml.example ~/.dbt/profiles.yml
# Edite ~/.dbt/profiles.yml com suas credenciais

# 4. Entrar no projeto
cd dbt-demo/dbt_project

# 5. Validar conexão
dbt debug

# 6. Instalar dependências
dbt deps

# 7. Executar os modelos
dbt run

# 8. Executar os testes
dbt test

# 9. Gerar e visualizar documentação
dbt docs generate
dbt docs serve
```

---

## 📚 Referências

- [Documentação oficial do DBT](https://docs.getdbt.com/)
- [dbt_utils package](https://hub.getdbt.com/dbt-labs/dbt_utils/latest/)
- [PostgreSQL](https://www.postgresql.org/docs/)
- [Apache Superset](https://superset.apache.org/)
- [Metabase](https://www.metabase.com/)