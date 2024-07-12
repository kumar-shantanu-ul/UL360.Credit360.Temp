--Please update version.sql too -- this keeps clean builds in sync
define version=2610
@update_header

@../section_root_pkg
@../section_root_body

@../section_pkg
@../section_body
	
@update_tail