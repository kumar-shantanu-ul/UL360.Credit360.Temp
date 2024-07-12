define version=3221
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


ALTER TABLE csr.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE CSR.TPL_REPORT_TAG ADD (
	CONSTRAINT CT_TPL_REPORT_TAG CHECK (
		(TAG_TYPE IN (1,4,5,14) AND TPL_REPORT_TAG_IND_ID IS NOT NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 6 AND TPL_REPORT_TAG_EVAL_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE IN (2,3,101) AND TPL_REPORT_TAG_DATAVIEW_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 7 AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 8 AND TPL_REP_CUST_TAG_TYPE_ID IS NOT NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 9 AND TPL_REPORT_TAG_TEXT_ID IS NOT NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = -1 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 10 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 11 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NOT NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 102 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NOT NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 103 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NOT NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 13 AND TPL_REPORT_TAG_SUGGESTION_ID IS NOT NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL)
	)
);
ALTER TABLE csrimp.tpl_report_tag DROP CONSTRAINT ct_tpl_report_tag;
ALTER TABLE CSRIMP.TPL_REPORT_TAG ADD (
	CONSTRAINT CT_TPL_REPORT_TAG CHECK (
		(TAG_TYPE IN (1,4,5,14) AND TPL_REPORT_TAG_IND_ID IS NOT NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 6 AND TPL_REPORT_TAG_EVAL_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE IN (2,3,101) AND TPL_REPORT_TAG_DATAVIEW_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 7 AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NOT NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 8 AND TPL_REP_CUST_TAG_TYPE_ID IS NOT NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 9 AND TPL_REPORT_TAG_TEXT_ID IS NOT NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = -1 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 10 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 11 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NOT NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 102 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NOT NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 103 AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NOT NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 12 AND TPL_REPORT_TAG_QC_ID IS NOT NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL AND TPL_REPORT_TAG_SUGGESTION_ID IS NULL)
		OR (TAG_TYPE = 13 AND TPL_REPORT_TAG_SUGGESTION_ID IS NOT NULL AND TPL_REPORT_TAG_DATAVIEW_ID IS NULL AND TPL_REPORT_TAG_IND_ID IS NULL AND TPL_REPORT_TAG_EVAL_ID IS NULL AND TPL_REPORT_TAG_LOGGING_FORM_ID IS NULL AND TPL_REP_CUST_TAG_TYPE_ID IS NULL AND TPL_REPORT_TAG_TEXT_ID IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND TPL_REPORT_TAG_APP_NOTE_ID IS NULL AND TPL_REPORT_TAG_APP_MATRIX_ID IS NULL AND TPL_REPORT_TAG_REG_DATA_ID IS NULL)
	)
);
ALTER TABLE CSR.TPL_REPORT_TAG_IND ADD (SHOW_FULL_PATH NUMBER(1) DEFAULT 0 NOT NULL);
ALTER TABLE CSR.TPL_REPORT_TAG_IND ADD CONSTRAINT CHK_TPL_RPT_TAG_IND_SFP CHECK (SHOW_FULL_PATH IN (1,0));
ALTER TABLE CSRIMP.TPL_REPORT_TAG_IND ADD (SHOW_FULL_PATH NUMBER(1) NOT NULL);
ALTER TABLE CSRIMP.TPL_REPORT_TAG_IND ADD CONSTRAINT CHK_TPL_RPT_TAG_IND_SFP CHECK (SHOW_FULL_PATH IN (1,0));
ALTER TABLE CSR.TPL_REPORT_TAG_SUGGESTION DROP CONSTRAINT FK_TPL_REPORT_TAG_SUG_CPN;
ALTER TABLE CSR.QS_FILTER_CONDITION_GENERAL DROP CONSTRAINT FK_QS_FLTR_CONDTN_GEN_CAMPAIGN;
ALTER TABLE CSR.DELEG_PLAN_COL DROP CONSTRAINT FK_DELEG_PLAN_COL_CAMP_SID;
ALTER TABLE CSR.QS_FILTER_CONDITION DROP CONSTRAINT FK_QS_FILTER_CONDITN_CAMPAIGN;
ALTER TABLE CSR.QUICK_SURVEY_RESPONSE DROP CONSTRAINT FK_QS_CAMP_QS_RESPONSE;


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




drop view csr.v$deleg_plan_survey_region;


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


BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description,  plugin_name, in_order, notify_address, max_retries, priority, timeout_mins)
	VALUES (87, 'Indicator selections groups translation export', 'batch-exporter', 0, 'support@credit360.com', 3, 1, 120);
	INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (87, 'Indicator selections translation export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorSelectionsTranslationExporter');
	
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (88, 'Indicator selection groups translations import', null, 'batch-importer', 0, null, 120);
	INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
	VALUES (88, 'Indicator selections translations import', 'Credit360.ExportImport.Import.Batched.Importers.Translations.IndicatorSelectionsTranslationImporter');
