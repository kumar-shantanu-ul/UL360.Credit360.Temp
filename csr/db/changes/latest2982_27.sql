-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.property_mandatory_roles (
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	role_sid						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_mandatory_roles PRIMARY KEY (app_sid, role_sid),
	CONSTRAINT fk_property_mandatory_roles
		FOREIGN KEY (app_sid, role_sid) 
		REFERENCES csr.role(app_sid, role_sid)
);

CREATE TABLE csrimp.property_mandatory_roles (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	role_sid						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_property_mandatory_roles PRIMARY KEY (csrimp_session_id, role_sid),
    CONSTRAINT fk_property_mandatory_roles
		FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id) 
		ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.metering_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_meter_show_inherited_roles CHECK(show_inherited_roles IN (1, 0))
);

ALTER TABLE csr.property_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL,
	CONSTRAINT ck_prop_show_inherited_roles CHECK(show_inherited_roles IN (1, 0))
);

ALTER TABLE csrimp.metering_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.property_options ADD (
	show_inherited_roles NUMBER(1, 0) DEFAULT 0 NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.role
   SET is_property_manager = 1
 WHERE is_metering = 1;

UPDATE csr.module 
   SET module_name = 'Properties - GRESB',
	   description = 'Enables GRESB integration for property module. See <a href="http://emu.helpdocsonline.com/GRESB">http://emu.helpdocsonline.com/GRESB</a> for instructions.'
 WHERE module_id = 65;

UPDATE csr.module 
   SET module_name = 'Properties - Energy Star',
	   description = 'Enables Energy Star integration for property module.'
 WHERE module_id = 66;

INSERT INTO csr.property_mandatory_roles (app_sid, role_sid)
	SELECT app_sid, role_sid 
	  FROM csr.role 
	 WHERE is_property_manager = 1;

GRANT SELECT, INSERT, UPDATE ON csr.property_mandatory_roles TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.property_mandatory_roles TO tool_user;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../role_pkg
@../property_pkg
@../meter_pkg
@../schema_pkg

@../role_body
@../property_body
@../meter_body
@../csr_app_body
@../schema_body
@../csrimp/imp_body

@update_tail
