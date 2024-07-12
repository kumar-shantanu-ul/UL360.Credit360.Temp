-- Please update version.sql too -- this keeps clean builds in sync
define version=3458
define minor_version=0
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
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
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
    PROCEDURE DeleteCapability (
        in_name							VARCHAR2
    )
    AS
        v_act_id						security.security_pkg.T_ACT_ID;
        v_app_sid						security.security_pkg.T_SID_ID;
        v_capability_sid				security.security_pkg.T_SID_ID;
    BEGIN
		v_act_id := security.security_pkg.GetAct;
        v_app_sid := security.security_pkg.GetApp;
        BEGIN
            v_capability_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, '/Capabilities/' || in_name);
            security.securableobject_pkg.DeleteSO(v_act_id, v_capability_sid);
        EXCEPTION
            WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
        END;
    END;
BEGIN
	security.user_pkg.logonAdmin();
	
	FOR r IN (
		SELECT host, app_sid
		  FROM csr.customer c
		  JOIN security.website w ON c.host = w.website_name
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		v_groups_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
        
        -- delete updated capabilty ACE
		DeleteCapability('Enable Delegation Pin Board');
		-- enable capability
		EnableCapability('Manage the Delegation Pinboard');		
		-- grant permission to registered users
		security.acl_pkg.AddACE(
			v_act_id,
			security.acl_pkg.GetDACLIDForSID(
				security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Capabilities/Manage the Delegation Pinboard')),
			-1,
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid,
			security.security_pkg.PERMISSION_STANDARD_ALL
		);
		
		security.user_pkg.logonAdmin();
	END LOOP;
	
	security.user_pkg.logonAdmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
