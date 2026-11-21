# Sistema_de_Captar_Projetos_Universitarios_Data_Base

## Ambiente de desenvolvimento

O banco roda em um container Docker com MySQL 8.2. Na raiz do repositório:

```bash
./scripts/db.sh up      # sobe o MySQL
./scripts/db.sh ddl     # cria o banco e as tabelas (sql/ddl.sql)
./scripts/db.sh test    # popula e testa as restrições (sql/teste_ddl.sql)
```

Tutorial completo (comandos, conexão pelo DBeaver e solução de problemas): [docs/TUTORIAL_DOCKER.md](docs/TUTORIAL_DOCKER.md).
