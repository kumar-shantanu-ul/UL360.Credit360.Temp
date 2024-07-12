-- Please update version.sql too -- this keeps clean builds in sync
define version=70
@update_header

@..\web_grants

grant execute on supplier_user_pkg to web_user;

@update_tail
