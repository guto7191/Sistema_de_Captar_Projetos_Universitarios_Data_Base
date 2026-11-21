# Verificação do Modelo Lógico (Modelo Relacional)

**Objeto:** `docs/Modelo Lógico - Modelo Relacional.docx` (commit `c8244a4`)
**Comparado com:** `docs/DER_Captacao_Projetos.drawio` (commit `132c1f4`) e o minimundo (`docs/Minimundo_ ... .pdf`)
**Critérios:** mapeamento ER → relacional (Heuser / Elmasri & Navathe), 1FN–3FN.
**Convenções adotadas:**
- Cardinalidade lida no padrão Heuser/brModelo: o rótulo ao lado da entidade X diz quantas instâncias de X se ligam a uma instância da outra entidade.
- Exigência da disciplina: tabelas + PK/FK. Tipos de dados, NULL/NOT NULL, UNIQUE e CHECK aparecem só como **recomendação**.

---

## 1. Resumo

| Resultado | Qtd. |
|---|---|
| Elementos do DER presentes no lógico | 25 de 25 (10 entidades/subclasses, 12 relacionamentos, 2 multivalorados, 1 composto); a especialização está mapeada, mas de forma questionável |
| **Erros** (no modelo lógico) | 3 |
| **Divergências** (DER ou minimundo, herdadas pelo lógico) | 7 |
| **Recomendações** | 6 |
| Perguntas da seção 5 do minimundo respondíveis | 5 completas, 1 parcial, 1 sem suporte |

O mapeamento mecânico está **correto**: as 4 relações 1:N viraram FK no lado N, as 7 N:N viraram tabelas com PK composta e atributos próprios, os 2 multivalorados viraram tabelas e o atributo composto foi achatado. Os problemas estão em: (a) FK sem tabela referenciada indicada, (b) mapeamento da especialização que não impõe as regras dela, (c) lacunas herdadas do DER em relação ao minimundo (projeto ↔ oportunidade e o alvo de COMPATIBILIDADE e INTERESSE).

---

## 2. Matriz de rastreabilidade: regras de negócio

| RN | Regra (resumo) | DER | Modelo lógico | Status |
|---|---|---|---|---|
| 1 | Departamento possui diversos docentes | VINCULA: DEPARTAMENTO (1,1), DOCENTE (1,n) | `DOCENTE.Cod_departamento` FK | OK (mín. 1 docente por depto. não é imposto, ver R‑4) |
| 2 | Docente tem dados cadastrais e expertises ligadas a áreas | DOCENTE (atributos), DOMINA, PERTENCE | `DOCENTE`, `DOCENTE_EXPERTISE`, `EXPERTISE.Cod_area` | OK |
| 3 | Expertise N:N docente | DOMINA (0,n)/(0,n) | `DOCENTE_EXPERTISE` | OK |
| 4 | Portfólio = projetos coordenados ou orientados | COORDENA, ORIENTA | `PROJETO_ACADEMICO.Matricula_coordenador`, `DOCENTE_PROJETO_ACADEMICO` | OK |
| 5 | Projeto: título, descrição, período, objetivos, resultados, situação | atributos de PROJETO_ACADEMICO | `PROJETO_ACADEMICO` (período = Data_inicio, Data_fim) | OK |
| 6 | Um coordenador e um ou mais orientadores por projeto | COORDENA DOCENTE (0,1); ORIENTA (0,n) | FK anulável; tabela N:N | OK |
| 7 | Setor: identificação, descrição, **áreas** de atuação | SETOR_INDUSTRIAL (Cod_setor, Nome, Descricao, Area_atuacao) | idem | Divergência D‑7 (plural sugere multivalorado) |
| 8 | Setor apresenta diversos desafios/oportunidades | APRESENTA: SETOR (1,1), DESAFIO (0,n) | `DESAFIO_OPORTUNIDADE.Cod_setor` FK | OK |
| 9 | Desafio/oportunidade: descrição, data, prioridade, situação | atributos | idem | OK |
| 10 | Desafio N:N área de conhecimento | EXIGE: AREA (1,n), DESAFIO (0,n) | `DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO` | OK (mín. 1 área não imposto, ver R‑4) |
| 11 | Empresa vinculada a setores; cadastro, área de atuação, contato | EMPRESA, ATUA, Telefone, ENDERECO | `EMPRESA`, `EMPRESA_TELEFONE`, `EMPRESA_SETOR_INDUSTRIAL` | OK |
| 12 | Empresa N:N setor | ATUA: SETOR (1,n), EMPRESA (0,n) + 2 rótulos soltos | `EMPRESA_SETOR_INDUSTRIAL` | Divergência D‑1 |
| 13 | **Oportunidade** compatível com vários docentes | COMPATIBILIDADE liga **DESAFIO_OPORTUNIDADE** | `DOCENTE_DESAFIO_OPORTUNIDADE` | Divergência D‑4 |
| 14a | Empresa demonstra interesse em **oportunidades** | INTERESSE liga **DESAFIO_OPORTUNIDADE** | `EMPRESA_DESAFIO_OPORTUNIDADE` | Divergência D‑4 |
| 14b | Empresa implementa projetos **relacionados a essas oportunidades** | IMPLEMENTA liga EMPRESA ↔ PROJETO; nada liga PROJETO ↔ oportunidade | `EMPRESA_PROJETO_ACADEMICO` | Divergência D‑5 |
| 15 | Registrar compatibilidade com justificativa e grau de aderência | COMPATIBILIDADE (Justificativa, Grau_aderencia) | colunas em `DOCENTE_DESAFIO_OPORTUNIDADE` | OK |
| 16 | Consultar portfólio para escolher parceiros | COORDENA + ORIENTA | consulta P2 | OK |

