-- Lista de SQL com extensões espaciais (PostGIS)
-- GeoSQL: http://aqui.io/geosql/

-- 1. Listar os nomes de municípios que se iniciam com “Santo” ou “Santa”
-- (sugestão: usar atabela sedemunbrasil ou a tabela mg_municipio e 
-- visualizar a distribuição espacial)
select nm_mun, geom
from municipio_mg
where (nm_mun like 'Santa%') or (nm_mun like 'Santo%')

-- 2. Listar a sigla da rodovia e o comprimento em km de todos os trechos
-- de rodovias contidos no banco de dados que tenham mais de 100km.
select sigla, st_length(geom::geography) as km, geom
from rodovia_br
where st_length(geom::geography) > 100000
order by km desc

-- 3. Listar o nome de todos os distritos do município ‘Ouro Preto'
select d.nome, d.geom
from distrito_mg d, municipio_mg m
where m.nm_mun = 'Ouro Preto' 
and st_contains(m.geom, st_transform(st_pointonsurface(d.geom), 4674)) 

-- 4. Listar o nome dos municípios que possuem pista de pouso
select distinct m.nm_mun, m.geom
from municipio_mg m, pista_pouso_mg p
where st_contains(m.geom, st_transform(p.geom, 4674))

-- 5. Listar o nome dos municípios cuja sede fica a mais de 50km da pista
-- de pouso mais próxima.
select sm.nome_munic, sm.geom
from sede_munbrasil sm, estado e,
    (
        select st_union(st_transform(st_buffer(p.geom::geography, 50000)::geometry, 4674)) as geom
        from pista_pouso_mg p
    ) as pbuf
where e.sigla = 'MG'
and st_contains(e.geom, st_transform(sm.geom, 4674))
and st_disjoint(pbuf.geom, st_transform(sm.geom, 4674))

-- 6. Listar o nome das rodovias que cruzam o “Rio das Velhas”
select rod.sigla, rod.geom
from rodovia_br rod, curso_dagua_mg rio
where rio.nome = 'Rio das Velhas'
and st_crosses(rod.geom, rio.geom)

-- 7. Listar o nome de todos os municípios ao longo da rodovia “MG-010”
select m.nm_mun, m.geom
from rodovia_br r, municipio_mg m
where r.sigla = 'MG-010'
and st_intersects(r.geom, m.geom)

-- 8. Listar os nomes dos municípios que fazem parte da microrregião “Curvelo”
select m.nm_mun, m.geom
from microrregiao_mg mr, municipio_mg m
where mr.nm_micro = 'CURVELO'
and st_contains(mr.geom, st_pointonsurface(m.geom))

-- 9. Listar o nome de todos os municípios limítrofes (exteriores e vizinhos) 
-- à microrregião “Curvelo”
select m.nm_mun, m.geom
from municipio_mg m, microrregiao_mg mr
where mr.nm_micro = 'CURVELO'
and st_touches(mr.geom, m.geom)

-- 10. Listar o nome de todos os municípios limítrofes (exteriores e vizinhos)
-- à microrregião “Curvelo” e suas respectivas microrregiões
select m.nm_mun, mr2.nm_micro, m.geom
from municipio_mg m, microrregiao_mg mr1, microrregiao_mg mr2
where mr1.nm_micro = 'CURVELO'
and st_touches(mr1.geom, m.geom)
and st_contains(mr2.geom, m.geom)

-- 11. Listar os nomes dos municípios cujas sedes municipais estão a menos de 
-- 10km de uma ferrovia. Obs: a solução envolve criar um buffer de 10km ao 
-- redor das ferrovias, mas o GeoSQL não permite o armazenamento de resultados
-- intermediários, então é necessário fazer tudo em uma única expressão SQL
select sm.nome_munic, sm.geom
from sede_munbrasil sm, estado e, (
        select st_union(st_transform(st_buffer(f.geom::geography, 10000)::geometry, 4674)) as geom
        from ferrovia_br f
    ) as f_buf
where e.sigla = 'MG'
and st_contains(e.geom, st_transform(sm.geom, 4674))
and st_contains(f_buf.geom, st_transform(sm.geom, 4674))

-- 12. Listar os nomes das sedes municipais que estão a menos de 200km da 
-- sede de Belo Horizonte.
select sm.name, sm.geom
from sede_munbrasil sm, sede_munbrasil smbh
where smbh.nome_munic = 'BELO HORIZONTE'
and sm.nome_munic <> 'BELO HORIZONTE'
and st_distance(smbh.geom::geography, sm.geom::geography) < 200000

