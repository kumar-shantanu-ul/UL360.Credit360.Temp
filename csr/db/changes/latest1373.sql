-- Please update version.sql too -- this keeps clean builds in sync
define version=1373
@update_header

grant select, references on csr.sheet_with_last_action to chem;

@..\chem\substance_pkg
@..\chem\substance_body

@update_tail
