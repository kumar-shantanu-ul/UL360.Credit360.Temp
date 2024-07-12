-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
CREATE OR REPLACE PROCEDURE csr.TEMP_EnableCapability(
	in_capability  					IN	security_pkg.T_SO_NAME,
	in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
)
AS
    v_allow_by_default      capability.allow_by_default%TYPE;
	v_capability_sid		security_pkg.T_SID_ID;
	v_capabilities_sid		security_pkg.T_SID_ID;
BEGIN
    -- this also serves to check that the capability is valid
    BEGIN
        SELECT allow_by_default
          INTO v_allow_by_default
          FROM capability
         WHERE LOWER(name) = LOWER(in_capability);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
	END;

    -- just create a sec obj of the right type in the right place
    BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
	EXCEPTION
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				SYS_CONTEXT('SECURITY','APP'), 
				security_pkg.SO_CONTAINER,
				'Capabilities',
				v_capabilities_sid
			);
	END;
	
	BEGIN
		securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
			v_capabilities_sid, 
			class_pkg.GetClassId('CSRCapability'),
			in_capability,
			v_capability_sid
		);
	EXCEPTION
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			IF in_swallow_dup_exception = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
			END IF;
	END;
END;
/

DECLARE
	v_host					VARCHAR2(255);
	v_capability_sid		NUMBER;
BEGIN
	security.user_pkg.logonAdmin();

	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.initiatives_options
	)
	LOOP
		SELECT host
		  INTO v_host
		  FROM csr.customer
		 WHERE app_sid = r.app_sid;
		
		security.user_pkg.logonAdmin(v_host);
		
		csr.TEMP_EnableCapability('Can import initiatives', 1);
		csr.TEMP_EnableCapability('Can purge initiatives', 1);
		csr.TEMP_EnableCapability('View initiatives audit log', 1);
		csr.TEMP_EnableCapability('Create users for approval', 1);
		
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/

DROP PROCEDURE csr.TEMP_EnableCapability;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\enable_body

@update_tail
