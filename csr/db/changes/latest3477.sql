define version=3477
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

CREATE SEQUENCE CHAIN.CAPABILITY_GROUP_SEQ;
CREATE TABLE CHAIN.CAPABILITY_GROUP(
	CAPABILITY_GROUP_ID		NUMBER(10, 0)		NOT NULL,
	CAPABILITY_ID			NUMBER(10, 0)		NOT NULL,
	GROUP_NAME				VARCHAR2(255)		NOT NULL,
	GROUP_POSITION			NUMBER(10, 0)		DEFAULT 0 NOT NULL,
	IS_VISIBLE				NUMBER(1, 0)		DEFAULT 1 NOT NULL,
	CONSTRAINT PK_CAPABILITY_GROUP PRIMARY KEY (CAPABILITY_GROUP_ID),
	CONSTRAINT UK_CI_CAPABILITY_GROUP UNIQUE (CAPABILITY_GROUP_ID, CAPABILITY_ID),
	CONSTRAINT FK_CAPABILITY_GROUP_CAPABILITY_ID
		FOREIGN KEY (CAPABILITY_ID)
		REFERENCES CHAIN.CAPABILITY (CAPABILITY_ID)
);
CREATE INDEX chain.ix_capability_gr_capability_id ON chain.capability_group (capability_id);


ALTER TABLE CSR.CUSTOM_FACTOR ADD CONSTRAINT FK_CUSTOM_FCTR_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
create index csr.ix_custom_factor_region_sid on csr.custom_factor (app_sid, region_sid);
ALTER TABLE CSR.PROPERTY_FUND_OWNERSHIP ADD CONSTRAINT FK_PFO_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE CSR.METER_UTILITY_CONTRACT ADD CONSTRAINT RefUTILITY_CONTRACT_REGION
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;
ALTER TABLE csr.failed_notification ADD retry_count NUMBER(10, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.failed_notification_archive ADD retry_count NUMBER(10, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.tt_audit_browse MODIFY auditor_name VARCHAR(256);


GRANT SELECT, UPDATE, DELETE ON chain.saved_filter_region TO csr;
grant select, UPDATE, DELETE, references on chain.saved_filter_alert_subscriptn to csr;








UPDATE csr.module
    SET module_name = 'ESG Disclosures',
        description = 'Enable the new ESG Disclosures module'
WHERE module_id = 119;
UPDATE security.menu
   SET description = 'ESG Disclosures'
 WHERE description = 'Framework Disclosures';
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set) 
	VALUES(4002, 'disclosureassignment', 'Allow assignment completion', 1, 0);
INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT, DESCRIPTION) VALUES ('Anonymise PII data', 1, 'Enable selection of users for anonymisation - DO NOT DISABLE IF ENABLED!');
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE)
VALUES (81, 'Reset Anonymise PII data capability permissions', 'Resets the permissions on the Anonymise PII data capability, giving permissions to only Superadmin users.', 'ResetAnonymisePiiDataPermissions','');
DECLARE
	v_act_id					security.security_pkg.T_ACT_ID;
	v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	v_capabilities				security.security_pkg.T_SID_ID;
	v_anonymise_pii				security.security_pkg.T_SID_ID;
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
	FOR r IN (
		SELECT DISTINCT application_sid_id, website_name
		  FROM security.website
		 WHERE application_sid_id IN (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		security.user_pkg.LogonAdmin(r.website_name);
		enablecapability('Anonymise PII data');
		v_act_id := security.security_pkg.GetAct;
		v_capabilities := security.securableobject_pkg.GetSidFromPath(v_act_id, r.application_sid_id, 'Capabilities');
		v_anonymise_pii := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities, 'Anonymise PII data');
		security.securableobject_pkg.SetFlags(v_act_id, v_anonymise_pii, 0);
		security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_anonymise_pii));
		security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_anonymise_pii), -1,
			security.security_pkg.ACE_TYPE_ALLOW,security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);
		security.user_pkg.LogonAdmin();
	END lOOP;
END;
/
BEGIN
	UPDATE csr.default_alert_frame_body
	   SET html = 
		'<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #CA0123;margin-bottom:20px;padding-bottom:10px;">'||
		'<img src="https://resource.credit360.com/csr/shared/branding/images/ul-solutions-logo-red.png" style="height:4em;" />'||
		'</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #CA0123;margin-top:20px;padding-top:10px;padding-bottom:10px;"></div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>'
	;
	UPDATE csr.default_alert_template_body
	   SET subject = '<template>New issue raised for your attention</template>'
	 WHERE std_alert_type_id = 17;
	
	UPDATE csr.default_alert_template_body
	   SET subject = '<template>Issue Summary<br /></template>'
	 WHERE std_alert_type_id = 18;
END;
/
DECLARE
	v_app_sid NUMBER;
