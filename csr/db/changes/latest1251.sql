-- Please update version.sql too -- this keeps clean builds in sync
define version=1251
@update_header

grant select on csr.csr_user to chem;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
