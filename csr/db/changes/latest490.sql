-- Please update version.sql too -- this keeps clean builds in sync
define version=490
@update_header

ALTER TABLE factor_type
	MODIFY std_measure_id NULL;

@update_tail
