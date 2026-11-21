-- =====================================================================
-- Teste do DDL — Sistema de Captação e Prospecção de Projetos Universitários
--
-- Executar DEPOIS de sql/ddl.sql:
--   mysql --force -u <usuario> -p < sql/teste_ddl.sql
--
-- O --force faz o cliente continuar após os erros ESPERADOS da parte 2.
-- Parte 1: inserções válidas (devem passar sem erro).
-- Parte 2: inserções inválidas (cada uma deve falhar com o erro indicado).
-- Parte 3: contagem de linhas por tabela (comparar com a coluna Esperado).
--
-- Dados fictícios baseados no exemplo prático do minimundo (seção 4).
-- =====================================================================

USE sistema_captacao_projetos;


-- =====================================================================
-- PARTE 1 — CASOS VÁLIDOS
-- =====================================================================

INSERT INTO DEPARTAMENTO (Cod_departamento, Nome) VALUES
    ('DCC', 'Departamento de Ciência da Computação'),
    ('DEP', 'Departamento de Engenharia de Produção');

INSERT INTO AREA_CONHECIMENTO (Cod_area, Nome, Descricao) VALUES
    ('A01', 'Inteligência Artificial', 'Métodos de aprendizado de máquina e raciocínio automático'),
    ('A02', 'Visão Computacional', 'Análise e interpretação de imagens e vídeos'),
    ('A03', 'Engenharia de Processos', 'Modelagem e otimização de processos produtivos');

INSERT INTO SETOR_INDUSTRIAL (Cod_setor, Nome, Descricao) VALUES
    ('S01', 'Alimentos', 'Indústria de processamento e embalagem de alimentos'),
    ('S02', 'Energia', 'Geração e distribuição de energia');

INSERT INTO SETOR_INDUSTRIAL_AREA_ATUACAO (Cod_setor, Area_atuacao) VALUES
    ('S01', 'Processamento de alimentos'),
    ('S01', 'Embalagens'),
    ('S02', 'Geração de energia');

INSERT INTO DOCENTE (Matricula, Cod_departamento, Nome, Email, Curriculo_resumido) VALUES
    ('D001', 'DCC', 'Ana Souza',  'ana.souza@univ.br',  'Doutora em IA, atua com visão computacional aplicada à indústria'),
    ('D002', 'DCC', 'Bruno Lima', 'bruno.lima@univ.br', 'Mestre em computação, pesquisa inspeção visual automatizada'),
    ('D003', 'DEP', 'Carla Melo', 'carla.melo@univ.br', 'Doutora em engenharia de produção, foco em processos enxutos');

INSERT INTO EXPERTISE (Cod_expertise, Cod_area, Nome, Descricao) VALUES
    ('E01', 'A01', 'Aprendizado de máquina', 'Modelos supervisionados e não supervisionados'),
    ('E02', 'A02', 'Detecção de defeitos em imagens', 'Inspeção visual automatizada em linhas de produção'),
    ('E03', 'A03', 'Otimização de processos', 'Redução de perdas e gargalos produtivos');

INSERT INTO EXPERTISE_PALAVRA_CHAVE (Cod_expertise, Palavra_chave) VALUES
    ('E01', 'redes neurais'),
    ('E01', 'classificação'),
    ('E02', 'inspeção visual'),
    ('E03', 'lean');

INSERT INTO DOCENTE_EXPERTISE (Matricula, Cod_expertise) VALUES
    ('D001', 'E01'),
    ('D001', 'E02'),
    ('D002', 'E02'),
    ('D003', 'E03');

-- P001: projeto concluído, com Data_fim e Resultados.
-- P002: projeto em andamento, Data_fim e Resultados NULL.
-- P003: projeto sem coordenador (Matricula_coordenador NULL).
INSERT INTO PROJETO_ACADEMICO
    (Cod_projeto, Matricula_coordenador, Titulo, Descricao, Objetivos,
     Data_inicio, Data_fim, Resultados, Situacao) VALUES
    ('P001', 'D001', 'Detecção de defeitos em embalagens',
     'Sistema de visão computacional para inspeção de embalagens',
     'Reduzir embalagens defeituosas na expedição',
     '2024-03-01', '2025-02-28', 'Protótipo com 95% de acurácia', 'CONCLUIDO'),
    ('P002', 'D003', 'Otimização de linha de envase',
     'Estudo de gargalos em linha de envase',
     'Aumentar a produtividade da linha',
     '2025-04-01', NULL, NULL, 'EM_ANDAMENTO'),
    ('P003', NULL, 'Previsão de demanda energética',
     'Modelos de previsão de consumo de energia',
     'Apoiar o planejamento de geração',
     '2026-01-15', NULL, NULL, 'PLANEJADO');

