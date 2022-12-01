-- 1
select nm_mun, geom
from municipio_mg
where (nm_mun like 'Santa%') or (nm_mun like 'Santo%')

--2
select sigla, st_length(geom::geography) as km, geom
from rodovia_br
where st_length(geom::geography) > 100000
order by km desc

--3
select d.nome, d.geom
from distrito_mg d, municipio_mg m
where m.nm_mun = 'Ouro Preto' 
and st_contains(m.geom, st_transform(st_pointonsurface(d.geom), 4674)) 

--4
select distinct m.nm_mun, m.geom
from municipio_mg m, pista_pouso_mg p
where st_contains(m.geom, st_transform(p.geom, 4674))

--5
select sm.nome_munic, sm.geom
from sede_munbrasil sm, estado e,
    (
        select st_union(st_transform(st_buffer(p.geom::geography, 50000)::geometry, 4674)) as geom
        from pista_pouso_mg p
    ) as pbuf
where e.sigla = 'MG'
and st_contains(e.geom, st_transform(sm.geom, 4674))
and st_disjoint(pbuf.geom, st_transform(sm.geom, 4674))

--6
select rod.sigla, rod.geom
from rodovia_br rod, curso_dagua_mg rio
where rio.nome = 'Rio das Velhas'
and st_crosses(rod.geom, rio.geom)

--7
select m.nm_mun, m.geom
from rodovia_br r, municipio_mg m
where r.sigla = 'MG-010'
and st_intersects(r.geom, m.geom)

--8
select m.nm_mun, m.geom
from microrregiao_mg mr, municipio_mg m
where mr.nm_micro = 'CURVELO'
and st_contains(mr.geom, st_pointonsurface(m.geom))

--9
select m.nm_mun, m.geom
from municipio_mg m, microrregiao_mg mr
where mr.nm_micro = 'CURVELO'
and st_touches(mr.geom, m.geom)

--10
select m.nm_mun, mr2.nm_micro, m.geom
from municipio_mg m, microrregiao_mg mr1, microrregiao_mg mr2
where mr1.nm_micro = 'CURVELO'
and st_touches(mr1.geom, m.geom)
and st_contains(mr2.geom, m.geom)

--11
select sm.nome_munic, sm.geom
from sede_munbrasil sm, estado e, (
        select st_union(st_transform(st_buffer(f.geom::geography, 10000)::geometry, 4674)) as geom
        from ferrovia_br f
    ) as f_buf
where e.sigla = 'MG'
and st_contains(e.geom, st_transform(sm.geom, 4674))
and st_contains(f_buf.geom, st_transform(sm.geom, 4674))

--12
select sm.name, sm.geom
from sede_munbrasil sm, sede_munbrasil smbh
where smbh.nome_munic = 'BELO HORIZONTE'
and sm.nome_munic <> 'BELO HORIZONTE'
and st_distance(smbh.geom::geography, sm.geom::geography) < 200000

--13
select m.nm_mun, m.geom
from municipio_mg m, municipio_mg m_bh
where m_bh.nm_mun = 'Belo Horizonte'
and m.nm_mun <> 'Belo Horizonte'
and st_distance(m.geom::geography, m_bh.geom::geography) < 200000

--14
select m.nm_mun, m.geom, st_area(m.geom::geography)
from municipio_mg m, (
        select sum(n_habitant) as pop, cd_mun
        from set_censo_2010_mg s, municipio_mg m
        where st_contains(m.geom, s.geom)
        group by m.cd_mun
    ) as p
where m.cd_mun = p.cd_mun
and p.pop > 100000

--15
select st_area(st_union(m.geom)::geography), st_union(m.geom) as geom
from mesorregiao_mg m
where m.nm_meso in ('NOROESTE DE MINAS', 'NORTE DE MINAS', 'JEQUITINHONHA')
group by nm_meso

-- 16
select st_npoints(geom)
from limite_mg

--17
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

--18
select sum(n_habitant) as n_habitant, sum(n_homens) as n_homens, sum(n_mulheres) as n_mulheres
from set_censo_2010_mg censo, municipio_mg mun
where mun.nm_mun = 'Betim'
and st_contains(mun.geom, st_pointonsurface(censo.geom))
-- meu  379084	186814	192270
-- dele 350609	172737	177872

--19
select sum(n_habitant) as populacao_total
from set_censo_2010_mg cen, comarca_tjmg com
where com.comarca = 'BRUMADINHO'
and st_contains(com.geom, st_pointonsurface(cen.geom))
-- meu 33973
-- dele 30614

