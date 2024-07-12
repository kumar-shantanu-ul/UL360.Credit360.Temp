--Please update version.sql too -- this keeps clean builds in sync
define version=2742
@update_header

DROP TABLE CSR.TEMP_METER_CONSUMPTIONS;
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_CONSUMPTIONS(
	ID						NUMBER(10),
	START_DTM				DATE,
	END_DTM					DATE,
	CONSUMPTION				NUMBER(24,10),
	COST					NUMBER(24,10) NULL,
	IS_ESTIMATE				NUMBER(1),
	CHECK (IS_ESTIMATE IN (0,1))
) ON COMMIT DELETE ROWS;

@../energy_star_pkg

@../energy_star_body
@../energy_star_job_data_body
@../property_body
@../initiative_aggr_body
	
@update_tail
