-- Please update version.sql too -- this keeps clean builds in sync
define version=1749
@update_header

grant execute on chem.audit_pkg to csr;
grant execute on chem.audit_pkg to web_user;

@..\chem\audit_pkg
@..\chem\audit_body

@..\chem\substance_body

@update_tail
