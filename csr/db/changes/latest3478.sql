define version=3478
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

TRUNCATE TABLE CHAIN.CAPABILITY_GROUP;
DROP SEQUENCE CHAIN.CAPABILITY_GROUP_SEQ;
DROP INDEX chain.ix_capability_gr_capability_id;
ALTER TABLE CHAIN.CAPABILITY_GROUP DROP CONSTRAINT UK_CI_CAPABILITY_GROUP DROP INDEX;
ALTER TABLE CHAIN.CAPABILITY_GROUP DROP COLUMN CAPABILITY_ID;
CREATE TABLE CSR.USER_ANONYMISATION_BATCH_JOB(
	APP_SID			NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	USER_SID		NUMBER(10, 0)    NOT NULL,
	BATCH_JOB_ID	NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_USER_ANONYMISATION_BATCH_JOB PRIMARY KEY (APP_SID, USER_SID, BATCH_JOB_ID)
)
;
CREATE INDEX CSR.IX_USER_ANONBATJOB ON CSR.USER_ANONYMISATION_BATCH_JOB (APP_SID, USER_SID);
ALTER TABLE CSR.USER_ANONYMISATION_BATCH_JOB ADD CONSTRAINT FK_USER_USERANONBATJOB
	FOREIGN KEY (APP_SID, USER_SID)
	REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE CSR.CSR_USER ADD ANONYMISED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CSR_USER ADD ANONYMISED NUMBER(1) DEFAULT 0 NOT NULL;


ALTER TABLE csr.customer ADD (
	AUTO_ANONYMISATION_ENABLED         NUMBER(1,0)  DEFAULT 0  NOT NULL,
	INACTIVE_DAYS_BEFORE_ANONYMISATION NUMBER(10,0) DEFAULT 30 NOT NULL
);
ALTER TABLE csrimp.customer ADD (
    AUTO_ANONYMISATION_ENABLED         NUMBER(1,0)      NOT NULL,
	INACTIVE_DAYS_BEFORE_ANONYMISATION NUMBER(10,0)     NOT NULL
);
ALTER TABLE CHAIN.CAPABILITY ADD (
	  CAPABILITY_GROUP_ID		    NUMBER(10, 0) DEFAULT 7 NOT NULL,
	  POSITION			            NUMBER(10, 0) DEFAULT 0 NOT NULL
	);
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE gt.location_lookup DISABLE CONSTRAINT FK_LOCATION_LOOKUP_REGION';
EXCEPTION
    WHEN OTHERS THEN
        -- ORA-00942: table or view does not exist
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/










INSERT INTO csr.capability (name, allow_by_default, description)
 VALUES ('Can manage notification failures', 0, 'Enables resending or deleting failed notifications');
BEGIN
	INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (1, 'Company Details' , 0, 1);
    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (2, 'Business relationships' , 1, 1);
    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (3, 'Users' , 2, 1);
    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (4, 'Survey invitation' , 3, 1);
    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (5, 'Onboarding and relationships' , 4, 1);
    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (6, 'Advanced' , 5, 1);
    INSERT INTO CHAIN.CAPABILITY_GROUP
	VALUES (7, 'Other' , 6, 1);
END;
/
BEGIN
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 1
	WHERE capability_name IN ('Company', 'Suppliers', 'Alternative company names', 'Company scores', 'Company tags', 'View company extra details', 'View company score log');
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 2
	WHERE capability_name IN ('Add company to business relationships', 'Update company business relationship periods', 'View company business relationships', 'Filter on company relationships', 'Create business relationships', 'View company business relationships (supplier => purchaser)', 'Update company business relationship periods (supplier => purchaser)', 'Add company to business relationships (supplier => purchaser)');
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 3
	WHERE capability_name IN ('Edit own email address', 'Add user to company', 'Company user', 'Create user', 'Edit user email address', 'Manage user', 'Promote user', 'Remove user from company', 'Reset password', 'Specify user name');
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 4
	WHERE capability_name IN ('Send questionnaire invitations on behalf of', 'Create questionnaire type', 'Manage questionnaire security', 'Questionnaire', 'Submit questionnaire', 'Approve questionnaire', 'Create company user with invitation', 'Reject questionnaire', 'Request questionnaire from an established relationship', 'Request questionnaire from an existing company in the database', 'Send questionnaire invitation', 'Send questionnaire invitation to existing company', 'Send questionnaire invitation to new company', 'Audit questionnaire responses', 'Create questionnaire type', 'Manage questionnaire security', 'Query questionnaire answers', 'Questionnaire', 'Setup stub registration', 'Submit questionnaire', 'Send questionnaire invitations on behalf of to existing company');
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 5
	WHERE capability_name IN ('Change supplier follower', 'Create company as subsidiary', 'Create company user without invitation', 'Create company without invitation', 'Create relationship with supplier', 'Edit own follower status', 'Supplier with no established relationship', 'Deactivate company');
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 6
	WHERE capability_name IN ('Send newsflash', 'Send company invitation', 'Send invitation on behalf of', 'Add supplier to products', 'Components', 'Create products', 'CT Hotspotter', 'Events', 'Manage activities', 'Manage product certification requirements', 'Metrics', 'Product certifications', 'Product code types', 'Product metric values', 'Product supplier certifications', 'Product supplier metric values', 'Product suppliers', 'Products', 'Tasks', 'Add product suppliers of suppliers', 'Product supplier certifications of suppliers', 'Product supplier metric values of suppliers', 'Product suppliers of suppliers', 'Filter on company audits', 'Filter on cms companies', 'Products as supplier', 'Product supplier metric values as supplier', 'Receive user-targeted newsflash', 'Product metric values as supplier');
	UPDATE chain.capability SET CAPABILITY_GROUP_ID = 7
	WHERE capability_name IN ('Is top company', 'Actions', 'Uploaded file', 'View certifications', 'View country risk levels', 'Manage workflows', 'Actions', 'Create supplier audit', 'Request audits', 'Uploaded file', 'View certifications', 'View supplier audits', 'Add remove relationships between A and B', 'Create subsidiary on behalf of', 'Create supplier audit on behalf of', 'Set primary purchaser in a relationship between A and B', 'View relationships between A and B', 'View subsidiaries on behalf of');
