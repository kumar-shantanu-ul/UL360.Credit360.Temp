-- Please update version.sql too -- this keeps clean builds in sync
define version=1758
@update_header

grant select on csr.delegation to chem;
	
@update_tail