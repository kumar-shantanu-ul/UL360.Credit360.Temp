define version=3181
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


DECLARE
	v_exists			NUMBER := 0;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_constraints
	 WHERE owner = 'CHAIN'
	   AND constraint_name = 'CHK_SUPP_REL_SRC_TYPE';
	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE ('ALTER TABLE chain.supplier_relationship_source DROP CONSTRAINT CHK_SUPP_REL_SRC_TYPE');
	END IF;
END;
/
ALTER TABLE chain.supplier_relationship_source
  ADD CONSTRAINT CHK_SUPP_REL_SRC_TYPE CHECK (source_type IN (0, 1, 2, 3));










DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_sid							security.security_pkg.T_SID_ID;
	v_regusers_sid					security.security_pkg.T_SID_ID;
    v_groups_sid					security.security_pkg.T_SID_ID;
    v_www_sid						security.security_pkg.T_SID_ID;
    v_www_api_compliance			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT wr.sid_id, wr.web_root_sid_id, so.application_sid_id
		  FROM security.web_resource wr
          JOIN security.securable_object so on wr.sid_id = so.sid_id
		 WHERE path = '/csr/site/compliance'
	)
	LOOP
  
        v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.application_sid_id, 'wwwroot');
        
        BEGIN
            v_www_api_compliance := security.securableobject_pkg.GetSidFromPath(v_act, v_www_sid, 'api.compliance');
        EXCEPTION
            WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
            BEGIN
                security.security_pkg.SetApp(r.application_sid_id);
                security.web_pkg.CreateResource(v_act, v_www_sid, v_www_sid, 'api.compliance', v_www_api_compliance);
                
                v_groups_sid := security.securableObject_pkg.GetSIDFromPath(v_act, r.application_sid_id, 'Groups');
                v_regusers_sid := security.securableobject_pkg.GetSidFromPath(v_act, v_groups_sid, 'RegisteredUsers');
                security.acl_pkg.AddACE(v_act, security.acl_pkg.GetDACLIDForSID(v_www_api_compliance), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT, v_regusers_sid, security.security_pkg.PERMISSION_STANDARD_READ);
                security.security_pkg.SetApp(null);
            END;
        END;
		
	END LOOP;
    security.user_pkg.LogOff(v_act);
END;
/
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (79, 'Create default campaign and campaign workflow?', 2, '(Y/N)');
UPDATE security.securable_object so
   SET name = 'csr_question_library_surveys'
 WHERE EXISTS (SELECT NULL 
				 FROM security.menu
				WHERE sid_id = so.sid_id
				  AND action = '/csr/site/quicksurvey/library/list.acds');






@..\enable_pkg
@..\region_api_pkg
@..\scenario_api_pkg
@..\chain\chain_pkg
@..\permit_pkg


@..\scenario_api_body
@..\enable_body.sql
@..\audit_report_body
@..\region_api_body
@..\non_compliance_report_body
@..\compliance_body
@..\sheet_body
@..\chain\activity_report_body
@..\chain\chain_body
@..\chain\business_relationship_body
@..\scrag_pp_body
@..\automated_import_body
@..\permit_body



@update_tail
