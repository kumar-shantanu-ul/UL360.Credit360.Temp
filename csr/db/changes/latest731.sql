-- Please update version.sql too -- this keeps clean builds in sync
define version=731
@update_header

declare
v_count number;
begin

for r in (
select 'Access all contracts' name, 0 allow_by_default from dual union all
select 'Allow adding snapshots', 0 from dual union all
select 'Allow approvers to edit submitted sheets', 1 from dual union all
select 'Configure strategy dashboard', 0 from dual union all
select 'Delegation reports', 0 from dual union all
select 'Delete Utility Contract', 0 from dual union all
select 'Delete Utility Invoice', 0 from dual union all
select 'Delete Utility Supplier', 0 from dual union all
select 'Edit Region Docs', 0 from dual union all
select 'Issue management', 0 from dual union all
select 'Load models into the calculation engine', 0 from dual union all
select 'Manage any portal', 0 from dual union all
select 'Report publication', 0 from dual union all
select 'Split delegations', 1 from dual union all
select 'Subdelegation', 1 from dual union all
select 'System management', 0 from dual union all
select 'Use gauge-style charts', 0 from dual union all
select 'View all meters', 0 from dual union all
select 'View strategy dashboard', 0 from dual union all
select 'Create users for approval', 0 from dual union all
select 'Can view account manager details', 0 from dual union all
select 'Manage Logistics', 0 from dual
) loop
select count(*) into v_count from capability where name = r.name;
if v_count = 0 then
insert into csr.capability (name, allow_by_default) values (r.name, r.allow_by_default);
dbms_output.put_line('Added missing capability ' || r.name);
end if;
end loop;
end;
/

@update_tail