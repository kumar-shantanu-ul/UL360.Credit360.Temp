-- Please update version.sql too -- this keeps clean builds in sync
define version=1793
@update_header

grant select on csr.delegation_ind to chem;
grant select on csr.delegation_plugin to chem;
grant select on csr.delegation_region to chem;

@..\chem\substance_body

@update_tail