END;
/
ALTER TABLE CHAIN.CAPABILITY ADD CONSTRAINT FK_CAP_CAP_GROUP
	FOREIGN KEY (CAPABILITY_GROUP_ID)
	REFERENCES CHAIN.CAPABILITY_GROUP(CAPABILITY_GROUP_ID)
;
create index chain.ix_capability_capability_gr on chain.capability (capability_group_id);
DECLARE
	v_act							security.security_pkg.T_ACT_ID;
	v_www_app_sid					security.security_pkg.T_SID_ID;
	v_www_notifications_sid			security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT w.application_sid_id app_sid, w.web_root_sid_id www_sid
		  FROM security.website w
		  JOIN csr.customer c ON w.application_sid_id = c.app_sid
	)
	LOOP
		-- Create wwwroot/ui.notifications (asset path)
		BEGIN
			security.web_pkg.CreateResource(
				in_act_id			=> v_act,
				in_web_root_sid_id	=> r.www_sid,
				in_parent_sid_id	=> r.www_sid,
				in_page_name		=> 'ui.notifications',
				in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
				in_rewrite_path		=> NULL,
				out_page_sid_id		=> v_www_notifications_sid
			);
			security.acl_pkg.AddACE(
				in_act_id			=> v_act,
				in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_www_notifications_sid),
				in_acl_index		=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=> security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id			=> security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups/Administrators'),
				in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		-- Create wwwroot/app
		BEGIN
			security.web_pkg.CreateResource(
				in_act_id			=> v_act,
				in_web_root_sid_id	=> r.www_sid,
				in_parent_sid_id	=> r.www_sid,
				in_page_name		=> 'app',
				in_class_id			=> security.security_pKg.SO_WEB_RESOURCE,
				in_rewrite_path		=> NULL,
				out_page_sid_id		=> v_www_app_sid
			);
			security.acl_pkg.AddACE(
				in_act_id			=> v_act,
				in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_www_app_sid),
				in_acl_index		=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=> security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id			=> security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups/RegisteredUsers'),
				in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_www_app_sid := security.securableobject_pkg.GetSidFromPath(v_act, r.www_sid, 'app');
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		-- Create wwwroot/app/ui.notifications (routed path)
		BEGIN
			security.web_pkg.CreateResource(
				in_act_id			=> v_act,
				in_web_root_sid_id	=> r.www_sid,
				in_parent_sid_id	=> v_www_app_sid,
				in_page_name		=> 'ui.notifications',
				in_class_id			=> security.security_pkg.SO_WEB_RESOURCE,
				in_rewrite_path		=> NULL,
				out_page_sid_id		=> v_www_notifications_sid
			);
			security.securableobject_pkg.ClearFlag(
				in_act_id			=> v_act,
				in_sid_id			=> v_www_notifications_sid,
				in_flag				=> security.security_pkg.SOFLAG_INHERIT_DACL
			);
			-- All accesible features are currently admin only
			security.acl_pkg.AddACE(
				in_act_id			=> v_act,
				in_acl_id			=> security.acl_pkg.GetDACLIDForSID(v_www_notifications_sid),
				in_acl_index		=> security.security_pkg.ACL_INDEX_LAST,
				in_ace_type			=> security.security_pkg.ACE_TYPE_ALLOW,
				in_ace_flags		=> security.security_pkg.ACE_FLAG_INHERIT_INHERITABLE,
				in_sid_id			=> security.securableobject_pkg.GetSidFromPath(v_act, r.app_sid, 'Groups/Administrators'),
				in_permission_set	=> security.security_pkg.PERMISSION_STANDARD_READ
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, in_order, timeout_mins)
VALUES (96, 'Anonymise users', 'csr.csr_user_pkg.ProcessAnonymiseUsersBatchJob', 0, 120);






@..\unit_test_pkg
@..\..\..\aspen2\cms\db\util_pkg
@..\csr_data_pkg
@..\notification_pkg
@..\audit_pkg
@..\flow_pkg
@..\batch_job_pkg
@..\csr_user_pkg


@..\unit_test_body
@..\..\..\aspen2\cms\db\util_body
@..\automated_import_body
@..\csr_data_body
@..\csrimp\imp_body
@..\schema_body
@..\packaged_content_body
@..\notification_body
@..\audit_body
@..\flow_body
@..\chain\capability_body
@..\csr_user_body



@update_tail
