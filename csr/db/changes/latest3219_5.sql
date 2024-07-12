-- Please update version.sql too -- this keeps clean builds in sync
define version=3219
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- fix for the build server that was failing to recompile suvey packages that never got updated through flyway
DECLARE
	v_count NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_count
	  FROM all_objects
	 WHERE owner = 'SURVEYS'
	   AND object_name = 'FLYWAY_VERSION';

	IF v_count = 0 THEN
		FOR r IN(
			SELECT object_name
			  FROM all_objects
			 WHERE owner = 'SURVEYS'
			   AND object_type = 'PACKAGE'
		)
		LOOP
			EXECUTE IMMEDIATE 'DROP PACKAGE SURVEYS.'||r.object_name;
		END LOOP;
	END IF;
END;
/


ALTER TYPE CAMPAIGNS.T_CAMPAIGN_ROW ADD ATTRIBUTE CAMPAIGN_SID NUMBER(10) CASCADE;

CREATE TABLE CAMPAIGNS.CAMPAIGN_REGION(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CAMPAIGN_SID				NUMBER(10, 0)	NOT NULL,
	REGION_SID					NUMBER(10, 0)	NOT NULL,
	HAS_MANUAL_AMENDS			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	PENDING_DELETION			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	REGION_SELECTION			VARCHAR2(2)	  	DEFAULT 'R' NOT NULL,
	TAG_ID						NUMBER(10, 0),
	CONSTRAINT CHK_CAMPAIGN_REG_PENDING_DEL CHECK (PENDING_DELETION IN (0,1,2)),
	CONSTRAINT CHK_CAMPAIGN_REGION_AMENDS CHECK (HAS_MANUAL_AMENDS IN (0,1)),
	CONSTRAINT CHK_CAMPAIGN_REGION_RS CHECK (REGION_SELECTION IN ('R','L','P','RT','LT','PT')),
	CONSTRAINT PK_CAMPAIGN_REGION PRIMARY KEY (APP_SID, CAMPAIGN_SID, REGION_SID)
)
;

CREATE INDEX CAMPAIGNS.IX_CAMPAIGN_REGION_TAG_ID ON CAMPAIGNS.CAMPAIGN_REGION(APP_SID, TAG_ID)
;

CREATE TABLE CAMPAIGNS.CAMPAIGN(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CAMPAIGN_SID				NUMBER(10, 0)	NOT NULL,
	NAME						VARCHAR2(255),
	TABLE_SID					NUMBER(10, 0),
	FILTER_SID					NUMBER(10, 0),
	SURVEY_SID					NUMBER(10, 0),
	FRAME_ID					NUMBER(10, 0),
	SUBJECT						CLOB,
	BODY						CLOB,
	SEND_AFTER_DTM				DATE,
	STATUS						VARCHAR2(20)	 DEFAULT 'draft' NOT NULL,
	SENT_DTM					DATE,
	PERIOD_START_DTM			DATE,
	PERIOD_END_DTM				DATE,
	AUDIENCE_TYPE				CHAR(2)		DEFAULT 'LF' NOT NULL,
	FLOW_SID					NUMBER(10, 0),
	INC_REGIONS_WITH_NO_USERS	NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	SKIP_OVERLAPPING_REGIONS	NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	CARRY_FORWARD_ANSWERS		NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	SEND_TO_COLUMN_SID			NUMBER(10, 0),
	REGION_COLUMN_SID			NUMBER(10, 0),
	CREATED_BY_SID				NUMBER(10, 0),
	FILTER_XML					CLOB,
	RESPONSE_COLUMN_SID			NUMBER(10, 0),
	TAG_LOOKUP_KEY_COLUMN_SID	NUMBER(10, 0),
	IS_SYSTEM_GENERATED			NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	CUSTOMER_ALERT_TYPE_ID		NUMBER(10, 0),
	CAMPAIGN_END_DTM			DATE,
	SEND_ALERT					NUMBER(1, 0)	 DEFAULT 1 NOT NULL,
	DYNAMIC						NUMBER(1, 0)	 DEFAULT 0 NOT NULL,
	RESEND						NUMBER(1, 0)	 DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_CARRY_FORWARD_ANSWERS CHECK (CARRY_FORWARD_ANSWERS IN (0,1)),
	CONSTRAINT CHK_CAMPAIGN_STATUS CHECK (STATUS IN ('draft', 'pending', 'sending', 'sent', 'error', 'emailing')),
	CONSTRAINT CHK_PERIOD_DATES CHECK ((period_start_dtm IS NULL AND period_end_dtm IS NULL) OR period_start_dtm < period_end_dtm),
	CONSTRAINT CHK_CAMPAIGN_AUD_TYPE CHECK (AUDIENCE_TYPE IN ('LF', 'WF')),
	CONSTRAINT CHK_AUDIENCE_REFERENCES CHECK ((AUDIENCE_TYPE='LF' AND FLOW_SID IS NULL) OR
	(AUDIENCE_TYPE='WF' AND TABLE_SID IS NULL AND FILTER_SID IS NULL)),
	CONSTRAINT CHK_QS_CAMP_REG_NO_USR_0_1 CHECK (INC_REGIONS_WITH_NO_USERS IN (0, 1)),
	CONSTRAINT CHK_SURVEY_SID_NOT_DRAFT CHECK ((LOWER(status) != 'draft' AND survey_sid IS NOT NULL) OR
	(LOWER(status) = 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NULL)),
	CONSTRAINT PK_CAMPAIGN PRIMARY KEY (APP_SID, CAMPAIGN_SID)
)
;