END;
/
INSERT INTO chem.usage_audit_log (app_sid, changed_by, changed_dtm, description, end_dtm, param_1, param_2, region_sid, root_delegation_sid, start_dtm, substance_id, usage_audit_log_id)
SELECT app_sid, changed_by, changed_dtm, 'Copied forward substance {0}', end_dtm, NULL, NULL, region_sid, root_delegation_sid, start_dtm, substance_id, chem.usage_audit_log_id_seq.NEXTVAL
  FROM (
	SELECT app_sid, changed_by, changed_dtm, end_dtm, mass_value, region_sid, root_delegation_sid, start_dtm, substance_id, retired_dtm,
		LAG(mass_value, 1) OVER (ORDER BY substance_id, region_sid, root_delegation_sid, start_dtm, changed_dtm) AS mass_value_prev
	  FROM chem.substance_process_use_change
) c
WHERE c.mass_value IS NULL
AND c.mass_value_prev IS NOT NULL
AND NOT EXISTS (
	SELECT NULL
	  FROM chem.usage_audit_log l
	 WHERE l.substance_id = c.substance_id
	   AND l.region_sid = c.region_sid
	   AND l.start_dtm = c.start_dtm
	   AND l.end_dtm = c.end_dtm
	   AND l.root_delegation_sid = c.root_delegation_sid
	   AND l.changed_dtm = c.changed_dtm
);
INSERT INTO chem.usage_audit_log (app_sid, changed_by, changed_dtm, description, end_dtm, param_1, param_2, region_sid, root_delegation_sid, start_dtm, substance_id, usage_audit_log_id)
SELECT app_sid, changed_by, changed_dtm, 'Chemical consumption changed for {0} from {1}kg to {2}kg', end_dtm, mass_value_prev, mass_value, region_sid, root_delegation_sid, start_dtm, substance_id, chem.usage_audit_log_id_seq.NEXTVAL
  FROM (
	SELECT app_sid, changed_by, changed_dtm, end_dtm, mass_value, region_sid, root_delegation_sid, start_dtm, substance_id, retired_dtm,
		LAG(mass_value, 1, -1) OVER (ORDER BY substance_id, region_sid, root_delegation_sid, start_dtm, changed_dtm) AS mass_value_prev
	  FROM chem.substance_process_use_change
) c
WHERE DECODE(c.mass_value_prev, -1, 0, 1) = 1 
AND c.mass_value IS NOT NULL
AND NOT EXISTS (
	SELECT NULL
	  FROM chem.usage_audit_log l
	 WHERE l.substance_id = c.substance_id
	   AND l.region_sid = c.region_sid
	   AND l.start_dtm = c.start_dtm
	   AND l.end_dtm = c.end_dtm
	   AND l.root_delegation_sid = c.root_delegation_sid
	   AND l.changed_dtm = c.changed_dtm
);
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
BEGIN
	/*
	Expected working sites are:
		-- biogen.credit360.com
		-- lendleasefootprint.credit360.com
		-- hyatt.credit360.com
	
	Leaving pilot sites as is:
		--'lendlease-pilot.credit360.com',
		--'vattenfall-pilot.credit360.com',
		--'biogen-copy.credit360.com',
		--'metrogroup-pilot.credit360.com',
		--'psjh-pilot.credit360.com',
		--'capitaland-pilot.credit360.com',
		--'volvocars-pilot.credit360.com',
		--'tesla-pilot.credit360.com',
	*/
	FOR r IN (SELECT app_sid FROM csr.customer WHERE name IN (
		'prop.credit360.com',
		'chandra-liyanage-demo.credit360.com',
		'bdclone.credit360.com',
		'phyllis-davies.credit360.com',
		'tinabean.credit360.com',
		'rs-prop.credit360.com',
		'msdemo.credit360.com',
		'jk-prop1.credit360.com',
		'shsusdemo.credit360.com',
		'lenanewkold.credit360.com',
		'mmdemo.credit360.com',
		'ambermehta.credit360.com',
		'sam-mw.credit360.com',
		'kimberly-ake-demo.credit360.com',
		'andreacoberly.credit360.com',
		'latamclone.credit360.com',
		'jmsusdemo.credit360.com',
		'salmanrashid.credit360.com',
		'amsusdemo.credit360.com'))
	LOOP
		UPDATE csr.Degreeday_Settings
		   SET download_enabled = 0
		 WHERE app_sid = r.app_sid;
	END LOOP;
END;
/


drop package csr.campaign_pkg;


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
 


@..\indicator_pkg
@..\customer_pkg
@..\templated_report_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\campaigns\campaign_pkg
@..\quick_survey_pkg
@..\flow_pkg
@..\campaign_flow_helper_pkg
@..\schema_pkg


@..\portlet_body
@..\enable_body
@..\factor_body
@..\indicator_body
@..\customer_body
@..\schema_body
@..\templated_report_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\filter_body
@..\chain\filter_body
@..\chem\audit_body
@..\chem\substance_body
@..\chem\substance_helper_body
@..\section_body
@..\scenario_run_body
@..\campaigns\campaign_body
@..\quick_survey_body
@..\quick_survey_report_body
@..\flow_body
@..\audit_body
@..\region_body
@..\alert_body
@..\csr_app_body
@..\util_script_body
@..\campaign_flow_helper_body
@..\workflow_api_body
@..\deleg_plan_body
@..\property_body



@update_tail
