-- =========================================================
-- Correção da tabela S_CID (CID-10) após a carga
-- =========================================================
-- Problema encontrado na validação: o arquivo S_CID do DATASUS contém 14 códigos
-- em minúsculo (ex.: 'j450', 'm050', 'n63') com a descrição "CID NÃO IDENTIFICADO".
-- Como a collation padrão do MySQL não diferencia maiúsculas de minúsculas,
-- 'J450' = 'j450' no JOIN da VIEW pa_ijui: cada registro do PARS com um desses CIDs
-- era devolvido duas vezes (+1.550 registros e +R$ 682 mil no valor aprovado de Ijuí).
--
-- Correção: remover os códigos em minúsculo e criar a chave primária,
-- que impede a repetição de códigos no futuro.
-- =========================================================

USE dbsia;

-- Conferência antes: códigos repetidos considerando a collation (esperado: 14)
SELECT COUNT(*) - COUNT(DISTINCT cd_cod) AS codigos_repetidos FROM s_cid;

-- Remove as linhas cujo código tem letra minúscula (CAST AS BINARY diferencia maiúsculas)
DELETE FROM s_cid
WHERE CAST(cd_cod AS BINARY) <> CAST(UPPER(cd_cod) AS BINARY);

-- Chave primária (executar apenas uma vez: falha se a chave já existir)
ALTER TABLE s_cid ADD PRIMARY KEY (cd_cod);

-- Opcional: índice para acelerar o filtro da VIEW (WHERE pa_ufmun = '431020')
-- CREATE INDEX ix_pars_ufmun ON pars (pa_ufmun);

-- Conferência depois (esperado: 0)
SELECT COUNT(*) - COUNT(DISTINCT cd_cod) AS codigos_repetidos FROM s_cid;

-- A comparação VIEW pa_ijui x pars (68.827 registros de Ijuí em jul/2026) é feita
-- automaticamente na Seção 1.0 do notebook, depois que a VIEW é criada.
