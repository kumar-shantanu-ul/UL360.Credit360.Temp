-- Please update version.sql too -- this keeps clean builds in sync
define version=2473
@update_header

begin
	for r in (select d.delegation_sid,md.name from csr.delegation d, csr.delegation md where md.delegation_sid=d.master_delegation_sid and d.name is null) loop
		update csr.delegation set name = r.name where delegation_sid = r.delegation_sid;
	end loop;
end;
/
update csr.delegation set name=delegation_sid where name is null;

alter table csr.delegation modify name not null;

@../delegation_body

@update_tail
