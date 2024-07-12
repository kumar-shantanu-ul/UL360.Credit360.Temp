-- Please update version.sql too -- this keeps clean builds in sync
define version=569
@update_header

CREATE GLOBAL TEMPORARY TABLE factor_for_update (
	app_sid				NUMBER(10, 0)	NOT NULL,
	geo_country			VARCHAR2(2),
	geo_region			VARCHAR2(4)
) ON COMMIT DELETE ROWS;

@update_tail
