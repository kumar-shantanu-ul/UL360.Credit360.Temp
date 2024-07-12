-- Please update version.sql too -- this keeps clean builds in sync
define version=476
@update_header

ALTER TABLE factor
	MODIFY is_selected NOT NULL;
ALTER TABLE factor
	MODIFY geo_country NOT NULL;
ALTER TABLE factor
	MODIFY factor_type_id NOT NULL;
ALTER TABLE factor
	MODIFY end_dtm NULL;
	
ALTER TABLE std_factor
	MODIFY end_dtm NULL;
ALTER TABLE std_factor
	MODIFY geo_country NOT NULL;
ALTER TABLE std_factor
	MODIFY std_measure_conversion_id NOT NULL;

@update_tail
