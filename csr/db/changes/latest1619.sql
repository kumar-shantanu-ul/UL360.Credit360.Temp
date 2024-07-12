-- Please update version.sql too -- this keeps clean builds in sync
define version=1619
@update_header

ALTER TABLE csr.est_building MODIFY (
	mapping_error	VARCHAR2(4000)
);

ALTER TABLE csr.est_energy_meter MODIFY (
	mapping_error	VARCHAR2(4000)
);


ALTER TABLE csr.est_water_meter MODIFY (
	mapping_error	VARCHAR2(4000)
);

@update_tail
