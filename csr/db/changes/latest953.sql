-- Please update version.sql too -- this keeps clean builds in sync
define version=953
@update_header

ALTER TABLE csr.logistics_tab_mode
	ADD location_changed_sp VARCHAR2(255);

@update_tail