-- Orientadores (nenhum é coordenador do mesmo projeto).
INSERT INTO DOCENTE_PROJETO_ACADEMICO (Matricula, Cod_projeto) VALUES
    ('D002', 'P001'),
    ('D001', 'P002');

INSERT INTO EMPRESA
    (CNPJ, Razao_social, Area_atuacao, Email, Nome_contato,
     Rua, Bairro, Cidade, Estado) VALUES
    ('12345678000190', 'Alimentos Bom Sabor Ltda', 'Laticínios', 'contato@bomsabor.com.br',
     'Marcos Pereira', 'Rua das Indústrias, 100', 'Distrito Industrial', 'Campina Grande', 'PB'),
    ('98765432000110', 'Energia Viva S.A.', 'Energia solar', 'contato@energiaviva.com.br',
     'Juliana Rocha', 'Av. Central, 2000', 'Centro', 'Recife', 'PE');

INSERT INTO EMPRESA_TELEFONE (CNPJ, Telefone) VALUES
    ('12345678000190', '83999990000'),
    ('12345678000190', '8333330000'),
    ('98765432000110', '81988880000');

INSERT INTO EMPRESA_SETOR_INDUSTRIAL (CNPJ, Cod_setor) VALUES
    ('12345678000190', 'S01'),
    ('98765432000110', 'S02');

-- DO01 e DO03 são oportunidades; DO02 é desafio.
INSERT INTO DESAFIO_OPORTUNIDADE
    (Cod_desafio_oportunidade, Cod_setor, Descricao, Data_identificacao, Prioridade, Situacao) VALUES
    ('DO01', 'S01', 'Reduzir perdas na linha de produção', '2025-03-10', 'ALTA',  'ABERTO'),
    ('DO02', 'S01', 'Contaminação cruzada no envase',      '2025-06-02', 'MEDIA', 'EM_ANALISE'),
    ('DO03', 'S02', 'Previsão de demanda de energia',      '2025-07-20', 'BAIXA', 'ABERTO');

INSERT INTO OPORTUNIDADE (Cod_desafio_oportunidade) VALUES ('DO01'), ('DO03');
INSERT INTO DESAFIO      (Cod_desafio_oportunidade) VALUES ('DO02');

INSERT INTO DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO (Cod_desafio_oportunidade, Cod_area) VALUES
    ('DO01', 'A01'),
    ('DO01', 'A02'),
    ('DO01', 'A03'),
    ('DO02', 'A03'),
    ('DO03', 'A01');

-- Compatibilidade só com DO01 (DO03 fica sem docentes compatíveis: pergunta P6).
INSERT INTO DOCENTE_OPORTUNIDADE (Matricula, Cod_oportunidade, Grau_aderencia, Justificativa) VALUES
    ('D001', 'DO01', 'ALTO',  'Experiência em detecção de defeitos (projeto P001)'),
    ('D003', 'DO01', 'MEDIO', 'Experiência em otimização de processos produtivos');

-- Histórico de interesse: duas datas para o mesmo par empresa/oportunidade.
INSERT INTO EMPRESA_OPORTUNIDADE (CNPJ, Cod_oportunidade, Data_interesse, Nivel_interesse) VALUES
    ('12345678000190', 'DO01', '2025-05-10', 'MEDIO'),
    ('12345678000190', 'DO01', '2025-08-20', 'ALTO');

INSERT INTO EMPRESA_PROJETO_ACADEMICO (CNPJ, Cod_projeto, Data_inicio, Situacao) VALUES
    ('12345678000190', 'P001', '2025-09-01', 'EM_ANDAMENTO');


-- =====================================================================
-- PARTE 2 — CASOS INVÁLIDOS (cada comando deve FALHAR)
-- =====================================================================

-- ---------- Chave estrangeira inexistente ----------

-- ESPERADO: ERRO 1452 (FK: departamento 'XXX' não existe)
INSERT INTO DOCENTE (Matricula, Cod_departamento, Nome, Email, Curriculo_resumido)
VALUES ('D900', 'XXX', 'Teste FK', 'fk@univ.br', 'Currículo');

-- ESPERADO: ERRO 1452 (FK: setor 'S99' não existe)
INSERT INTO DESAFIO_OPORTUNIDADE
    (Cod_desafio_oportunidade, Cod_setor, Descricao, Data_identificacao, Prioridade, Situacao)
VALUES ('DO90', 'S99', 'Setor inexistente', '2025-01-01', 'ALTA', 'ABERTO');

-- ESPERADO: ERRO 1452 (COMPATIBILIDADE com DO02, que é DESAFIO e não OPORTUNIDADE)
INSERT INTO DOCENTE_OPORTUNIDADE (Matricula, Cod_oportunidade, Grau_aderencia, Justificativa)
VALUES ('D002', 'DO02', 'ALTO', 'Aponta para um desafio');

