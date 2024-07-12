-- Please update version.sql too -- this keeps clean builds in sync
define version=1928
@update_header

ALTER TABLE CSR.EST_SPACE ADD (
	MISSING            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (MISSING IN(0,1))
);

ALTER TABLE CSR.EST_ENERGY_METER ADD (
	MISSING            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (MISSING IN(0,1))
);

ALTER TABLE CSR.EST_WATER_METER ADD (
	MISSING            NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (MISSING IN(0,1))
);

create index csr.ix_est_building_prev_region_s on csr.est_building (app_sid, prev_region_sid);
create index csr.ix_est_energy_me_prev_region_s on csr.est_energy_meter (app_sid, prev_region_sid);
create index csr.ix_est_space_prev_region_s on csr.est_space (app_sid, prev_region_sid);
create index csr.ix_est_water_met_prev_region_s on csr.est_water_meter (app_sid, prev_region_sid);

@../energy_star_body

@update_tail