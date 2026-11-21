# Tutorial — Ambiente Docker com MySQL 8.2

Este tutorial explica como subir o banco de dados do **Sistema de Captação e Prospecção de Projetos Universitários** em um container Docker, aplicar o DDL, rodar os testes e conectar pelo DBeaver.

## 1. Visão geral

| Item | Valor |
|---|---|
| SGBD | MySQL **8.2** (imagem oficial `mysql:8.2`) |
| Container | `captacao_mysql` |
| Host / porta | `localhost` / `3306` |
| Usuário / senha | `root` / `root` |
| Banco | `sistema_captacao_projetos` (criado pelo `sql/ddl.sql`) |
| Persistência | **Nenhuma**: os dados ficam em memória e somem quando o container para |

> **Atenção:** as credenciais são fixas e fracas de propósito. Use este ambiente **apenas para desenvolvimento**.

O container sobe **vazio**. O banco só é criado quando você roda `./scripts/db.sh ddl`.

## 2. Pré-requisitos

1. **Docker Engine** e o plugin **Docker Compose v2**. Para conferir:
   ```bash
   docker --version
   docker compose version     # com espaço; o antigo "docker-compose" não é usado
   ```
2. **Rodar Docker sem `sudo`** (Linux). Se aparecer `permission denied ... docker.sock`:
   ```bash
   sudo usermod -aG docker "$USER"
   # depois saia e entre de novo na sessão (ou reinicie)
   ```
3. **Porta 3306 livre.** Para conferir (não deve aparecer nada):
   ```bash
   ss -ltn | grep ':3306 '
   ```
   Se houver um MySQL local rodando, pare-o (`sudo systemctl stop mysql`) ou troque a porta (seção 9).

## 3. Arquivos do ambiente

```
.
├── docker-compose.yml      # definição do container MySQL 8.2
├── scripts/
│   └── db.sh               # automação (up, ddl, test, shell...)
└── sql/
    ├── ddl.sql             # cria o banco e as 20 tabelas
    └── teste_ddl.sql       # inserções válidas e inválidas
```

A pasta `sql/` é montada **somente leitura** em `/sql` dentro do container.

## 4. Início rápido

Na raiz do repositório:

```bash
./scripts/db.sh up      # sobe o MySQL e espera ficar pronto (1ª vez baixa a imagem)
./scripts/db.sh ddl     # cria o banco e as tabelas
./scripts/db.sh test    # popula com dados de exemplo e testa as restrições
./scripts/db.sh shell   # abre o console mysql
```

Para encerrar:

```bash
./scripts/db.sh down    # para o container (os dados são perdidos)
```

## 5. Referência dos comandos

Uso: `./scripts/db.sh <comando> [argumentos]`

| Comando | O que faz |
|---|---|
| `up` | Sobe o MySQL 8.2 e espera o *healthcheck* indicar que está pronto |
| `down` | Para e remove o container. **Os dados são perdidos** |
| `restart` | `down` + `up`; o servidor volta vazio |
| `ddl` | Aplica `sql/ddl.sql`, que apaga e recria o banco `sistema_captacao_projetos`. Ao final mostra quantas tabelas (esperado 20) e triggers (esperado 7) existem |
| `test` | Executa `sql/teste_ddl.sql`. Exige que o `ddl` já tenha sido aplicado |
| `reset` | `ddl` + `test`: recria e popula o banco sem reiniciar o container |
| `shell` | Abre o console `mysql` já conectado ao banco (sair com `exit`) |
| `sql <arquivo>` | Executa um arquivo `.sql` do seu computador no banco |
| `logs` | Mostra os logs do MySQL em tempo real (`Ctrl+C` para sair) |
| `status` | Mostra o estado do container |
| `help` | Mostra a ajuda |

O script pode ser chamado de qualquer pasta (`/caminho/do/repo/scripts/db.sh up`); ele sempre trabalha a partir da raiz do repositório. Os comandos usam o cliente `mysql` de **dentro** do container, então não é preciso ter o MySQL instalado no computador.

### Exemplos de saída

`./scripts/db.sh ddl`
```
==> Aplicando sql/ddl.sql (recria o banco sistema_captacao_projetos do zero)...
OK: DDL aplicado: 20 tabelas (esperado 20), 7 triggers (esperado 7).
```

`./scripts/db.sh test` — primeiro aparecem 23 linhas `ERROR ...`. **Elas são esperadas**: a parte 2 do `teste_ddl.sql` tenta, de propósito, inserir dados que violam as restrições (FK, NOT NULL, UNIQUE, CHECK e triggers). Cada comando inválido tem, no arquivo, um comentário `-- ESPERADO: ERRO <código>`. No final aparece a conferência, em que `Esperado` deve ser igual a `Encontrado` em todas as linhas:
```
+----------------------+----------+------------+
| Tabela               | Esperado | Encontrado |
+----------------------+----------+------------+
| DEPARTAMENTO         |        2 |          2 |
| DOCENTE              |        3 |          3 |
...
```