## 3. Rastreabilidade: perguntas da seção 5 (caminho de junções)

| # | Pergunta | Caminho no modelo lógico | Status |
|---|---|---|---|
| P1 | Docentes compatíveis com um desafio | `DOCENTE_DESAFIO_OPORTUNIDADE` (direto) **ou** `DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO` → `EXPERTISE.Cod_area` → `DOCENTE_EXPERTISE` → `DOCENTE` | OK |
| P2 | Projetos do portfólio desses docentes | `PROJETO_ACADEMICO.Matricula_coordenador` ∪ `DOCENTE_PROJETO_ACADEMICO` | OK |
| P3 | Setores com oportunidades compatíveis com as competências do departamento | `SETOR` ← `DESAFIO_OPORTUNIDADE.Cod_setor` ⋈ `OPORTUNIDADE` → `..._AREA_CONHECIMENTO` → `EXPERTISE` → `DOCENTE_EXPERTISE` | OK |
| P4 | Empresas nos setores de uma oportunidade | `DESAFIO_OPORTUNIDADE.Cod_setor` → `EMPRESA_SETOR_INDUSTRIAL` → `EMPRESA` | OK |
| P5 | Empresas que já demonstraram interesse em determinada **solução** | `EMPRESA_DESAFIO_OPORTUNIDADE` (interesse no problema) ou `EMPRESA_PROJETO_ACADEMICO` (implementação). Não há registro de "interesse em uma solução/projeto" | Parcial (D‑5) |
| P6 | Oportunidades sem docentes compatíveis | `OPORTUNIDADE` anti‑join `DOCENTE_DESAFIO_OPORTUNIDADE` | OK |
| P7 | Docentes com experiência em projetos **semelhantes à demanda** | Projeto não tem ligação com área, expertise ou desafio. Só daria por busca textual em `Titulo`/`Descricao` | **Sem suporte estrutural** (D‑5) |

## 4. Completude DER ↔ modelo lógico

