-- Please update version.sql too -- this keeps clean builds in sync
define version=2559
@update_header

ALTER TABLE CSR.EST_OPTIONS ADD(
	AUTO_CREATE_PROP_TYPE     NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    AUTO_CREATE_SPACE_TYPE    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (AUTO_CREATE_PROP_TYPE IN(0,1)),
    CHECK (AUTO_CREATE_SPACE_TYPE IN(0,1))
);

ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP RENAME TO EST_PROPERTY_TYPE_MAP_OLD;
ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP_OLD DROP CONSTRAINT PK_EST_PROPERTY_TYPE_MAP;
ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP_OLD DROP CONSTRAINT FK_CUST_ESTPROPTYPEMAP;
ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP_OLD DROP CONSTRAINT FK_PROPST_ESTPROPTYPEMAP;


CREATE TABLE CSR.EST_PROPERTY_TYPE_MAP(
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROPERTY_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    EST_PROPERTY_TYPE    VARCHAR2(256)    NOT NULL,
    CONSTRAINT PK_EST_PROPERTY_TYPE_MAP PRIMARY KEY (APP_SID, PROPERTY_TYPE_ID, EST_PROPERTY_TYPE)
);

ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP ADD CONSTRAINT FK_CUST_ESTPROPTYPEMAP 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.EST_PROPERTY_TYPE_MAP ADD CONSTRAINT FK_PROPTYPE_EST_PROPTYPEMAP 
    FOREIGN KEY (APP_SID, PROPERTY_TYPE_ID)
    REFERENCES CSR.PROPERTY_TYPE(APP_SID, PROPERTY_TYPE_ID)
;

begin
	for r in (select * from all_indexes where owner='CSR' and index_name='IX_CUST_ESTPROPTYPEMAP') loop
		execute immediate 'drop index  CSR.IX_CUST_ESTPROPTYPEMAP';
	end loop;
end;
/

CREATE INDEX CSR.IX_CUST_ESTPROPTYPEMAP ON CSR.EST_PROPERTY_TYPE_MAP(APP_SID);
CREATE INDEX CSR.IX_PROPTYPE_EST_PROPTYPEMAP ON CSR.EST_PROPERTY_TYPE_MAP(APP_SID, PROPERTY_TYPE_ID);

ALTER TABLE CSR.EST_SPACE_TYPE_MAP ADD(
	IS_PUSH				NUMBER(10, 0) 		DEFAULT 0	NOT NULL,
	CHECK (IS_PUSH IN(0,1))
);

CREATE UNIQUE INDEX CSR.UK_SPACE_TYPE_MAP_DEFAULT ON CSR.EST_SPACE_TYPE_MAP(APP_SID, SPACE_TYPE_ID, DECODE(IS_PUSH, 0, EST_SPACE_TYPE, IS_PUSH))
;

BEGIN
	FOR r IN (
		SELECT app_sid, property_type_id, est_property_type
		  FROM csr.est_property_type_map_old
	) LOOP
		BEGIN
			INSERT INTO csr.est_property_type_map (app_sid, property_type_id, est_property_type)
			VALUES (r.app_sid, r.property_type_id, r.est_property_type);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

DROP TABLE CSR.EST_PROPERTY_TYPE_MAP_OLD;

CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;

@../property_pkg
@../energy_star_pkg

@../property_body
@../energy_star_body
@../energy_star_job_data_body
@../energy_star_attr_body


@update_tail
