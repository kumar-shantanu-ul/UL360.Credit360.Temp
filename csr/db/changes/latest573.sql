-- Please update version.sql too -- this keeps clean builds in sync
define version=573
@update_header

ALTER TABLE factor
	MODIFY is_selected DEFAULT 0;

@update_tail
