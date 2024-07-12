-- Please update version.sql too -- this keeps clean builds in sync
define version=3438
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.PACKAGED_CONTENT_SITE(
	APP_SID					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	VERSION					VARCHAR2(100) NOT NULL,
	PACKAGE_NAME			VARCHAR2(1024) NOT NULL,
	ENABLED_MODULES_JSON	CLOB,
	CONSTRAINT PK_PACKAGED_CONTENT_SITE PRIMARY KEY (APP_SID)
);

CREATE TABLE CSR.PACKAGED_CONTENT_OBJECT_MAP(
	APP_SID					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OBJECT_REF				VARCHAR2(1024) NOT NULL,
	CREATED_OBJECT_ID		NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_PACKAGED_CONTENT_OBJECT_MAP PRIMARY KEY (APP_SID, OBJECT_REF, CREATED_OBJECT_ID)
);

-- Alter tables

-- *** Grants ***
GRANT EXECUTE ON csr.capability_pkg to TOOL_USER;
GRANT EXECUTE ON csr.util_script_pkg to TOOL_USER;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (126, 'Delegation status overview', 'EnableDelegStatusOverview', 'Enables the delegation status overview page.');
END;
/

BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (127, 'Measure conversions page', 'EnableMeasureConversionsPage', 'Enable the measure conversions page.');
END;
/

BEGIN
	INSERT INTO csr.packaged_content_site
		(app_sid, version, enabled_modules_json, package_name)
	SELECT app_sid, version, enabled_modules_json, 'SustainabilityEssentials'
	  FROM csr.sustainability_essentials_enable;
END;
/

BEGIN
	INSERT INTO csr.packaged_content_object_map
		(app_sid, object_ref, created_object_id)
	SELECT app_sid, object_ref, created_object_id
	  FROM csr.sustainability_essentials_object_map;
END;
/

DROP TABLE csr.sustainability_essentials_object_map;
DROP TABLE csr.sustainability_essentials_enable;

-- ** New package grants **
create or replace package csr.packaged_content_pkg as
procedure dummy;
end;
/
create or replace package body csr.packaged_content_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON csr.packaged_content_pkg to TOOL_USER;

DROP PACKAGE csr.sustain_essentials_pkg;

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../issue_pkg
@../util_script_pkg
@../packaged_content_pkg

@../enable_body
@../issue_body
@../util_script_body
@../packaged_content_body

@update_tail
