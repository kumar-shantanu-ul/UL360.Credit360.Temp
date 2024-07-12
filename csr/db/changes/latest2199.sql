-- Please update version.sql too -- this keeps clean builds in sync
define version=2199
@update_header

grant select on csr.ind to chem;
grant select on csr.v$ind to chem;
grant select on csr.delegation to chem;
grant select on csr.delegation_plugin to chem;

@../chem/substance_pkg
@../chem/substance_body

	
@update_tail
