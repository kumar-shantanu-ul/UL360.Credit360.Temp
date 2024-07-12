-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.compliance_regulation ADD (
	is_policy						NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT ck_is_policy			CHECK (is_policy IN (0,1))
);

ALTER TABLE csrimp.compliance_regulation ADD (
	is_policy						NUMBER(1)	NOT NULL,
	CONSTRAINT ck_is_policy			CHECK (is_policy IN (0,1))
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS
DECLARE
	PROCEDURE DeleteMenu(in_path	IN VARCHAR2) 
	AS
		v_menu_sid					security.security_pkg.T_SID_ID;
	BEGIN
		v_menu_sid := security.securableobject_pkg.GetSIDFromPath(
			in_act => security.security_pkg.GetAct,
			in_parent_sid_id => security.security_pkg.GetApp,
			in_path => in_path
		);
		security.securableobject_pkg.DeleteSO(
			in_act_id => security.security_pkg.GetAct,
			in_sid_id => v_menu_sid
		);
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN RETURN;
	END;
BEGIN
	security.user_pkg.LogonAdmin(NULL);

	FOR r IN (SELECT host
				FROM csr.customer c
				JOIN csr.compliance_options co ON c.app_sid = co.app_sid)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		DeleteMenu('menu/csr_compliance/csr_compliance_create_regulation');
		DeleteMenu('menu/csr_compliance/csr_compliance_create_requirement');
	END LOOP;

	security.user_pkg.LogonAdmin(NULL);
END;
/

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@../compliance_library_report_pkg
@@../compliance_library_report_body
@@../compliance_register_report_body
@@../compliance_pkg
@@../compliance_body
@@../enable_body
@@../schema_body
@@../csrimp/imp_body

@update_tail
