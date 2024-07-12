define version=3206
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
CREATE OR REPLACE TYPE CSR.T_SID_AND_PATH_AND_DESC_ROW AS
  OBJECT ( 
	pos				NUMBER(10,0),
	sid_id			NUMBER(10,0),
	path			VARCHAR2(2047),
	description		VARCHAR2(2047)
  );
/
CREATE OR REPLACE TYPE CSR.T_SID_AND_PATH_AND_DESC_TABLE AS 
  TABLE OF CSR.T_SID_AND_PATH_AND_DESC_ROW;
/
CREATE TABLE CSR.AUTOMATED_IMPORT_BUS_FILE (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	FILE_BLOB						BLOB NOT NULL,
	AUTOMATED_IMPORT_INSTANCE_ID	NUMBER(10) NOT NULL,
	MESSAGE_RECEIVED_DTM			DATE DEFAULT SYSDATE NOT NULL,
	SOURCE_DESCRIPTION				VARCHAR(1024),
	CONSTRAINT PK_AUTO_IMP_BUS_FILE PRIMARY KEY (APP_SID, AUTOMATED_IMPORT_INSTANCE_ID)
)
;
DECLARE
	v_exists NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_users
	 WHERE username = 'CAMPAIGNS';
	 IF v_exists <> 0 THEN
		EXECUTE IMMEDIATE 'DROP USER CAMPAIGNS CASCADE';
	END IF;
	EXECUTE IMMEDIATE 'CREATE USER CAMPAIGNS IDENTIFIED BY campaigns DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS';
END;
/
CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_ROW AS
  OBJECT (
		APP_SID							NUMBER(10),
		FLOW_STATE_TRANSITION_ID		NUMBER(10),
		FLOW_ITEM_GENERATED_ALERT_ID	NUMBER(10),
		CUSTOMER_ALERT_TYPE_ID			NUMBER(10),
		FLOW_STATE_LOG_ID				NUMBER(10),
		FROM_STATE_LABEL				VARCHAR2(255),
		TO_STATE_LABEL					VARCHAR2(255),
		SET_BY_USER_SID					NUMBER(10),
		SET_BY_EMAIL					VARCHAR2(256),
		SET_BY_FULL_NAME				VARCHAR2(256),
		SET_BY_USER_NAME				VARCHAR2(256),
		TO_USER_SID						NUMBER(10),
		FLOW_ALERT_HELPER				VARCHAR2(256),
		TO_USER_NAME					VARCHAR2(256),
		TO_FULL_NAME					VARCHAR2(256),
		TO_EMAIL						VARCHAR2(256),
		TO_FRIENDLY_NAME				VARCHAR2(255),
		TO_INITIATOR					NUMBER(1),
		FLOW_ITEM_ID					NUMBER(10),
		FLOW_TRANSITION_ALERT_ID		NUMBER(10),
		COMMENT_TEXT					CLOB
  );
/
CREATE OR REPLACE TYPE CSR.T_FLOW_ALERT_TABLE AS 
  TABLE OF CSR.T_FLOW_ALERT_ROW;
/
CREATE OR REPLACE TYPE CAMPAIGNS.T_CAMPAIGN_ROW AS
	OBJECT (
		APP_SID						NUMBER(10),
		QS_CAMPAIGN_SID				NUMBER(10),
		NAME						VARCHAR2(255),
		TABLE_SID					NUMBER(10),
		FILTER_SID					NUMBER(10),
		SURVEY_SID					NUMBER(10),
		FRAME_ID					NUMBER(10),
		SUBJECT						CLOB,
		BODY						CLOB,
		SEND_AFTER_DTM				DATE,
		STATUS						VARCHAR2(20),
		SENT_DTM					DATE,
		PERIOD_START_DTM			DATE,
		PERIOD_END_DTM				DATE,
		AUDIENCE_TYPE				CHAR(2),
		FLOW_SID					NUMBER(10),
		INC_REGIONS_WITH_NO_USERS	NUMBER(1),
		SKIP_OVERLAPPING_REGIONS 	NUMBER(1),
		CARRY_FORWARD_ANSWERS		NUMBER(1),
		SEND_TO_COLUMN_SID			NUMBER(10),
		REGION_COLUMN_SID			NUMBER(10),
		CREATED_BY_SID				NUMBER(10),
		FILTER_XML					CLOB,
		RESPONSE_COLUMN_SID			NUMBER(10),
		TAG_LOOKUP_KEY_COLUMN_SID	NUMBER(10),
		IS_SYSTEM_GENERATED			NUMBER(10),
		CUSTOMER_ALERT_TYPE_ID		NUMBER(10),
		CAMPAIGN_END_DTM			DATE,
		SEND_ALERT					NUMBER(1),
		DYNAMIC						NUMBER(1),
		RESEND						NUMBER(1)
	);