-- 13. Listar os nomes dos municípios que estão a menos de 200km de 
-- Belo Horizonte (polígonos)
select m.nm_mun, m.geom
from municipio_mg m, municipio_mg m_bh
where m_bh.nm_mun = 'Belo Horizonte'
and m.nm_mun <> 'Belo Horizonte'
and st_distance(m.geom::geography, m_bh.geom::geography) < 200000

-- 14. Calcular a área total dos municípios cuja população é maior que 
-- 100.000 habitantes
select m.nm_mun, m.geom, st_area(m.geom::geography)
from municipio_mg m, (
        select sum(n_habitant) as pop, cd_mun
        from set_censo_2010_mg s, municipio_mg m
        where st_contains(m.geom, s.geom)
        group by m.cd_mun
    ) as p
where m.cd_mun = p.cd_mun
and p.pop > 100000

-- 15. Calcular a porcentagem da área do estado que é ocupada pelas mesorregiões
-- “NOROESTE DE MINAS”, “NORTE DE MINAS” e “JEQUITINHONHA”
select st_area(st_union(m.geom)::geography), st_union(m.geom) as geom
from mesorregiao_mg m
where m.nm_meso in ('NOROESTE DE MINAS', 'NORTE DE MINAS', 'JEQUITINHONHA')
group by nm_meso

-- 16. Informar o número de vértices usados para descrever as fronteiras do
-- Estado na tabela MG
select st_npoints(geom)
from limite_mg

-- 17. Informar em lat/long os limites do retângulo que envolve o estado de 
-- Minas Gerais inteiro (coordenadas dos cantos). Determinar também as dimensões
-- desse retângulo em km, na mesma expressão SQL.
select st_xmin(st_envelope(geom)) as x1, st_ymin(st_envelope(geom)) as y1,
    st_xmax(st_envelope(geom)) as x2, st_ymax(st_envelope(geom)) as y2,
    st_distance(
        st_makepoint(
            st_xmin(st_envelope(geom)), st_ymin(st_envelope(geom))
        )::geography,
        st_makepoint(
            st_xmax(st_envelope(geom)), st_ymin(st_envelope(geom))
        )::geography
    ) as largura_km,
        st_distance(
        st_makepoint(
            st_xmin(st_envelope(geom)), st_ymin(st_envelope(geom))
        )::geography,
        st_makepoint(
            st_xmin(st_envelope(geom)), st_ymax(st_envelope(geom))
        )::geography
    ) as altura_km
from limite_mg

-- 18. Calcular a população total, quantidade de homens e de mulheres 
-- de Betim (soma da população dos setores censitários contidos nos limites
-- do município)
select sum(n_habitant) as n_habitant, sum(n_homens) as n_homens, sum(n_mulheres) as n_mulheres
from set_censo_2010_mg censo, municipio_mg mun
where mun.nm_mun = 'Betim'
and st_contains(mun.geom, st_pointonsurface(censo.geom))

-- 19. Calcular a população total da comarca de ‘BRUMADINHO’
select sum(n_habitant) as populacao_total
from set_censo_2010_mg cen, comarca_tjmg com
where com.comarca = 'BRUMADINHO'
and st_contains(com.geom, st_pointonsurface(cen.geom))
-- meu 33973
-- dele 30614

-- 20. Verificar quantos municípios estão contidos total ou parcialmente
-- na bacia do Rio Doce
select count(*)
from municipio_mg m, bacia_hidrografica_mg b
where b.nome = 'Bacia do Rio Doce'
and st_intersects(b.geom, st_transform(m.geom, 4326))

-- 21. Contar a quantidade de barragens de rejeitos em cada município mineiro,
-- e produzir uma lista em ordem decrescente dessa quantidade, indicando também
-- o nome do município
select m.nm_mun, count(*) as quantidade
from municipio_mg m, barragem_rejeito b
where st_contains(m.geom, st_transform(b.geom, 4674))
group by m.nm_mun
order by quantidade desc

-- 22. Calcular a distância média entre a sede de cada município de MG e as localidades
contidas nele
select m.nm_mun, avg(st_distance(s.geom::geography, l.geom::geography)) as dist
from municipio_mg m, sede_munbrasil s, localidade_ibge l
where st_contains(m.geom, st_transform(s.geom, 4674))
and st_contains(m.geom, st_transform(l.geom, 4674))
group by m.nm_mun
order by dist desc

