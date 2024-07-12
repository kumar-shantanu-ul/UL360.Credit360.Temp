-- Please update version.sql too -- this keeps clean builds in sync
define version=972
@update_header

@../region_list_pkg
@../region_list_body

grant execute on csr.region_list_pkg to web_user;

@update_tail
