with
v as
(
    -- get all delegations 
    select d.app_sid, d.delegation_sid, dr.region_sid, di.ind_sid, d.start_dtm, d.end_dtm
      from csr.delegation d
     inner join csr.delegation_region dr on dr.delegation_sid = d.delegation_sid and dr.app_sid = d.app_sid
     inner join csr.delegation_ind di on di.delegation_sid = d.delegation_sid and di.app_sid = d.app_sid
     inner join csr.ind i on i.ind_sid = di.ind_sid and i.app_sid = di.app_sid
     where d.app_sid = security.security_pkg.GetApp()
     and i.measure_sid is not null -- Exclude indicators that aren't editable
	 AND lower(di.visibility) = 'show'
	 AND lower(dr.visibility) = 'show' -- may or may not care about what's "shown" to the user 
), 
d1 as 
(
    select delegation_sid, name from csr.delegation where app_sid = security.security_pkg.GetApp()
), 
d2 as 
(
    select delegation_sid, name from csr.delegation where app_sid = security.security_pkg.GetApp()
),
s as
(
    select
        (select delegation_sid from csr.delegation where connect_by_isleaf = 1 start with delegation_sid = v.delegation_sid connect by prior parent_sid = delegation_sid) root_del_sid,
        v.delegation_sid, v.start_dtm, v.end_dtm, d1.name name,
        (select delegation_sid from csr.delegation where connect_by_isleaf = 1 start with delegation_sid = d.delegation_sid connect by prior parent_sid = delegation_sid) d_root_del_sid,
        d.delegation_sid d_delegation_sid, d.start_dtm d_start_dtm, d.end_dtm d_end_dtm, d2.name d_name,
        count(*) conflict_count
      from v
     inner join v d on v.delegation_sid <> d.delegation_sid
     inner join d1 on v.delegation_sid = d1.delegation_sid
     inner join d2 on d.delegation_sid = d2.delegation_sid
     where v.region_sid = d.region_sid -- Same region
       and v.ind_sid = d.ind_sid -- Same indicator
       and ((v.start_dtm >= d.start_dtm AND v.end_dtm <= d.end_dtm) OR (d.start_dtm >= v.start_dtm AND d.end_dtm <= v.end_dtm)) -- Do the periods overlap in any way 
       and v.delegation_sid not in (select delegation_sid from csr.delegation start with delegation_sid = d.delegation_sid connect by prior parent_sid = delegation_sid) -- v is not a parent of d (in deleg chain) 
       and d.delegation_sid not in (select delegation_sid from csr.delegation start with delegation_sid = v.delegation_sid connect by prior parent_sid = delegation_sid) -- d is not a parent of v (in deleg chain) 
       and v.delegation_sid not in (select delegation_sid from csr.delegation start with delegation_sid = d.delegation_sid connect by prior delegation_sid = parent_sid) -- v is not a child of d (in deleg chain) 
       and d.delegation_sid not in (select delegation_sid from csr.delegation start with delegation_sid = v.delegation_sid connect by prior delegation_sid = parent_sid) -- d is not a child of v (in deleg chain) 
	   group by v.delegation_sid, d1.name, v.start_dtm, v.end_dtm, d.delegation_sid, d2.name, d.start_dtm, d.end_dtm
),
rns as
(
    select rownum rn, s.*
    from s
)
select
    root_del_sid, delegation_sid, name, cast(to_char(start_dtm, 'DD-MON-YYYY') as varchar2(11)) start_dtm, cast(to_char(end_dtm, 'DD-MON-YYYY') as varchar2(11)) end_dtm,
    d_root_del_sid, d_delegation_sid, d_name, cast(to_char(d_start_dtm, 'DD-MON-YYYY') as varchar2(11)) d_start_dtm, cast(to_char(d_end_dtm, 'DD-MON-YYYY') as varchar2(11)) d_end_dtm,
    conflict_count
  from rns
 where (delegation_sid, d_delegation_sid) not in (select d_delegation_sid, delegation_sid from rns rnsd where rns.rn > rnsd.rn) -- Get rid of duplicates (i.e. A conflicts with B and B conflicts with A)
   and csr.trash_pkg.IsInTrash(security.security_pkg.GetAct, delegation_sid) = 0
   and csr.trash_pkg.IsInTrash(security.security_pkg.GetAct, d_delegation_sid) = 0
 order by root_del_sid, delegation_sid, start_dtm, end_dtm;