-- 23. Gerar as regiões (agregados de municípios) que têm o mesmo DDD 
-- (usar união para produzir a saída – o GeoSQL não permitirá o armazenamento 
-- do resultado)
select st_union(m.geom) as geom, d.ddd
from municipio_mg m, ddd_munic d
where m.cd_mun::numeric = d.codibge
group by d.ddd

-- 24. Listar as comarcas do TJMG relacionadas espacialmente à macrorregião
-- ‘Jequitinhonha’.

select c.comarca, c.geom, c.tid
from comarca_tjmg c, macrorregiao_mg m
where m.macroreg = 'Jequitinhonha' 
and st_intersects(c.geom, m.geom)

-- 25. Visualizar e listar os dados das barragens de rejeitos que se situam 
-- no interior de áreas de preservação do estado de MG
select b.*
from barragem_rejeito b, area_protecao_especial_mg a
where st_contains(a.geom, st_transform(b.geom, 4674))

-- 26. Listar, sem repetição, os nomes dos rios que atravessam, estão dentro
-- ou passam na fronteira de áreas de preservação do estado de MG.
select distinct r.nome, r.geom
from curso_dagua_mg r, area_protecao_especial_mg a
where st_intersects(r.geom, a.geom)

-- 27. Determinar quantos municípios do estado de Minas Gerais têm todo o seu
-- território dentro de uma única bacia hidrográfica.
select count(*)
from bacia_hidrografica_mg b, municipio_mg m
where  st_contains(st_transform(b.geom, 4674), m.geom)

-- 28. Mostrar os municípios que, ao mesmo tempo, tenham parte do seu território
-- na bacia do Rio Grande, são atravessados pela BR-040 e fazem parte da mesorregião
-- ‘CAMPO DAS VERTENTES’.
select m.*
from municipio_mg m, bacia_hidrografica_mg b, mesorregiao_mg meso, rodovia_br rd
where b.nome = 'Bacia do Rio Grande'
and rd.sigla = 'BR-040'
and meso.nm_meso = 'CAMPO DAS VERTENTES'
and st_intersects(st_transform(b.geom, 4674), m.geom)
and st_intersects(rd.geom, m.geom)
and st_contains(meso.geom, st_pointonsurface(m.geom))

-- 29. Usando o dado de PIB per capita da tabela munbrasilpib, apresente os
-- 10 municípios com os maiores valores de PIB per capita por unidade de área,
-- p. ex., por km2 de território.
select pib.percapita2010 / (st_area(m.geom::geography) / 1000000) as valor, m.nm_mun, m.geom
from munbrasilpib pib, municipio_mg m
where pib.cod = m.cd_mun::numeric
order by valor desc
limit 10

-- 30. Produza uma lista de correspondências entre as regiões-polo de saúde
-- e as microrregiões do estado. Deseja-se saber tanto que microrregiões 
-- compartilham território com as regiões-polo de saúde, quanto o inverso.
select distinct s.nomepolo, nm_micro, m.geom
from saude_mun_mg s, microrregiao_mg m
where st_intersects(s.geom, m.geom)

-- 31. Determinar (e visualizar o polígono) o percentual da área da macrorregião 
-- ‘Oeste’ que não faz parte da bacia hidrográfica do Rio São Francisco
select st_difference(m.geom, st_transform(b.geom, 4674)) as geom,
    st_area(st_difference(m.geom, st_transform(b.geom, 4674))) / st_area(m.geom) * 100 as porcentagem
from macrorregiao_mg m, bacia_hidrografica_mg b
where m.macroreg = 'Oeste'
and b.nome = 'Bacia do Rio São Francisco'

-- 32. Determinar a população total que reside a menos de 50km de uma barragem
-- de rejeitos. Obs: cuidado para não somar os mesmos dados mais de uma vez!
select sum(n_habitant)
from set_censo_2010_mg censo, (
        select st_union(st_buffer(b.geom::geography, 50000)::geometry) as geom
        from barragem_rejeito b, limite_mg l
        where st_contains(st_transform(l.geom, 4326), b.geom)
    ) as b_buf
where st_intersects(censo.geom, st_transform(b_buf.geom, 4674))

