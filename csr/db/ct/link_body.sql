CREATE OR REPLACE PACKAGE BODY ct.link_pkg
IS

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_act_id 					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid 					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_hu_group 					security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Hotspot Users');
	v_rhu_group 				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Restricted Hotspot Users');
	v_vca_group 				security_pkg.T_SID_ID;
	v_vcu_group 				security_pkg.T_SID_ID;
	v_admins_group				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_company_sid, 'Administrators');
	v_users_group				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_company_sid, 'Users');
	v_builtin_admin_act			security_pkg.T_ACT_ID;
	v_stored_app_sid			security_pkg.T_SID_ID;
	v_stored_act				security_pkg.T_ACT_ID;
	v_top_company_sid			security_pkg.T_SID_ID;
	v_is_value_chain			customer_options.is_value_chain%TYPE;
BEGIN
	
	SELECT ct.is_value_chain, ch.top_company_sid
	  INTO v_is_value_chain, v_top_company_sid
	  FROM customer_options ct, chain.customer_options ch
	 WHERE ct.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND ct.app_sid = ch.app_sid;

	IF v_is_value_chain = 0 AND v_top_company_sid IS NOT NULL THEN
		-- if this happens, it's because the hotspotter has been enabled for a chain site which will break things (not sure what, but certainly "things")
		RAISE_APPLICATION_ERROR(-20001, 'Cannot have multiple companies in a hotspotter application');
	END IF;

	-- we fiddle with this, so just keep track of it for now
	v_stored_app_sid := SYS_CONTEXT('SECURITY', 'APP');
	v_stored_act := SYS_CONTEXT('SECURITY', 'ACT');

	-- Add hotspot users group to the company users group - this needs to happen, so let's do it as the admin
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security_pkg.SetACT(v_builtin_admin_act);
	
	-- Three scenarios here:
	-- 	1. This is a hotspotter site, and this is the only company being added
	-- 	2. This is a value chain site, and this is the first company being added
	-- 	3. This is a value chain site, and this is a subsequent company being added
	--
	-- 	1. Anyone can do anything 
	--		-> Add hotspot users to the admins group for the company 
	--		-> All registered users are already hotspot users by default
	--		-> Set chain.customer_options.top_company_sid
	--	2. Value chain admins can do anything
	--		-> Add value chain admins to the admins group for the company
	--		-> Add value chain users to the users group for the company
	--		-> Set chain.customer_options.top_company_sid
	--      -> Set up value chain dashboards
	--  3. Supplier users can edit the hotspotter
	--		-> Add supplier users as restricted hotspot users
	
	IF v_top_company_sid IS NULL THEN
		UPDATE chain.customer_options SET top_company_sid = in_company_sid WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	END IF;
	
	IF v_is_value_chain = 0 THEN
		-- adds hotspot users as admins
		security.group_pkg.AddMember(v_builtin_admin_act, v_hu_group, v_admins_group);
	ELSE
		IF v_top_company_sid IS NULL THEN
			v_vca_group := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Value Chain Admins');
			v_vcu_group := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Value Chain Users');
			-- adds value chain [admins/users] as company [admins/users]
			security.group_pkg.AddMember(v_builtin_admin_act, v_vca_group, v_admins_group);
			security.group_pkg.AddMember(v_builtin_admin_act, v_vcu_group, v_users_group);
			
			-- Create value chain dashboards
			util_pkg.EnableValueChainDashboard(in_company_sid);
		ELSE
			-- adds company users as restricted hotspotter users
			security.group_pkg.AddMember(v_builtin_admin_act, v_users_group, v_rhu_group);
		END IF;
	END IF;
		
	user_pkg.Logoff(v_builtin_admin_act);
	security_pkg.SetACT(v_stored_act, v_stored_app_sid);
END;

PROCEDURE DeleteCompany (
	in_company_sid			IN security_pkg.T_SID_ID
)
AS
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	company_pkg.DeleteCompany(in_company_sid);	
END;

PROCEDURE InviteCreated (
	in_invitation_id			IN	chain.invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
)
AS	
BEGIN
	supplier_pkg.SetSupplierStatus(in_to_company_sid, ct_pkg.SS_INVITATIONSENT);
END;

PROCEDURE InvitationAccepted (
	in_invitation_id			IN  chain.invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_act_id 					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid 					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_rhu_group 				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Restricted Hotspot Users');
	v_users_group				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, in_to_company_sid, 'Users');
	v_count						NUMBER;
BEGIN
	--Find whether the hotspotter qnr has been started. If yes try add their users to the restricted hotspotter users group 
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.questionnaire q
	  JOIN chain.questionnaire_type qt on qt.questionnaire_type_id = q.questionnaire_type_id
	 WHERE q.app_sid = security_pkg.getApp
	   AND q.company_sid = in_to_company_sid
	   AND qt.class = hotspot_pkg.HOTSPOTTER_QNR_CLASS;
	
	IF v_count > 0 THEN 
		security.group_pkg.AddMember(security_pkg.getAct, v_users_group, v_rhu_group);
	END IF;
	
	supplier_pkg.SetSupplierStatus(in_to_company_sid, ct_pkg.SS_ACCEPTEDINVITATION);
END;

PROCEDURE NukeChain
AS
BEGIN
	DELETE FROM brick
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_air_trip
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_bus_trip
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_cab_trip
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_car_trip
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_emissions
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_motorbike_trip
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_profile
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM bt_train_trip
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM company_consumption_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_bus_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_car_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_emissions_all
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_motorbike_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_questionnaire_answers
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_questionnaire
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_train_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ec_profile
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM hotspot_result
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ht_consumption_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ht_cons_source_breakdown
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ht_consumption
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ps_emissions_all
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ps_item_eio
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ps_item
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ps_spend_breakdown
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ps_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM ps_supplier_eio_freq
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM supplier_contact
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM up_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM up_product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM worksheet_value_map_breakdown
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM worksheet_value_map_currency
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM worksheet_value_map_distance
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM worksheet_value_map_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM worksheet_value_map_supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM breakdown_region_eio
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM breakdown_region_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM breakdown_region
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM breakdown_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM breakdown
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM breakdown_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM supplier
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	DELETE FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;
	
END link_pkg;
/
