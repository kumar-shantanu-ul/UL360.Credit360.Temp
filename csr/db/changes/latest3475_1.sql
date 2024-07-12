-- Please update version.sql too -- this keeps clean builds in sync
define version=3475
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Anonymise PII data', 1, 'Enable selection of users for anonymisation - DO NOT DISABLE IF ENABLED!');

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (81, 'Reset Anonymise PII data capability permissions', 'Resets the permissions on the Anonymise PII data capability, giving permissions to only Superadmin users.', 'ResetAnonymisePiiDataPermissions','');

DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	v_capabilities				security.security_pkg.T_SID_ID;
	v_anonymise_pii				security.security_pkg.T_SID_ID;
	PROCEDURE EnableCapability(
		in_capability  					IN	security.security_pkg.T_SO_NAME,
		in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
	)
	AS
		v_allow_by_default      csr.capability.allow_by_default%TYPE;
		v_capability_sid		security.security_pkg.T_SID_ID;
		v_capabilities_sid		security.security_pkg.T_SID_ID;
	BEGIN
		-- this also serves to check that the capability is valid
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;

		-- just create a sec obj of the right type in the right place
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				in_capability,
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				IF in_swallow_dup_exception = 0 THEN
					RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
				END IF;
		END;
	END;
BEGIN
	security.user_pkg.logonadmin();

	FOR r IN (
		SELECT DISTINCT application_sid_id, website_name
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		security.user_pkg.LogonAdmin(r.website_name);

		enablecapability('Anonymise PII data');

		v_act_id := security.security_pkg.GetAct;
		v_capabilities := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Capabilities');
		v_anonymise_pii := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities, 'Anonymise PII data');

		security.securableobject_pkg.SetFlags(v_act_id, v_anonymise_pii, 0);
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_anonymise_pii));
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_anonymise_pii), -1,
			security.security_pkg.ACE_TYPE_ALLOW,security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);

		security.user_pkg.LogonAdmin();
	END lOOP;

END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg
@..\util_script_body

@update_tail
