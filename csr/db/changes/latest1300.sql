-- Please update version.sql too -- this keeps clean builds in sync
define version=1300
@update_header

create or replace package csr.dataset_legacy_pkg as
	procedure dummy;
end;
/
create or replace package body csr.dataset_legacy_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on csr.dataset_legacy_pkg to web_user;

@../dataset_legacy_pkg
@../dataset_legacy_body

@update_tail
