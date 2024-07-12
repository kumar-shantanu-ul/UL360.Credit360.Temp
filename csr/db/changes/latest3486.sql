define version=3486
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE CSR.CUSTOMER DROP CONSTRAINT CK_SITE_TYPE DROP INDEX;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_SITE_TYPE CHECK (SITE_TYPE IN ('Customer', 'Prospect', 'Sandbox', 'Staff', 'Retired', 'AutomationTest'));






CREATE OR REPLACE FORCE EDITIONABLE VIEW "CHAIN"."V$COMPANY_REFERENCE" ("APP_SID", "COMPANY_REFERENCE_ID", "COMPANY_SID", "VALUE", "REFERENCE_ID", "LOOKUP_KEY", "LABEL") AS 
  SELECT cr.app_sid, cr.company_reference_id, cr.company_sid, cr.value, cr.reference_id, r.lookup_key, r.label
	  FROM chain.company_reference cr
	  JOIN chain.reference r ON r.app_sid = cr.app_sid AND r.reference_id = cr.reference_id;




BEGIN
	FOR r IN (
		SELECT so.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		 WHERE description = 'Failed notifications'
		   AND action = '/app/ui.notifications/notifications')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = (SELECT dacl_id
						   FROM security.securable_object
						  WHERE sid_id = r.sid_id);
		DELETE FROM security.menu
		 WHERE sid_id = r.sid_id;
		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;
END;
/
DECLARE
	v_www_ui_notifications  	security.security_pkg.T_SID_ID;
	v_app_ui_notifications		security.security_pkg.T_SID_ID;
	v_www_app_sid				security.security_pkg.T_SID_ID;
	v_www_root					security.security_pkg.T_SID_ID;
	v_registered_users			security.security_pkg.T_SID_ID;
	v_ui_notifications_dacl 	NUMBER(10);
	v_ui_app_notifications_dacl	NUMBER(10);
	v_act						security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT w.application_sid_id app_sid
		  FROM security.website w
		  JOIN csr.customer c ON w.application_sid_id = c.app_sid
	)
	LOOP
		BEGIN
			v_www_root := security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'wwwroot');
			v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'app');
			-- web resource for the ui
			v_www_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_root, 'ui.notifications');
			v_ui_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_www_ui_notifications);
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_notifications_dacl
			);
			-- Read/write www ui for registered users
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
			-- web resource for the ui
			v_app_ui_notifications := security.securableobject_pkg.GetSidFromPath(v_act, v_www_app_sid, 'ui.notifications');
			v_ui_app_notifications_dacl := security.acl_pkg.GetDACLIDForSID(v_app_ui_notifications);
			
			security.acl_pkg.DeleteAllACEs(
				in_act_id					=> v_act,
				in_acl_id 					=> v_ui_app_notifications_dacl
			);
			-- Read/write app ui for admins
			v_registered_users := security.securableobject_pkg.GetSidFromPath(
				in_act						=> v_act,
				in_parent_sid_id			=> r.app_sid,
				in_path						=> 'Groups/RegisteredUsers'
			);
			security.acl_pkg.AddACE(
				in_act_id					=> v_act,
				in_acl_id					=> v_ui_app_notifications_dacl,
				in_acl_index				=> -1,
				in_ace_type					=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags				=> security.security_pkg.ACE_FLAG_INHERITABLE + security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id					=> v_registered_users,
				in_permission_set			=> security.security_pkg.PERMISSION_STANDARD_ALL
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
			WHEN OTHERS THEN
				NULL;
		END;
	END LOOP;
	security.user_pkg.logonadmin;
END;
/
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(3002, 'disclosure', 'Create/Cancel assignments', 1, 0);
DECLARE
	v_act 				security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(
		in_sid_id			=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
		in_act_timeout		=> NULL,
		in_app_sid			=> NULL,
		out_act_id			=> v_act
	);
	
	BEGIN
		security.class_pkg.AddPermission(
			in_act_id				=> v_act,
			in_class_id				=> security.security_pkg.SO_WEB_RESOURCE,
			in_permission			=> 131072, -- question_library_pkg.PERMISSION_PUBLISH_SURVEY
			in_permission_name		=> 'Publish survey'
		);
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (82, 'Create a Chain System Administrator Role', 'A system wide administrator with permissions outside of the supply chain module for administration of the module itself.', 'CreateChainSystemAdminRole','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (82, 'Secondary Company Type Id', 'The company type id that the top company will have permissions configured against (the chain two tier default is suppliers)', 1);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (83, 'Create a Chain Supplier Administrator Role', 'A supply chain administrator for top level company with access to managing all suppliers.', 'CreateSupplierAdminRole','');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint , pos) VALUES (83, 'Secondary Company Type Id', 'The company type id that the top company will have permissions configured against (the chain two tier default is suppliers)', 1);
DELETE FROM cms.DATA_HELPER WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DATA_HELPER cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);
DELETE FROM cms.DEBUG_SQL_LOG WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DEBUG_SQL_LOG cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);
DELETE FROM cms.DOC_TEMPLATE_VERSION WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DOC_TEMPLATE_VERSION cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);
DELETE FROM cms.DOC_TEMPLATE_FILE WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DOC_TEMPLATE_FILE cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);
DELETE FROM cms.DOC_TEMPLATE WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.DOC_TEMPLATE cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);
DELETE FROM cms.FORM_RESPONSE_IMPORT_OPTIONS WHERE app_sid IN (
    SELECT DISTINCT cmsr.app_sid FROM cms.FORM_RESPONSE_IMPORT_OPTIONS cmsr
    LEFT JOIN csr.customer c ON c.app_sid = cmsr.app_sid
    WHERE c.app_sid IS NULL
);
DECLARE
	v_audit_bsci_plugin_id		csr.plugin.plugin_id%TYPE;
	v_chain_bsci_plugin_id		csr.plugin.plugin_id%TYPE;
	TYPE card_id_list 			IS TABLE OF CHAIN.CARD.CARD_ID%TYPE;
	v_card_ids card_id_list 	:= card_id_list();
