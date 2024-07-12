define version=3210
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

-- Need to drop CHAIN.T_PERMISSION_MATRIX_TABLE if it exists before recreating CHAIN.T_PERMISSION_MATRIX_ROW
BEGIN
	FOR r IN (
		SELECT owner, type_name
		  FROM all_types
		 WHERE owner = 'CHAIN' AND type_name = 'T_PERMISSION_MATRIX_TABLE'
	) LOOP
		EXECUTE IMMEDIATE 'DROP TYPE CHAIN.T_PERMISSION_MATRIX_TABLE';
	END LOOP;
END;
/

CREATE OR REPLACE TYPE CHAIN.T_PERMISSION_MATRIX_ROW AS
  OBJECT (
	CAPABILITY_ID 					NUMBER(10),
	PRIMARY_COMPANY_GROUP_TYPE_ID	NUMBER(10),
	PRIMARY_COMPANY_TYPE_ROLE_SID	NUMBER(10)
  );
/
CREATE OR REPLACE TYPE CHAIN.T_PERMISSION_MATRIX_TABLE AS
 TABLE OF T_PERMISSION_MATRIX_ROW;
/

DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CHAIN'
	   AND table_name = 'CAPABILITY'
	   AND column_name = 'DESCRIPTION';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE chain.capability ADD (
			description VARCHAR2(1024)
		)';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'ISSUE_RAISE_ALERT'
	   AND column_name = 'ISSUE_COMMENT'
	   AND data_type = 'CLOB';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.issue_raise_alert ADD (issue_comment_clob CLOB)';
		EXECUTE IMMEDIATE 'UPDATE csr.issue_raise_alert SET issue_comment_clob = issue_comment, issue_comment = null';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.issue_raise_alert DROP COLUMN issue_comment';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.issue_raise_alert RENAME COLUMN issue_comment_clob TO issue_comment';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'QUICK_SURVEY_TYPE'
	   AND column_name = 'CAPTURE_GEO_LOCATION';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.quick_survey_type ADD (
			CAPTURE_GEO_LOCATION NUMBER(1, 0) DEFAULT 0 NOT NULL,
			CONSTRAINT CHK_CAPTURE_GEO_LOCATION CHECK (CAPTURE_GEO_LOCATION IN (0,1))
		)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'QUICK_SURVEY_SUBMISSION'
	   AND column_name IN ('GEO_LATITUDE','GEO_LONGITUDE','GEO_ALTITUDE','GEO_H_ACCURACY','GEO_V_ACCURACY');
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.quick_survey_submission ADD (
			GEO_LATITUDE						NUMBER(24,10),
			GEO_LONGITUDE						NUMBER(24,10),
			GEO_ALTITUDE						NUMBER(24,10),
			GEO_H_ACCURACY						NUMBER(24,10),
			GEO_V_ACCURACY						NUMBER(24,10),
			CONSTRAINT ck_qss_geolocation CHECK ((
				(GEO_LATITUDE IS NULL AND GEO_LONGITUDE IS NULL AND GEO_H_ACCURACY IS NULL) OR
				(GEO_LATITUDE IS NOT NULL AND GEO_LONGITUDE IS NOT NULL AND GEO_H_ACCURACY IS NOT NULL)
			) AND (
				(GEO_ALTITUDE IS NULL AND GEO_V_ACCURACY IS NULL) OR
				(GEO_ALTITUDE IS NOT NULL AND GEO_V_ACCURACY IS NOT NULL)
			))
		)';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'QUICK_SURVEY_TYPE'
	   AND column_name = 'CAPTURE_GEO_LOCATION';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.quick_survey_type ADD (
			CAPTURE_GEO_LOCATION NUMBER(1, 0) DEFAULT 0 NOT NULL
		)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'QUICK_SURVEY_SUBMISSION'
	   AND column_name IN ('GEO_LATITUDE','GEO_LONGITUDE','GEO_ALTITUDE','GEO_H_ACCURACY','GEO_V_ACCURACY');
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.quick_survey_submission ADD (
			GEO_LATITUDE						NUMBER(24,10),
			GEO_LONGITUDE						NUMBER(24,10),
			GEO_ALTITUDE						NUMBER(24,10),
			GEO_H_ACCURACY						NUMBER(24,10),
			GEO_V_ACCURACY						NUMBER(24,10)
		)';
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'AUDIT_TYPE_CLOSURE_TYPE'
	   AND column_name = 'MANUAL_EXPIRY_DATE';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.AUDIT_TYPE_CLOSURE_TYPE ADD MANUAL_EXPIRY_DATE NUMBER(1) DEFAULT 0 NOT NULL';
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'AUDIT_TYPE_CLOSURE_TYPE'
	   AND column_name = 'MANUAL_EXPIRY_DATE';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.AUDIT_TYPE_CLOSURE_TYPE ADD MANUAL_EXPIRY_DATE NUMBER(1) DEFAULT 0 NOT NULL';
	END IF;