| Elemento do DER | Tipo | Tabela(s) no lógico | Status |
|---|---|---|---|
| DEPARTAMENTO | entidade | 1. DEPARTAMENTO | OK |
| DOCENTE | entidade | 2. DOCENTE | OK |
| PROJETO_ACADEMICO | entidade | 3 | OK |
| AREA_CONHECIMENTO | entidade | 4 | OK |
| EXPERTISE | entidade | 5 | OK |
| SETOR_INDUSTRIAL | entidade | 6 | OK |
| EMPRESA (+ ENDERECO composto) | entidade | 7 (Rua, Bairro, Cidade, Estado achatados) | OK |
| DESAFIO_OPORTUNIDADE | entidade (superclasse) | 8 | OK |
| DESAFIO, OPORTUNIDADE | subclasses | 18, 19 | Mapeado, ver E‑2 |
| VINCULA (1:N) | relacionamento | FK `DOCENTE.Cod_departamento` | OK |
| COORDENA (1:N, opcional) | relacionamento | FK `PROJETO_ACADEMICO.Matricula_coordenador` | OK, falta indicar referência (E‑1) |
| APRESENTA (1:N) | relacionamento | FK `DESAFIO_OPORTUNIDADE.Cod_setor` | OK |
| PERTENCE (1:N) | relacionamento | FK `EXPERTISE.Cod_area` | OK |
| ORIENTA (N:N) | relacionamento | 9 | OK |
| IMPLEMENTA (N:N + Data_inicio, Situacao) | relacionamento | 10 | OK |
| INTERESSE (N:N + Data_interesse, Nivel_interesse) | relacionamento | 11 | OK |
| ATUA (N:N) | relacionamento | 12 | OK |
| DOMINA (N:N) | relacionamento | 13 | OK |
| EXIGE (N:N) | relacionamento | 14 | OK |
| COMPATIBILIDADE (N:N + Grau_aderencia, Justificativa) | entidade associativa | 15 | OK |
| Telefone (1,n) | multivalorado | 16 | OK |
| Palavras_chave (1,n) | multivalorado | 17 (`Palavra_chave`) | OK, grafia diferente (E‑3) |

Conferência atributo a atributo: todos os 46 atributos do DER (incluindo os 4 sub‑atributos de ENDERECO) estão no lógico, e o lógico não tem nenhuma coluna sem origem no DER além das FKs. Cada um dos 7 relacionamentos N:N tem PK composta exatamente pelas PKs das entidades participantes.

## 5. Verificação das regras de mapeamento

| Regra | Esperado | Encontrado | Status |
|---|---|---|---|
| 1:N obrigatório no lado 1 | FK no lado N, NOT NULL | VINCULA, APRESENTA, PERTENCE: FK no lado N | OK (nulabilidade não declarada, ver R‑1) |
| 1:N opcional (0,1) | FK anulável no lado N | COORDENA: FK em PROJETO | OK |
| N:N | tabela com PK = PK₁ + PK₂ + atributos | 7 tabelas | OK |
| Multivalorado | tabela (FK, valor) com PK composta | 16, 17 | OK |
| Composto | achatamento | ENDERECO | OK |
| Especialização | mapeamento que respeite totalidade e disjunção | 2 tabelas só com PK/FK | **E‑2** |
| FK referencia tabela/coluna | explícito | nenhuma FK diz o que referencia | **E‑1** |

## 6. Normalização

| Tabela | 1FN | 2FN | 3FN | Observação |
|---|---|---|---|---|
| DEPARTAMENTO, DOCENTE, PROJETO_ACADEMICO, AREA_CONHECIMENTO, EXPERTISE, DESAFIO_OPORTUNIDADE | ✓ | ✓ (PK simples) | ✓ | — |
| SETOR_INDUSTRIAL | ✓* | ✓ | ✓ | *Se `Area_atuacao` guardar várias áreas, fere a 1FN (D‑7) |
| EMPRESA | ✓ | ✓ | ✓ | `Cidade → Estado` **não** é dependência funcional (há cidades homônimas em estados diferentes), então não fere a 3FN. `Area_atuacao` pode ficar redundante com ATUA, mas é exigida pela RN11 |
| Tabelas N:N com atributos (10, 11, 15) | ✓ | ✓ (atributos dependem da chave inteira) | ✓ | ver R‑3 sobre histórico |
| Demais N:N, 16, 17, 18, 19 | ✓ | ✓ | ✓ | só chave |

