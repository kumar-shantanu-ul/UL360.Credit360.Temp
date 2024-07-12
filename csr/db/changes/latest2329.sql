-- Please update version.sql too -- this keeps clean builds in sync
define version=2329
@update_header

ALTER TABLE csrimp.aggregate_ind_group ADD (js_include VARCHAR2(255) NULL);

@update_tail