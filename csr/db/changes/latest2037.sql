-- Please update version.sql too -- this keeps clean builds in sync
define version=2037
@update_header

ALTER TABLE csrimp.region_metric DROP COLUMN lookup_key;

@..\schema_pkg
@..\schema_body

@update_tail