-- Please update version.sql too -- this keeps clean builds in sync
define version=1570
@update_header

ALTER TABLE CSR.PROPERTY ADD (
	PM_BUILDING_ID          VARCHAR2(256)
);

@../energy_star_body

@update_tail
