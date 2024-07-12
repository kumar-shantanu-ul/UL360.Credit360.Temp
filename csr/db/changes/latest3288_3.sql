-- Please update version.sql too -- this keeps clean builds in sync
define version=3288
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.property_gresb(
	app_sid			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	region_sid		NUMBER(10, 0)	NOT NULL,
	asset_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_gresb PRIMARY KEY (app_sid, region_sid),
	CONSTRAINT uk_property_gresb_asset_id UNIQUE (app_sid, asset_id),
	CONSTRAINT fk_property_gresb_region FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid)
);

CREATE TABLE csrimp.property_gresb(
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10, 0)	NOT NULL,
	asset_id						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_gresb PRIMARY KEY (csrimp_session_id, region_sid),
	CONSTRAINT uk_property_gresb_asset_id UNIQUE (csrimp_session_id, asset_id),
	CONSTRAINT fk_property_gresb FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.property_gresb TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.property_gresb TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../property_pkg
@../schema_pkg

@../csrimp/imp_body
@../csr_app_body
@../property_body
@../property_report_body
@../region_body
@../schema_body

@update_tail