--Prova
-- 1.a. Determine o código da escola mais próxima do ponto de coordenadas long-lat
-- (44.0, 19.9), indicando também a distância em metros (Obs: SRID = 4674, mesmo 
-- do banco de dados inteiro)
select esc.CodEscola, st_distance(esc.geom::geography, st_point(44, 19.9)::geography) as dist, esc.geom
from escola esc
order by dist asc
limit 1

-- 1.b. Listar os nomes dos bairros que contêm pelo menos uma escola
select distinct b.NomeBairro, b.geom
from bairro b, escola e
where st_contains(b.geom, e.geom)

-- 1.c. Listar os bairros que fazem parte da área de responsabilidade da escola
-- cujo código é ‘E9213’
select b.CodBairro, b.NomeBairro, b.geom
from area_escola a, bairro b
where a.CodEscola = 'E9213'
and st_intersects(a.geom, b.geom)

-- 1.d. Verificar se existe alguma área de responsabilidade de escola que 
-- esteja inteiramente contida em um bairro.
select a.CodEscola, a.geom
from area_escola a, bairro b
where st_contains(b.geom, a.geom)

-- 1.e. Determinar a quantidade de alunos residentes em cada bairro cuja data
-- de nascimento seja posterior a 2015.
select b.NomeBairro, count(*) as quantidade
from bairro b, aluno a
where a.DataNasc >= '2016-01-01'::date
and st_contains(b.geom, a.geom)
group by b.NomeBairro

-- 1.f. Verificar se existem erros topológicos na tabela de bairros, ou seja, 
-- se existem bairros cujos polígonos se sobrepõem.
select b1.NomeBairro, b2.NomeBairro
from bairro b1, bairro b2
where st_overlaps(b1.geom, b2.geom)

-- 1.g. Calcular o déficit (ou superávit) de vagas em cada município. Compare o 
-- total de vagas disponíveis nas escolas com a quantidade de alunos em cada município.
select c.NomeMun, e_vagas.NumVagas - a.NumAlunos as dif
from municipio m, (
        select m.CodIBGE, sum(e.NumVagas) as NumVagas
        from municipio m, escola e
        where st_contains(m.geom, e.geom)
        group by m.CodIBGE
    ) as e_vagas,
    (
        select m.CodIBGE, count(*) as NumAlunos
        from municipio m, aluno a
        where st_contains(m.geom, a.geom)
        group by m.CodIBGE
    ) as n_alunos
where e_vagas.CodIBGE = m.CodIBGE
and n_alunos.CodIBGE = m.CodIBGE

-- 1.h. Calcular a população total de todas as áreas adjacentes à área de 
-- responsabilidade da escola cujo código é ‘E4978’
select sum(b.PopTot)
from area_escola a, area_escola b, escola e
where e.CodEscola = 'E4978'
and st_contains(e.geom, a.geom)
and st_touches(a.gem, b.geom)

-- 1.i. Determinar a proporção entre o número de alunos e o número de endereços 
-- encontrados no interior de cada bairro do município cujo código IBGE é ‘37711321’
select b.CodBairro, n_aluno_p_bairro.QntAlunos / num_end_p_bairro.QntEndereco
from municipio m, bairro b, (
        select b.CodBairro, count(*) as QntAlunos
        from bairro b, municipio m, aluno a
        where m.CodIBGE = '37711321' 
        and st_contains(m.geom, b.geom)
        and st_contains(b.geom, a.geom)
        group by b.CodBairro
    ) as n_aluno_p_bairro,
    (
        select b.CodBairro, count(*) as QntEndereco
        from bairro b, municipio m, endereco e
        where m.CodIBGE = '37711321'
        and st_contains(m.geom, b.geom)
        and st_contains(b.geom, e.geom)
        group by b.CodBairro
    ) as num_end_p_bairro
where m.codIBGE = '37711321'
and b.CodBairro = n_aluno_p_bairro.CodBairro
and b.CodBairro = num_end_p_bairro.CodBairro
and st_contains(m.geom, b.geom)
group by b.CodBairro

-- 1.j. Gerar uma nova tabela contendo polígonos correspondentes às áreas de 
-- responsabilidade de escolas municipais e estaduais, unificando os polígonos
--  das escolas de cada tipo
create table escola_por_tipo as
select e.Munic_est, st_union(a.geo) as geom
from area_escola a, escola e
where st_contains(a.geom, e.geom)
group by e.Munic_est
