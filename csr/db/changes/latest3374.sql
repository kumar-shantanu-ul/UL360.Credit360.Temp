define version=3374
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

CREATE TABLE csr.non_compliance_type_flow_cap(
    app_sid                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    non_compliance_type_id    NUMBER(10, 0)    NOT NULL,
    flow_capability_id        NUMBER(10, 0)    NOT NULL,
    base_flow_capability_id   NUMBER(10 ,0)    NOT NULL,
    CONSTRAINT pk_non_compliance_typ_flow_cap PRIMARY KEY (app_sid, non_compliance_type_id, flow_capability_id),
    CONSTRAINT uk_nc_type_base_flow_cap UNIQUE (app_sid, non_compliance_type_id, base_flow_capability_id)
)
;
ALTER TABLE CSR.NON_COMPLIANCE_TYPE_FLOW_CAP ADD CONSTRAINT FK_NON_COMP_FC_NON_COMP_TYPE
    FOREIGN KEY (APP_SID, NON_COMPLIANCE_TYPE_ID)
    REFERENCES CSR.NON_COMPLIANCE_TYPE(APP_SID, NON_COMPLIANCE_TYPE_ID)
;
ALTER TABLE CSR.NON_COMPLIANCE_TYPE_FLOW_CAP ADD CONSTRAINT FK_NON_COMP_FC_CFC
    FOREIGN KEY (APP_SID, FLOW_CAPABILITY_ID)
    REFERENCES CSR.CUSTOMER_FLOW_CAPABILITY(APP_SID, FLOW_CAPABILITY_ID)
;
ALTER TABLE CSR.NON_COMPLIANCE_TYPE_FLOW_CAP ADD CONSTRAINT FK_NON_COMP_FC_FC
    FOREIGN KEY (BASE_FLOW_CAPABILITY_ID)
    REFERENCES CSR.FLOW_CAPABILITY(FLOW_CAPABILITY_ID)
;
CREATE INDEX CSR.IX_NON_COMP_FC_NON_COMP_TYPE ON CSR.NON_COMPLIANCE_TYPE_FLOW_CAP(APP_SID, NON_COMPLIANCE_TYPE_ID);
CREATE INDEX CSR.IX_NON_COMP_FC_CFC ON CSR.NON_COMPLIANCE_TYPE_FLOW_CAP(APP_SID, FLOW_CAPABILITY_ID);
CREATE INDEX CSR.IX_NON_COMP_FC_FC ON CSR.NON_COMPLIANCE_TYPE_FLOW_CAP(BASE_FLOW_CAPABILITY_ID);
ALTER TABLE csr.non_compliance_type RENAME COLUMN flow_capability_id TO xxx_flow_capability_id;
CREATE TABLE csrimp.non_compliance_type_flow_cap(
    csrimp_session_id         NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    non_compliance_type_id    NUMBER(10, 0)    NOT NULL,
    flow_capability_id        NUMBER(10, 0)    NOT NULL,
	base_flow_capability_id   NUMBER(10 ,0)    NOT NULL,
    CONSTRAINT pk_non_compliance_typ_flow_cap PRIMARY KEY (csrimp_session_id, non_compliance_type_id, flow_capability_id),
	CONSTRAINT uk_nc_type_base_flow_cap UNIQUE (csrimp_session_id, non_compliance_type_id, base_flow_capability_id),
    CONSTRAINT fk_non_com_typ_flow_cap_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
)
;


ALTER TABLE csr.flow_item ADD resource_uuid VARCHAR2(64);
CREATE UNIQUE INDEX csr.ix_flow_item_resource_uuid ON csr.flow_item (lower(resource_uuid));


grant select,insert on csr.non_compliance_type_flow_cap to csrimp;
grant select,insert,update,delete on csrimp.non_compliance_type_flow_cap to tool_user;








DECLARE
	v_id NUMBER(10);