`./scripts/db.sh sql consultas.sql`
```
==> Executando consultas.sql...
+------------+
| Nome       |
+------------+
| Ana Souza  |
...
```

## 6. Fluxo de trabalho

- **Alterei o `sql/ddl.sql`:** rode `./scripts/db.sh reset`. O banco é recriado do zero e os testes rodam de novo.
- **Quero testar consultas:** escreva-as em um arquivo `.sql` e rode `./scripts/db.sh sql arquivo.sql`, ou use `./scripts/db.sh shell` / DBeaver.
- **Lembre-se:** não há persistência. `down`, `restart` ou desligar o computador apagam tudo. Para voltar ao estado de trabalho: `up` → `reset`.

## 7. Conectar pelo DBeaver

1. Suba o ambiente e crie o banco: `./scripts/db.sh up` e `./scripts/db.sh ddl` (ou `reset`, para já ter dados).
2. No DBeaver: **Database → New Database Connection → MySQL → Next**.
3. Aba **Main**:
   | Campo | Valor |
   |---|---|
   | Server Host | `localhost` |
   | Port | `3306` |
   | Database | `sistema_captacao_projetos` |
   | Username | `root` |
   | Password | `root` (marque *Save password*, se quiser) |
4. Aba **Driver properties** (aceite baixar o driver, se o DBeaver pedir). Altere:
   | Propriedade | Valor |
   |---|---|
   | `allowPublicKeyRetrieval` | `true` |
   | `useSSL` | `false` |

   **Por quê:** o MySQL 8 usa a autenticação `caching_sha2_password`. Sem SSL, o driver precisa buscar a chave pública do servidor para enviar a senha, e isso vem bloqueado por padrão. Sem esse ajuste aparece o erro *"Public Key Retrieval is not allowed"*. É seguro aqui porque a conexão é local e o ambiente é só de desenvolvimento.
5. Clique em **Test Connection** → deve aparecer *Connected*. Depois, **Finish**.
6. Depois de um `reset`/`ddl`, clique com o botão direito na conexão → **Refresh** (F5) para ver as tabelas recriadas. Depois de um `down`/`restart`, o banco não existe mais até você rodar `ddl` de novo.

## 8. Usando sem o script

O script só encapsula comandos do Docker Compose. Os equivalentes manuais, na raiz do repositório:

| Script | Comando direto |
|---|---|
| `up` | `docker compose up -d --wait` |
| `down` | `docker compose down` |
| `ddl` | `docker compose exec -T mysql mysql -uroot -proot < sql/ddl.sql` |
| `test` | `docker compose exec -T mysql mysql -uroot -proot --force --table sistema_captacao_projetos < sql/teste_ddl.sql` |
| `shell` | `docker compose exec mysql mysql -uroot -proot sistema_captacao_projetos` |
| `logs` | `docker compose logs -f mysql` |
| `status` | `docker compose ps` |

(Com `-proot` o cliente mostra o aviso *"Using a password on the command line interface can be insecure"*; o script evita isso passando a senha pela variável `MYSQL_PWD`.)

## 9. Solução de problemas

| Problema | Solução |
|---|---|
| `Bind for 0.0.0.0:3306 failed: port is already allocated` | Outro serviço usa a porta 3306. Pare o MySQL local (`sudo systemctl stop mysql`) ou troque, no `docker-compose.yml`, `"3306:3306"` por `"3307:3306"` e use a porta `3307` no DBeaver |
| `permission denied while trying to connect to the Docker daemon socket` | Seu usuário não está no grupo `docker` (seção 2) |
| `ERRO: o daemon do Docker não respondeu` | Inicie o Docker: `sudo systemctl start docker` |
| `ERRO: o container não está rodando (ou ainda não está pronto)` | Rode `./scripts/db.sh up`. Se já rodou, veja `./scripts/db.sh logs` |
| `up` demora ou falha no *healthcheck* | Veja `./scripts/db.sh logs`. Na primeira vez o download da imagem pode levar alguns minutos |
| `ERRO: o banco sistema_captacao_projetos não existe` | Rode `./scripts/db.sh ddl` (o container sobe vazio) |
| DBeaver: *"Public Key Retrieval is not allowed"* | Ajuste as propriedades do driver (seção 7, passo 4) |
| DBeaver: *"Unknown database 'sistema_captacao_projetos'"* | O container foi reiniciado e o banco sumiu. Rode `./scripts/db.sh ddl` |
| `bash: ./scripts/db.sh: Permission denied` | `chmod +x scripts/db.sh` (ou rode `bash scripts/db.sh ...`) |

**Sobre a versão:** o MySQL 8.2 é uma versão *Innovation* que já não recebe atualizações. Ela é usada por exigência do projeto; para um ambiente de produção seria preferível uma versão LTS (8.0 ou 8.4).
