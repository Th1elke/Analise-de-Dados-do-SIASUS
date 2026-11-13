-- =========================================================
-- DIMTEMPO (MySQL 8) – meses + bimestre + trimestre + semestre
-- Gera 2010-01 .. mês corrente
-- =========================================================

SET NAMES utf8mb4;
SET lc_time_names = 'pt_BR';  -- garante nomes de meses/formatos em pt-BR

DROP TABLE IF EXISTS DIMTEMPO;

CREATE TABLE DIMTEMPO (
  Id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,

  -- Data base do grão (um registro por mês)
  di DATE NOT NULL,                                           -- 1º dia do mês
  df DATE            GENERATED ALWAYS AS (LAST_DAY(di)) STORED,

  -- Atributos de mês
  mes TINYINT        GENERATED ALWAYS AS (MONTH(di)) STORED,                  -- 1..12
  mesext VARCHAR(20) GENERATED ALWAYS AS (DATE_FORMAT(di, '%M')) STORED,      -- "janeiro", "fevereiro", ...
  ano SMALLINT       GENERATED ALWAYS AS (YEAR(di)) STORED,                    -- 2010, 2011, ...
  anomes CHAR(6)     GENERATED ALWAYS AS (DATE_FORMAT(di, '%Y%m')) STORED,     -- "AAAAMM"
  MAExt VARCHAR(10)  GENERATED ALWAYS AS (CONCAT(DATE_FORMAT(di, '%b'), '-', DATE_FORMAT(di, '%Y'))) STORED,
                                                                               -- "jan-2010" (abreviado, depende de lc_time_names)

  -- -------- Bimestre --------
  bimestre TINYINT GENERATED ALWAYS AS (((MONTH(di) - 1) DIV 2) + 1) STORED,   -- 1..6
  bi_inicio DATE  GENERATED ALWAYS AS (
    DATE_ADD(MAKEDATE(YEAR(di), 1), INTERVAL (( (MONTH(di) - 1) DIV 2) * 2) MONTH)
  ) STORED,
  bi_fim DATE      GENERATED ALWAYS AS (LAST_DAY(DATE_ADD(bi_inicio, INTERVAL 1 MONTH))) STORED,
  biex_t VARCHAR(20) GENERATED ALWAYS AS (CONCAT((((MONTH(di) - 1) DIV 2) + 1), 'º bimestre')) STORED,
  anobi  CHAR(7)    GENERATED ALWAYS AS (CONCAT(YEAR(di), 'B', (((MONTH(di) - 1) DIV 2) + 1))) STORED, -- ex.: 2025B3

  -- -------- Trimestre --------
  trimestre TINYINT GENERATED ALWAYS AS (QUARTER(di)) STORED,                  -- 1..4
  tri_inicio DATE  GENERATED ALWAYS AS (
    DATE_ADD(MAKEDATE(YEAR(di), 1), INTERVAL ((QUARTER(di) - 1) * 3) MONTH)
  ) STORED,
  tri_fim DATE     GENERATED ALWAYS AS (LAST_DAY(DATE_ADD(tri_inicio, INTERVAL 2 MONTH))) STORED,
  triex_t VARCHAR(20) GENERATED ALWAYS AS (CONCAT(QUARTER(di), 'º trimestre')) STORED,
  anotri CHAR(7)   GENERATED ALWAYS AS (CONCAT(YEAR(di), 'T', QUARTER(di))) STORED,                    -- ex.: 2025T2

  -- -------- Semestre --------
  semestre TINYINT GENERATED ALWAYS AS (((MONTH(di) - 1) DIV 6) + 1) STORED,    -- 1..2
  sem_inicio DATE GENERATED ALWAYS AS (
    DATE_ADD(MAKEDATE(YEAR(di), 1), INTERVAL (((MONTH(di) - 1) DIV 6) * 6) MONTH)
  ) STORED,
  sem_fim DATE     GENERATED ALWAYS AS (LAST_DAY(DATE_ADD(sem_inicio, INTERVAL 5 MONTH))) STORED,
  semex_t VARCHAR(20) GENERATED ALWAYS AS (CONCAT((((MONTH(di) - 1) DIV 6) + 1), 'º semestre')) STORED,
  anosem CHAR(7)   GENERATED ALWAYS AS (CONCAT(YEAR(di), 'S', (((MONTH(di) - 1) DIV 6) + 1))) STORED,  -- ex.: 2025S1

  PRIMARY KEY (Id),
  UNIQUE KEY uq_dimtempo_di (di),
  KEY ix_anomes (anomes),
  KEY ix_anobi (anobi),
  KEY ix_anotri (anotri),
  KEY ix_anosem (anosem)
) ENGINE=InnoDB;

-- ----------------------------
-- Carga dinâmica: 2010-01 até o último dia do mês corrente
-- ----------------------------
CREATE TEMPORARY TABLE tmp_seq
ENGINE=MEMORY
AS
WITH RECURSIVE seq(n) AS (
  SELECT 0
  UNION ALL
  SELECT n + 1
  FROM seq
  WHERE DATE('2010-01-01') + INTERVAL (n + 1) MONTH <= LAST_DAY(CURDATE())
)
SELECT n FROM seq;

INSERT INTO DIMTEMPO (di)
SELECT DATE('2010-01-01') + INTERVAL n MONTH
FROM tmp_seq
ORDER BY n;

DROP TEMPORARY TABLE tmp_seq;

-- Conferência rápida
SELECT COUNT(*) AS total_meses, MIN(di) AS inicio, MAX(di) AS fim FROM DIMTEMPO;
-- SELECT * FROM DIMTEMPO ORDER BY di LIMIT 12;