BEGIN
	INSERT INTO csr.flow_capability (flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (23, 'audit', 'Finding tags', 0, security.security_pkg.PERMISSION_READ);
		
	INSERT INTO csr.flow_state_role_capability
	(app_sid, flow_state_rl_cap_id, flow_capability_id, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid)
	SELECT app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, 23 /*FLOW_CAP_AUDIT_NC_TAGS*/, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid
	  FROM csr.flow_state_role_capability
	 WHERE flow_capability_id = 3; -- FLOW_CAP_AUDIT_NON_COMPL	
 
	FOR r IN (
		SELECT app_sid, non_compliance_type_id, xxx_flow_capability_id flow_capability_id, label
		  FROM csr.non_compliance_type
		 WHERE xxx_flow_capability_id IS NOT NULL
	) LOOP  
		v_id := csr.customer_flow_cap_id_seq.NEXTVAL;
		
		INSERT INTO csr.customer_flow_capability (app_sid, flow_capability_id, flow_alert_class, description, perm_type, default_permission_set, is_system_managed) 
		VALUES (r.app_sid, v_id, 'audit', r.label || ' tags', 1, 0, 1);
		
		INSERT INTO csr.non_compliance_type_flow_cap (app_sid, non_compliance_type_id, flow_capability_id, base_flow_capability_id)
		VALUES (r.app_sid, r.non_compliance_type_id, r.flow_capability_id, 3); -- FLOW_CAP_AUDIT_NON_COMPL 
		INSERT INTO csr.non_compliance_type_flow_cap (app_sid, non_compliance_type_id, flow_capability_id, base_flow_capability_id)
		VALUES (r.app_sid, r.non_compliance_type_id, v_id, 23); -- FLOW_CAP_AUDIT_NC_TAGS
		
		INSERT INTO csr.flow_state_role_capability
		(app_sid, flow_state_rl_cap_id, flow_capability_id, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid)
		SELECT app_sid, csr.flow_state_rl_cap_id_seq.NEXTVAL, v_id, flow_involvement_type_id, flow_state_id, group_sid, permission_set, role_sid
		  FROM csr.flow_state_role_capability
		 WHERE flow_capability_id = r.flow_capability_id;	
	END LOOP;
END;
/
DECLARE
	v_act_id			security.security_pkg.T_ACT_ID;
	v_www_root			security.security_pkg.T_SID_ID;
	v_www_api_security	security.security_pkg.T_SID_ID;
	v_groups_sid		security.security_pkg.T_SID_ID;
	v_reg_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonAdmin;
	FOR r IN (
		SELECT c.app_sid, c.host
		  FROM csr.customer c
		  JOIN security.website w ON c.app_sid = w.application_sid_id AND LOWER(c.host) = LOWER(w.website_name)
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		v_act_id := security.security_pkg.getact;
		v_groups_sid 			:= security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups');
		v_reg_users_sid 		:= security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
		v_www_root := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
		-- web resource for the api
		BEGIN
			v_www_api_security := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_root, 'api.translations');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_root, v_www_root, 'api.translations', v_www_api_security);
		END;
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_api_security), -1, security.security_pkg.ACE_TYPE_ALLOW, security.security_pkg.ACE_FLAG_DEFAULT,
			v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);
	END LOOP;
END;
/
INSERT INTO csr.plugin 
(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
VALUES 
(csr.plugin_id_seq.nextval, 13, 'Integration Question/Answers List', '/csr/site/audit/controls/IntegrationQuestionAnswerTab.js',
	'Audit.Controls.IntegrationQuestionAnswerTab', 'Credit360.Audit.Plugins.IntegrationQuestionAnswerList',
	'This tab shows question and answer records usually received via an integration',
	'/csr/shared/plugins/screenshots/audit_tab_iqa_list.png');






@..\audit_pkg
@..\csr_data_pkg
@..\schema_pkg
@..\region_api_pkg
@..\flow_pkg


@..\audit_body
@..\enable_body
@..\flow_body
@..\non_compliance_report_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\filter_body
@..\integration_question_answer_report_body
@..\region_api_body



@update_tail
