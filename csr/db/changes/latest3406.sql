define version=3406
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



ALTER TABLE ASPEN2.APPLICATION ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE ASPEN2.APPLICATION ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));
UPDATE aspen2.application a
   SET ul_design_system_enabled = (
		SELECT ul_design_system_enabled
		  FROM csr.customer c
		 WHERE a.app_sid = c.app_sid
	)
 WHERE a.app_sid IN (
	SELECT app_sid
	  FROM csr.customer
	);
ALTER TABLE CSR.CUSTOMER DROP COLUMN UL_DESIGN_SYSTEM_ENABLED;
ALTER TABLE CSRIMP.CUSTOMER DROP COLUMN UL_DESIGN_SYSTEM_ENABLED;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD UL_DESIGN_SYSTEM_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION MODIFY (UL_DESIGN_SYSTEM_ENABLED DEFAULT NULL);
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD CONSTRAINT CK_ENABLE_UL_DESIGN_SYSTEM CHECK (UL_DESIGN_SYSTEM_ENABLED IN (0,1));
DECLARE
    COLUMN_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT (COLUMN_EXISTS, -01430);
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE CSR.CUSTOMER ADD (ENABLE_JAVA_AUTH NUMBER(1) DEFAULT 0 NOT NULL, CONSTRAINT CK_ENABLE_JAVA_AUTH CHECK (ENABLE_JAVA_AUTH IN (0, 1)))';
EXCEPTION
	WHEN COLUMN_EXISTS THEN NULL;
END;
/
ALTER TABLE ASPEN2.APPLICATION ADD GA4_ENABLED NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE ASPEN2.APPLICATION ADD CONSTRAINT CK_GA4_ENABLED CHECK (GA4_ENABLED IN (0,1,2));
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD GA4_ENABLED NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE CSRIMP.ASPEN2_APPLICATION MODIFY (GA4_ENABLED DEFAULT NULL);
ALTER TABLE CSRIMP.ASPEN2_APPLICATION ADD CONSTRAINT CK_GA4_ENABLED CHECK (GA4_ENABLED IN (0,1,2));
ALTER TABLE csr.tpl_report_tag_suggestion DROP CONSTRAINT chk_tpl_report_tag_suggestion;
ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT fk_tpl_report_tag_suggestion;
ALTER TABLE csr.tpl_report_tag_suggestion DROP CONSTRAINT pk_tpl_report_tag_suggestion;
DROP TABLE csr.tpl_report_tag_suggestion;
ALTER TABLE csrimp.tpl_report_tag_suggestion DROP CONSTRAINT pk_tpl_report_tag_suggestion;
DROP TABLE csrimp.tpl_report_tag_suggestion;
ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csr.tpl_report_tag DROP COLUMN tpl_report_tag_suggestion_id;
ALTER TABLE csr.tpl_report_tag ADD (
	CONSTRAINT ct_tpl_report_tag CHECK (
		(tag_type IN (1,4,5,14) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
		OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
	)
);
ALTER TABLE csrimp.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE csrimp.tpl_report_tag DROP COLUMN tpl_report_tag_suggestion_id;
ALTER TABLE csrimp.tpl_report_tag ADD (
	CONSTRAINT ct_tpl_report_tag CHECK (
		(tag_type IN (1,4,5,14) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 11 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NOT NULL)
		OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL AND tpl_report_tag_reg_data_id IS NULL)
		OR (tag_type = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND tpl_report_non_compl_id IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL AND tpl_report_tag_reg_data_id IS NULL)
	)
);
DROP TABLE csrimp.map_tpl_report_tag_suggestion;
DROP SEQUENCE csr.tpl_report_tag_sugg_id_seq;
BEGIN
	FOR r IN (
		SELECT *
		  FROM all_users
		 WHERE UPPER(username) = 'SUGGESTIONS'
	)
	LOOP
		EXECUTE IMMEDIATE 'DROP USER '|| r.username ||' CASCADE';
	END LOOP;
END;
/

grant select, insert, update on csr.doc_folder to csrimp;








BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (69, 'Disable new password hashing scheme', 'Switches the users directly belonging to this site back to legacy password authenticaton.', 'DisableJavaAuth', NULL);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
	VALUES (70, 'Enable new password hashing scheme', 'Switches the users directly belonging to this site to the new password authentication module.', 'EnableJavaAuth', NULL);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
DECLARE
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
	FOR apps IN (
		SELECT host
		  FROM csr.customer c
		  JOIN security.website w ON c.host = w.website_name
	)
	LOOP
		security.user_pkg.logonadmin(apps.host);
		EnableCapability('Enable Delegation Plan Folders');
		security.user_pkg.logonadmin();
	END LOOP;
