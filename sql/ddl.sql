-- =====================================================================
-- Sistema de Captação e Prospecção de Projetos Universitários
-- DDL (MySQL >= 8.0.16)
--
-- Origem: docs/Modelo Lógico - Modelo Relacional.docx (tabelas 1 a 20)
--         + restrições R-2 de docs/Verificacao_Modelo_Logico.md
--
-- Execução:
--   mysql -u <usuario> -p < sql/ddl.sql
--
-- Atenção: o script apaga e recria o banco sistema_captacao_projetos.
--
-- Convenções de nomes das restrições:
--   pk_<TABELA>               chave primária
--   fk_<TABELA>_<TABELA_REF>  chave estrangeira
--   uq_<TABELA>_<coluna>      unicidade
--   ck_<TABELA>_<coluna>      verificação (CHECK)
--   trg_<TABELA>_<bi|bu>      trigger before insert / before update
-- Todas as FKs usam ON DELETE RESTRICT ON UPDATE RESTRICT.
-- =====================================================================

DROP DATABASE IF EXISTS sistema_captacao_projetos;

CREATE DATABASE sistema_captacao_projetos
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE sistema_captacao_projetos;


-- =====================================================================
-- ENTIDADES PRINCIPAIS
-- =====================================================================

-- 1. DEPARTAMENTO
CREATE TABLE DEPARTAMENTO (
    Cod_departamento VARCHAR(20)  NOT NULL,
    Nome             VARCHAR(150) NOT NULL,
    CONSTRAINT pk_DEPARTAMENTO PRIMARY KEY (Cod_departamento)
) ENGINE = InnoDB;

-- 4. AREA_CONHECIMENTO
CREATE TABLE AREA_CONHECIMENTO (
    Cod_area  VARCHAR(20)  NOT NULL,
    Nome      VARCHAR(150) NOT NULL,
    Descricao TEXT         NOT NULL,
    CONSTRAINT pk_AREA_CONHECIMENTO PRIMARY KEY (Cod_area)
) ENGINE = InnoDB;

-- 6. SETOR_INDUSTRIAL
CREATE TABLE SETOR_INDUSTRIAL (
    Cod_setor VARCHAR(20)  NOT NULL,
    Nome      VARCHAR(150) NOT NULL,
    Descricao TEXT         NOT NULL,
    CONSTRAINT pk_SETOR_INDUSTRIAL PRIMARY KEY (Cod_setor)
) ENGINE = InnoDB;