-- ESPERADO: ERRO 1452 (INTERESSE em DO02, que é DESAFIO e não OPORTUNIDADE)
INSERT INTO EMPRESA_OPORTUNIDADE (CNPJ, Cod_oportunidade, Data_interesse, Nivel_interesse)
VALUES ('12345678000190', 'DO02', '2025-09-01', 'ALTO');

-- ---------- NOT NULL ----------

-- ESPERADO: ERRO 1048 (Nome do departamento não pode ser NULL)
INSERT INTO DEPARTAMENTO (Cod_departamento, Nome) VALUES ('DXX', NULL);

-- ESPERADO: ERRO 1048 (Cod_departamento do docente não pode ser NULL — VINCULA)
INSERT INTO DOCENTE (Matricula, Cod_departamento, Nome, Email, Curriculo_resumido)
VALUES ('D901', NULL, 'Sem departamento', 'semdep@univ.br', 'Currículo');

-- ---------- UNIQUE ----------

-- ESPERADO: ERRO 1062 (Email de docente repetido)
INSERT INTO DOCENTE (Matricula, Cod_departamento, Nome, Email, Curriculo_resumido)
VALUES ('D902', 'DCC', 'Email repetido', 'ana.souza@univ.br', 'Currículo');

-- ESPERADO: ERRO 1062 (Email de empresa repetido)
INSERT INTO EMPRESA
    (CNPJ, Razao_social, Area_atuacao, Email, Nome_contato, Rua, Bairro, Cidade, Estado)
VALUES ('11111111000111', 'Empresa Repetida', 'Laticínios', 'contato@bomsabor.com.br',
        'Fulano', 'Rua A', 'Bairro B', 'Cidade C', 'PB');

-- ---------- CHECK ----------

-- ESPERADO: ERRO 3819 (Data_fim anterior a Data_inicio)
INSERT INTO PROJETO_ACADEMICO
    (Cod_projeto, Matricula_coordenador, Titulo, Descricao, Objetivos,
     Data_inicio, Data_fim, Resultados, Situacao)
VALUES ('P900', 'D001', 'Datas invertidas', 'Desc', 'Obj',
        '2025-05-01', '2025-01-01', NULL, 'PLANEJADO');

-- ESPERADO: ERRO 3819 (Situacao de projeto fora do domínio)
INSERT INTO PROJETO_ACADEMICO
    (Cod_projeto, Matricula_coordenador, Titulo, Descricao, Objetivos,
     Data_inicio, Data_fim, Resultados, Situacao)
VALUES ('P901', 'D001', 'Situação inválida', 'Desc', 'Obj',
        '2025-05-01', NULL, NULL, 'PAUSADO');

-- ESPERADO: ERRO 3819 (Prioridade fora do domínio)
INSERT INTO DESAFIO_OPORTUNIDADE
    (Cod_desafio_oportunidade, Cod_setor, Descricao, Data_identificacao, Prioridade, Situacao)
VALUES ('DO91', 'S01', 'Prioridade inválida', '2025-01-01', 'URGENTE', 'ABERTO');

-- ESPERADO: ERRO 3819 (Situacao de desafio/oportunidade fora do domínio)
INSERT INTO DESAFIO_OPORTUNIDADE
    (Cod_desafio_oportunidade, Cod_setor, Descricao, Data_identificacao, Prioridade, Situacao)
VALUES ('DO92', 'S01', 'Situação inválida', '2025-01-01', 'ALTA', 'FECHADO');

-- ESPERADO: ERRO 3819 (Situacao da implementação fora do domínio)
INSERT INTO EMPRESA_PROJETO_ACADEMICO (CNPJ, Cod_projeto, Data_inicio, Situacao)
VALUES ('98765432000110', 'P003', '2026-02-01', 'NEGOCIANDO');

-- ESPERADO: ERRO 3819 (Grau_aderencia fora do domínio)
INSERT INTO DOCENTE_OPORTUNIDADE (Matricula, Cod_oportunidade, Grau_aderencia, Justificativa)
VALUES ('D002', 'DO01', 'TOTAL', 'Grau inválido');

-- ESPERADO: ERRO 3819 (Nivel_interesse fora do domínio)
INSERT INTO EMPRESA_OPORTUNIDADE (CNPJ, Cod_oportunidade, Data_interesse, Nivel_interesse)
VALUES ('98765432000110', 'DO03', '2025-09-01', 'NENHUM');

-- ---------- Trigger: especialização disjunta ----------

-- ESPERADO: ERRO 1644 / SQLSTATE 45000 (DO01 já é OPORTUNIDADE)
INSERT INTO DESAFIO (Cod_desafio_oportunidade) VALUES ('DO01');

-- ESPERADO: ERRO 1644 / SQLSTATE 45000 (DO02 já é DESAFIO)
INSERT INTO OPORTUNIDADE (Cod_desafio_oportunidade) VALUES ('DO02');

