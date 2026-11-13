use dbsia;

drop view if exists pa_ijui;

CREATE OR REPLACE VIEW pa_ijui AS
SELECT
    -- 1. DIMENSÃO TEMPORAL
    dt.ano AS Ano,
    dt.mes AS Mes,
    dt.anobi AS AnoBimestre,
    dt.anotri AS AnoTrimestre,

    pa.pa_cmp AS Competencia,          -- mês em que o atendimento foi realizado (AAAAMM)

    -- 2. ESTABELECIMENTO DE SAÚDE
    ca.fantasia AS Estabelecimento,
    pa.pa_tpups AS TipoUnidade,         -- tipo de unidade do CNES (05 hospital, 70 CAPS, 73 UPA...)

    -- 2.1 INSTRUMENTO DE REGISTRO
    pa.pa_docorig AS Instrumento,       -- C/I = BPA consolidado/individualizado; P/S = APAC; A/B = RAAS
    pa.pa_autoriz AS NumAutorizacao,    -- número da APAC (vazio no BPA)

    -- 3. PROCEDIMENTO AMBULATORIAL
    pa.pa_proc_id AS CodProcedimento,   -- código SIGTAP (10 dígitos: grupo/subgrupo/forma de organização)
    pro.ip_dscr AS Procedimento,

    -- 4. OCUPAÇÃO PROFISSIONAL    
    cb.ds_cbo AS Ocupacao,

    -- 5. PERFIL DEMOGRÁFICO
    pa.pa_sexo,
    pa.pa_idade, 

    -- 6. DIAGNÓSTICO PRINCIPAL
    pa.pa_cidpri,
    cid.cd_descr AS Diagnostico,

    -- 7. MUNICÍPIO DO ESTABELECIMENTO    
    mun_est.ds_nome AS MunicipioEstabelecimento,

    -- 8. MUNICÍPIO, REGIÃO DE SAÚDE E MACRORREGIÃO DO PACIENTE
    pa.pa_munpcn AS CodMunicipioPaciente,
    mun_pac.ds_nome AS MunicipioPaciente,
    mun_pac.uf AS UFPaciente,
    mun_pac.nu_latitud AS LatPaciente,      -- coordenadas do município (vírgula decimal), usadas no mapa
    mun_pac.nu_longit AS LonPaciente,
    reg.ds_nome AS RegiaoSaudePaciente,
    mac.ds_nome AS MacrorregiaoPaciente,

    -- 9. PRODUÇÃO AMBULATORIAL
    pa.pa_qtdpro,
    pa.pa_qtdapr,

    -- 10. VALORES FINANCEIROS
    pa.pa_valpro,
    pa.pa_valapr

FROM pars AS pa

-- Estabelecimento de saúde
LEFT JOIN cadgerrs AS ca
    ON pa.pa_coduni = ca.cnes

-- Procedimento ambulatorial
LEFT JOIN procedimentos AS pro
    ON pa.pa_proc_id = pro.ip_cod

-- Ocupação profissional
LEFT JOIN cbo AS cb
    ON pa.pa_cbocod = cb.cbo

-- Diagnóstico principal
LEFT JOIN s_cid AS cid
    ON pa.pa_cidpri = cid.cd_cod

-- Município do estabelecimento
LEFT JOIN tb_municip AS mun_est
    ON pa.pa_ufmun = mun_est.co_municip

-- Município do paciente
LEFT JOIN tb_municip AS mun_pac
    ON pa.pa_munpcn = mun_pac.co_municip

-- Região de Saúde do paciente (MUNICIPIO -> RL -> região)
LEFT JOIN rl_municip_regsaud AS rl_reg
    ON pa.pa_munpcn = rl_reg.co_municip
LEFT JOIN tb_regsaud AS reg
    ON rl_reg.co_regsaud = reg.co_regsaud

-- Macrorregião de Saúde do paciente
LEFT JOIN rl_municip_macsaud AS rl_mac
    ON pa.pa_munpcn = rl_mac.co_municip
LEFT JOIN tb_macsaud AS mac
    ON rl_mac.co_macsaud = mac.co_macsaud

-- Dimensão temporal (mês de movimento)
LEFT JOIN DIMTEMPO AS dt
    ON pa.pa_mvm = dt.anomes

-- Produção realizada nos estabelecimentos de Ijuí
WHERE pa.pa_ufmun = '431020';


select count(*) from pa_ijui;

select * from pa_ijui LIMIT 5;