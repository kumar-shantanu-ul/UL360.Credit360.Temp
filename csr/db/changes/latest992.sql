-- Please update version.sql too -- this keeps clean builds in sync
define version=992
@update_header

declare
	v_version number;
begin
	select db_version
	  into v_version
	  from cms.version;
	if v_version != 69 then
		raise_application_error(-20001, 'cms must be version 69 first');
	end if;
end;
/

drop table cms.version;

@update_tail
