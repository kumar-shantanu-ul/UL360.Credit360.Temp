define version=3293
define minor_version=0
define is_combined=1
@update_header

set serveroutput on

-- fix invalid FK constraints in csrimp
ALTER TABLE csrimp.non_compliance_type DROP CONSTRAINT FK_NON_COMP_TYP_CAPAB DROP INDEX;
ALTER TABLE csrimp.compliance_audit_log DROP CONSTRAINT FK_CAL_CI DROP INDEX;
ALTER TABLE csrimp.compliance_audit_log
  ADD CONSTRAINT FK_CAL_IS
  FOREIGN KEY (csrimp_session_id)
  REFERENCES csrimp.csrimp_session (csrimp_session_id);

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		BEGIN
			EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
		EXCEPTION
			WHEN OTHERS THEN
				dbms_output.put_line('Error truncating csrimp.'||r.table_name);
				RAISE;
		END;
	END LOOP;
	DELETE FROM  csrimp.csrimp_session;
	COMMIT;
END;
/


ALTER TABLE csr.issue_custom_field
ADD restrict_to_group_sid NUMBER(10);
ALTER TABLE csrimp.issue_custom_field
ADD restrict_to_group_sid NUMBER(10);
CREATE INDEX csr.ix_issue_custom_field_group ON csr.issue_custom_field (restrict_to_group_sid);
ALTER TABLE csr.gresb_submission_log 
RENAME COLUMN submission_data TO response_data;
ALTER TABLE csr.gresb_submission_log ADD request_data CLOB;
/* csrimp changes */
ALTER TABLE csrimp.gresb_submission_log 
RENAME COLUMN submission_data TO response_data;
ALTER TABLE csrimp.gresb_submission_log ADD request_data CLOB;




ALTER TABLE csr.issue_custom_field ADD CONSTRAINT fk_iss_cus_field_group
	FOREIGN KEY (restrict_to_group_sid)
	REFERENCES security.group_table (sid_id);






DECLARE
	v_app_sid					security.security_pkg.T_SID_ID;
	v_act_id					security.security_pkg.T_ACT_ID;
	v_groups_sid				security.security_pkg.T_SID_ID;
	v_admins_sid				security.security_pkg.T_SID_ID;
	v_everyone_sid				security.security_pkg.T_SID_ID;
	v_www_sid					security.security_pkg.T_SID_ID;
	v_www_beta_menu_sid			security.security_pkg.T_SID_ID;
	PROCEDURE INTERNAL_CreateOrGetResource(
		in_act_id			IN  security.security_pkg.T_ACT_ID,
		in_web_root_sid_id	IN  security.security_pkg.T_SID_ID,
		in_parent_sid_id	IN  security.security_pkg.T_SID_ID,
		in_page_name		IN  security.web_resource.path%TYPE,
		out_page_sid_id		OUT security.web_resource.sid_id%TYPE
	)
	IS
	BEGIN
		security.web_pkg.CreateResource(
			in_act_id			=> in_act_id,
			in_web_root_sid_id	=> in_web_root_sid_id,
			in_parent_sid_id	=> in_parent_sid_id,
			in_page_name		=> in_page_name,
			in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
			in_rewrite_path		=> NULL,
			out_page_sid_id		=> out_page_sid_id
		);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			out_page_sid_id := security.securableobject_pkg.GetSidFromPath(in_act_id, in_parent_sid_id, in_page_name);
	END;
	PROCEDURE INTERNAL_AddACE_NoDups(
		in_act_id			IN  security.security_pkg.T_ACT_ID,
		in_acl_id			IN  security.security_Pkg.T_ACL_ID,
		in_acl_index		IN  security.security_Pkg.T_ACL_INDEX,
		in_ace_type			IN  security.security_Pkg.T_ACE_TYPE,
		in_ace_flags		IN  security.security_Pkg.T_ACE_FLAGS,
		in_sid_id			IN  security.security_Pkg.T_SID_ID,
		in_permission_set	IN  security.security_Pkg.T_PERMISSION
	)
	IS
	BEGIN
		security.acl_pkg.RemoveACEsForSid(in_act_id, in_acl_id, in_sid_id);
		security.acl_pkg.AddACE(in_act_id, in_acl_id, in_acl_index, in_ace_type, in_ace_flags, in_sid_id, in_permission_set);
	END;
BEGIN
	FOR r IN (
		SELECT c.app_sid, c.name
		  FROM aspen2.application a
		  JOIN csr.customer c ON a.app_sid = c.app_sid
		 WHERE a.branding_service_css IS NOT NULL 
	)LOOP
		security.user_pkg.logonadmin(r.name);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
		v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
		v_everyone_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
		v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
		INTERNAL_CreateOrGetResource(v_act_id, v_www_sid, v_www_sid, 'ui.menu', v_www_beta_menu_sid);
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_beta_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_admins_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		INTERNAL_AddACE_NoDups(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_beta_menu_sid), -1, security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);
		security.user_pkg.logonadmin();
	END LOOP;
END;
/
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1000,1,'gresb_asset_id','integer','Unique GRESB Asset ID. Generated automatically when creating a new asset. Can be uploaded into 360 for pre-existing assets.','',NULL,1,'Property''s GRESB asset id. The asset ID is recorded when a GRESB asset is created or can be uploaded for pre-existing assets. If we have an ID, we will update the specified asset, otherwise we will attempt to create it.');
UPDATE csr.gresb_indicator
	SET description='Gross asset value of the asset at the end of the reporting period. This is in millions of the relevant currency.'
	WHERE gresb_indicator_id=1011;
UPDATE csr.gresb_indicator
	SET sm_description='The first date within the reporting year for which any field beginning with en_ has data'
	WHERE gresb_indicator_id=1054;
UPDATE csr.gresb_indicator
	SET sm_description='The last date within the reporting year for which any field beginning with en_ has data'
	WHERE gresb_indicator_id=1055; 
UPDATE csr.gresb_indicator
	SET sm_description='The first date within the reporting year for which any field beginning with wat_ has data'
	WHERE gresb_indicator_id=1125; 
UPDATE csr.gresb_indicator
	SET sm_description='The last date within the reporting year for which any field beginning with wat_ has data'
	WHERE gresb_indicator_id=1126; 
UPDATE csr.gresb_indicator
	SET sm_description='The first date within the reporting year for which any field beginning with was_ has data'
	WHERE gresb_indicator_id=1148; 
UPDATE csr.gresb_indicator
	SET sm_description='The last date within the reporting year for which any field beginning with was_ has data'
	WHERE gresb_indicator_id=1149; 
INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id, system_managed, sm_description)
	VALUES (1159,1,'partners_id','integer','360 provided Asset ID to ensure correct mapping within 360.','',NULL,1,'Property''s region sid.');






@..\issue_pkg
@..\stored_calc_datasource_pkg
@..\audit_pkg
@..\..\..\aspen2\db\aspenapp_pkg
@..\gresb_config_pkg


@..\issue_body
@..\schema_body
@..\csrimp\imp_body
@..\meter_body
@..\stored_calc_datasource_body
@..\unit_test_body
@..\audit_body
@..\..\..\aspen2\db\aspenapp_body
@..\gresb_config_body



@update_tail