END;
/
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Google Analytics Management', 0);
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (123, 'Consent Settings', 'EnableConsentSettings', 'Enable Consent Settings page.');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (123, 'State', 1, '0 (disable) or 1 (enable)');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (123, 'Menu Position', 2, '-1=end, or 1 based position');
/*
DECLARE
	v_act_id				security.security_pkg.T_ACT_ID;
	v_app_sid				security.security_pkg.T_SID_ID;
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_capabilities_sid		security.security_pkg.T_SID_ID;
	v_menu					security.security_pkg.T_SID_ID;
	v_admin_menu			security.security_pkg.T_SID_ID;
	v_ga_menu				security.security_pkg.T_SID_ID;
	v_position				NUMBER := -1;
BEGIN
	security.user_pkg.LogonAdmin();
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		security.user_pkg.LogonAuthenticated(
			in_sid_id		=> security.security_pkg.SID_BUILTIN_ADMINISTRATOR,
			in_act_timeout	=> 30000,
			in_app_sid		=> r.application_sid_id,
			out_act_id		=> v_act_id);
		BEGIN
		v_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Menu');
		v_admin_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'Admin');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
		END;
		
		IF v_admin_menu IS NOT NULL THEN
			BEGIN
				v_ga_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'csr_site_admin_consent_settings');
				security.menu_pkg.SetPos(
					in_act_id => v_act_id,
					in_sid_id => v_ga_menu,
					in_pos => v_position
				);
			EXCEPTION
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.menu_pkg.CreateMenu(
						in_act_id => v_act_id,
						in_parent_sid_id => v_admin_menu,
						in_name => 'csr_site_admin_consent_settings',
						in_description => 'Consent Settings',
						in_action => '/csr/site/admin/superadmin/consentSettings/consentSettings.acds',
						in_pos => v_position,
						in_context => NULL,
						out_sid_id => v_ga_menu
					);
			END;
		END IF;
		-- csr_data_pkg.EnableCapability;
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				'Google Analytics Management',
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN NULL;
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
	END LOOP;
	security.user_pkg.LogonAdmin();
END;
/
*/
UPDATE csr.module SET enable_class = null, post_enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableQuestionLibrary';
UPDATE csr.module SET enable_class = null, post_enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableFileSharingApi';
UPDATE csr.util_script_param
   SET param_hint = 'SP called when importing child data for responses. Type "NULL" or whitespace if no child helper SP is needed',
	   param_name = 'Child Helper SP (Type "NULL" or whitespace if no child helper SP is needed)'
 WHERE util_script_id = 66
   AND pos = 4;
BEGIN
	-- DELETE menu item
	FOR r IN (
		SELECT so.sid_id
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		 WHERE description = 'Suggestions'
		   AND action = '/app/ui.suggestions/suggestions')
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
	-- DELETE ui.suggestions WR
	FOR r IN (
		SELECT so.sid_id, so.dacl_id
		  FROM security.securable_object so
		 WHERE so.name = 'ui.suggestions')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = r.dacl_id;
		DELETE FROM security.web_resource
		 WHERE sid_id = r.sid_id;
		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;
	-- DELETE suggestions API WR
	FOR r IN (
		SELECT so.sid_id, so.dacl_id
		  FROM security.securable_object so
		 WHERE so.name = 'api.suggestions')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = r.dacl_id;
		DELETE FROM security.web_resource
		 WHERE sid_id = r.sid_id;
		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;
	-- DELETE suggestions ui API WR
	FOR r IN (
		SELECT so.sid_id, so.dacl_id
		  FROM security.securable_object so
		 WHERE so.name = 'api.suggestions.reactui')
	LOOP
		DELETE FROM security.acl
		 WHERE acl_id = r.dacl_id;
		DELETE FROM security.web_resource
		 WHERE sid_id = r.sid_id;
		DELETE FROM security.securable_object
		 WHERE sid_id = r.sid_id;
	END LOOP;
	DELETE FROM csr.module
	 WHERE module_name = 'API Suggestions'
		OR module_name = 'Suggestions';
END;
/
UPDATE csr.util_script
   SET util_script_name = 'New password hashing scheme: disable'
 WHERE util_script_id = 69;
UPDATE csr.util_script
   SET util_script_name = 'New password hashing scheme: enable'
 WHERE util_script_id = 70;






@..\util_script_pkg
@..\schema_pkg
@..\csr_data_pkg
@..\customer_pkg
@..\enable_pkg
@..\templated_report_pkg
@..\..\..\aspen2\db\aspenapp_pkg
@..\csr_app_pkg
@..\factor_pkg


@..\..\..\aspen2\db\aspenapp_body
@..\branding_body
@..\csrimp\imp_body
@..\customer_body
@..\schema_body
@..\csr_user_body
@..\util_script_body
@..\csr_data_body
@..\enable_body
@..\templated_report_body
@..\csr_app_body
@..\factor_body



@update_tail