BEGIN
	-- SupplierCarbon specific
	v_app_sid := 74343586;
	UPDATE csr.alert_template_body
	   SET subject = '<template>New issue raised for your attention</template>'
	 WHERE app_sid = v_app_sid
	   AND customer_alert_type_id = 80057;
	UPDATE csr.alert_template_body
	   SET subject = '<template>Issue Summary<br /></template>'
	 WHERE app_sid = v_app_sid
	   AND customer_alert_type_id = 80058;
	UPDATE csr.alert_frame_body
	   SET html = 
		'<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #CA0123;margin-bottom:20px;padding-bottom:10px;">'||
		'<img src="https://resource.credit360.com/csr/shared/branding/images/ul-solutions-logo-red.png" style="height:4em;" />'||
		'</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #CA0123;margin-top:20px;padding-top:10px;padding-bottom:10px;"></div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>'
	 WHERE app_sid = v_app_sid;
END;
/
BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Company', 'Suppliers', 'Alternative company names', 'Company scores', 'Company tags', 'View company extra details', 'View company score log')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Company Details', 0, 1);
	END LOOP;
END;
/
BEGIN
	FOR rec IN ( 
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Add company to business relationships', 'Update company business relationship periods', 'View company business relationships', 'Filter on company relationships', 'Create business relationships', 'View company business relationships (supplier => purchaser)', 'Update company business relationship periods (supplier => purchaser)', 'Add company to business relationships (supplier => purchaser)')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Business relationships', 1, 1);
	END LOOP;
END;
/
BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Edit own email address', 'Add user to company', 'Company user', 'Create user', 'Edit user email address', 'Manage user', 'Promote user', 'Remove user from company', 'Reset password', 'Specify user name')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Users', 2, 1);
	END LOOP;
END;
/
BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Send questionnaire invitations on behalf of', 'Create questionnaire type', 'Manage questionnaire security', 'Questionnaire', 'Submit questionnaire', 'Approve questionnaire', 'Create company user with invitation', 'Reject questionnaire', 'Request questionnaire from an established relationship', 'Request questionnaire from an existing company in the database', 'Send questionnaire invitation', 'Send questionnaire invitation to existing company', 'Send questionnaire invitation to new company', 'Audit questionnaire responses', 'Create questionnaire type', 'Manage questionnaire security', 'Query questionnaire answers', 'Questionnaire', 'Setup stub registration', 'Submit questionnaire', 'Send questionnaire invitations on behalf of to existing company')
		)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Survey invitation', 3, 1);
	END LOOP;
END;
/
BEGIN
	FOR rec IN (
		SELECT capability_id 
		FROM chain.capability 
		WHERE capability_name IN ('Change supplier follower', 'Create company as subsidiary', 'Create company user without invitation', 'Create company without invitation', 'Create relationship with supplier', 'Edit own follower status', 'Supplier with no established relationship', 'Deactivate company')
		)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Onboarding and relationships', 4, 1);
	END LOOP;
END;
/
BEGIN
	FOR rec IN (
		SELECT capability_id 
		FROM chain.capability 
		WHERE capability_name IN ('Send newsflash', 'Send company invitation', 'Send invitation on behalf of', 'Add supplier to products', 'Components', 'Create products', 'CT Hotspotter', 'Events', 'Manage activities', 'Manage product certification requirements', 'Metrics', 'Product certifications', 'Product code types', 'Product metric values', 'Product supplier certifications', 'Product supplier metric values', 'Product suppliers', 'Products', 'Tasks', 'Add product suppliers of suppliers', 'Product supplier certifications of suppliers', 'Product supplier metric values of suppliers', 'Product suppliers of suppliers', 'Filter on company audits', 'Filter on cms companies', 'Products as supplier', 'Product supplier metric values as supplier', 'Receive user-targeted newsflash', 'Product metric values as supplier')
	)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Advanced', 5, 1);
	END LOOP;
END;
/
BEGIN
	FOR rec IN (
		SELECT capability_id
		FROM chain.capability
		WHERE capability_name IN ('Is top company', 'Actions', 'Uploaded file', 'View certifications', 'View country risk levels', 'Manage workflows', 'Actions', 'Create supplier audit', 'Request audits', 'Uploaded file', 'View certifications', 'View supplier audits', 'Add remove relationships between A and B', 'Create subsidiary on behalf of', 'Create supplier audit on behalf of', 'Set primary purchaser in a relationship between A and B', 'View relationships between A and B', 'View subsidiaries on behalf of')
		)
	LOOP
		INSERT INTO chain.capability_group
		VALUES (chain.capability_group_seq.nextval, rec.capability_id, 'Other', 6, 1);
	END LOOP;
END;
/
BEGIN
	security.user_pkg.logonadmin('sso.credit360.demo');
	UPDATE csr.customer
	   SET require_sa_login_reason = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/
BEGIN
	security.user_pkg.logonadmin('sso-local.credit360.com');
	UPDATE csr.customer
	   SET require_sa_login_reason = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	security.user_pkg.LogonAdmin('');
EXCEPTION
	WHEN OTHERS THEN
		NULL;
END;
/






@..\audit_pkg
@..\tag_pkg
@..\core_access_pkg
@..\trash_pkg
@..\csr_data_pkg
@..\util_script_pkg
@..\chain\capability_pkg
@..\issue_pkg


@..\audit_body
@..\enable_body
@..\tag_body
@..\core_access_body
@..\dataview_body
@..\flow_body
@..\region_body
@..\trash_body
@..\notification_body
@..\util_script_body
@..\chain\capability_body
@..\quick_survey_report_body
@..\issue_body



@update_tail
