-- Please update version.sql too -- this keeps clean builds in sync
define version=254
@update_header

DROP TABLE temp_val_id;
CREATE GLOBAL TEMPORARY TABLE temp_val_id
(
	app_sid				NUMBER(10,0),
	val_id				NUMBER(10,0)
) ON COMMIT DELETE ROWS;

@..\region_body
    
@update_tail
