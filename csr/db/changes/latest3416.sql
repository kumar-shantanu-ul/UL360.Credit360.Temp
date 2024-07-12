define version=3416
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

CREATE OR REPLACE TYPE CSR.T_FIRST_SHEET_ACTION_DTM AS
	OBJECT (
		app_sid 				NUMBER(10),
		sheet_id 				NUMBER(10),
		first_action_dtm 		DATE
	);
/
CREATE OR REPLACE TYPE CSR.T_FIRST_SHEET_ACTION_DTM_TABLE AS
	TABLE OF CSR.T_FIRST_SHEET_ACTION_DTM;
/
DROP TABLE csr.temp_first_sheet_action_dtm;
CREATE OR REPLACE TYPE CSR.T_DELEGATION_DETAIL AS
	OBJECT (
		sheet_id						number(10),
		parent_sheet_id					number(10),
		delegation_sid					number(10),
		parent_delegation_sid			number(10),
		is_visible						number(1),
		name							varchar2(1023),
		start_dtm						date,
		end_dtm							date,
		period_set_id					number(10),
		period_interval_id				number(10),
		delegation_start_dtm			date,
		delegation_end_dtm				date,
		submission_dtm					date,
		status							number(10),
		sheet_action_description		varchar2(255),
		sheet_action_downstream			varchar2(255),
		fully_delegated					number(1),
		editing_url						varchar2(255),
		last_action_id					number(10),
		is_top_level					number(1),
		approve_dtm						date,
		delegated_by_user				number(1),
		percent_complete				number(10,0),
		rid								number(10),
		root_delegation_sid				number(10),
		parent_sid						number(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_DELEGATION_DETAIL_TABLE AS
	TABLE OF CSR.T_DELEGATION_DETAIL;
/
CREATE OR REPLACE TYPE CSR.T_DELEGATION_USER AS
	OBJECT (
		delegation_sid 					NUMBER(10),
		user_sid 						NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_DELEGATION_USER_TABLE AS
	TABLE OF CSR.T_DELEGATION_USER;
/
CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_ISSUES AS
	OBJECT (
		APP_SID							NUMBER(10),
		ISSUE_LOG_ID					NUMBER(10),
		CSR_USER_SID					NUMBER(10),
		FRIENDLY_NAME					VARCHAR2(255),
		FULL_NAME						VARCHAR2(256),
		EMAIL							VARCHAR2(256)
	);
/
CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_ISSUES_TABLE AS
	TABLE OF CSR.T_ALERT_BATCH_ISSUES;
/
CREATE OR REPLACE TYPE CSR.T_SHEETS_IND_REG_TO_USE_ROW AS
  OBJECT (
  APP_SID             NUMBER(10),
  DELEGATION_SID      NUMBER(10),
  LVL                 NUMBER(10),
  SHEET_ID            NUMBER(10),
  IND_SID             NUMBER(10),
  REGION_SID          NUMBER(10),
  START_DTM           DATE,
  END_DTM             DATE,
  LAST_ACTION_COLOUR  VARCHAR2(1)
  );
/
CREATE OR REPLACE TYPE CSR.T_SHEETS_IND_REG_TO_USE_TABLE AS 
  TABLE OF CSR.T_SHEETS_IND_REG_TO_USE_ROW;
/
CREATE OR REPLACE TYPE CHAIN.T_CUSTOMER_OPTIONS_PARAM_ROW AS
	OBJECT (
		id        NUMBER(10),     
		name      VARCHAR2(100), 
		value     VARCHAR2(4000),
		data_type VARCHAR2(100), 
		nullable  NUMBER(1)  
	);
/
CREATE OR REPLACE TYPE CHAIN.T_CUSTOMER_OPTIONS_PARAM_TABLE AS
	TABLE OF CHAIN.T_CUSTOMER_OPTIONS_PARAM_ROW;
/
CREATE OR REPLACE TYPE CHAIN.T_MESSAGE_SEARCH_ROW AS
	OBJECT (
		message_id 							NUMBER(10),
		message_definition_id 				NUMBER(10),
		to_company_sid 						NUMBER(10),
		to_user_sid 						NUMBER(10),
		re_company_sid 						NUMBER(10),
		re_user_sid 						NUMBER(10),
		re_questionnaire_type_id 			NUMBER(10),
		re_component_id 					NUMBER(10),
		order_by_dtm 						TIMESTAMP(6),
		last_refreshed_by_user_sid 			NUMBER(10),
		completed_by_user_sid				NUMBER(10),
		viewed_dtm 							TIMESTAMP(6),
		re_secondary_company_sid 			NUMBER(10),
		re_invitation_id 					NUMBER(10),
		re_audit_request_id 				NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CHAIN.T_MESSAGE_SEARCH_TABLE AS
	TABLE OF CHAIN.T_MESSAGE_SEARCH_ROW;
/
CREATE OR REPLACE TYPE CHAIN.T_FILTER_VALUE_MAP_ROW AS
	OBJECT (
		OLD_FILTER_VALUE_ID       NUMBER(10),
		NEW_FILTER_VALUE_ID       NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CHAIN.T_FILTER_VALUE_MAP_TABLE AS
	TABLE OF CHAIN.T_FILTER_VALUE_MAP_ROW;
/
CREATE OR REPLACE TYPE CHAIN.T_REFERENCE_LABEL_ROW AS
	OBJECT (
		COMPANY_SID	NUMBER(10,0),
		NAME		VARCHAR2(255 BYTE),
		LOOKUP_KEY	VARCHAR2(255 BYTE)
	);
/
CREATE OR REPLACE TYPE CHAIN.T_REFERENCE_LABEL_TABLE AS
	TABLE OF CHAIN.T_REFERENCE_LABEL_ROW;
/
CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED_ROW AS
	OBJECT (
		IND_SID				NUMBER(10),
		REGION_SID			NUMBER(10),
		PERIOD_START_DTM	DATE,
		PERIOD_END_DTM		DATE,
		VAL_NUMBER			NUMBER(24,10),
		SOURCE_TYPE_ID		NUMBER(10),
		SOURCE_ID			NUMBER(10)
	);
/
CREATE OR REPLACE TYPE CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED_TABLE AS
	TABLE OF CSR.T_LIKE_FOR_LIKE_VAL_NORMALISED_ROW;
/


ALTER TABLE csr.auto_imp_importer_plugin
ADD allow_manual NUMBER(1) DEFAULT 1 NOT NULL;
ALTER TABLE csr.auto_imp_importer_plugin
ADD CONSTRAINT CK_AUTO_IMP_IMPRTR_PLGN_MAN CHECK (ALLOW_MANUAL IN (0,1));


grant select, references, insert, update, delete on chain.supplier_relationship to CSR;
grant select, references, insert, update, delete on chain.company_type to csr;








UPDATE csr.auto_imp_importer_plugin
   SET allow_manual = 0
 WHERE importer_assembly = 'Credit360.ExportImport.Automated.Import.Importers.XmlBulkImporter';






@..\region_pkg
@..\delegation_pkg
@..\enable_pkg
@..\stored_calc_datasource_pkg
@..\supplier_pkg
@..\like_for_like_pkg


@..\region_body
@..\delegation_body
@..\issue_body
@..\enable_body
@..\csr_app_body
@..\stored_calc_datasource_body
@..\chain\admin_helper_body
@..\chain\company_body
@..\chain\message_body
@..\chain\filter_body
@..\supplier_body
@..\like_for_like_body
@..\automated_import_body



@update_tail
