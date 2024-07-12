-- Please update version.sql too -- this keeps clean builds in sync
define version=491
@update_header

ALTER TABLE factor
	MODIFY geo_country NULL;

ALTER TABLE std_factor
	MODIFY geo_country NULL;

@update_tail
