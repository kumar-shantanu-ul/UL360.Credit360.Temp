define version=3255
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/


ALTER TABLE aspen2.application ADD branding_service_css VARCHAR2(512);
ALTER TABLE csrimp.aspen2_application ADD branding_service_css VARCHAR2(512);










DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT DISTINCT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.schema', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.analysis', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.portlets', v_sid);
			security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/
BEGIN
	UPDATE csr.customer_flow_capability
	   SET is_system_managed = 1
	 WHERE flow_capability_id in (
		  SELECT csr_cfc.flow_capability_id
			FROM csr.customer_flow_capability csr_cfc
			JOIN chain.capability_flow_capability ch_cfc ON ch_cfc.flow_capability_id = csr_cfc.flow_capability_id
			JOIN chain.capability cap ON cap.capability_id = ch_cfc.capability_id
		   WHERE ( cap.capability_name IN ('Company', 'Suppliers'))
		   GROUP BY csr_cfc.flow_capability_id);
END;
/








@..\region_body
@..\region_tree_body
@..\delegation_body
@..\csrimp\imp_body
@..\..\..\aspen2\db\aspenapp_body
@..\schema_body



@update_tail
