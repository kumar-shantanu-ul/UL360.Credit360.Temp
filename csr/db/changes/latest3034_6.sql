-- Please update version.sql too -- this keeps clean builds in sync
define version=3034
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.property_fund_ownership (
    app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	start_dtm						DATE NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	CONSTRAINT pk_property_fund_ownership PRIMARY KEY (app_sid, region_sid, fund_id, start_dtm),
    CONSTRAINT ck_ownerships CHECK (ownership >= 0 AND ownership <= 1)
);

CREATE TABLE csrimp.property_fund_ownership (
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	start_dtm						DATE NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	CONSTRAINT pk_property_fund_ownership PRIMARY KEY (csrimp_session_id, region_sid, fund_id, start_dtm),
	CONSTRAINT fk_property_fund_ownership FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

INSERT INTO csr.property_fund_ownership (app_sid, region_sid, fund_id, start_dtm, ownership)
	SELECT app_sid, region_sid, fund_id, DATE'1900-01-01', ownership
	  FROM csr.property_fund;

-- Alter tables
ALTER TABLE csr.property_fund DROP COLUMN ownership;
ALTER TABLE csr.property_fund_ownership ADD CONSTRAINT fk_pfo_pf
    FOREIGN KEY (app_sid, region_sid, fund_id)
    REFERENCES csr.property_fund(app_sid, region_sid, fund_id);

ALTER TABLE csrimp.property_fund DROP COLUMN ownership;

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.property_fund_ownership TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.property_fund_ownership TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$property_fund_ownership AS 
	SELECT fo.app_sid, 
		   fo.region_sid, 
		   fo.fund_id, 
		   f.name,
		   pf.container_sid,
		   fo.start_dtm, 
		   LEAD(fo.start_dtm) OVER (PARTITION BY fo.app_sid, fo.region_sid, fo.fund_id 
										ORDER BY fo.start_dtm) end_dtm, 
		   fo.ownership
	  FROM property_fund_ownership fo
	  JOIN property_fund pf ON fo.app_sid = pf.app_sid AND pf.region_sid = fo.region_sid AND fo.fund_id = pf.fund_id
	  JOIN fund f ON fo.app_sid = f.app_sid AND fo.fund_id = f.fund_id
	 ORDER BY fo.region_sid, fo.fund_id, fo.start_dtm;

-- csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency, r.geo_type,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, pf.fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id,
        pt.lookup_key property_type_lookup_key,
        p.energy_star_sync, p.energy_star_push
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
		LEFT JOIN (
			-- In the case of multiple fund ownership, the "default" fund is the fund with the highest
			-- current ownership. Where multiple funds have the same ownership, the default is the 
			-- fund that was created first. Fund ID is retained for compatibility with pre-multi 
			-- ownership code.
			SELECT
				app_sid, region_sid, fund_id, ownership,
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid
								   ORDER BY start_dtm DESC, ownership DESC, fund_id ASC) priority
			FROM csr.property_fund_ownership
		) pf ON pf.app_sid = r.app_sid AND pf.region_sid = r.region_sid AND pf.priority = 1;


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_pkg
@../schema_pkg

@../csr_app_body
@../csrimp/imp_body
@../property_body
@../region_body
@../schema_body

@update_tail
