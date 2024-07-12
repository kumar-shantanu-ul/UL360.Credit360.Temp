DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	-- create csr classes
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'DonationsScheme', 'donations.scheme_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsScheme');
	END;
	BEGIN	
		-- View donations I have added
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_VIEW_MINE, 'View donations I have added');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_READ, new_class_id, donations.SCHEME_pkg.PERMISSION_VIEW_MINE);
		-- View all donations
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_VIEW_ALL, 'View all donations');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, donations.SCHEME_pkg.PERMISSION_VIEW_ALL);
		-- Update donations I have added
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_UPDATE_MINE, 'Update donations I have added');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, donations.SCHEME_pkg.PERMISSION_UPDATE_MINE);
		-- Update all donations
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_UPDATE_ALL, 'Update all donations');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_ADD_CONTENTS, new_class_id, donations.SCHEME_pkg.PERMISSION_UPDATE_ALL);
		-- Add new donations
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_ADD_NEW, 'Add new donations');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, donations.SCHEME_pkg.PERMISSION_ADD_NEW);
		-- Transition is allowed 
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_TRANSITION_ALLOWED, 'Transition is allowed');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_WRITE, new_class_id, donations.SCHEME_pkg.PERMISSION_TRANSITION_ALLOWED);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'DonationsRecipient', 'donations.recipient_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsRecipient');
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'DonationsRegionGroup', 'donations.region_group_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsRegionGroup');
	END;
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'DonationsTagGroup', 'donations.tag_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsTagGroup');
	END;
		BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'DonationsTagGroup', 'donations.tag_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsTagGroup');
	END;
	BEGIN
		security.class_pkg.CreateClass(v_act, NULL, 'DonationsStatus', 'donations.status_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsStatus');
	END;
	
	BEGIN	
	security.class_pkg.CreateClass(v_act, NULL, 'DonationsTransition', 'donations.transition_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			new_class_id:=security.class_pkg.GetClassId('DonationsTransition');
	END;
	BEGIN	
		-- Transition
		security.class_pkg.AddPermission(v_act, new_class_id, donations.SCHEME_pkg.PERMISSION_TRANSITION_ALLOWED, 'Transition is allowed');
		security.class_pkg.CreateMapping(v_act, security.security_pkg.SO_CONTAINER, security.security_pkg.PERMISSION_READ, new_class_id, donations.SCHEME_pkg.PERMISSION_TRANSITION_ALLOWED);
		EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	security.user_pkg.LOGOFF(v_ACT);
END;
/
