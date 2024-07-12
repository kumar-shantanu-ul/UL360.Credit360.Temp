-- Please update version.sql too -- this keeps clean builds in sync
define version=2198
@update_header

grant select, update on aspen2.application to chain;

@../chain/setup_body
@../enable_body

	
@update_tail
