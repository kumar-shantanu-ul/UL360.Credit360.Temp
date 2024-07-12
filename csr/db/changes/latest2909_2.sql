-- Please update version.sql too -- this keeps clean builds in sync
define version=2909
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE CSR.GRESB_SUBMISSION_SEQ 
	START WITH 1 
	INCREMENT BY 1
	ORDER; 
-- convienient for auditing 

CREATE TABLE CSR.GRESB_PROPERTY_TYPE (
	NAME	VARCHAR2(255),
	CODE	VARCHAR2(255),
	CONSTRAINT PK_GRESB_PROP_TYPE PRIMARY KEY (CODE)
);

CREATE TABLE CSR.GRESB_INDICATOR_TYPE (
	GRESB_INDICATOR_TYPE_ID				NUMBER(10, 0) NOT NULL,
	TITLE								VARCHAR2(255) NOT NULL,
	REQUIRED							NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_GRESB_INDICATOR_TYPE PRIMARY KEY (GRESB_INDICATOR_TYPE_ID)
);

CREATE TABLE CSR.GRESB_INDICATOR (
	GRESB_INDICATOR_ID				NUMBER(10, 0) NOT NULL,
	GRESB_INDICATOR_TYPE_ID			NUMBER(10, 0) NOT NULL,
	TITLE							VARCHAR2(255) NOT NULL,
	FORMAT							VARCHAR2(255),
	DESCRIPTION						VARCHAR2(4000),
	UNIT							VARCHAR2(255),
	STD_MEASURE_CONVERSION_ID		NUMBER(10,0),
	CONSTRAINT PK_GRESB_INDICATOR PRIMARY KEY (GRESB_INDICATOR_ID),
	CONSTRAINT FK_GI_STD_MC FOREIGN KEY (STD_MEASURE_CONVERSION_ID) REFERENCES CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID),
	CONSTRAINT FK_GI_GIT FOREIGN KEY (GRESB_INDICATOR_TYPE_ID) REFERENCES CSR.GRESB_INDICATOR_TYPE (GRESB_INDICATOR_TYPE_ID)
);

CREATE TABLE CSR.GRESB_ERROR (
	GRESB_ERROR_ID					VARCHAR2(255) NOT NULL,
	DESCRIPTION						VARCHAR2(4000) NULL,
	CONSTRAINT PK_GRESB_ERROR PRIMARY KEY (GRESB_ERROR_ID)
);

CREATE TABLE CSR.GRESB_INDICATOR_MAPPING (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	GRESB_INDICATOR_ID				NUMBER(10, 0) NOT NULL,
	IND_SID							NUMBER(10, 0),
	MEASURE_CONVERSION_ID			NUMBER(10, 0),
	NOT_APPLICABLE					NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_GRESB_INDICATOR_MAPPING PRIMARY KEY (APP_SID, GRESB_INDICATOR_ID),
	CONSTRAINT FK_GIM_GI FOREIGN KEY (GRESB_INDICATOR_ID) REFERENCES CSR.GRESB_INDICATOR (GRESB_INDICATOR_ID),
	CONSTRAINT FK_GIM_IND FOREIGN KEY (APP_SID, IND_SID) REFERENCES CSR.IND (APP_SID, IND_SID),
	CONSTRAINT FK_GIM_MC FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID) REFERENCES CSR.MEASURE_CONVERSION (APP_SID, MEASURE_CONVERSION_ID)
);

CREATE TABLE CSR.GRESB_SUBMISSION_LOG (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	GRESB_SUBMISSION_ID				NUMBER(10, 0) NOT NULL,
	GRESB_RESPONSE_ID				VARCHAR2(255) NOT NULL,
	SUBMISSION_TYPE					NUMBER(10, 0) NOT NULL,
	SUBMISSION_DATE					DATE NOT NULL,
	SUBMISSION_DATA					CLOB NULL,
	CONSTRAINT PK_GRESB_SUBMISSION_LOG PRIMARY KEY (APP_SID, GRESB_SUBMISSION_ID),
	CONSTRAINT CK_SUBMISSION_TYPE_VALID CHECK (SUBMISSION_TYPE IN (0, 1))
);

