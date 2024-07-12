--Please update version.sql too -- this keeps clean builds in sync
define version=2706
@update_header

ALTER TABLE CSR.EST_BUILDING ADD(
	SOURCE_PM_CUSTOMER_ID    VARCHAR2(256)
);

ALTER TABLE CSR.EST_METER ADD(
	SOURCE_PM_CUSTOMER_ID    VARCHAR2(256)
);


@../energy_star_pkg
@../energy_star_body
	
@update_tail