--20
select count(*)
from municipio_mg m, bacia_hidrografica_mg b
where b.nome = 'Bacia do Rio Doce'
and st_intersects(b.geom, st_transform(m.geom, 4326))

--21
select m.nm_mun, count(*) as quantidade
from municipio_mg m, barragem_rejeito b
where st_contains(m.geom, st_transform(b.geom, 4674))
group by m.nm_mun
order by quantidade desc

--22
select m.nm_mun, avg(st_distance(s.geom::geography, l.geom::geography)) as dist
from municipio_mg m, sede_munbrasil s, localidade_ibge l
where st_contains(m.geom, st_transform(s.geom, 4674))
and st_contains(m.geom, st_transform(l.geom, 4674))
group by m.nm_mun
order by dist desc

--23
select st_union(m.geom) as geom, d.ddd
from municipio_mg m, ddd_munic d
where m.cd_mun::numeric = d.codibge
group by d.ddd

--24
select c.comarca, c.geom, c.tid
from comarca_tjmg c, macrorregiao_mg m
where m.macroreg = 'Jequitinhonha' 
and st_intersects(c.geom, m.geom)

--25
select b.*
from barragem_rejeito b, area_protecao_especial_mg a
where st_contains(a.geom, st_transform(b.geom, 4674))

--26
select distinct r.nome, r.geom
from curso_dagua_mg r, area_protecao_especial_mg a
where st_intersects(r.geom, a.geom)

--27
select count(*)
from bacia_hidrografica_mg b, municipio_mg m
where  st_contains(st_transform(b.geom, 4674), m.geom)

--28
select m.*
from municipio_mg m, bacia_hidrografica_mg b, mesorregiao_mg meso, rodovia_br rd
where b.nome = 'Bacia do Rio Grande'
and rd.sigla = 'BR-040'
and meso.nm_meso = 'CAMPO DAS VERTENTES'
and st_intersects(st_transform(b.geom, 4674), m.geom)
and st_intersects(rd.geom, m.geom)
and st_contains(meso.geom, st_pointonsurface(m.geom))

--29
select pib.percapita2010 / (st_area(m.geom::geography) / 1000000) as valor, m.nm_mun, m.geom
from munbrasilpib pib, municipio_mg m
where pib.cod = m.cd_mun::numeric
order by valor desc
limit 10

--30
select distinct s.nomepolo, nm_micro, m.geom
from saude_mun_mg s, microrregiao_mg m
where st_intersects(s.geom, m.geom)

--31
select st_difference(m.geom, st_transform(b.geom, 4674)) as geom,
    st_area(st_difference(m.geom, st_transform(b.geom, 4674))) / st_area(m.geom) * 100 as porcentagem
from macrorregiao_mg m, bacia_hidrografica_mg b
where m.macroreg = 'Oeste'
and b.nome = 'Bacia do Rio São Francisco'

--32
select sum(n_habitant)
from set_censo_2010_mg censo, (
        select st_union(st_buffer(b.geom::geography, 50000)::geometry) as geom
        from barragem_rejeito b, limite_mg l
        where st_contains(st_transform(l.geom, 4326), b.geom)
    ) as b_buf
where st_intersects(censo.geom, st_transform(b_buf.geom, 4674))

--Prova
--1.a
select esc.CodEscola, st_distance(esc.geom::geography, st_point(44, 19.9)::geography) as dist, esc.geom
from escola esc
order by dist asc
limit 1

--1.b
select distinct b.NomeBairro, b.geom
from bairro b, escola e
where st_contains(b.geom, e.geom)

--1.c
select b.CodBairro, b.NomeBairro, b.geom
from area_escola a, bairro b
where a.CodEscola = 'E9213'
and st_intersects(a.geom, b.geom)

--1.d
select a.CodEscola, a.geom
from area_escola a, bairro b
where st_contains(b.geom, a.geom)

--1.e
select b.NomeBairro, count(*) as quantidade
from bairro b, aluno a
where a.DataNasc >= '2016-01-01'::date
and st_contains(b.geom, a.geom)
group by b.NomeBairro

--1.f
select b1.NomeBairro, b2.NomeBairro
from bairro b1, bairro b2
where st_overlaps(b1.geom, b2.geom)

--1.g
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

--1.h
select sum(b.PopTot)
from area_escola a, area_escola b, escola e
where e.CodEscola = 'E4978'
and st_contains(e.geom, a.geom)
and st_touches(a.gem, b.geom)

--1.i
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

--1.j
create table escola_por_tipo as
select e.Munic_est, st_union(e.geom) as geom
from escola e
group by e.Munic_est