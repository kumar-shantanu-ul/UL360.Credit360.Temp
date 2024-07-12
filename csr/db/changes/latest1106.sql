-- Please update version.sql too -- this keeps clean builds in sync
define version=1106
@update_header

ALTER TABLE CSR.TEMP_METER_CONSUMPTIONS ADD (
	COST	NUMBER(24,10) NULL
);

@..\energy_star_pkg
@..\energy_star_body

@update_tail