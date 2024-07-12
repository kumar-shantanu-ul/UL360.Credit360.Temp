-- Please update version.sql too -- this keeps clean builds in sync
define version=45
@update_header


connect csr/csr@&_CONNECT_IDENTIFIER

grant execute on sqlreport_pkg to donations;

connect donations/donations@&_CONNECT_IDENTIFIER

@..\reports_pkg
@..\reports_body

grant execute on reports_pkg to csr, web_user;



@update_tail
