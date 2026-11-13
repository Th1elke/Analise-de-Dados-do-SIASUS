-- =========================================================
-- 01 - Criação do banco dbsia e da tabela de produção ambulatorial (pars)
-- =========================================================
-- Estrutura obtida do arquivo PARS2607.dbf (SIASUS - Produção Ambulatorial do RS),
-- convertido de .dbc com o TabWin: 62 campos. Campos "C" do DBF viram CHAR(n);
-- campos numéricos "N" viram DECIMAL(n,d).
-- =========================================================

CREATE DATABASE IF NOT EXISTS dbsia CHARACTER SET utf8mb4;
USE dbsia;

DROP TABLE IF EXISTS pars;

CREATE TABLE pars (
  pa_coduni   CHAR(7),
  pa_gestao   CHAR(6),
  pa_condic   CHAR(2),
  pa_ufmun    CHAR(6),
  pa_regct    CHAR(4),
  pa_incout   CHAR(4),
  pa_incurg   CHAR(4),
  pa_tpups    CHAR(2),
  pa_tippre   CHAR(2),
  pa_mn_ind   CHAR(1),
  pa_cnpjcpf  CHAR(14),
  pa_cnpjmnt  CHAR(14),
  pa_cnpj_cc  CHAR(14),
  pa_mvm      CHAR(6),
  pa_cmp      CHAR(6),
  pa_proc_id  CHAR(10),
  pa_tpfin    CHAR(2),
  pa_subfin   CHAR(4),
  pa_nivcpl   CHAR(1),
  pa_docorig  CHAR(1),
  pa_autoriz  CHAR(13),
  pa_cnsmed   CHAR(15),
  pa_cbocod   CHAR(6),
  pa_motsai   CHAR(2),
  pa_obito    CHAR(1),
  pa_encerr   CHAR(1),
  pa_perman   CHAR(1),
  pa_alta     CHAR(1),
  pa_transf   CHAR(1),
  pa_cidpri   CHAR(4),
  pa_cidsec   CHAR(4),
  pa_cidcas   CHAR(4),
  pa_catend   CHAR(2),
  pa_idade    CHAR(3),
  idademin    CHAR(3),
  idademax    CHAR(3),
  pa_flidade  CHAR(1),
  pa_sexo     CHAR(1),
  pa_racacor  CHAR(2),
  pa_munpcn   CHAR(6),
  pa_qtdpro   DECIMAL(11,0),
  pa_qtdapr   DECIMAL(11,0),
  pa_valpro   DECIMAL(20,2),
  pa_valapr   DECIMAL(20,2),
  pa_ufdif    CHAR(1),
  pa_mndif    CHAR(1),
  pa_dif_val  DECIMAL(20,2),
  nu_vpa_tot  DECIMAL(20,2),
  nu_pa_tot   DECIMAL(20,2),
  pa_indica   CHAR(1),
  pa_codoco   CHAR(1),
  pa_flqt     CHAR(1),
  pa_fler     CHAR(1),
  pa_etnia    CHAR(4),
  pa_vl_cf    DECIMAL(20,2),
  pa_vl_cl    DECIMAL(20,2),
  pa_vl_inc   DECIMAL(20,2),
  pa_srv_c    CHAR(6),
  pa_ine      CHAR(10),
  pa_nat_jur  CHAR(4),
  pa_fntorc   CHAR(2),
  pa_vl_crd   DECIMAL(20,2)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Índice no município do estabelecimento: acelera o filtro da VIEW (WHERE pa_ufmun = '431020').
-- Criar DEPOIS da carga (02) deixa o LOAD DATA mais rápido; por isso está aqui comentado e repetido no 02.
-- CREATE INDEX ix_pars_ufmun ON pars (pa_ufmun);
