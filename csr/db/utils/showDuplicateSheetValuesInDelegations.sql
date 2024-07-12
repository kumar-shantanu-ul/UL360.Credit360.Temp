-- Shows entries in csr.sheet_value that have come from conflicting delegations - i.e. delegations that are capturing data for the same
-- region and indicator in an overlapping time period. This script does not consider split regions.

with v as
(
select v.sheet_value_id, s.delegation_sid, s.start_dtm, s.end_dtm, v.ind_sid, v.region_sid, v.val_number, v.entry_measure_conversion_id, v.entry_val_number
from csr.sheet_value v
inner join csr.sheet s on s.sheet_id = v.sheet_id
inner join csr.delegation d on s.delegation_sid = d.delegation_sid
where d.app_sid = security.security_pkg.GetApp()
)
select
case
when v.val_number is null and d.val_number is not null then 'V'
when v.val_number is not null and d.val_number is null then 'V'
when v.val_number <> d.val_number then 'C'
else ' '
end status,
(select delegation_sid from csr.delegation where connect_by_isleaf = 1 start with delegation_sid = v.delegation_sid connect by prior parent_sid = delegation_sid) root_del_sid,
v.delegation_sid, v.sheet_value_id, v.entry_measure_conversion_id, v.entry_val_number, cast(to_char(v.start_dtm, 'DD-MON-YYYY') as varchar2(11)) start_dtm, cast(to_char(v.end_dtm, 'DD-MON-YYYY') as varchar2(11)) end_dtm, v.region_sid, v.ind_sid, v.val_number,
(select delegation_sid from csr.delegation where connect_by_isleaf = 1 start with delegation_sid = d.delegation_sid connect by prior parent_sid = delegation_sid) root_del_sid,
d.delegation_sid, d.sheet_value_id, d.entry_measure_conversion_id d_entry_measure_conversion_id, d.entry_val_number d_entry_val_number, cast(to_char(d.start_dtm, 'DD-MON-YYYY') as varchar2(11)) start_dtm, cast(to_char(d.end_dtm, 'DD-MON-YYYY') as varchar2(11)) end_dtm, d.val_number
from v
inner join v d on v.sheet_value_id <> d.sheet_value_id
where v.ind_sid = d.ind_sid
and v.region_sid = d.region_sid
and ((v.start_dtm >= d.start_dtm AND v.end_dtm <= d.end_dtm) OR (d.start_dtm >= v.start_dtm AND d.end_dtm <= v.end_dtm)) 
and v.delegation_sid not in (select delegation_sid from delegation start with delegation_sid = d.delegation_sid connect by prior parent_sid = delegation_sid) -- v is not a parent of d (in deleg chain) 
and d.delegation_sid not in (select delegation_sid from delegation start with delegation_sid = v.delegation_sid connect by prior parent_sid = delegation_sid) -- d is not a parent of v (in deleg chain) 
and v.delegation_sid not in (select delegation_sid from delegation start with delegation_sid = d.delegation_sid connect by prior delegation_sid = parent_sid) -- v is not a child of d (in deleg chain) 
and d.delegation_sid not in (select delegation_sid from delegation start with delegation_sid = v.delegation_sid connect by prior delegation_sid = parent_sid) -- d is not a child of v (in deleg chain) 
--and (d.start_dtm >= '1 jan 2012' or v.start_dtm >= '1 jan 2012')
order by v.region_sid, v.ind_sid, v.start_dtm, v.end_dtm
;

select '      C - conflicting value across multiple delegations' status from dual
union all select '      V - value is NULL is one delegation chain but provided in another delegation chain' from dual
union all select '[space] - value is captured across multiple delegation chains but the value is the same' from dual
;