-- ESPERADO: ERRO 1644 / SQLSTATE 45000 (UPDATE levaria DESAFIO para código de OPORTUNIDADE)
UPDATE DESAFIO SET Cod_desafio_oportunidade = 'DO03' WHERE Cod_desafio_oportunidade = 'DO02';

-- ---------- Trigger: coordenador não pode ser orientador ----------

-- ESPERADO: ERRO 1644 / SQLSTATE 45000 (D001 coordena P001)
INSERT INTO DOCENTE_PROJETO_ACADEMICO (Matricula, Cod_projeto) VALUES ('D001', 'P001');

-- ESPERADO: ERRO 1644 / SQLSTATE 45000 (UPDATE tornaria D003, coordenador de P002, orientador de P002)
UPDATE DOCENTE_PROJETO_ACADEMICO SET Matricula = 'D003'
WHERE Matricula = 'D001' AND Cod_projeto = 'P002';

-- ESPERADO: ERRO 1644 / SQLSTATE 45000 (D002 já orienta P001 e não pode virar coordenador dele)
UPDATE PROJETO_ACADEMICO SET Matricula_coordenador = 'D002' WHERE Cod_projeto = 'P001';

-- ---------- ON DELETE RESTRICT ----------

-- ESPERADO: ERRO 1451 (departamento DCC tem docentes)
DELETE FROM DEPARTAMENTO WHERE Cod_departamento = 'DCC';

-- ESPERADO: ERRO 1451 (oportunidade DO01 tem compatibilidades e interesses)
DELETE FROM OPORTUNIDADE WHERE Cod_desafio_oportunidade = 'DO01';


-- =====================================================================
-- PARTE 3 — CONFERÊNCIA (Encontrado deve ser igual a Esperado)
-- =====================================================================

SELECT 'DEPARTAMENTO' AS Tabela, 2 AS Esperado, COUNT(*) AS Encontrado FROM DEPARTAMENTO
UNION ALL SELECT 'DOCENTE', 3, COUNT(*) FROM DOCENTE
UNION ALL SELECT 'PROJETO_ACADEMICO', 3, COUNT(*) FROM PROJETO_ACADEMICO
UNION ALL SELECT 'AREA_CONHECIMENTO', 3, COUNT(*) FROM AREA_CONHECIMENTO
UNION ALL SELECT 'EXPERTISE', 3, COUNT(*) FROM EXPERTISE
UNION ALL SELECT 'SETOR_INDUSTRIAL', 2, COUNT(*) FROM SETOR_INDUSTRIAL
UNION ALL SELECT 'EMPRESA', 2, COUNT(*) FROM EMPRESA
UNION ALL SELECT 'DESAFIO_OPORTUNIDADE', 3, COUNT(*) FROM DESAFIO_OPORTUNIDADE
UNION ALL SELECT 'DOCENTE_PROJETO_ACADEMICO', 2, COUNT(*) FROM DOCENTE_PROJETO_ACADEMICO
UNION ALL SELECT 'EMPRESA_PROJETO_ACADEMICO', 1, COUNT(*) FROM EMPRESA_PROJETO_ACADEMICO
UNION ALL SELECT 'EMPRESA_OPORTUNIDADE', 2, COUNT(*) FROM EMPRESA_OPORTUNIDADE
UNION ALL SELECT 'EMPRESA_SETOR_INDUSTRIAL', 2, COUNT(*) FROM EMPRESA_SETOR_INDUSTRIAL
UNION ALL SELECT 'DOCENTE_EXPERTISE', 4, COUNT(*) FROM DOCENTE_EXPERTISE
UNION ALL SELECT 'DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO', 5, COUNT(*) FROM DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO
UNION ALL SELECT 'DOCENTE_OPORTUNIDADE', 2, COUNT(*) FROM DOCENTE_OPORTUNIDADE
UNION ALL SELECT 'EMPRESA_TELEFONE', 3, COUNT(*) FROM EMPRESA_TELEFONE
UNION ALL SELECT 'EXPERTISE_PALAVRA_CHAVE', 4, COUNT(*) FROM EXPERTISE_PALAVRA_CHAVE
UNION ALL SELECT 'SETOR_INDUSTRIAL_AREA_ATUACAO', 3, COUNT(*) FROM SETOR_INDUSTRIAL_AREA_ATUACAO
UNION ALL SELECT 'DESAFIO', 1, COUNT(*) FROM DESAFIO
UNION ALL SELECT 'OPORTUNIDADE', 2, COUNT(*) FROM OPORTUNIDADE;

-- Coordenador do P001 continua D001 (o UPDATE inválido não foi aplicado).
SELECT Cod_projeto, Matricula_coordenador FROM PROJETO_ACADEMICO WHERE Cod_projeto = 'P001';