O modelo está na 3FN, com a ressalva da D‑7.

---

## 7. Achados

### Erros (no modelo lógico)

**E‑1. As FKs não indicam a tabela referenciada.**
O caso mais grave é `PROJETO_ACADEMICO.Matricula_coordenador FK`: o nome é diferente da PK de destino, então não dá para saber que ela referencia `DOCENTE(Matricula)`. Isso vale para todas as FKs, inclusive as das tabelas de junção.
*Correção:* escrever `Matricula_coordenador FK → DOCENTE(Matricula)` (e o mesmo padrão em todas).

**E‑2. A especialização foi mapeada sem impor as próprias regras.**
`DESAFIO (Cod PK/FK)` e `OPORTUNIDADE (Cod PK/FK)` têm só a chave. Com isso:
- não há impedimento a que um mesmo código esteja nas duas tabelas (disjunção não imposta);
- não há garantia de que todo `DESAFIO_OPORTUNIDADE` esteja em alguma subclasse (totalidade "T" não imposta);
- como as subclasses não têm atributos nem relacionamentos próprios (D‑3, D‑4), as duas tabelas não guardam nada além de um rótulo de tipo.

*Opções (decisão sua, item da seção 8):* (a) uma coluna discriminadora `Tipo` em `DESAFIO_OPORTUNIDADE` (com domínio {DESAFIO, OPORTUNIDADE}) e remover as tabelas 18 e 19; (b) manter as tabelas 18/19 e ligar a elas os relacionamentos que são específicos (ver D‑4), justificando sua existência.

**E‑3. Problemas de forma no documento.**
- DEPARTAMENTO e DOCENTE não têm número (a lista começa em "3.").
- Os títulos de seção "1." a "4." usam a mesma numeração das tabelas (há dois "3.", por exemplo).
- `Palavras_chave` (DER) e `Palavra_chave` (lógico) estão escritos de formas diferentes. No lógico o singular faz sentido (uma palavra por linha), mas o DER deve usar o mesmo nome.
- Falta uma legenda da notação (PK, FK, PK/FK).

### Divergências (DER ou minimundo; o modelo lógico herda)

**D‑1. ATUA tem dois rótulos `(1,1)` soltos.** A aresta `e11` (ATUA–EMPRESA) tem, além de `(0,n)`, os rótulos `aCJUbiWEIw-xWO4H5gHp-55` e `-56` com valor `(1,1)`. Isso torna a cardinalidade ambígua. Pela RN12 o correto é N:N, que é o que o lógico implementou.
*Correção:* apagar os dois rótulos.

**D‑2. ENDERECO está desenhado como entidade (retângulo).** Pela notação deveria ser um atributo composto (elipse ligada a EMPRESA, com Rua, Bairro, Cidade e Estado como sub‑atributos). O lógico já o tratou como composto.
*Correção:* trocar o retângulo por uma elipse.

**D‑3. Especialização incompleta no DER.** O triângulo diz só "T" (total). Falta dizer se é disjunta ou sobreposta (ex.: "t,d" / "t,s"), e as subclasses não têm atributos nem relacionamentos.

**D‑4. COMPATIBILIDADE e INTERESSE ligam à superclasse.** As RN13 e RN15 falam em compatibilidade entre docente e **oportunidade**, e a RN14 em interesse da empresa em **oportunidades**. No DER os dois relacionamentos ligam a `DESAFIO_OPORTUNIDADE`, ou seja, também a desafios. Ou isso é intencional (e então a especialização perde a razão de existir, E‑2), ou os relacionamentos devem apontar para OPORTUNIDADE.

