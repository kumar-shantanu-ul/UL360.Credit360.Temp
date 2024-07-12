exec user_pkg.logonadmin('otto.credit360.com');

with prob_delegs as (
    select delegation_sid, next_delegation_sid, stragg(distinct root_region_sid) problem_regions
      from (
        select /*+ ALL_ROWS */d.delegation_sid, art.root_region_sid, art.region_sid, di.ind_sid, d.start_dtm, d.end_dtm,
            count(*) over (partition by art.region_sid, di.ind_sid) cnt,
            lead(d.start_dtm) over (partition by art.region_sid, di.ind_sid order by art.region_sid, di.ind_sid, d.start_dtm, d.end_dtm) next_start_dtm,
            lead(d.delegation_sid) over (partition by art.region_sid, di.ind_sid order by art.region_sid, di.ind_sid, d.start_dtm, d.end_dtm) next_delegation_sid
          from delegation d
            join delegation_region dr on d.delegation_sid = dr.delegation_sid and d.app_sid = dr.app_sid
            join (
                -- all possible region tree roots and descendents (could get big!)
                select connect_by_root region_sid root_region_sid, region_sid
                  from region
                 connect by prior region_sid = parent_sid
            )art on dr.region_sid = art.root_region_sid
            join delegation_ind di on d.delegation_sid = di.delegation_sid and d.app_sid = di.app_sid
         where d.app_sid = d.parent_sid -- top level
           and exists (
                -- indicates there's data, so we have a problem
                select 0 
                  from sheet s 
                    join sheet_value sv on s.sheet_Id = sv.sheet_id and s.app_sid = sv.app_sid 
                 where s.delegation_sid = d.delegation_sid and d.app_sid = s.app_sid
           )
     )
     where next_start_dtm < end_dtm
     group by delegation_sid, next_delegation_sid
)
select *
  from prob_delegs pd; 
