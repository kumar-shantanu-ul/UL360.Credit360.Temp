-- Please update version.sql too -- this keeps clean builds in sync
define version=1162
@update_header 

grant execute on cms.upload_pkg to web_user;

@update_tail