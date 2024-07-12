-- Please update version.sql too -- this keeps clean builds in sync
define version=1895
@update_header

grant execute on chain.supplier_audit_pkg to web_user;

@update_tail