/
CREATE OR REPLACE TYPE CAMPAIGNS.T_CAMPAIGN_TABLE IS TABLE OF CAMPAIGNS.T_CAMPAIGN_ROW;
/


ALTER TABLE csr.batch_job_srt_refresh ADD user_sid NUMBER(10) DEFAULT NVL(SYS_CONTEXT('SECURITY','SID'),3) NOT NULL;
ALTER TABLE CSR.METERING_OPTIONS ADD (
	PROC_API_KEY			VARCHAR2(256)
);
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE
ADD IS_FROM_BUS NUMBER(1) DEFAULT 0 NOT NULL;

DELETE FROM csr.compl_permit_application_pause cpap
 WHERE permit_application_id
	IN (SELECT permit_application_id FROM csr.compliance_permit_application cpa
		 WHERE application_type_id
		   NOT IN (SELECT application_type_id FROM csr.compliance_application_type WHERE app_sid = cpa.app_sid)
		   AND app_sid = cpap.app_sid);

DELETE FROM csr.compliance_permit_application cpa
 WHERE application_type_id
   NOT IN (SELECT application_type_id FROM csr.compliance_application_type WHERE app_sid = cpa.app_sid);

ALTER TABLE csr.compliance_permit_application ADD CONSTRAINT fk_compl_permit_app_type_id
	FOREIGN KEY (app_sid, application_type_id)
	REFERENCES csr.compliance_application_type (app_sid, application_type_id);


grant execute on campaigns.t_campaign_row to surveys;
grant execute on campaigns.t_campaign_table to surveys;
grant select, delete on csr.flow_item to campaigns;
grant select on csr.quick_survey_response to campaigns;
grant select on csr.region to campaigns;
grant select, delete on csr.flow_state_log to campaigns;
grant select on csr.flow_transition_alert to campaigns;
grant select on csr.flow_involvement_type to campaigns;
grant delete on csr.flow_item_subscription to campaigns;
grant select on csr.trash to campaigns;
grant select, delete, insert, update on csr.flow_item_generated_alert to campaigns;
grant select on csr.qs_campaign to campaigns;
grant select on csr.deleg_plan_survey_region to campaigns;




INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (63, 'Set customer helper plugin', 'Provide name for a customer helper assembly', 'SetCustomerHelperAssembly', 'W3161');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (63, 'Name of assembly', 'Typically "CustomerName.Helper"', 1, NULL);




BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (107, 'Create OWL client', 'CreateOwlClient', 'Creates the site you are logged in to as an OWL client.');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_admin_access', 'Admin access (Y/N)', 0);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_handling_office', 'Handling office. Must exist in owl.handling_office. Cambridge, eg.', 1);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_customer_name', 'The name of the customer', 2);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (107, 'in_parenthost', 'The parent host. Usually www.credit360.com', 3);
END;
/
UPDATE chain.card
   SET class_type = 'Credit360.Schema.Cards.RegionFilter'
 WHERE class_type = 'Credit360.Region.Cards.RegionFilter';
UPDATE csr.alert_frame_body
   SET html = REPLACE(html, '<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>', '<mergefield name="BODY" />')
 WHERE html LIKE '%<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>%';
