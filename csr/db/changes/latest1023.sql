-- Please update version.sql too -- this keeps clean builds in sync
define version=1023
@update_header

-- THIS DATA SHOULD ACTUALLY HAVE A PERIOD ASSOCIATED WITH IT
-- WE CAN RETRIEVE THIS DATA FROM ENERGY STAR AT ANY TIME
-- SO THERE'S NO HARM IN DELETING IT IN OUR EST SCHEMA.
BEGIN
	DELETE FROM csr.est_building_metric;
END;
/

ALTER TABLE CSR.EST_BUILDING_METRIC DROP CONSTRAINT PK_EST_BUILDING_METRIC;

ALTER TABLE CSR.EST_BUILDING_METRIC ADD (
	PERIOD_END_DTM     DATE              NOT NULL,
	CONSTRAINT PK_EST_BUILDING_METRIC PRIMARY KEY (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, METRIC_NAME, PERIOD_END_DTM)
);

@../energy_star_pkg
@../energy_star_body

@update_tail