**D‑5. Não há ligação entre projeto e oportunidade/área.** A RN14 fala em "projetos relacionados a essas oportunidades" e a pergunta P7 pede "projetos semelhantes à demanda". Nenhuma tabela liga `PROJETO_ACADEMICO` a `DESAFIO_OPORTUNIDADE` nem a `AREA_CONHECIMENTO`/`EXPERTISE`. Por isso P7 não tem suporte e P5 é parcial.
*Opções:* um relacionamento N:N PROJETO ↔ AREA_CONHECIMENTO (projetos classificados por área; permite comparar com EXIGE), e/ou PROJETO ↔ DESAFIO_OPORTUNIDADE (projeto originado de uma oportunidade).

**D‑6. COMPATIBILIDADE desenhada como entidade associativa sem necessidade.** Ela está como retângulo envolvendo o losango, mas nenhum outro relacionamento se liga a ela. Um losango com atributos bastaria. Não afeta o modelo lógico; é só notação.

**D‑7. "Áreas de atuação" do setor no plural (RN7).** No DER e no lógico, `Area_atuacao` é um atributo simples. Se um setor pode ter várias áreas, deveria ser multivalorado (tabela `SETOR_AREA_ATUACAO`).

### Recomendações (não contam como erro)

- **R‑1.** Declarar nulabilidade: as FKs de VINCULA, APRESENTA e PERTENCE são NOT NULL; `Matricula_coordenador` é anulável.
- **R‑2.** UNIQUE em `DOCENTE.Email` e `EMPRESA.Email`; CHECK `Data_fim >= Data_inicio`; domínios para `Situacao`, `Prioridade`, `Grau_aderencia` e `Nivel_interesse`.
- **R‑3.** Histórico: com a PK `(CNPJ, Cod_projeto)`, uma empresa só pode implementar o mesmo projeto uma vez. Com a PK `(CNPJ, Cod_desafio_oportunidade)`, só fica um registro de interesse por par, sem histórico. Se o histórico importar, incluir a data na PK.
- **R‑4.** Documentar as restrições de participação mínima que PK/FK não conseguem impor (precisam de trigger ou aplicação): departamento com ≥ 1 docente; empresa em ≥ 1 setor; desafio com ≥ 1 área exigida; empresa com ≥ 1 telefone; expertise com ≥ 1 palavra‑chave; totalidade e disjunção da especialização.
- **R‑5.** Indicar no documento de qual relacionamento do DER vem cada FK de 1:N (como já foi feito nas tabelas N:N).
- **R‑6.** Orientador e coordenador: decidir se o mesmo docente pode ser as duas coisas no mesmo projeto. Se não puder, é uma restrição a documentar.

---

## 8. Decisões tomadas e correções aplicadas

Cada item abaixo foi aprovado pela equipe antes de ser aplicado no `.docx` e no `.drawio`.