UPDATE csr.default_alert_frame_body
   SET html = REPLACE(html, '<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>', '<mergefield name="BODY" />')
 WHERE html LIKE '%<img alt="Message body" title="The body of the message" style="vertical-align:middle" src="/csr/site/alerts/renderMergeField.ashx?field=BODY&'||'amp;text=Message+body&'||'amp;lang=en"></img>%';
DECLARE
	v_company_score_cap_id	NUMBER;
	v_supplier_score_cap_id	NUMBER;
	v_company_cap_id		NUMBER;
	v_supplier_cap_id		NUMBER;
	v_chg_already_applied	NUMBER;
	v_suppliers_cap_id			NUMBER;
	v_company_scores_pri_cap_id	NUMBER;
	v_company_scores_sec_cap_id	NUMBER;
BEGIN
	-- Log out of any apps from other scripts
	security.user_pkg.LogonAdmin;
	SELECT DECODE(COUNT(*), 0, 0, 1)
	  INTO v_chg_already_applied
	  FROM chain.capability
	 WHERE capability_name = 'Company scores';
	IF v_chg_already_applied = 1 THEN
		RETURN;
	END IF;
	-- COPIED FROM latest3035
	-- Change to specific capability and rename
	UPDATE chain.capability
	   SET capability_name = 'Company scores',
		   perm_type = 0
	 WHERE capability_name = 'Set company scores';
	
	SELECT capability_id INTO v_company_score_cap_id  FROM chain.capability WHERE is_supplier = 0 AND capability_name = 'Company scores';
	SELECT capability_id INTO v_supplier_score_cap_id FROM chain.capability WHERE is_supplier = 1 AND capability_name = 'Company scores';
	SELECT capability_id INTO v_company_cap_id		  FROM chain.capability WHERE is_supplier = 0 AND capability_name = 'Company';
	SELECT capability_id INTO v_supplier_cap_id		  FROM chain.capability WHERE is_supplier = 1 AND capability_name = 'Suppliers';
	-- We already have write capability from previous type, add read capbability from company
	-- There are some instances where user has write on score but not read on company
	UPDATE chain.company_type_capability cs
	   SET cs.permission_set = cs.permission_set + NVL((
		SELECT BITAND(permission_set, 1)
		  FROM chain.company_type_capability c
		 WHERE c.app_sid = cs.app_sid
		   AND c.primary_company_type_id = cs.primary_company_type_id
		   AND NVL(c.secondary_company_type_id, -1) = NVL(cs.secondary_company_type_id, -1)
		   AND NVL(c.primary_company_group_type_id, -1) = NVL(cs.primary_company_group_type_id, -1)
		   AND NVL(c.primary_company_type_role_sid, -1) = NVL(cs.primary_company_type_role_sid, -1)
		   AND c.capability_id IN (v_company_cap_id, v_supplier_cap_id)
		), 0)
	 WHERE cs.capability_id IN (v_company_score_cap_id, v_supplier_score_cap_id)
	   AND cs.permission_set IN (0, 2); -- check we haven't applied read permission before so script is rerunnable
	
	-- Where we have no capability already (i.e. no row in company_type_capability), we still want read access
	INSERT INTO chain.company_type_capability (app_sid, primary_company_type_id, secondary_company_type_id,
		   primary_company_group_type_id, primary_company_type_role_sid, capability_id, permission_set)
	SELECT app_sid, primary_company_type_id, secondary_company_type_id,
		   primary_company_group_type_id, primary_company_type_role_sid, 
		   DECODE(capability_id, v_company_cap_id, v_company_score_cap_id, v_supplier_cap_id, v_supplier_score_cap_id), 1
	  FROM chain.company_type_capability cs
	 WHERE BITAND(permission_set, 1) = 1
	   AND capability_id IN (v_company_cap_id, v_supplier_cap_id)
	   AND NOT EXISTS (
		SELECT *
		  FROM chain.company_type_capability c
		 WHERE c.app_sid = cs.app_sid
		   AND c.primary_company_type_id = cs.primary_company_type_id
		   AND NVL(c.secondary_company_type_id, -1) = NVL(cs.secondary_company_type_id, -1)
		   AND NVL(c.primary_company_group_type_id, -1) = NVL(cs.primary_company_group_type_id, -1)
		   AND NVL(c.primary_company_type_role_sid, -1) = NVL(cs.primary_company_type_role_sid, -1)
		   AND c.capability_id IN (v_company_score_cap_id, v_supplier_score_cap_id)
		);
	-- 	COPIED FROM latest3187
	-- Only these capabilities actually use anything other than Read and Write, and they only additional use Delete:	
	SELECT capability_id INTO v_company_cap_id				FROM chain.capability WHERE capability_name = 'Company';
	SELECT capability_id INTO v_suppliers_cap_id			FROM chain.capability WHERE capability_name = 'Suppliers';
	SELECT capability_id INTO v_company_scores_pri_cap_id	FROM chain.capability WHERE capability_name = 'Company scores' AND is_supplier = 0;
	SELECT capability_id INTO v_company_scores_pri_cap_id	FROM chain.capability WHERE capability_name = 'Company scores' AND is_supplier = 1;
	
	UPDATE chain.company_type_capability
	   SET permission_set = CASE
				WHEN capability_id IN (v_company_cap_id, v_suppliers_cap_id, v_company_scores_pri_cap_id, v_company_scores_pri_cap_id) THEN BITAND(permission_set, 7)
				ELSE BITAND(permission_set, 3)
		   END;
