-- Please update version.sql too -- this keeps clean builds in sync
define version=1103
@update_header

create or replace package donations.sys_pkg as
procedure dummy;
end;
/
create or replace package body donations.sys_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on donations.sys_pkg to security;

@../donations/sys_pkg
@../donations/sys_body

@update_tail
