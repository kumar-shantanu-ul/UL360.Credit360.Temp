-- Please update version.sql too -- this keeps clean builds in sync
define version=1573
@update_header

ALTER TABLE csr.dataview RENAME COLUMN rank_missing_values_treatment TO rank_filter_type;

ALTER TABLE csrimp.dataview RENAME COLUMN rank_missing_values_treatment TO rank_filter_type;

@../dataview_pkg
@../dataview_body
@../csrimp/imp_body
@../schema_body

@update_tail