END;
/

BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description,  plugin_name, in_order, notify_address, max_retries,   priority, timeout_mins)
		 VALUES (86, 'OSHA Zipped Export', 'batch-exporter', 0, 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batched_export_type (label, assembly, batch_job_type_id)
		 VALUES ('OSHA Zipped Export', 'Credit360.ExportImport.Export.Batched.Exporters.OshaZippedBatchExporter', 86);
	
	INSERT INTO csr.osha_map_field (osha_map_field_id, label, pos)
		 VALUES (34, 'Standard Industrial Classification (SIC)', 34);
	INSERT INTO csr.osha_map_field_type (osha_map_field_id, osha_map_type_id)
		 VALUES (34, 1);
	INSERT INTO csr.osha_map_field_type (osha_map_field_id, osha_map_type_id)
		 VALUES (34, 2);
	INSERT INTO csr.osha_map_field_type (osha_map_field_id, osha_map_type_id)
		 VALUES (34, 3);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required, agg_type, osha_map_field_id)
		 VALUES (28, 'sic_code', 'Standard Industrial Classification (SIC), if known (e.g., SIC 3715)', 'Integer', 4, 1, 0, 34);
	UPDATE security.menu
	   SET description =  'OSHA Export'
	 WHERE description = 'OSHA 300A Export';
END;
/




CREATE OR REPLACE PACKAGE campaigns.campaign_pkg AS
END;
/
CREATE OR REPLACE PACKAGE BODY campaigns.campaign_pkg AS
END;
/
grant execute on csr.csr_data_pkg to campaigns;
grant execute on csr.campaign_pkg to campaigns;
grant execute on campaigns.campaign_pkg to surveys;
grant execute on campaigns.campaign_pkg to csr;
grant execute on campaigns.campaign_pkg to web_user;


@..\region_tree_pkg
@..\meter_pkg
@..\automated_import_pkg
@..\quick_survey_pkg
@..\region_report_pkg
@..\audit_pkg
@..\flow_pkg
@..\campaigns\campaign_pkg
@..\chain\type_capability_pkg
@..\util_script_pkg
@..\osha_pkg


@..\region_tree_body
@..\audit_body
@..\region_body
@..\csr_app_body
@..\meter_body
@..\automated_import_body
@..\quick_survey_body
@..\region_report_body
@..\tag_body
@..\workflow_api_body
@..\deleg_admin_body
@..\flow_body
@..\campaigns\campaign_body
@..\property_body
@..\chain\type_capability_body
@..\chain\company_filter_body
@..\util_script_body
@..\chain\activity_body
@..\osha_body
@..\enable_body



@update_tail