| Achado | Decisão | Modelo lógico (.docx) | DER (.drawio) |
|---|---|---|---|
| E‑1 | Aplicar | Toda FK agora indica a tabela e a coluna que referencia: `FK → TABELA(coluna)` | — |
| E‑2 / D‑3 | Manter as tabelas de subclasse; especialização **total e disjunta**, garantida por restrição textual (não por PK/FK) | Tabelas 19 e 20; restrição na seção "Restrições de integridade" | Triângulo `T` → `t,d` |
| E‑3 | Aplicar | Títulos de seção sem número; tabelas numeradas de 1 a 20; legenda da notação no topo | `Palavras_chave (1,n)` → `Palavra_chave (1,n)` |
| D‑1 | Aplicar | — | Removidos os rótulos `(1,1)` soltos em ATUA (`aCJUbiWEIw-xWO4H5gHp-55`, `-56`) |
| D‑2 | Aplicar | — | ENDERECO passou de retângulo para elipse (atributo composto) |
| D‑4 | Ligar a OPORTUNIDADE; renomear tabelas e coluna | `EMPRESA_DESAFIO_OPORTUNIDADE` → **`EMPRESA_OPORTUNIDADE`**; `DOCENTE_DESAFIO_OPORTUNIDADE` → **`DOCENTE_OPORTUNIDADE`**; coluna **`Cod_oportunidade FK → OPORTUNIDADE(Cod_desafio_oportunidade)`** | Arestas de INTERESSE e COMPATIBILIDADE agora vão a OPORTUNIDADE |
| D‑5 | Não criar ligação; usar consultas SQL aproximadas (abaixo) | — | — |
| D‑6 | Losango simples | — | Removido o retângulo `CMP`; atributos e arestas ligados ao losango |
| D‑7 | Multivalorado (1,n) | `Area_atuacao` saiu de `SETOR_INDUSTRIAL`; nova tabela **18. `SETOR_INDUSTRIAL_AREA_ATUACAO (Cod_setor PK/FK, Area_atuacao PK)`** | `Area_atuacao` → `Area_atuacao (1,n)` |
| R‑1, R‑4, R‑5 | Incluir no .docx | Nova seção "Restrições de integridade": nulabilidade e origem das FKs 1:N, participações mínimas | — |
| R‑3 | Guardar histórico (data na PK) | PK de `EMPRESA_PROJETO_ACADEMICO` = (CNPJ, Cod_projeto, **Data_inicio**); PK de `EMPRESA_OPORTUNIDADE` = (CNPJ, Cod_oportunidade, **Data_interesse**) | `Data_inicio` (IMPLEMENTA) e `Data_interesse` (INTERESSE) marcados como identificadores (círculo preenchido) |
| R‑6 | O coordenador **não pode** ser orientador do mesmo projeto | Restrição na seção "Restrições de integridade" | — |
| R‑2 | Aplicado no DDL (`sql/ddl.sql`): UNIQUE em `DOCENTE.Email` e `EMPRESA.Email`; CHECK `Data_fim IS NULL OR Data_fim >= Data_inicio`; domínios por CHECK: `Situacao` de projeto e de implementação ∈ {PLANEJADO, EM_ANDAMENTO, CONCLUIDO, CANCELADO}, `Situacao` de desafio/oportunidade ∈ {ABERTO, EM_ANALISE, ATENDIDO, ARQUIVADO}, `Prioridade` ∈ {BAIXA, MEDIA, ALTA}, `Grau_aderencia` e `Nivel_interesse` ∈ {BAIXO, MEDIO, ALTO} | — (não alterado) | — |

### Pergunta P7 sem ligação projeto ↔ demanda (decisão D‑5)
O modelo não diz quais projetos são "semelhantes" a uma demanda. A resposta sai por aproximação:
1. **Pelas expertises:** `OPORTUNIDADE → DESAFIO_OPORTUNIDADE_AREA_CONHECIMENTO → EXPERTISE (Cod_area) → DOCENTE_EXPERTISE → DOCENTE`, e depois os projetos do docente (`PROJETO_ACADEMICO.Matricula_coordenador` ∪ `DOCENTE_PROJETO_ACADEMICO`). Mostra docentes capacitados e o portfólio deles, mas não confirma que algum projeto foi semelhante.
2. **Busca textual:** `MATCH(Titulo, Descricao) AGAINST (...)` (índice FULLTEXT no MySQL) ou `LIKE`, comparando o projeto com a descrição da demanda ou com as palavras‑chave das expertises exigidas. É uma heurística: depende de como o texto foi escrito.
3. **Pela empresa:** projetos implementados (`EMPRESA_PROJETO_ACADEMICO`) por empresas que demonstraram interesse (`EMPRESA_OPORTUNIDADE`) na mesma oportunidade. Só encontra casos em que a mesma empresa aparece nos dois registros.

### Efeito das decisões nos itens das seções 2 e 3
- RN13, RN14a e RN15 passam a **OK**: compatibilidade e interesse ligam a OPORTUNIDADE.
- RN7 passa a **OK**: áreas de atuação do setor viraram multivalorado.
- RN12 passa a **OK**: os rótulos ambíguos de ATUA foram removidos.
- P6 agora é um anti‑join direto: `OPORTUNIDADE` sem linha em `DOCENTE_OPORTUNIDADE`.
- P5 continua **parcial** e P7 continua **aproximada**, pela decisão D‑5.
