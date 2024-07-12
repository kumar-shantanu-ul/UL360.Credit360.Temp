-- Please update version.sql too -- this keeps clean builds in sync
define version=956
@update_header

ALTER TABLE CSR.EST_TRANSACTION ADD (
	METRICS_ONLY		NUMBER(1,0)		DEFAULT 0	NOT NULL,
	CHECK (METRICS_ONLY IN(0,1))
);

@../energy_star_pkg
@../energy_star_body

@update_tail
