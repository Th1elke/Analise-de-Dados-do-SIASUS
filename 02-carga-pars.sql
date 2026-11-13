-- =========================================================
-- 02 - Carga do PARS (CSV exportado pelo TabWin) com LOAD DATA INFILE
-- =========================================================
-- Executar pelo cliente de linha de comando do MySQL, como administrador
-- (pelo Workbench o LOAD DATA costuma falhar por permissão).
--
-- O arquivo precisa estar na pasta permitida pelo servidor:
--   SHOW VARIABLES LIKE 'secure_file_priv';
-- (no Windows, normalmente C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/)
--
-- Formato do CSV gerado pelo TabWin: separador vírgula, textos entre aspas,
-- números com ponto decimal, primeira linha com os nomes dos campos e fim de linha \r\n.
-- Para carregar outros meses, repita o LOAD DATA com os demais arquivos (ex.: PARS2606a.csv, PARS2606b.csv).
-- =========================================================

USE dbsia;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/PARS2607.csv'
INTO TABLE pars
CHARACTER SET latin1
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

-- Índice para o filtro da VIEW (criado depois da carga).
CREATE INDEX ix_pars_ufmun ON pars (pa_ufmun);

-- Conferência: registros carregados (RS inteiro) e registros de Ijuí (esperado jul/2026: 68.827)
SELECT pa_mvm AS movimento, COUNT(*) AS registros FROM pars GROUP BY pa_mvm;
SELECT COUNT(*) AS registros_ijui FROM pars WHERE pa_ufmun = '431020';
