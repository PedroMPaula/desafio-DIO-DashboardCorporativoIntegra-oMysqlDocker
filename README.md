# Desafio Power BI – Integração MySQL Local + Power BI
> Solução **sem Azure** – MySQL rodando localmente via Docker

---

## Visão Geral

Este projeto implementa o desafio de coleta e transformação de dados com Power BI usando a base **Company**, conectada a um MySQL **local** (via Docker), eliminando a necessidade de uma instância na Azure.

---

## 1. Pré-requisitos

| Ferramenta | Download |
|---|---|
| Docker Desktop | https://www.docker.com/products/docker-desktop |
| MySQL Workbench | https://dev.mysql.com/downloads/workbench/ |
| Power BI Desktop | https://powerbi.microsoft.com/pt-br/desktop/ |

---

## 2. Subindo o MySQL com Docker

Abra o terminal e execute:

```bash
docker run --name mysql-company \
  -e MYSQL_ROOT_PASSWORD=root1234 \
  -e MYSQL_DATABASE=company_db \
  -p 3306:3306 \
  -d mysql:8.0
```

Aguarde ~20 segundos e verifique se está rodando:

```bash
docker ps
```

---

## 3. Criando o Banco de Dados

Com o MySQL Workbench, conecte-se a:

| Campo | Valor |
|---|---|
| Host | `127.0.0.1` |
| Porta | `3306` |
| Usuário | `root` |
| Senha | `root1234` |

Em seguida, execute o arquivo `company_database.sql` fornecido neste projeto.  
**Menu:** File → Open SQL Script → Execute (⚡)

---

## 4. Conectando o Power BI ao MySQL Local

1. Abra o Power BI Desktop
2. **Obter Dados** → **Banco de Dados MySQL**
3. Preencha:
   - Servidor: `localhost`
   - Banco de dados: `company_db`
4. Autenticação: `root` / `root1234`
5. Selecione as tabelas: `employee`, `department`, `dept_locations`, `project`, `works_on`, `dependent`

> ⚠️ Se o Power BI pedir um conector, instale o **MySQL Connector/NET** em https://dev.mysql.com/downloads/connector/net/

---

## 5. Transformações Realizadas no Power Query

### 5.1 Cabeçalhos e Tipos de Dados
- Verificados e corrigidos os tipos de cada coluna
- `Salary` → tipo `Número Decimal Fixo` (Double)
- `Bdate` e `Mgr_start_date` → tipo `Data`
- `Ssn`, `Super_ssn` → tipo `Texto`

### 5.2 Valores Monetários
- Coluna `Salary` (employee) convertida para `Double` / Número Decimal

### 5.3 Tratamento de Nulos
- `Super_ssn` nulo em `employee`: identificados como **gerentes de topo** (James Borg – CEO)
- `Hours` nulo em `works_on`: linha referente ao gerente geral; mantida com `null` ou substituída por `0` conforme análise
- Nenhum departamento encontrado sem gerente na base fornecida

### 5.4 Verificação de Gerentes
- `Super_ssn = NULL` → apenas **James Borg** (888665555), confirma que é o gerente máximo
- Todos os demais colaboradores possuem gerente atribuído

### 5.5 Departamentos sem Gerente
- Todos os 3 departamentos possuem `Mgr_ssn` preenchido
- Caso houvesse ausência, preencheria com o Ssn do gerente mais adequado com base na hierarquia

### 5.6 Horas dos Projetos
- Verificadas na tabela `works_on`
- 1 registro com `Hours = NULL` (888665555 no projeto 20) – gerente geral; mantido como nulo

### 5.7 Separação de Colunas Complexas
- Coluna `Address` separada em: `Street`, `City`, `State`
  - Power Query → **Dividir Coluna** → por delimitador `,`

### 5.8 Mesclagem Employee + Department
- Mescla: `employee[Dno]` ↔ `department[Dnumber]` → **Left Outer Join** (base = employee)
- Motivo do Left Join: queremos **todos os colaboradores**, mesmo que o departamento esteja com dados incompletos
- Coluna adicionada: `Department_Name`
- Colunas desnecessárias de `department` removidas após expansão

### 5.9 Junção Colaborador + Nome do Gerente

Feita via **mescla de tabelas no Power Query** (self-join em `employee`):

```
employee[Super_ssn] ↔ employee[Ssn]  →  Left Outer Join
```

Ou via SQL (query nativa):

```sql
SELECT 
  CONCAT(e.Fname, ' ', e.Lname)  AS Employee_Name,
  e.Ssn,
  e.Salary,
  e.Dno,
  CONCAT(m.Fname, ' ', m.Lname)  AS Manager_Name,
  m.Ssn AS Manager_Ssn
FROM employee e
LEFT JOIN employee m ON e.Super_ssn = m.Ssn;
```

### 5.10 Mesclagem Nome + Sobrenome
- `Fname` + `Lname` → coluna única `Full_Name`
- Power Query: **Coluna Personalizada** → `= [Fname] & " " & [Lname]`

### 5.11 Mesclagem Departamento + Localização
- `dept_locations[Dlocation]` mesclada com `department[Dname]`
- Resultado: `"Research – Bellaire"`, `"Research – Houston"`, etc.
- Cada combinação **departamento-local** torna-se única → essencial para o **modelo estrela**

#### Por que Mesclar e não Atribuir?
> **Mesclar** combina dados de duas tabelas com base em uma chave de correspondência, gerando uma nova tabela relacional que preserva a granularidade e a rastreabilidade dos dados originais.  
> **Atribuir** simplesmente substitui valores em uma coluna existente, sem criar o relacionamento — perderia a capacidade de identificar cada par único departamento-local como uma entidade distinta, inviabilizando a normalização necessária para o modelo estrela.

### 5.12 Contagem de Colaboradores por Gerente
- Agrupamento na tabela `employee`:
  - **Agrupar por:** `Super_ssn`
  - **Nova coluna:** `Total_Employees` = Contagem de linhas
- Resultado: quantos subordinados diretos cada gerente possui

### 5.13 Remoção de Colunas Desnecessárias
Removidas de cada tabela:
- `employee`: `Minit`, `Bdate` (se não usar no relatório), colunas duplicadas após mescla
- `department`: colunas expandidas redundantes
- `dept_locations`, `works_on`: IDs internos após mescla

---

## 6. Estrutura de Arquivos

```
📁 desafio-DIO-DashboardCorporativoIntegra-oMysqlDocker/
├── company_database.sql    ← Script para criar e popular o banco
└── PowerBI_Company.pbix    ← Arquivo Power BI (gerado pelo usuário)
```

---

## 7. Vantagens da Solução Sem Azure

| Azure | MySQL Local (Docker) |
|---|---|
| Custo mensal (~$20–50+) | **Gratuito** |
| Necessita conta e cartão | Sem cadastro |
| Latência de rede | Conexão local instantânea |
| Firewall/regras de acesso | Sem configuração de rede |
| Dependência de internet | Funciona offline |

---

## 8. Encerrar o Ambiente

```bash
# Parar o container
docker stop mysql-company

# Remover (apaga os dados)
docker rm mysql-company
```

Para **preservar os dados** entre reinicializações, use um volume:

```bash
docker run --name mysql-company \
  -e MYSQL_ROOT_PASSWORD=root1234 \
  -e MYSQL_DATABASE=company_db \
  -p 3306:3306 \
  -v mysql_company_data:/var/lib/mysql \
  -d mysql:8.0
```