-- 2. DOCENTE
--    Cod_departamento: relacionamento VINCULA (todo docente pertence a
--    exatamente 1 departamento, por isso NOT NULL).
CREATE TABLE DOCENTE (
    Matricula          VARCHAR(20)  NOT NULL,
    Cod_departamento   VARCHAR(20)  NOT NULL,
    Nome               VARCHAR(150) NOT NULL,
    Email              VARCHAR(254) NOT NULL,
    Curriculo_resumido TEXT         NOT NULL,
    CONSTRAINT pk_DOCENTE PRIMARY KEY (Matricula),
    CONSTRAINT uq_DOCENTE_Email UNIQUE (Email),
    CONSTRAINT fk_DOCENTE_DEPARTAMENTO
        FOREIGN KEY (Cod_departamento)
        REFERENCES DEPARTAMENTO (Cod_departamento)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 3. PROJETO_ACADEMICO
--    Matricula_coordenador: relacionamento COORDENA (0 ou 1 coordenador,
--    por isso aceita NULL).
CREATE TABLE PROJETO_ACADEMICO (
    Cod_projeto           VARCHAR(20)  NOT NULL,
    Matricula_coordenador VARCHAR(20)  NULL,
    Titulo                VARCHAR(150) NOT NULL,
    Descricao             TEXT         NOT NULL,
    Objetivos             TEXT         NOT NULL,
    Data_inicio           DATE         NOT NULL,
    Data_fim              DATE         NULL,
    Resultados            TEXT         NULL,
    Situacao              VARCHAR(20)  NOT NULL,
    CONSTRAINT pk_PROJETO_ACADEMICO PRIMARY KEY (Cod_projeto),
    CONSTRAINT fk_PROJETO_ACADEMICO_DOCENTE
        FOREIGN KEY (Matricula_coordenador)
        REFERENCES DOCENTE (Matricula)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_PROJETO_ACADEMICO_Situacao
        CHECK (Situacao IN ('PLANEJADO', 'EM_ANDAMENTO', 'CONCLUIDO', 'CANCELADO')),
    CONSTRAINT ck_PROJETO_ACADEMICO_Data_fim
        CHECK (Data_fim IS NULL OR Data_fim >= Data_inicio)
) ENGINE = InnoDB;

-- 5. EXPERTISE
--    Cod_area: relacionamento PERTENCE (toda expertise pertence a
--    exatamente 1 área de conhecimento, por isso NOT NULL).
CREATE TABLE EXPERTISE (
    Cod_expertise VARCHAR(20)  NOT NULL,
    Cod_area      VARCHAR(20)  NOT NULL,
    Nome          VARCHAR(150) NOT NULL,
    Descricao     TEXT         NOT NULL,
    CONSTRAINT pk_EXPERTISE PRIMARY KEY (Cod_expertise),
    CONSTRAINT fk_EXPERTISE_AREA_CONHECIMENTO
        FOREIGN KEY (Cod_area)
        REFERENCES AREA_CONHECIMENTO (Cod_area)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 7. EMPRESA
--    Endereço (atributo composto no DER) achatado em Rua, Bairro, Cidade, Estado.
CREATE TABLE EMPRESA (
    CNPJ         CHAR(14)     NOT NULL,
    Razao_social VARCHAR(150) NOT NULL,
    Area_atuacao VARCHAR(100) NOT NULL,
    Email        VARCHAR(254) NOT NULL,
    Nome_contato VARCHAR(150) NOT NULL,
    Rua          VARCHAR(100) NOT NULL,
    Bairro       VARCHAR(100) NOT NULL,
    Cidade       VARCHAR(100) NOT NULL,
    Estado       CHAR(2)      NOT NULL,
    CONSTRAINT pk_EMPRESA PRIMARY KEY (CNPJ),
    CONSTRAINT uq_EMPRESA_Email UNIQUE (Email)
) ENGINE = InnoDB;

-- 8. DESAFIO_OPORTUNIDADE (superclasse da especialização)
--    Cod_setor: relacionamento APRESENTA (todo desafio/oportunidade
--    pertence a exatamente 1 setor, por isso NOT NULL).
CREATE TABLE DESAFIO_OPORTUNIDADE (
    Cod_desafio_oportunidade VARCHAR(20) NOT NULL,
    Cod_setor                VARCHAR(20) NOT NULL,
    Descricao                TEXT        NOT NULL,
    Data_identificacao       DATE        NOT NULL,
    Prioridade               VARCHAR(10) NOT NULL,
    Situacao                 VARCHAR(20) NOT NULL,
    CONSTRAINT pk_DESAFIO_OPORTUNIDADE PRIMARY KEY (Cod_desafio_oportunidade),
    CONSTRAINT fk_DESAFIO_OPORTUNIDADE_SETOR_INDUSTRIAL
        FOREIGN KEY (Cod_setor)
        REFERENCES SETOR_INDUSTRIAL (Cod_setor)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_DESAFIO_OPORTUNIDADE_Prioridade
        CHECK (Prioridade IN ('BAIXA', 'MEDIA', 'ALTA')),
    CONSTRAINT ck_DESAFIO_OPORTUNIDADE_Situacao
        CHECK (Situacao IN ('ABERTO', 'EM_ANALISE', 'ATENDIDO', 'ARQUIVADO'))
) ENGINE = InnoDB;


-- =====================================================================
-- ESPECIALIZAÇÃO (total e disjunta)
--   Disjunção: imposta pelos triggers trg_DESAFIO_* e trg_OPORTUNIDADE_*.
--   Totalidade: responsabilidade da aplicação (ver bloco final).
-- =====================================================================

-- 19. DESAFIO
CREATE TABLE DESAFIO (
    Cod_desafio_oportunidade VARCHAR(20) NOT NULL,
    CONSTRAINT pk_DESAFIO PRIMARY KEY (Cod_desafio_oportunidade),
    CONSTRAINT fk_DESAFIO_DESAFIO_OPORTUNIDADE
        FOREIGN KEY (Cod_desafio_oportunidade)
        REFERENCES DESAFIO_OPORTUNIDADE (Cod_desafio_oportunidade)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 20. OPORTUNIDADE
CREATE TABLE OPORTUNIDADE (
    Cod_desafio_oportunidade VARCHAR(20) NOT NULL,
    CONSTRAINT pk_OPORTUNIDADE PRIMARY KEY (Cod_desafio_oportunidade),
    CONSTRAINT fk_OPORTUNIDADE_DESAFIO_OPORTUNIDADE
        FOREIGN KEY (Cod_desafio_oportunidade)
        REFERENCES DESAFIO_OPORTUNIDADE (Cod_desafio_oportunidade)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;


-- =====================================================================
-- RELACIONAMENTOS N:N — TABELAS DE JUNÇÃO
-- =====================================================================

-- 9. DOCENTE_PROJETO_ACADEMICO — relacionamento ORIENTA
CREATE TABLE DOCENTE_PROJETO_ACADEMICO (
    Matricula   VARCHAR(20) NOT NULL,
    Cod_projeto VARCHAR(20) NOT NULL,
    CONSTRAINT pk_DOCENTE_PROJETO_ACADEMICO PRIMARY KEY (Matricula, Cod_projeto),
    CONSTRAINT fk_DOCENTE_PROJETO_ACADEMICO_DOCENTE
        FOREIGN KEY (Matricula)
        REFERENCES DOCENTE (Matricula)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_DOCENTE_PROJETO_ACADEMICO_PROJETO_ACADEMICO
        FOREIGN KEY (Cod_projeto)
        REFERENCES PROJETO_ACADEMICO (Cod_projeto)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 10. EMPRESA_PROJETO_ACADEMICO — relacionamento IMPLEMENTA
--     Data_inicio na PK para guardar o histórico de implementações.
CREATE TABLE EMPRESA_PROJETO_ACADEMICO (
    CNPJ        CHAR(14)    NOT NULL,
    Cod_projeto VARCHAR(20) NOT NULL,
    Data_inicio DATE        NOT NULL,
    Situacao    VARCHAR(20) NOT NULL,
    CONSTRAINT pk_EMPRESA_PROJETO_ACADEMICO PRIMARY KEY (CNPJ, Cod_projeto, Data_inicio),
    CONSTRAINT fk_EMPRESA_PROJETO_ACADEMICO_EMPRESA
        FOREIGN KEY (CNPJ)
        REFERENCES EMPRESA (CNPJ)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_EMPRESA_PROJETO_ACADEMICO_PROJETO_ACADEMICO
        FOREIGN KEY (Cod_projeto)
        REFERENCES PROJETO_ACADEMICO (Cod_projeto)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_EMPRESA_PROJETO_ACADEMICO_Situacao
        CHECK (Situacao IN ('PLANEJADO', 'EM_ANDAMENTO', 'CONCLUIDO', 'CANCELADO'))
) ENGINE = InnoDB;

-- 11. EMPRESA_OPORTUNIDADE — relacionamento INTERESSE
--     Data_interesse na PK para guardar o histórico de interesse.
CREATE TABLE EMPRESA_OPORTUNIDADE (
    CNPJ             CHAR(14)    NOT NULL,
    Cod_oportunidade VARCHAR(20) NOT NULL,
    Data_interesse   DATE        NOT NULL,
    Nivel_interesse  VARCHAR(10) NOT NULL,
    CONSTRAINT pk_EMPRESA_OPORTUNIDADE PRIMARY KEY (CNPJ, Cod_oportunidade, Data_interesse),
    CONSTRAINT fk_EMPRESA_OPORTUNIDADE_EMPRESA
        FOREIGN KEY (CNPJ)
        REFERENCES EMPRESA (CNPJ)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_EMPRESA_OPORTUNIDADE_OPORTUNIDADE
        FOREIGN KEY (Cod_oportunidade)
        REFERENCES OPORTUNIDADE (Cod_desafio_oportunidade)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_EMPRESA_OPORTUNIDADE_Nivel_interesse
        CHECK (Nivel_interesse IN ('BAIXO', 'MEDIO', 'ALTO'))
) ENGINE = InnoDB;

-- 12. EMPRESA_SETOR_INDUSTRIAL — relacionamento ATUA
CREATE TABLE EMPRESA_SETOR_INDUSTRIAL (
    CNPJ      CHAR(14)    NOT NULL,
    Cod_setor VARCHAR(20) NOT NULL,
    CONSTRAINT pk_EMPRESA_SETOR_INDUSTRIAL PRIMARY KEY (CNPJ, Cod_setor),
    CONSTRAINT fk_EMPRESA_SETOR_INDUSTRIAL_EMPRESA
        FOREIGN KEY (CNPJ)
        REFERENCES EMPRESA (CNPJ)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_EMPRESA_SETOR_INDUSTRIAL_SETOR_INDUSTRIAL
        FOREIGN KEY (Cod_setor)
        REFERENCES SETOR_INDUSTRIAL (Cod_setor)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 13. DOCENTE_EXPERTISE — relacionamento DOMINA
CREATE TABLE DOCENTE_EXPERTISE (
    Matricula     VARCHAR(20) NOT NULL,
    Cod_expertise VARCHAR(20) NOT NULL,
    CONSTRAINT pk_DOCENTE_EXPERTISE PRIMARY KEY (Matricula, Cod_expertise),
    CONSTRAINT fk_DOCENTE_EXPERTISE_DOCENTE
        FOREIGN KEY (Matricula)
        REFERENCES DOCENTE (Matricula)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_DOCENTE_EXPERTISE_EXPERTISE
        FOREIGN KEY (Cod_expertise)
        REFERENCES EXPERTISE (Cod_expertise)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 14. DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO — relacionamento EXIGE
CREATE TABLE DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO (
    Cod_desafio_oportunidade VARCHAR(20) NOT NULL,
    Cod_area                 VARCHAR(20) NOT NULL,
    CONSTRAINT pk_DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO
        PRIMARY KEY (Cod_desafio_oportunidade, Cod_area),
    CONSTRAINT fk_DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO_DESAFIO_OPORTUNIDADE
        FOREIGN KEY (Cod_desafio_oportunidade)
        REFERENCES DESAFIO_OPORTUNIDADE (Cod_desafio_oportunidade)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO_AREA_CONHECIMENTO
        FOREIGN KEY (Cod_area)
        REFERENCES AREA_CONHECIMENTO (Cod_area)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 15. DOCENTE_OPORTUNIDADE — relacionamento COMPATIBILIDADE
CREATE TABLE DOCENTE_OPORTUNIDADE (
    Matricula        VARCHAR(20) NOT NULL,
    Cod_oportunidade VARCHAR(20) NOT NULL,
    Grau_aderencia   VARCHAR(10) NOT NULL,
    Justificativa    TEXT        NOT NULL,
    CONSTRAINT pk_DOCENTE_OPORTUNIDADE PRIMARY KEY (Matricula, Cod_oportunidade),
    CONSTRAINT fk_DOCENTE_OPORTUNIDADE_DOCENTE
        FOREIGN KEY (Matricula)
        REFERENCES DOCENTE (Matricula)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT fk_DOCENTE_OPORTUNIDADE_OPORTUNIDADE
        FOREIGN KEY (Cod_oportunidade)
        REFERENCES OPORTUNIDADE (Cod_desafio_oportunidade)
        ON DELETE RESTRICT ON UPDATE RESTRICT,
    CONSTRAINT ck_DOCENTE_OPORTUNIDADE_Grau_aderencia
        CHECK (Grau_aderencia IN ('BAIXO', 'MEDIO', 'ALTO'))
) ENGINE = InnoDB;


-- =====================================================================
-- ATRIBUTOS MULTIVALORADOS
-- =====================================================================

-- 16. EMPRESA_TELEFONE
CREATE TABLE EMPRESA_TELEFONE (
    CNPJ     CHAR(14)    NOT NULL,
    Telefone VARCHAR(20) NOT NULL,
    CONSTRAINT pk_EMPRESA_TELEFONE PRIMARY KEY (CNPJ, Telefone),
    CONSTRAINT fk_EMPRESA_TELEFONE_EMPRESA
        FOREIGN KEY (CNPJ)
        REFERENCES EMPRESA (CNPJ)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 17. EXPERTISE_PALAVRA_CHAVE
CREATE TABLE EXPERTISE_PALAVRA_CHAVE (
    Cod_expertise VARCHAR(20)  NOT NULL,
    Palavra_chave VARCHAR(100) NOT NULL,
    CONSTRAINT pk_EXPERTISE_PALAVRA_CHAVE PRIMARY KEY (Cod_expertise, Palavra_chave),
    CONSTRAINT fk_EXPERTISE_PALAVRA_CHAVE_EXPERTISE
        FOREIGN KEY (Cod_expertise)
        REFERENCES EXPERTISE (Cod_expertise)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;

-- 18. SETOR_INDUSTRIAL_AREA_ATUACAO
CREATE TABLE SETOR_INDUSTRIAL_AREA_ATUACAO (
    Cod_setor    VARCHAR(20)  NOT NULL,
    Area_atuacao VARCHAR(100) NOT NULL,
    CONSTRAINT pk_SETOR_INDUSTRIAL_AREA_ATUACAO PRIMARY KEY (Cod_setor, Area_atuacao),
    CONSTRAINT fk_SETOR_INDUSTRIAL_AREA_ATUACAO_SETOR_INDUSTRIAL
        FOREIGN KEY (Cod_setor)
        REFERENCES SETOR_INDUSTRIAL (Cod_setor)
        ON DELETE RESTRICT ON UPDATE RESTRICT
) ENGINE = InnoDB;


-- =====================================================================
-- TRIGGERS
-- =====================================================================

DELIMITER $$

-- Especialização disjunta: um código não pode estar em DESAFIO e em
-- OPORTUNIDADE ao mesmo tempo.

CREATE TRIGGER trg_DESAFIO_bi
BEFORE INSERT ON DESAFIO
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM OPORTUNIDADE
               WHERE Cod_desafio_oportunidade = NEW.Cod_desafio_oportunidade) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Disjunção violada: código já cadastrado em OPORTUNIDADE';
    END IF;
END$$

CREATE TRIGGER trg_DESAFIO_bu
BEFORE UPDATE ON DESAFIO
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM OPORTUNIDADE
               WHERE Cod_desafio_oportunidade = NEW.Cod_desafio_oportunidade) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Disjunção violada: código já cadastrado em OPORTUNIDADE';
    END IF;
END$$

CREATE TRIGGER trg_OPORTUNIDADE_bi
BEFORE INSERT ON OPORTUNIDADE
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM DESAFIO
               WHERE Cod_desafio_oportunidade = NEW.Cod_desafio_oportunidade) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Disjunção violada: código já cadastrado em DESAFIO';
    END IF;
END$$

CREATE TRIGGER trg_OPORTUNIDADE_bu
BEFORE UPDATE ON OPORTUNIDADE
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM DESAFIO
               WHERE Cod_desafio_oportunidade = NEW.Cod_desafio_oportunidade) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Disjunção violada: código já cadastrado em DESAFIO';
    END IF;
END$$

-- Coordenação e orientação: o coordenador de um projeto não pode constar
-- como orientador do mesmo projeto.

CREATE TRIGGER trg_DOCENTE_PROJETO_ACADEMICO_bi
BEFORE INSERT ON DOCENTE_PROJETO_ACADEMICO
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM PROJETO_ACADEMICO
               WHERE Cod_projeto = NEW.Cod_projeto
                 AND Matricula_coordenador = NEW.Matricula) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O coordenador do projeto não pode ser orientador do mesmo projeto';
    END IF;
END$$

CREATE TRIGGER trg_DOCENTE_PROJETO_ACADEMICO_bu
BEFORE UPDATE ON DOCENTE_PROJETO_ACADEMICO
FOR EACH ROW
BEGIN
    IF EXISTS (SELECT 1 FROM PROJETO_ACADEMICO
               WHERE Cod_projeto = NEW.Cod_projeto
                 AND Matricula_coordenador = NEW.Matricula) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O coordenador do projeto não pode ser orientador do mesmo projeto';
    END IF;
END$$

-- No INSERT de PROJETO_ACADEMICO ainda não há orientadores, então só o
-- UPDATE precisa ser verificado.
CREATE TRIGGER trg_PROJETO_ACADEMICO_bu
BEFORE UPDATE ON PROJETO_ACADEMICO
FOR EACH ROW
BEGIN
    IF NEW.Matricula_coordenador IS NOT NULL
       AND EXISTS (SELECT 1 FROM DOCENTE_PROJETO_ACADEMICO
                   WHERE Cod_projeto = NEW.Cod_projeto
                     AND Matricula = NEW.Matricula_coordenador) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'O coordenador do projeto não pode ser orientador do mesmo projeto';
    END IF;
END$$

DELIMITER ;


-- =====================================================================
-- RESTRIÇÕES NÃO IMPOSTAS PELO BANCO (responsabilidade da aplicação)
--
-- O MySQL não tem restrições diferidas (verificadas só no COMMIT). Por
-- isso as participações mínimas abaixo não podem ser impostas por
-- PK/FK/CHECK nem por trigger sem impedir a primeira inserção. A
-- aplicação deve inserir os registros dependentes na mesma transação.
--
--   * Especialização total: todo DESAFIO_OPORTUNIDADE aparece em
--     DESAFIO ou em OPORTUNIDADE (a disjunção é imposta pelos triggers).
--   * Todo DEPARTAMENTO tem ao menos 1 DOCENTE (VINCULA).
--   * Toda EMPRESA atua em ao menos 1 SETOR_INDUSTRIAL (ATUA).
--   * Todo DESAFIO_OPORTUNIDADE exige ao menos 1 AREA_CONHECIMENTO (EXIGE).
--   * Toda EMPRESA tem ao menos 1 telefone em EMPRESA_TELEFONE.
--   * Toda EXPERTISE tem ao menos 1 palavra-chave em EXPERTISE_PALAVRA_CHAVE.
--   * Todo SETOR_INDUSTRIAL tem ao menos 1 área de atuação em
--     SETOR_INDUSTRIAL_AREA_ATUACAO.
-- =====================================================================