CREATE INDEX CAMPAIGNS.IX_CAMPAIGN_ALERT_TYPE_ID ON CAMPAIGNS.CAMPAIGN(APP_SID, CUSTOMER_ALERT_TYPE_ID)
;

CREATE INDEX CAMPAIGNS.IX_CAMPAIGN_FLOW_SID ON CAMPAIGNS.CAMPAIGN(APP_SID, FLOW_SID)
;

CREATE TABLE CSRIMP.CAMPAIGN(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    CAMPAIGN_SID              	NUMBER(10, 0)	NOT NULL,
    NAME                        VARCHAR2(255),
    TABLE_SID                   NUMBER(10, 0),
    FILTER_SID                  NUMBER(10, 0),
    SURVEY_SID                  NUMBER(10, 0),
    FRAME_ID                    NUMBER(10, 0),
    SUBJECT                     CLOB,
    BODY                        CLOB,
    SEND_AFTER_DTM              DATE,
    STATUS                      VARCHAR2(20)	NOT NULL,
    SENT_DTM                    DATE,
    PERIOD_START_DTM            DATE,
    PERIOD_END_DTM              DATE,
    AUDIENCE_TYPE               CHAR(2)			NOT NULL,
    FLOW_SID                    NUMBER(10, 0),  
    INC_REGIONS_WITH_NO_USERS   NUMBER(1, 0)	NOT NULL,
    SKIP_OVERLAPPING_REGIONS    NUMBER(1, 0)	NOT NULL,
	CARRY_FORWARD_ANSWERS		NUMBER(1)		NOT NULL,
	SEND_TO_COLUMN_SID			NUMBER(10),
	REGION_COLUMN_SID			NUMBER(10),
	CREATED_BY_SID				NUMBER(10),
	FILTER_XML					CLOB,
	RESPONSE_COLUMN_SID			NUMBER(10),
	TAG_LOOKUP_KEY_COLUMN_SID	NUMBER(10),
	IS_SYSTEM_GENERATED			NUMBER(10)		NOT NULL,
	CUSTOMER_ALERT_TYPE_ID		NUMBER(10),
	CAMPAIGN_END_DTM 			DATE,
	SEND_ALERT 					NUMBER(1)		NOT NULL,
	DYNAMIC 					NUMBER(1)		NOT NULL,
	RESEND 						NUMBER(1)		NOT NULL,
    CONSTRAINT CHK_CAMPAIGN_STATUS CHECK (STATUS IN ('draft', 'pending', 'sending', 'sent', 'error', 'emailing')),
    CONSTRAINT CHK_CMPGN_PERIOD_DATES CHECK ((period_start_dtm IS NULL AND period_end_dtm IS NULL) OR period_start_dtm < period_end_dtm),
    CONSTRAINT CHK_CAMPAIGNS_AUD_TYPE CHECK (AUDIENCE_TYPE IN ('LF', 'WF')),
    CONSTRAINT CHK_C_AUDIENCE_REFERENCES CHECK ((AUDIENCE_TYPE='LF' AND FLOW_SID IS NULL) OR
	(AUDIENCE_TYPE='WF' AND TABLE_SID IS NULL AND FILTER_SID IS NULL)),
    CONSTRAINT CHK_CAMP_REG_NO_USR_0_1 CHECK (INC_REGIONS_WITH_NO_USERS IN (0, 1)),
	CONSTRAINT CHK_C_CARRY_FORWARD_ANSWERS CHECK (CARRY_FORWARD_ANSWERS IN (0,1)),
	CONSTRAINT CHK_C_SURVEY_SID_NOT_DRAFT CHECK ((LOWER(status) != 'draft' AND survey_sid IS NOT NULL) OR
	(LOWER(status) = 'draft' AND survey_sid IS NOT NULL) OR (LOWER(status) = 'draft' AND survey_sid IS NULL)),
    CONSTRAINT PK_CAMPAIGN PRIMARY KEY (CSRIMP_SESSION_ID, CAMPAIGN_SID),
    CONSTRAINT FK_CAMPAIGN_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CAMPAIGN_REGION(
	CSRIMP_SESSION_ID			NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CAMPAIGN_SID				NUMBER(10, 0)	NOT NULL,
	REGION_SID					NUMBER(10, 0)	NOT NULL,
	HAS_MANUAL_AMENDS			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	PENDING_DELETION			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	REGION_SELECTION			VARCHAR2(2)	  	DEFAULT 'R' NOT NULL,
	TAG_ID						NUMBER(10, 0),
	CONSTRAINT CHK_CAMPAIGN_REG_PENDING_DEL CHECK (PENDING_DELETION IN (0,1,2)),
	CONSTRAINT CHK_CAMPAIGN_REGION_AMENDS CHECK (HAS_MANUAL_AMENDS IN (0,1)),
	CONSTRAINT CHK_CAMPAIGN_REGION_RS CHECK (REGION_SELECTION IN ('R','L','P','RT','LT','PT')),
	CONSTRAINT PK_CAMPAIGN_REGION PRIMARY KEY (CSRIMP_SESSION_ID, CAMPAIGN_SID, REGION_SID),
	CONSTRAINT FK_CAMPAIGN_REGION FOREIGN KEY
	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
	ON DELETE CASCADE
)
;


CREATE OR REPLACE TYPE CAMPAIGNS.T_REGION_OVERLAP_ROW AS
	OBJECT (
		REGION_SID					NUMBER(10),
		OVERLAPPING					NUMBER(1)
	);
/

CREATE OR REPLACE TYPE CAMPAIGNS.T_REGION_OVERLAP_TABLE IS TABLE OF CAMPAIGNS.T_REGION_OVERLAP_ROW;
/

CREATE TABLE CAMPAIGNS.CAMPAIGN_REGION_RESPONSE (
	APP_SID				NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CAMPAIGN_SID		NUMBER(10)	NOT NULL,
	REGION_SID			NUMBER(10)	NOT NULL,
	RESPONSE_ID			NUMBER(10)	NOT NULL,
	SURVEYS_VERSION		NUMBER(1)	NOT NULL,
	FLOW_ITEM_ID		NUMBER(10),
	CONSTRAINTS PK_CAMPAIGN_REGION_RESPONSE PRIMARY KEY (APP_SID, CAMPAIGN_SID, REGION_SID, RESPONSE_ID)
);

CREATE INDEX CAMPAIGNS.IX_CAMPAIGN_REG_RESP_FLOW_ITEM ON CAMPAIGNS.CAMPAIGN_REGION_RESPONSE(APP_SID, FLOW_ITEM_ID);

CREATE TABLE CSRIMP.CAMPAIGN_REGION_RESPONSE (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CAMPAIGN_SID		NUMBER(10)	NOT NULL,
	REGION_SID			NUMBER(10)	NOT NULL,
	RESPONSE_ID			NUMBER(10)	NOT NULL,
	SURVEYS_VERSION		NUMBER(1)	NOT NULL,
	FLOW_ITEM_ID		NUMBER(10),
	CONSTRAINTS PK_CAMPAIGN_REGION_RESPONSE PRIMARY KEY (CSRIMP_SESSION_ID, CAMPAIGN_SID, REGION_SID, RESPONSE_ID),
    CONSTRAINT FK_CMPGN_REGION_RESPONSE_CSI FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

ALTER TABLE CAMPAIGNS.CAMPAIGN_REGION ADD CONSTRAINT FK_CAMPAIGN_REGION_CAMPAIGN 
	FOREIGN KEY (APP_SID, CAMPAIGN_SID) REFERENCES CAMPAIGNS.CAMPAIGN (APP_SID, CAMPAIGN_SID);

ALTER TABLE CAMPAIGNS.CAMPAIGN_REGION_RESPONSE ADD CONSTRAINT FK_CAMP_REGION_RESP_CAMPAIGN 
	FOREIGN KEY (APP_SID, CAMPAIGN_SID) REFERENCES CAMPAIGNS.CAMPAIGN (APP_SID, CAMPAIGN_SID);

-- Alter tables
ALTER TABLE CSR.TPL_REPORT_TAG_SUGGESTION DROP CONSTRAINT FK_TPL_REPORT_TAG_SUG_CPN;
ALTER TABLE CSR.QS_FILTER_CONDITION_GENERAL DROP CONSTRAINT FK_QS_FLTR_CONDTN_GEN_CAMPAIGN;
ALTER TABLE CSR.DELEG_PLAN_COL DROP CONSTRAINT FK_DELEG_PLAN_COL_CAMP_SID;
ALTER TABLE CSR.QS_FILTER_CONDITION DROP CONSTRAINT FK_QS_FILTER_CONDITN_CAMPAIGN;
ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP CONSTRAINT FK_QS_CAMP_QS_RESPONSE;

-- *** Grants ***
grant select, update, delete, insert on csr.quick_survey_response to campaigns;
grant select on csr.quick_survey to campaigns;
grant select on csr.quick_survey_version to campaigns;
grant select on csr.region_survey_response to campaigns;
grant select on csr.flow to campaigns;
grant select, delete on csr.flow_item to campaigns;
grant select on csr.flow_state to campaigns;
grant select on csr.flow_state_role to campaigns;
grant select on csr.flow_state_role_capability to campaigns;
grant select on csr.flow_transition_alert to campaigns;
grant select on csr.flow_involvement_type to campaigns;
grant select on csr.flow_item_region to campaigns;
grant select, delete on csr.flow_state_log to campaigns;
grant select, delete, insert, update on csr.flow_item_generated_alert to campaigns;
grant delete on csr.flow_item_subscription to campaigns;
grant select on csr.region_role_member to campaigns;
grant select on csr.region to campaigns;
grant select on csr.region_tag to campaigns;
grant select on csr.region_type to campaigns;
grant select on csr.v$region to campaigns;
grant select on csr.v$quick_survey to campaigns;
grant select on csr.v$quick_survey_response to campaigns;
grant select on cms.tab to campaigns;
grant select on cms.tab_column to campaigns;
grant select on cms.filter to campaigns;
grant select on cms.v$form to campaigns;
grant select on security.securable_object to campaigns;
grant select on csr.trash to campaigns;
grant select on csr.alert_mail to campaigns;
grant select on csr.csr_user to campaigns;
grant select, references on csr.aggregate_ind_group to campaigns;
grant select on csr.flow_item_gen_alert_id_seq to campaigns;
grant select on csr.supplier to campaigns;
grant select on chain.supplier_relationship to campaigns;
grant select on chain.company to campaigns;
grant select on chain.supplier_involvement_type to campaigns;
grant select on chain.v$company_user to campaigns;
grant select on csr.v$open_flow_item_gen_alert to campaigns;
grant select on security.web_resource to campaigns;
grant select on csr.quick_survey_submission to campaigns;
grant select on csr.role to campaigns;
grant select, references on csr.score_type to campaigns;
grant select on chain.v$purchaser_involvement to campaigns;
grant select on csr.customer to campaigns;

grant execute on csr.csr_data_pkg to campaigns;
grant execute on csr.region_pkg to campaigns;
grant execute on security.security_pkg to campaigns;
grant execute on security.securableobject_pkg to campaigns;
grant execute on security.bitwise_pkg to campaigns;
grant execute on security.class_pkg to campaigns;
grant execute on csr.flow_pkg to campaigns;
grant execute on cms.tab_pkg to campaigns;
grant execute on csr.quick_survey_pkg to campaigns;
grant execute on csr.aggregate_ind_pkg to campaigns;
grant execute on chain.chain_pkg to campaigns;
grant execute on csr.stragg to campaigns;
grant execute on aspen2.error_pkg to campaigns;
grant execute on csr.supplier_pkg to campaigns;
grant execute on csr.trash_pkg to campaigns;

grant select on campaigns.campaign to csr;
grant select on campaigns.campaign_region to csr;
grant insert on campaigns.campaign to csrimp;
grant insert on campaigns.campaign_region to csrimp;
grant select, insert, delete, update on csr.temp_campaign_sid to campaigns;
grant select, insert, delete, update on csr.temp_region_sid to campaigns;

grant insert on campaigns.campaign_region to csrimp;
grant insert on campaigns.campaign to csrimp;

grant select on campaigns.campaign_region_response to csr;
grant insert on campaigns.campaign_region_response to csrimp;
grant select,insert,update,delete on csrimp.campaign_region_response to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
drop view csr.v$deleg_plan_survey_region;

-- *** Data changes ***
-- RLS

CREATE OR REPLACE FUNCTION campaigns.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN	
	-- Not logged on => see everything.  Support for old batch apps, should probably
	-- check for a special batch flag to work with the whole table?
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- Only show data if you are logged on and data is for the current application
	RETURN 'app_sid = sys_context(''SECURITY'', ''APP'')';	
END;
/


-- Data
BEGIN
	security.user_pkg.logonadmin;
	
	INSERT INTO campaigns.campaign (
	    app_sid,
	    campaign_sid,
	    name,
	    table_sid,
	    filter_sid,
	    survey_sid,
	    frame_id,
	    subject,
	    body,
	    send_after_dtm,
	    status,
	    sent_dtm,
	    period_start_dtm,
	    period_end_dtm,
	    audience_type,
	    flow_sid,
	    inc_regions_with_no_users,
	    skip_overlapping_regions,
	    carry_forward_answers,
	    send_to_column_sid,
	    region_column_sid,
	    created_by_sid,
	    filter_xml,
	    response_column_sid,
	    tag_lookup_key_column_sid,
	    is_system_generated,
	    customer_alert_type_id,
	    campaign_end_dtm,
	    send_alert,
	    dynamic,
	    resend
	)
	SELECT 
	    app_sid,
	    qs_campaign_sid,
	    name,
	    table_sid,
	    filter_sid,
	    survey_sid,
	    frame_id,
	    subject,
	    body,
	    send_after_dtm,
	    status,
	    sent_dtm,
	    period_start_dtm,
	    period_end_dtm,
	    audience_type,
	    flow_sid,
	    inc_regions_with_no_users,
	    skip_overlapping_regions,
	    carry_forward_answers,
	    send_to_column_sid,
	    region_column_sid,
	    created_by_sid,
	    filter_xml,
	    response_column_sid,
	    tag_lookup_key_column_sid,
	    is_system_generated,
	    customer_alert_type_id,
	    campaign_end_dtm,
	    send_alert,
	    dynamic,
	    resend
	  FROM csr.qs_campaign;
	
	INSERT INTO campaigns.campaign_region(
		app_sid,
		campaign_sid,
		region_sid,
		has_manual_amends,
		pending_deletion,
		region_selection,
		tag_id
	)
	SELECT 
		dpsr.app_sid,
		dpc.qs_campaign_sid,
		dpsr.region_sid,
		dpsr.has_manual_amends,
		dpsr.pending_deletion,
		dpsr.region_selection,
		dpsr.tag_id
	  FROM csr.deleg_plan_survey_region dpsr
	  JOIN csr.deleg_plan_col dpc ON dpc.deleg_plan_col_survey_id = dpsr.deleg_plan_col_survey_id;
	
	UPDATE csr.flow_alert_class
	   SET helper_pkg = 'csr.campaign_flow_helper_pkg'
	 WHERE flow_alert_class = 'campaign';
END;
/

DECLARE
	v_act	security.security_pkg.T_ACT_ID;
	v_sid	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
			SELECT app_sid FROM csr.customer
		 )
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.users', v_sid);
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
	security.user_pkg.logonadmin;

	INSERT INTO campaigns.campaign_region_response (app_sid, campaign_sid, region_sid, response_id, surveys_version, flow_item_id)
	SELECT qsr.app_sid, qsr.qs_campaign_sid, region_sid, qsr.survey_response_id, 1, fi.flow_item_id
	  FROM csr.quick_survey_response qsr 
	  JOIN csr.region_survey_response rsr ON rsr.survey_response_id = qsr.survey_response_id
	  LEFT JOIN csr.flow_item fi ON fi.survey_response_id = qsr.survey_response_id
	 WHERE qsr.qs_campaign_sid IS NOT NULL;
END;
/

-- ** New package grants **
revoke select on csr.qs_campaign from campaigns;
revoke select on csr.deleg_plan_survey_region from campaigns;


ALTER TABLE CSRIMP.DELEG_PLAN_SURVEY_REGION RENAME TO XX_DELEG_PLAN_SURVEY_REGION;
ALTER TABLE CSRIMP.QS_CAMPAIGN RENAME TO XX_QS_CAMPAIGN;

ALTER TABLE CSR.QS_CAMPAIGN DROP CONSTRAINT FK_QS_CAMP_FRAME_ID;
ALTER TABLE CSR.QS_CAMPAIGN DROP CONSTRAINT FK_QS_CAMPAIGN_ALERT_TYPE_ID;
ALTER TABLE CSR.QS_CAMPAIGN DROP CONSTRAINT FK_QS_CAMPAIGN_APP_SID;
ALTER TABLE CSR.QS_CAMPAIGN DROP CONSTRAINT FK_QS_CAMPAIGN_FLOW_SID;

ALTER TABLE CSR.DELEG_PLAN_SURVEY_REGION RENAME TO XX_DELEG_PLAN_SURVEY_REGION;
ALTER TABLE CSR.QS_CAMPAIGN RENAME TO XX_QS_CAMPAIGN;

grant execute on campaigns.t_campaign_table to csr;
grant execute on campaigns.campaign_pkg to security;

UPDATE security.securable_object_class
   SET helper_pkg = 'campaigns.campaign_pkg'
 WHERE class_name = 'CSRSurveyCampaign';
 
-- *** Conditional Packages ***
drop package csr.campaign_pkg;

-- *** Packages ***
@..\campaigns\campaign_pkg
@..\quick_survey_pkg
@..\flow_pkg
@..\campaign_flow_helper_pkg
@..\schema_pkg

@..\campaigns\campaign_body
@..\quick_survey_body
@..\quick_survey_report_body
@..\flow_body
@..\audit_body
@..\region_body
@..\enable_body
@..\alert_body
@..\csr_app_body
@..\schema_body
@..\util_script_body
@..\campaign_flow_helper_body
@..\workflow_api_body
@..\deleg_plan_body
@..\csrimp\imp_body

@update_tail