CREATE TABLE csr.property_fund (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	container_sid					NUMBER(10, 0) NULL,
	CONSTRAINT pk_property_fund PRIMARY KEY (app_sid, region_sid, fund_id),
	CONSTRAINT fk_property_fund_region FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_property_fund_fund FOREIGN KEY (app_sid, fund_id) REFERENCES csr.fund (app_sid, fund_id),
	CONSTRAINT fk_property_fund_container FOREIGN KEY (app_sid, container_sid) REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT ck_ownership CHECK (ownership > 0 AND ownership <= 1)
);
CREATE INDEX csr.ix_property_fund_fund_id ON csr.property_fund (app_sid, fund_id);

CREATE TABLE CSRIMP.MAP_GRESB_SUBMISSION_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_GRESB_SUBMISSION_ID NUMBER(10) NOT NULL,
	NEW_GRESB_SUBMISSION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_GRESB_SUBMISSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_GRESB_SUBMISSION_ID) USING INDEX,
	CONSTRAINT FK_MAP_GRESB_SUBMISSION_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.GRESB_INDICATOR_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GRESB_INDICATOR_ID				NUMBER(10, 0) NOT NULL,
	IND_SID							NUMBER(10, 0) NOT NULL,
	MEASURE_CONVERSION_ID			NUMBER(10, 0),
	NOT_APPLICABLE					NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT PK_GRESB_INDICATOR_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, GRESB_INDICATOR_ID),
	CONSTRAINT FK_GRESB_INDICATOR_MAPPING FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.GRESB_SUBMISSION_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GRESB_SUBMISSION_ID				NUMBER(10, 0) NOT NULL,
	GRESB_RESPONSE_ID				VARCHAR2(255) NOT NULL,
	SUBMISSION_TYPE					NUMBER(10, 0) NOT NULL,
	SUBMISSION_DATE					DATE NOT NULL,
	SUBMISSION_DATA					CLOB NULL,
	CONSTRAINT PK_GRESB_SUBMISSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, GRESB_SUBMISSION_ID),
	CONSTRAINT FK_GRESB_SUBMISSION_LOG FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.property_fund (
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	fund_id							NUMBER(10, 0) NOT NULL,
	ownership						NUMBER(29, 28) NOT NULL,
	container_sid					NUMBER(10, 0) NULL,
	CONSTRAINT pk_property_fund		PRIMARY KEY (csrimp_session_id, region_sid, fund_id),
	CONSTRAINT fk_property_fund		FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csr.gresb_service_config (
	name							VARCHAR2(255) NOT NULL,
	url								VARCHAR2(255) NOT NULL,
	client_id						VARCHAR2(255) NOT NULL,
	client_secret					VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_gresb_service_config PRIMARY KEY (name)
);

CREATE UNIQUE INDEX csr.ix_gresb_service_config_name ON csr.gresb_service_config(LOWER(name));

-- Alter tables
ALTER TABLE CSR.PROPERTY_TYPE
ADD (GRESB_PROP_TYPE_CODE VARCHAR2(255));

ALTER TABLE CSR.PROPERTY_TYPE
ADD CONSTRAINT FK_PROP_TYPE_GRESB_PROP_TYPE FOREIGN KEY (GRESB_PROP_TYPE_CODE)
REFERENCES CSR.GRESB_PROPERTY_TYPE(CODE);

ALTER TABLE csr.fund ADD (
	region_sid NUMBER(10, 0) NULL,
	CONSTRAINT fk_fund_region 
		FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid));

