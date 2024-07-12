-- Please update version.sql too -- this keeps clean builds in sync
define version=2142
@update_header

grant select, insert, update on csr.ind_description to aspen2;
@../../../aspen2/NPSL.TRANSLATION/db/tr_pkg
@../../../aspen2/NPSL.TRANSLATION/db/tr_body
	
@update_tail
