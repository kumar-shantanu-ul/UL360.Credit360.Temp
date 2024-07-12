-- Please update version.sql too -- this keeps clean builds in sync
define version=1524
@update_header

@..\dataset_legacy_pkg
@..\dataset_legacy_body

@update_tail