-- Mutliple ownership is disabled for existing customers, enabled for new customers.
ALTER TABLE csr.property_options ADD (enable_multi_fund_ownership NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.property_options MODIFY (enable_multi_fund_ownership DEFAULT 1);

ALTER TABLE csr.property_options ADD (
	gresb_service_config			VARCHAR2(255),
	CONSTRAINT fk_prop_optns_gresb_srvc_cfg FOREIGN KEY (gresb_service_config)
		REFERENCES csr.gresb_service_config (name)
);

-- Missing from csrimp schema - make conditional as exists on live.
DECLARE
	v_count		NUMBER;
BEGIN
	SELECT COUNT(column_name)
	  INTO v_count
	  FROM all_tab_cols
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'PROPERTY_TYPE'
	   AND column_name = 'LOOKUP_KEY';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.PROPERTY_TYPE ADD LOOKUP_KEY VARCHAR2(255)';
	END IF;
END;
/

ALTER TABLE CSRIMP.PROPERTY_TYPE
ADD GRESB_PROP_TYPE_CODE VARCHAR2(255);

ALTER TABLE csr.region_tree ADD (is_fund NUMBER(1, 0) DEFAULT 0 NOT NULL);

ALTER TABLE csr.all_property RENAME COLUMN fund_id TO obsolete_fund_id;

ALTER TABLE csrimp.property_options ADD (
	enable_multi_fund_ownership		NUMBER(1, 0) DEFAULT 1 NOT NULL,
	properties_geo_map_sid			NUMBER(10) NULL,
	gresb_service_config			VARCHAR2(255) NULL
);
ALTER TABLE csrimp.fund ADD (region_sid NUMBER(10, 0) NULL);
ALTER TABLE csrimp.region_tree ADD (is_fund NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.property DROP (fund_id);

create index csr.ix_property_fund_container_sid on csr.property_fund (app_sid, container_sid);
create index csr.ix_property_opti_gresb_service on csr.property_options (gresb_service_config);
create index csr.ix_property_type_gresb_prop_ty on csr.property_type (gresb_prop_type_code);
create index csr.ix_gresb_indicat_type_id on csr.gresb_indicator (gresb_indicator_type_id);
create index csr.ix_gresb_indicat_std_measure_c on csr.gresb_indicator (std_measure_conversion_id);
create index csr.ix_gresb_indicat_indicat_id on csr.gresb_indicator_mapping (gresb_indicator_id);
create index csr.ix_gresb_indicat_measure_conve on csr.gresb_indicator_mapping (app_sid, measure_conversion_id);
create index csr.ix_gresb_indicat_ind_sid on csr.gresb_indicator_mapping (app_sid, ind_sid);
create index csr.ix_fund_region_sid on csr.fund (app_sid, region_sid);

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.gresb_indicator_mapping TO web_user;
GRANT SELECT, INSERT, UPDATE ON csr.gresb_indicator_mapping TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.gresb_submission_log to csrimp;
GRANT SELECT ON csr.gresb_submission_seq to csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.gresb_indicator_mapping to web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.gresb_submission_log to web_user;
grant select, insert, update on csr.property_fund to csrimp;
grant select, insert, update, delete on csrimp.property_fund to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- csr/db/create_views.sql
CREATE OR REPLACE VIEW CSR.PROPERTY
	(APP_SID, REGION_SID, FLOW_ITEM_ID,
	 STREET_ADDR_1, STREET_ADDR_2, CITY, STATE, POSTCODE,
	 COMPANY_SID, PROPERTY_TYPE_ID, PROPERTY_SUB_TYPE_ID,
	 MGMT_COMPANY_ID, MGMT_COMPANY_OTHER,
	 PM_BUILDING_ID, CURRENT_LEASE_ID, MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH) AS
  SELECT ALP.APP_SID, ALP.REGION_SID, ALP.FLOW_ITEM_ID,
	 ALP.STREET_ADDR_1, ALP.STREET_ADDR_2, ALP.CITY, ALP.STATE, ALP.POSTCODE,
	 ALP.COMPANY_SID, ALP.PROPERTY_TYPE_ID, ALP.PROPERTY_SUB_TYPE_ID,
	 ALP.MGMT_COMPANY_ID, ALP.MGMT_COMPANY_OTHER,
	 ALP.PM_BUILDING_ID, ALP.CURRENT_LEASE_ID, ALP.MGMT_COMPANY_CONTACT_ID,
	 ENERGY_STAR_SYNC, ENERGY_STAR_PUSH
    FROM ALL_PROPERTY ALP JOIN region r ON r.region_sid = alp.region_sid
   WHERE r.region_type = 3;

-- csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, r.region_ref, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
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
			-- ownership. Where multiple funds have the same ownership, the default is the fund that was 
			-- created first. Fund ID is retained for compatability with pre-multi ownership code.
			SELECT 
				app_sid, region_sid, fund_id, ownership,
				ROW_NUMBER() OVER (PARTITION BY app_sid, region_sid 
								   ORDER BY ownership DESC, fund_id ASC) priority 
			FROM csr.property_fund 
		) pf ON pf.app_sid = r.app_sid AND pf.region_sid = r.region_sid AND pf.priority = 1;

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.property_fund (app_sid, region_sid, fund_id, ownership)
	SELECT app_sid, region_sid, obsolete_fund_id, 1
	  FROM csr.all_property
	 WHERE obsolete_fund_id IS NOT NULL;

INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('accepted', 'A boolean field must be set');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('blank', 'Cannot be blank');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('confirmation', 'Value must match {0}’s value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('cov_lt_tot', 'Maximum Coverage must be greater than or equal to Data Coverage');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('cov_value_required', 'All fields (value, max coverage, and total coverage) must be provided if any are provided');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('empty', 'Cannot be blank or an empty collection');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('equal_to', 'Value must be exactly {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('even', 'Must be even');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('exclusion', 'The value is one of the attributes excluded values');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('field_invalid', 'The field name is not valid');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than', 'Must be greater than {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than_or_equal_to', 'Must be greater than or equal to {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('inclusion', 'Must be one of the attributes permitted value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('invalid', 'Is not a valid value');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('less_than', 'Must be less than {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('less_than_or_equal_to', 'Must be less than or equal to {0}');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('months_in_year', 'Must be within a year (12 months)');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_a_number', 'Must be a number');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_an_integer', 'Must be an integer');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('odd', 'Must be odd');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('other_than', 'The value is the wrong length. It must not be {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('percentage_lte_100', 'Must be less than or equal to 100%');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('present', 'Must be blank');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('record_invalid', 'There is some unspecified problem with the record. More details me be present on other attributes');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('restrict_dependent_destroy', 'The record could not be deleted because a {0} depends on it');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('taken', 'The value must be unique and has already been used in this context');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('too_long', 'The value is too long. It must be at most {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('too_short', 'The value is too short. It must be at least {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('wrong_length', 'The value is the wrong length. It must be exactly {0} characters');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('waste_lte_100', 'Total waste disposal must be less than or equal to 100%');
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('waste_alloc', 'Waste management data cannot be provided for both Managed and Indirectly Managed columns');

-- GRESB documentation says "Must be negative", but this seems to be a mistake
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('not_negative', 'Must not be negative'); 

-- This one is not documented 
INSERT INTO csr.gresb_error (gresb_error_id, description) VALUES ('greater_than_zero', 'Must be greater than zero'); 

INSERT INTO csr.gresb_property_type (name, code) VALUES ('Retail, High Street', 'RHS');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Retail, Shopping Center', 'RSM');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Retail, Warehouse', 'RWB');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Office', 'OFF');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Industrial, Distribution Warehouse', 'DWH');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Industrial, Business Parks', 'BUS');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Industrial, Manufacturing', 'MAN');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Multi-family', 'RMF');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Family Houses', 'RFA');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Senior Houses', 'RSE');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Residential, Student Houses', 'RST');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Hotel', 'HOT');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Healthcare', 'HEC');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Medical Office', 'MED');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Leisure', 'LEI');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Data Centers', 'DAT');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Self-storage', 'SST');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Parking (indoors)', 'PAR');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Other', 'OTH');
INSERT INTO csr.gresb_property_type (name, code) VALUES ('Other 2', 'OT2');

INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (1, 'Property', 1);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (2, 'Energy', 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (3, 'GHG', 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (4, 'Water', 0);
INSERT INTO csr.gresb_indicator_type(gresb_indicator_type_id, title, required) VALUES (5, 'Waste', 0);

INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (103, 1, 'asset_size', 'x > 0', 'The total floor area of an asset in square meters. See the GRESB Survey Guidance for further information.', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (104, 1, 'major_renovation', '[Y, N, null]', 'Has the building been involved in any major renovation? This should be a checkbox or list indicator, or alternatively a date or numeric indicator containing the year of the last major renovation.', ' ', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (1, 2, 'en_man_bcf_abs', 'x > 0', 'Fuel consumption from all common areas of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (2, 2, 'en_man_bcf_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (en_man_bcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (3, 2, 'en_man_bcf_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (en_man_bcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (4, 2, 'en_man_bcd_abs', 'x > 0', 'District heating and cooling consumption from all common areas of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (5, 2, 'en_man_bcd_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (en_man_bcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (6, 2, 'en_man_bcd_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (en_man_bcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (7, 2, 'en_man_bce_abs', 'x > 0', 'Electricity consumption from all common areas of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (8, 2, 'en_man_bce_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (en_man_bce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (9, 2, 'en_man_bce_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (en_man_bce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (10, 2, 'en_man_bsf_abs', 'x > 0', 'Fuel consumption from all shared services or central plants of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (11, 2, 'en_man_bsf_cov', 'x > 0', 'Data coverage area of the shared services or central plant specified in the field above (en_man_bsf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (12, 2, 'en_man_bsf_tot', 'x > 0', 'Maximum coverage area of shared services or the central plant specified in the field above (en_man_bsf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (13, 2, 'en_man_bsd_abs', 'x > 0', 'District heating and cooling consumption from all shared services or central plants of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (14, 2, 'en_man_bsd_cov', 'x > 0', 'Data coverage area of the shared services or the central plant specified in the field above (en_man_bsd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (15, 2, 'en_man_bsd_tot', 'x > 0', 'Maximum coverage area of the shared services or the central plant specified in the field above (en_man_bsd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (16, 2, 'en_man_bse_abs', 'x > 0', 'Electricity consumption from all shared services or central plants of the base building over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (17, 2, 'en_man_bse_cov', 'x > 0', 'Data coverage area of the shared services or the central plant specified in the field above (en_man_bse_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (18, 2, 'en_man_bse_tot', 'x > 0', 'Maximum coverage area of the shared services or the central plant specified in the field above (en_man_bse_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (19, 2, 'en_man_bof_abs', 'x > 0', 'Fuel consumption from outdoor, exterior and parking areas of the asset over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (20, 2, 'en_man_boe_abs', 'x > 0', 'Electricity consumption from outdoor, exterior, and parking areas of the asset over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (21, 2, 'en_man_tlf_abs', 'x > 0', 'Fuel consumption of tenant space purchased by landlords over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (22, 2, 'en_man_tlf_cov', 'x > 0', 'Data coverage area of the tenant space purchased by landlords specified in the field above (en_man_tlf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (23, 2, 'en_man_tlf_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tlf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (24, 2, 'en_man_tld_abs', 'x > 0', 'District heating and cooling consumption of tenant space purchased by a landlord over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (25, 2, 'en_man_tld_cov', 'x > 0', 'Data coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tld_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (26, 2, 'en_man_tld_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tld_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (27, 2, 'en_man_tle_abs', 'x > 0', 'Electricity consumption of tenant space purchased by a landlord over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (28, 2, 'en_man_tle_cov', 'x > 0', 'Data coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tle_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (29, 2, 'en_man_tle_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by a landlord specified in the field above (en_man_tle_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (30, 2, 'en_man_ttf_abs', 'x > 0', 'Fuel consumption of tenant space purchased by tenants over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (31, 2, 'en_man_ttf_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (32, 2, 'en_man_ttf_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (33, 2, 'en_man_ttd_abs', 'x > 0', 'District heating and cooling consumption of tenant space purchased by tenants over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (34, 2, 'en_man_ttd_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (35, 2, 'en_man_ttd_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (en_man_ttd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (36, 2, 'en_man_tte_abs', 'x > 0', 'Electricity consumption of tenant space purchased by tenants over the current year. Measured in kWh. Applies only to managed assets.', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (37, 2, 'en_man_tte_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (en_man_tte_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (38, 2, 'en_man_tte_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (en_man_tte_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (39, 2, 'en_man_wcf_abs', 'x > 0', 'Fuel consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (40, 2, 'en_man_wcf_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_man_wcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (41, 2, 'en_man_wcf_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_man_wcf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (42, 2, 'en_man_wcd_abs', 'x > 0', 'District heating and cooling consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (43, 2, 'en_man_wcd_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_man_wcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (44, 2, 'en_man_wcd_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_man_wcd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (45, 2, 'en_man_wce_abs', 'x > 0', 'Electricity consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (46, 2, 'en_man_wce_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_man_wce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (47, 2, 'en_man_wce_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_man_wce_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (48, 2, 'en_ind_wwf_abs', 'x > 0', 'Fuel consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (49, 2, 'en_ind_wwf_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_ind_wwf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (50, 2, 'en_ind_wwf_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_ind_wwf_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (51, 2, 'en_ind_wwd_abs', 'x > 0', 'District heating and cooling consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (52, 2, 'en_ind_wwd_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_ind_wwd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (53, 2, 'en_ind_wwd_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_ind_wwd_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (54, 2, 'en_ind_wwe_abs', 'x > 0', 'Electricity consumption within the rational building (tenant space and common areas combined) over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (55, 2, 'en_ind_wwe_cov', 'x > 0', 'Data coverage area of the rational building specified in the field above (en_ind_wwe_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (56, 2, 'en_ind_wwe_tot', 'x > 0', 'Maximum coverage area of the rational building specified in the field above (en_ind_wwe_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (57, 2, 'en_ind_wof_abs', 'x > 0', 'Fuel consumption of outdoor, exterior, and parking areas over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (58, 2, 'en_ind_woe_abs', 'x > 0', 'Electricity consumption of outdoor, exterior, and parking areas over the current year. Measured in kWh. Applies only to indirectly managed assets', 'kWh', 8);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (59, 3, 'ghg_s1_abs', 'x > 0', 'Scope 1 greenhouse gas emissions over the current year. Scope 1 is defined as all direct GHG emissions of the asset. Measured in metric tonnes. Applies to all assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (60, 3, 'ghg_s1_cov', 'x > 0', 'Data coverage area of the asset specified in the field above (ghg_s1_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (61, 3, 'ghg_s1_tot', 'x > 0', 'Maximum coverage area of the asset specified in the field above (ghg_s1_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (62, 3, 'ghg_s2_abs', 'x > 0', 'Scope 2 greenhouse gas emissions of the asset over the current year. Scope 2 is defined as indirect GHG emissions as a result of purchased electricity, heat, and steam. Measured in metric tonnes. Applies to all assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (63, 3, 'ghg_s2_cov', 'x > 0', 'Data coverage area of the asset specified in the field above (ghg_s2_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (64, 3, 'ghg_s2_tot', 'x > 0', 'Maximum coverage area of the asset specified in the field above (ghg_s2_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (65, 3, 'ghg_s3_abs', 'x > 0', 'Scope 3 greenhouse gas emissions over the current year. Scope 3 is defined as all indirect GHG emissions that do not result from the purchase of electricity, heat, or steam. Scope 3 does not apply to all assets. Measured in metric tonnes', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (66, 3, 'ghg_s3_cov', 'x > 0', 'Data coverage area of the asset specified in the field above (ghg_s3_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (67, 3, 'ghg_s3_tot', 'x > 0', 'Maximum coverage area of the asset specified in the field above (ghg_s3_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (68, 3, 'ghg_offset_abs', 'x > 0', 'The greenhouse gas offset purchased for the asset over the current year. Greenhouse gas offset is defined as the purchased reduction in greenhouse gases in order to offset the emissions made at the asset. Measured in metric tonnes. Applies to all assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (69, 3, 'ghg_net_abs', 'x > 0', 'The net greenhouse gas emissions for the asset after purchasing the greenhouse gas offsets.', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (70, 4, 'wat_man_bc_abs', 'x > 0', 'Water consumption of all common areas within the base building over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (71, 4, 'wat_man_bc_cov', 'x > 0', 'Data coverage area of the common areas specified in the field above (wat_man_bc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (72, 4, 'wat_man_bc_tot', 'x > 0', 'Maximum coverage area of the common areas specified in the field above (wat_man_bc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (73, 4, 'wat_man_bs_abs', 'x > 0', 'Water consumption of all shared services/ central plant areas within the base building over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (74, 4, 'wat_man_bs_cov', 'x > 0', 'Data coverage area of the shared services/ central plant areas specified in the field above (wat_man_bs_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (75, 4, 'wat_man_bs_tot', 'x > 0', 'Maximum coverage area of the shared services/ central plant areas specified in the field above (wat_man_bs_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (76, 4, 'wat_man_bo_abs', 'x > 0', 'Water consumption of all exterior or outdoor areas of the asset over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (77, 4, 'wat_man_tl_abs', 'x > 0', 'Water consumption of tenant space purchase by landlords over the current year. Measure in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (78, 4, 'wat_man_tl_cov', 'x > 0', 'Data coverage area of the tenant space purchased by landlords specified in the field above (wat_man_tl_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (79, 4, 'wat_man_tl_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by landlords specified in the field above (wat_man_tl_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (80, 4, 'wat_man_tt_abs', 'x > 0', 'Water consumption of tenant space purchase by tenants over the current year. Measure in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (81, 4, 'wat_man_tt_cov', 'x > 0', 'Data coverage area of the tenant space purchased by tenants specified in the field above (wat_man_tt_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (82, 4, 'wat_man_tt_tot', 'x > 0', 'Maximum coverage area of the tenant space purchased by tenants specified in the field above (wat_man_tt_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (83, 4, 'wat_man_wc_abs', 'x > 0', 'Water consumption of the rational building (tenant space and common areas combined) over the current year. Measured in cubic meters. Applies only to managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (84, 4, 'wat_man_wc_cov', 'x > 0', 'Data coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_man_wc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (85, 4, 'wat_man_wc_tot', 'x > 0', 'Maximum coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_man_wc_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (86, 4, 'wat_ind_ww_abs', 'x > 0', 'Water consumption of the rational building (tenant space and common areas combined) over the current year. Measured in cubic meters. Applies only to indirectly managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (87, 4, 'wat_ind_ww_cov', 'x > 0', 'Data coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_ind_ww_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (88, 4, 'wat_ind_ww_tot', 'x > 0', 'Maximum coverage area of the rational building (tenant space and common areas combined) specified in the field above (wat_ind_ww_abs)', 'm'||UNISTR('\00B2')||'', 27);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (89, 4, 'wat_ind_wo_abs', 'x > 0', 'Water consumption of outdoor or exterior areas of the asset over the current year. Measured in cubic meters. Applies only to indirectly managed assets', 'm'||UNISTR('\00B3')||'', 9);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (90, 5, 'was_man_haz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (91, 5, 'was_man_nhaz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of non-hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (92, 5, 'was_man_perc', '0 < x '||UNISTR('\2264')||' 100', 'Percent of the asset covered by the data above (was_man_haz_abs), (was_man_nhaz_abs) . Based on floor area covered / total floor area.', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (93, 5, 'was_ind_haz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to indirectly managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (94, 5, 'was_ind_nhaz_abs', 'x '||UNISTR('\2265')||' 0', 'The total weight of non-hazardous waste produced by the asset over the current year. Measured in metric tonnes. Applies only to indirectly managed assets', 'tonnes', 4);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (95, 5, 'was_ind_perc', '0 < x '||UNISTR('\2264')||' 100', 'Percent of the asset covered by the data above (was_man_haz_abs), (was_man_nhaz_abs) . Based on floor area covered / total floor area.', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (96, 5, 'was_i_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste disposed via incineration over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (97, 5, 'was_l_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste disposed via landfills over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (98, 5, 'was_wd_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted from landfills over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (99, 5, 'was_dwe_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted through converting waste to energy over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (100, 5, 'was_dr_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted through recycling over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (101, 5, 'was_do_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste diverted through other methods over the current year. Applies to all assets', '%', NULL);
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id) VALUES (102, 5, 'was_oth_perc', '0 '||UNISTR('\2264')||' x '||UNISTR('\2264')||' 100', 'Percent of waste disposed via other methods over the current year. Applies to all assets', '%', NULL);

COMMIT;

INSERT INTO csr.gresb_service_config (name, url, client_id, client_secret)
	 VALUES ('live', 'https://api.gresb.com', '97f9abc25fe4cdbbbf71120d2cea7e05f1c54043e6ff5b38c2fc5ece3cd8d6d0', '965590d32c7f52055c75de27087b8cbce6fe982e30ab02281bebee7e58b90720');
	 
INSERT INTO csr.gresb_service_config (name, url, client_id, client_secret)
	 VALUES ('sandbox', 'https://api-sandbox.gresb.com', '74efe6224867e4237ac20304b42b0989ccf8a18d1c20e08a86e8e8d2b1467d34', '7a5d844f78f4ae0e0eb138b335405957d42791928161f4ce79cdfb971f53619c');
COMMIT;

INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
		VALUES (65, 'GRESB', 'EnableGRESB', 'Enable GRESB property integration. Once enabled, the client''s site has to be added to the cr360 GRESB account, '||
		'by adding a new application under account settings, with the callback URL ''https://CLIENT_NAME.credit360.com/csr/site/property/gresb/authorise.acds''. '||
		'NOTE  - if enabling in a test environment, be sure to set the gresb_service_config from ''live'' to ''sandbox'' on the property_options table.', 1);
		
-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.gresb_config_pkg AS END;
/
GRANT EXECUTE ON csr.gresb_config_pkg TO web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../gresb_config_pkg
@../gresb_config_body
@../property_pkg
@../property_body
@../energy_star_body
@../schema_pkg
@../schema_body
@../csr_app_body
@../region_tree_body
@../supplier_body
@../property_report_body
@../csrimp/imp_body
@../enable_pkg
@../enable_body
@../stored_calc_datasource_body

@update_tail
