-- Please update version.sql too -- this keeps clean builds in sync
define version=3455
define minor_version=4
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
BEGIN
 INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION)
 VALUES ('Enable roll forward on indicators', 0, 'Enable the legacy functionality for roll forward on indicators. Do not ENABLE without reference to Product.');
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

DECLARE
	v_act_id_unused					security.security_pkg.T_ACT_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_reg_users_sid					security.security_pkg.T_SID_ID;
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
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath_(SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
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
	FOR r IN (
	SELECT host, app_sid
		  FROM csr.customer
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_groups_sid := security.securableobject_pkg.GetSIDFromPath_(r.app_sid, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSIDFromPath_(v_groups_sid, 'RegisteredUsers');
        
		-- enable capability
		  EnableCapability('Enable roll forward on indicators');		

		-- grant permission to registered users
			security.acl_pkg.AddACE(v_act_id_unused,
			security.acl_pkg.GetDACLIDForSID(
				security.securableobject_pkg.GetSIDFromPath_(r.app_sid, 'Capabilities/Enable roll forward on indicators')),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL);
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