BEGIN
	security.user_pkg.logonadmin();
	BEGIN
		SELECT plugin_id INTO v_audit_bsci_plugin_id
		  FROM csr.plugin
		 WHERE LOWER(js_class) = 'audit.controls.bscisupplierdetailstab';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			v_audit_bsci_plugin_id := -1;
	END;
		
	BEGIN
			SELECT plugin_id INTO v_chain_bsci_plugin_id
			  FROM csr.plugin
			 WHERE LOWER(js_class) = 'chain.managecompany.bscisupplierdetailstab';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_chain_bsci_plugin_id := -1;
	END;
	DELETE FROM chain.company_tab_company_type_role
	 WHERE company_tab_id IN (
		SELECT company_tab_id FROM chain.company_tab
		 WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id)
	);
	DELETE FROM chain.company_tab
	 WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id);
	DELETE FROM csr.audit_type_tab
		WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id);
	DELETE FROM csr.plugin
	 WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id);
	
	/*
	extension_card_group_id		Record Name
	64							bsciSupplier
	65							bsci2009Audit
	66							bsci2014Audit
	67							bsciExternalAudit */
	
	DELETE FROM chain.customer_grid_extension
	 WHERE grid_extension_id IN (
				SELECT cge.grid_extension_id
				  FROM chain.customer_grid_extension cge
				  JOIN chain.grid_extension ge ON cge.grid_extension_id = ge.grid_extension_id
				 WHERE ge.extension_card_group_id BETWEEN 64 AND 67
			);
		
	DELETE FROM chain.card_group_card
	 WHERE card_group_id BETWEEN 64 AND 67;
 
	DELETE FROM chain.grid_extension
	 WHERE extension_card_group_id BETWEEN 64 AND 67;
	DELETE FROM chain.card_group_column_type
	 WHERE card_group_id BETWEEN 64 AND 67;
	DELETE FROM chain.aggregate_type
	 WHERE card_group_id BETWEEN 64 AND 67;
	DELETE FROM chain.card_group
	 WHERE card_group_id BETWEEN 64 AND 67;
	SELECT card_id BULK COLLECT 
	  INTO v_card_ids
	  FROM chain.card
	 WHERE LOWER(js_class_type) LIKE '%bsci%';
	FOR i IN 1..v_card_ids.COUNT LOOP
		 DELETE FROM chain.filter_type WHERE card_id = v_card_ids(i);
		 DELETE FROM chain.card_progression_action WHERE card_id = v_card_ids(i);
		 DELETE FROM chain.card_group_card WHERE card_id = v_card_ids(i);
		 DELETE FROM chain.card WHERE card_id = v_card_ids(i);
	END LOOP;
	-- Removing BSCI Jobs
	DELETE FROM csr.batch_job WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batch_job_type_app_cfg WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batch_job_type_app_stat WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batched_export_type WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batched_import_type WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batch_job_type WHERE batch_job_type_id IN (26, 28);
END;
/






@..\csr_data_pkg
@..\csr_user_pkg
@..\util_script_pkg
DROP PACKAGE chain.bsci_supplier_report_pkg;
DROP PACKAGE chain.bsci_2009_audit_report_pkg;
DROP PACKAGE chain.bsci_2014_audit_report_pkg;
DROP PACKAGE chain.bsci_ext_audit_report_pkg;
DROP PACKAGE chain.bsci_pkg;
@..\chain\helper_pkg


@..\user_profile_body
@..\chain\chain_body
@..\csr_app_body
@..\notification_body
@..\chain\company_body
@..\csr_user_body
@..\util_script_body
@..\chain\setup_body
@..\..\..\aspen2\cms\db\zap_body
@..\chain\helper_body
@..\chain\filter_body
@..\audit_body



@update_tail
