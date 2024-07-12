-- Please update version.sql too -- this keeps clean builds in sync
define version=1290
@update_header

grant all on csr.tab_user to ct;


@..\ct\company_body


@update_tail
