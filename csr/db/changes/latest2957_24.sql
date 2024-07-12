-- Please update version.sql too -- this keeps clean builds in sync
define version=2957
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.factor ADD (
	custom_factor_id	NUMBER(10)
);

ALTER TABLE csr.factor ADD CONSTRAINT fk_factor_custom_factor 
    FOREIGN KEY (app_sid, custom_factor_id)
    REFERENCES csr.custom_factor(app_sid, custom_factor_id)
;

ALTER TABLE csrimp.factor ADD (
	custom_factor_id	NUMBER(10)
);

ALTER TABLE csr.custom_factor_set ADD (
	created_by_sid		NUMBER(10), 
	created_dtm			DATE
);

ALTER TABLE csr.custom_factor_set ADD CONSTRAINT fk_custom_factor_set_user
    FOREIGN KEY (app_sid, created_by_sid)
    REFERENCES csr.csr_user(app_sid, csr_user_sid);
	
ALTER TABLE csrimp.custom_factor_set ADD (
	created_by_sid		NUMBER(10), 
	created_dtm			DATE
);

ALTER SEQUENCE csr.factor_set_id_seq INCREMENT BY +998;
SELECT csr.factor_set_id_seq.NEXTVAL FROM dual;
ALTER SEQUENCE csr.factor_set_id_seq INCREMENT BY 1;

ALTER SEQUENCE csr.factor_set_grp_id_seq INCREMENT BY +998;
SELECT csr.factor_set_grp_id_seq.NEXTVAL FROM dual;
ALTER SEQUENCE csr.factor_set_grp_id_seq INCREMENT BY 1;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
SET DEFINE OFF
BEGIN
	
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (1, 'Brazilian Agricultural Yearbook');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (2, 'Australia National Greenhouse Accounts (NGA)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (3, 'Canada National Inventory Report ');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (4, 'China National Bureau of Statistics');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (5, 'US Environmental Protection Agency (EPA) Climate Leaders');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (6, 'US Environmental Protection Agency (EPA) Egrid');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (7, 'Greenhouse Gas Protocol');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (8, 'Intergovernmental Panel on Climate Change (IPCC)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (9, 'International Energy Agency (IEA)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (10, 'Inventory of Carbon & Energy (ICE)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (11, 'New Zealand Ministry for the Environment');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (12, 'The Climate Registry');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (13, 'Reliable Disclosure (RE-DISS) European Residual Mixes');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (14, 'Taiwan Bureau of Energy');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (15, 'UK CRC Energy Efficiency Scheme');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (16, 'UK Department for Environment, Food & Rural Affairs (Defra)');
	INSERT INTO csr.factor_set_group (factor_set_group_id, name) VALUES (17, 'US Energy Information Administration');
	
	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 1;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 2;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 3;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 4;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 5;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 6;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 7;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 8;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 9;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 10;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 11;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 12;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 13;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 14;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 15;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 16;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 17;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 18;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 1
	 WHERE std_factor_set_id = 19;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 20;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 21;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 22;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 23;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 24;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 4
	 WHERE std_factor_set_id = 25;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 14
	 WHERE std_factor_set_id = 26;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 27;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 28;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 11
	 WHERE std_factor_set_id = 29;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 5
	 WHERE std_factor_set_id = 30;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 17
	 WHERE std_factor_set_id = 31;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 32;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 33;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 34;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 35;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 36;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 37;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 38;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 39;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 15
	 WHERE std_factor_set_id = 40;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 41;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 8
	 WHERE std_factor_set_id = 42;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 11
	 WHERE std_factor_set_id = 43;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 11
	 WHERE std_factor_set_id = 44;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 10
	 WHERE std_factor_set_id = 45;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 46;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 47;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 7
	 WHERE std_factor_set_id = 48;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 49;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 12
	 WHERE std_factor_set_id = 50;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 5
	 WHERE std_factor_set_id = 51;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 52;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 53;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 54;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 55;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 13
	 WHERE std_factor_set_id = 56;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 16
	 WHERE std_factor_set_id = 57;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 9
	 WHERE std_factor_set_id = 58;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 3
	 WHERE std_factor_set_id = 59;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 2
	 WHERE std_factor_set_id = 60;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 5
	 WHERE std_factor_set_id = 61;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 62;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 63;

	UPDATE csr.std_factor_set
	   SET factor_set_group_id = 6
	 WHERE std_factor_set_id = 64;

END;
/

SET DEFINE &

INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can import std factor set', 0);
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Can publish std factor set', 0);

DECLARE
	v_act_id 					security.security_pkg.T_ACT_ID;
	v_app_sid 					security.security_pkg.T_SID_ID;
	v_menu						security.security_pkg.T_SID_ID;
	v_sa_sid					security.security_pkg.T_SID_ID;
	v_setup_menu				security.security_pkg.T_SID_ID;
	v_factorset_menu			security.security_pkg.T_SID_ID;

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
	FOR r IN (SELECT host FROM csr.customer WHERE host = 'emissionfactors.credit360.com')
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		v_act_id 	:= security.security_pkg.GetAct;
		v_app_sid 	:= security.security_pkg.GetApp;
		v_menu		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
		v_sa_sid	:= security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
		
		EnableCapability('Can import std factor set', 1);
		EnableCapability('Can publish std factor set', 1);
		
		BEGIN
			v_setup_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Setup');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_menu, 'setup', 'Setup', '/csr/site/admin/config/global.acds', 0, null, v_setup_menu);
		END;
	
		BEGIN
			v_factorset_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_setup_menu, 'csr_admin_factor_sets');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_setup_menu, 'csr_admin_factor_sets', 'Factor sets',
					'/csr/site/admin/emissionFactors/new/factorsetgroups.acds', 0, null, v_factorset_menu);
		END;
		
		-- don't inherit dacls
		security.securableobject_pkg.SetFlags(v_act_id, v_factorset_menu, 0);
		--Remove inherited ones
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_factorset_menu));
		-- Add SA permission
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_factorset_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
			security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);
			
		
		security.user_pkg.logoff(sys_context('security','act'));
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../factor_set_group_pkg

@../sheet_body
@../factor_set_group_body
@../schema_body
@../csrimp/imp_body

@update_tail