END;
/

grant insert,update on security.home_page to csr;

CREATE OR REPLACE VIEW csr.v$meter_reading_multi_src AS
	WITH m AS (
		SELECT m.app_sid, m.region_sid legacy_region_sid, NULL urjanet_arb_region_sid, 0 auto_source
		  FROM csr.all_meter m
		 WHERE urjanet_meter_id IS NULL
		UNION
		SELECT app_sid, NULL legacy_region_sid, region_sid urjanet_arb_region_sid, 1 auto_source
		  FROM all_meter m
		 WHERE urjanet_meter_id IS NOT NULL
		   AND EXISTS (
			SELECT 1
			  FROM meter_source_data sd
			 WHERE sd.app_sid = m.app_sid
			   AND sd.region_sid = m.region_sid
		)
	)
	--
	-- Legacy meter readings part
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.cost,
		mr.baseline_val, mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference,
		mr.meter_document_id, mr.created_invoice_id, mr.approved_dtm, mr.approved_by_sid,
		mr.is_estimate, mr.flow_item_id, mr.pm_reading_id, mr.format_mask,
		m.auto_source
	  FROM m
	  JOIN csr.v$meter_reading mr on mr.app_sid = m.app_sid AND mr.region_sid = m.legacy_region_sid
	--
	-- Source data part
	UNION
	SELECT MAX(x.app_sid) app_sid, ROW_NUMBER() OVER (ORDER BY x.start_dtm) meter_reading_id,
		MAX(x.region_sid) region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
		NULL baseline_val, 3 entered_by_user_sid, NULL entered_dtm, 
		REPLACE(STRAGG(x.note), ',', '; ') note,
		NULL reference, NULL meter_document_id, NULL created_invoice_id, NULL approved_dtm, NULL approved_by_sid,
		0 is_estimate, NULL flow_item_id, NULL pm_reading_id, NULL format_mask, x.auto_source
	FROM (
		-- Consumption (value part)
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, sd.consumption val_number, NULL cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (value part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, sd.consumption cost, m.auto_source, NULL note
		  FROM m
		  JOIN csr.v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Consumption (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'CONSUMPTION' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
		-- Cost (distinct note part)
		UNION
		SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, m.auto_source, sd.note
		  FROM m
		  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.urjanet_arb_region_sid
		  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key = 'COST' AND sd.meter_input_id = ip.meter_input_id
		  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.urjanet_arb_region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	) x
	GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, x.auto_source
;
CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc, qs.current_version,
		   qs.from_question_library, qs.lookup_key, qst.capture_geo_location
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id AND st.app_sid = qs.app_sid
	  LEFT JOIN csr.quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id AND qst.app_sid = qs.app_sid
	 WHERE d.survey_version = 0;




UPDATE chain.capability SET description = 'Ability to edit details in the "Company" tab on the Supply Chain Company Details page.' WHERE capability_name = 'Company';
UPDATE chain.capability SET description = 'View and make change to details in the Company Details page.' WHERE capability_name = 'Suppliers';
UPDATE chain.capability SET description = 'Give users a user name to log in with that is separate from their email address.' WHERE capability_name = 'Specify user name';
UPDATE chain.capability SET description = 'View and edit any questionnaire associated with the company.' WHERE capability_name = 'Questionnaire';
UPDATE chain.capability SET description = 'Submit a questionnaire associated with the user''s company.' WHERE capability_name = 'Submit questionnaire';
UPDATE chain.capability SET description = 'Add actions (issues) to individual questions on a supplier survey. The Survey Answer issue type must also be enabled.' WHERE capability_name = 'Query questionnaire answers';
UPDATE chain.capability SET description = 'Managing read, write, approve, submit permissions on a survey for a particular user.' WHERE capability_name = 'Manage questionnaire security';
UPDATE chain.capability SET description = 'Create a survey that can be sent to suppliers.' WHERE capability_name = 'Create questionnaire type';
UPDATE chain.capability SET description = 'Register a user without sending them an invitation.' WHERE capability_name = 'Setup stub registration';
UPDATE chain.capability SET description = 'Reset a user''s password.' WHERE capability_name = 'Reset password';
UPDATE chain.capability SET description = 'Create a user from the Company users page.' WHERE capability_name = 'Create user';
UPDATE chain.capability SET description = 'Ability to add users to the company.' WHERE capability_name = 'Add user to company';
UPDATE chain.capability SET description = 'Deprecated - now replaced by Tasks.' WHERE capability_name = 'Events';
UPDATE chain.capability SET description = 'Ability to read and create new actions on supply chain specific pages that don''t result from data collection (e.g. audits and surveys).' WHERE capability_name = 'Actions';
UPDATE chain.capability SET description = 'Whether users can view or edit tasks the company has to do. Tasks have replaced "actions" and "events".' WHERE capability_name = 'Tasks';
UPDATE chain.capability SET description = 'Whether you can edit any company metrics.' WHERE capability_name = 'Metrics';
UPDATE chain.capability SET description = 'Around managing products supplied by suppliers' WHERE capability_name = 'Products';
UPDATE chain.capability SET description = 'Relates to whether you can add products a supplier sells to a top company.' WHERE capability_name = 'Components';
UPDATE chain.capability SET description = 'Ability to promote a company user to a company administrator from the Company users page.' WHERE capability_name = 'Promote user';
UPDATE chain.capability SET description = 'Around managing products supplied by suppliers' WHERE capability_name = 'Product code types';
UPDATE chain.capability SET description = 'This controls who can view and edit company folders and documents in the Supply Chain document library.' WHERE capability_name = 'Uploaded file';
UPDATE chain.capability SET description = 'Ability to edit another company user''s email address on the Company users page.' WHERE capability_name = 'Edit user email address';
UPDATE chain.capability SET description = 'Ability to edit your own email address on the Supply Chain My details page and the Company users page.' WHERE capability_name = 'Edit own email address';
UPDATE chain.capability SET description = 'View supplier audits on a "Supplier Audits" tab in the supplier profile page.' WHERE capability_name = 'View supplier audits';
UPDATE chain.capability SET description = 'Ability to view/edit any extra details in yellow in the supplier details tab.' WHERE capability_name = 'View company extra details';
UPDATE chain.capability SET description = 'Deprecated - now replaced by Tasks.' WHERE capability_name = 'Manage activities';
UPDATE chain.capability SET description = 'Ability to add and remove users from roles.' WHERE capability_name = 'Manage user';
UPDATE chain.capability SET description = 'Read access allows the user to view alternative names for the company. These are displayed under "Additional information" on the Company details tab of the company''s profile page (in this case, the Manage companies page). Read/write access allows the user to view and edit alternative names for the company.' WHERE capability_name = 'Alternative company names';
UPDATE chain.capability SET description = 'Specific to Carbon Trust Hotspotter tool.' WHERE capability_name = 'CT Hotspotter';
UPDATE chain.capability SET description = 'The company is at the highest level of the hierarchy and can view all suppliers.' WHERE capability_name = 'Is top company';
UPDATE chain.capability SET description = 'Enable the Supplier Registration Wizard for sending questionnaires to new companies (as part of an invitation) or existing companies.' WHERE capability_name = 'Send questionnaire invitation';
UPDATE chain.capability SET description = 'Create a new company with an invitation but without a questionnaire.' WHERE capability_name = 'Send company invitation';
UPDATE chain.capability SET description = 'Deprecated - replaced by tertiary relationships' WHERE capability_name = 'Send invitation on behalf of';
UPDATE chain.capability SET description = 'Ability to send news items.' WHERE capability_name = 'Send newsflash';
UPDATE chain.capability SET description = 'Ability to view news items.' WHERE capability_name = 'Receive user-targeted newsflash';
UPDATE chain.capability SET description = 'Approve a questionnaire submitted by another company.' WHERE capability_name = 'Approve questionnaire';
UPDATE chain.capability SET description = 'Allow users to cancel a survey that has been sent to a supplier. Once canceled, the supplier can no longer access the survey to edit or submit it.' WHERE capability_name = 'Reject questionnaire';
UPDATE chain.capability SET description = 'Change the user who receives supplier messages (if you only want certain users as contacts for certain suppliers) and add or remove users from the Supplier followers plugin.' WHERE capability_name = 'Change supplier follower';
UPDATE chain.capability SET description = 'Must be true for the workflow transition buttons to be displayed.' WHERE capability_name = 'Manage workflows';
UPDATE chain.capability SET description = 'Create a subsidiary/sub-company below the supplier.' WHERE capability_name = 'Create company as subsidiary';
UPDATE chain.capability SET description = 'Create a new company user without an invitation (i.e. from the Company users page or the Company invitation wizard). If false, the Company invitation wizard does not allow you to search for existing companies or add contacts.' WHERE capability_name = 'Create company without invitation.';
UPDATE chain.capability SET description = 'Create a new company user with an invitation.' WHERE capability_name = 'Create company user with invitation';
UPDATE chain.capability SET description = 'Remove a user from the company so that they are no longer a member of the company and no longer have the permissions associated with that company type. This does not delete a user from the system. In order to remove administrator users, the "Promote user" permission is also required.' WHERE capability_name = 'Remove user from company';
UPDATE chain.capability SET description = 'Create a new company by sending an invitation with a questionnaire.' WHERE capability_name = 'Send questionnaire invitation to new company';
UPDATE chain.capability SET description = 'Send a questionnaire to an existing company.' WHERE capability_name = 'Send questionnaire invitation to existing company';
UPDATE chain.capability SET description = 'See secondary suppliers that you have no relationship with.' WHERE capability_name = 'Supplier with no established relationship';
UPDATE chain.capability SET description = 'Create a company relationship with an existing company without sending a company or questionnaire invitation. The "Supplier with no established relationship" must also be set to "Read" on the company type relationship. Users with the permission can search for existing companies that they don''t have a relationship with from the Supplier list tab/plugin on the Manage Companies page. ' WHERE capability_name = 'Create relationship with supplier';
UPDATE chain.capability SET description = 'View the relationship between the secondary and tertiary company on the "Relationships" plugin.' WHERE capability_name = 'View relationships between A and B';
UPDATE chain.capability SET description = 'Add or remove a relationship between a secondary and a tertiary company from the "Relationships" plugin.' WHERE capability_name = 'Add remove relationships between A and B';
UPDATE chain.capability SET description = 'Ability to ask an auditor to carry out an audit on a supplier without specifying/creating the audit (requires its own page). The Auditor company must also have the “Create supplier audit” permission on the Auditor > Auditee company type relationship.' WHERE capability_name = 'Request audits';
UPDATE chain.capability SET description = 'Create a 2nd party audit (i.e. top company auditing a supplier).' WHERE capability_name = 'Create supplier audit';
UPDATE chain.capability SET description = 'If true, users can filter by "Supplier of" and "Related by <business relationship type>" on the Supplier list plugin.' WHERE capability_name = 'Filter on company relationships';
UPDATE chain.capability SET description = 'Adds filters to the Supplier list plugin for audits on companies.' WHERE capability_name = 'Filter on company audits';
UPDATE chain.capability SET description = 'Adds filters to the Supplier list plugin for the fields of CMS tables on the company record. The CMS table must include company columns pointing to actual company SIDs. A flag on the CMS table is also required (this is enabled automatically but may be switched off).' WHERE capability_name = 'Filter on cms companies';
UPDATE chain.capability SET description = 'Ability to create business relationships. Business relationship types must also be configured.' WHERE capability_name = 'Create business relationships';
UPDATE chain.capability SET description = 'Ability to add the company to business relationships.' WHERE capability_name = 'Add company to business relationships';
UPDATE chain.capability SET description = 'View the company''s business relationships. Requires the Business relationships plugin/tab.' WHERE capability_name = 'View company business relationships';
UPDATE chain.capability SET description = 'Ability to update the time periods on a business relationship.' WHERE capability_name = 'Update company business relationship periods';
UPDATE chain.capability SET description = 'Make a company active or inactive. When a company is made inactive, users of that company cannot log in and new surveys, audits, delegation forms, logging forms and activities cannot be created. Existing data can be viewed.' WHERE capability_name = 'Deactivate company';
UPDATE chain.capability SET description = 'Allows the secondary company in the company relationship to create a business relationship with the primary company.' WHERE capability_name = 'Add company to business relationships (supplier => purchaser)';
UPDATE chain.capability SET description = 'Allows the secondary company to view business relationships with the primary company. Requires the business relationships plugin/tab.' WHERE capability_name = 'View company business relationships (supplier => purchaser)';
UPDATE chain.capability SET description = 'Allows the secondary company to update the time periods on a business relationship between them and the primary company.' WHERE capability_name = 'Update company business relationship periods (supplier => purchaser)';
UPDATE chain.capability SET description = 'Send a questionnaire to a supplier (new or existing) on behalf of the secondary company.' WHERE capability_name = 'Send questionnaire invitations on behalf of';
UPDATE chain.capability SET description = 'Send a questionnaire to an existing supplier on behalf of the secondary company.' WHERE capability_name = 'Send questionnaire invitations on behalf of to existing company';
UPDATE chain.capability SET description = 'Create an audit on the tertiary company on behalf of the secondary company. For example, if the indirect relationship were "Top Company (Third party auditor => Supplier), this permission would allow the top company to create an audit between the third party auditor and supplier.' WHERE capability_name = 'Create supplier audit on behalf of';
UPDATE chain.capability SET description = 'Create a subsidiary/sub-company below the tertiary company.' WHERE capability_name = 'Create subsidiary on behalf of';
UPDATE chain.capability SET description = 'View subsidiaries/sub-companies of the secondary company.' WHERE capability_name = 'View subsidiaries on behalf of';
UPDATE chain.capability SET description = 'Allows a holding company to ask any company in the system to share a survey that has been approved by the top company.' WHERE capability_name = 'Request questionnaire from an existing company in the database';
UPDATE chain.capability SET description = 'Allows a holding company to ask a company that it has a direct company relationship with to share a survey that has been approved by the top company.' WHERE capability_name = 'Request questionnaire from an established relationship';
UPDATE chain.capability SET description = 'Read access allows the user to view company scores. Scores are displayed in the score header on the company''s profile page, and in columns on the supplier list. Read/write access allows the user to view and edit company scores, if the score type is configured to allow the score to be set manually.' WHERE capability_name = 'Company scores';
UPDATE chain.capability SET description = 'View changes to the company score. Requires the Score header for company management page header plugin.' WHERE capability_name = 'View company score log';
UPDATE chain.capability SET description = 'Compare submissions of the same survey by a single company.' WHERE capability_name = 'Audit questionnaire responses';
UPDATE chain.capability SET description = 'Used if there is a separate tab used to show any tags associated with a company (not relevant if tags are shown on the same tab as the company details).' WHERE capability_name = 'Company tags';
UPDATE chain.capability SET description = 'Enables the user to follow or stop following companies through the Supplier follower plugin.' WHERE capability_name = 'Edit own follower status';
UPDATE chain.capability SET description = 'View certifications for companies on the supplier list page. This permission allows users to see the following information about the most recent audit of the type(s) specified in the certification: audit type, valid from, valid to, and audit result.' WHERE capability_name = 'View certifications';
UPDATE chain.capability SET description = 'Set the purchaser company in a relationship as the primary purchaser for that supplier.' WHERE capability_name = 'Set primary purchaser in a relationship between A and B';
BEGIN
	UPDATE csr.util_script
	   SET util_script_name = 'API: Create API Client'
	 WHERE util_script_id = 38;
	
	UPDATE csr.util_script
	   SET util_script_name = 'API: Update API Client secret'
	 WHERE util_script_id = 39;
	
	
	UPDATE csr.module
	   SET description = 'Enables API integrations . See utility script page for API user creation.'
	 WHERE module_id = 97;
END;
/




CREATE OR REPLACE PACKAGE csr.site_name_management_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.site_name_management_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.site_name_management_pkg TO web_user;


@..\chain\capability_pkg
@..\chain\type_capability_pkg
@..\site_name_management_pkg
@..\issue_pkg
@..\..\..\aspen2\cms\db\form_pkg
@..\..\..\aspen2\db\utils_pkg
@..\role_pkg
@..\chain\company_type_pkg
@..\quick_survey_pkg
@..\audit_pkg
@..\meter_pkg
@..\section_tree_pkg


@..\chain\capability_body
@..\chain\type_capability_body
@..\site_name_management_body
@..\issue_body
@..\enable_body
@..\section_tree_body
@..\..\..\aspen2\cms\db\form_body
@..\..\..\aspen2\db\utils_body
@..\compliance_library_report_body
@..\compliance_register_report_body
@..\util_script_body
@..\role_body
@..\meter_body
@..\chain\company_body
@..\chain\helper_body
@..\chain\company_type_body
@..\chain\test_chain_utils_body
@..\chain\supplier_flow_body
@..\quick_survey_body
@..\qs_incident_helper_body
@..\schema_body
@..\csrimp\imp_body
@..\audit_body
@..\meter_monitor_body
@..\doc_body



@update_tail
