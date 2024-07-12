-- Please update version.sql too -- this keeps clean builds in sync
define version=966
@update_header

ALTER TABLE CSR.EST_ENERGY_METER ADD (
	OTHER_DESC			VARCHAR2(512)
);

ALTER TABLE CSR.EST_ENERGY_TYPE_MAPPING ADD (
	DESC_IND_SID		NUMBER(10, 0)
);


ALTER TABLE CSR.EST_WATER_METER ADD (
	OTHER_DESC			VARCHAR2(512)
);

ALTER TABLE CSR.EST_WATER_USE_MAPPING ADD (
	DESC_IND_SID		NUMBER(10, 0)
);

ALTER TABLE CSR.EST_ENERGY_TYPE_MAPPING ADD CONSTRAINT FK_EST_ENTYP_DESCIND 
    FOREIGN KEY (APP_SID, DESC_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.EST_WATER_USE_MAPPING ADD CONSTRAINT FK_WUMAP_DESCIND 
    FOREIGN KEY (APP_SID, DESC_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

CREATE INDEX csr.ix_est_entyp_descind ON csr.est_energy_type_mapping (app_sid, desc_ind_sid);
CREATE INDEX csr.ix_wumap_descind ON csr.est_water_use_mapping (app_sid, desc_ind_sid);

@../energy_star_pkg
@../energy_star_body

@update_tail
