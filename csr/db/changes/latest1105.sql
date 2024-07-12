-- Please update version.sql too -- this keeps clean builds in sync
define version=1105
@update_header

DROP VIEW ct.v$bt_region;

@update_tail
