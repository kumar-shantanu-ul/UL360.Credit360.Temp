-- Please update version.sql too -- this keeps clean builds in sync
define version=1070
@update_header

create or replace package csr.folderlib_pkg as
	procedure dummy;
end;
/
create or replace package body csr.folderlib_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on csr.folderlib_pkg to web_user;

@..\folderlib_pkg
@..\folderlib_body

@..\csr_user_pkg
@..\csr_user_body

@..\delegation_pkg
@..\delegation_body
    
@..\imp_pkg
@..\imp_body

@update_tail
