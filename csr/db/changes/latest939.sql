-- Please update version.sql too -- this keeps clean builds in sync
define version=939
@update_header

ALTER TABLE csr.logistics_tab_mode MODIFY get_aggregates_sp NULL;

@update_tail