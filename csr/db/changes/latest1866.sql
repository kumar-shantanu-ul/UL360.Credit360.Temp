-- Please update version.sql too -- this keeps clean builds in sync
define version=1866
@update_header

ALTER TABLE csrimp.cms_tab_column_role_permission 
        ADD policy_function VARCHAR2(100);

@update_tail