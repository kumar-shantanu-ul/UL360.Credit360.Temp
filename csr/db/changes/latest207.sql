-- Please update version.sql too -- this keeps clean builds in sync
define version=207
@update_header

CREATE GLOBAL TEMPORARY TABLE temp_val_id
(
	val_id				NUMBER(10,0)
) ON COMMIT DELETE ROWS;

@..\region_body

@update_tail

