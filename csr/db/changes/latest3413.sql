define version=3413
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

CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_DETAILS_ROW AS
  OBJECT (
  APP_SID					NUMBER(10),
  CSR_USER_SID				NUMBER(10),
  FULL_NAME					VARCHAR2(256),
  FRIENDLY_NAME				VARCHAR2(256),
  EMAIL						VARCHAR2(256),
  USER_NAME					VARCHAR2(256),
  SHEET_ID					NUMBER(10),
  SHEET_URL					VARCHAR2(400),
  DELEGATION_NAME			VARCHAR2(1023),
  PERIOD_SET_ID				NUMBER(10),
  PERIOD_INTERVAL_ID		NUMBER(10),
  DELEGATION_SID			NUMBER(10),
  SUBMISSION_DTM			DATE,
  REMINDER_DTM				DATE,
  START_DTM					DATE,
  END_DTM					DATE
  );
/
CREATE OR REPLACE TYPE CSR.T_ALERT_BATCH_DETAILS_TABLE AS 
  TABLE OF CSR.T_ALERT_BATCH_DETAILS_ROW;
/
CREATE OR REPLACE TYPE CSR.T_FLOW_FILTER_DATA_ROW AS
	OBJECT (
		ID						NUMBER(10),
		IS_EDITABLE				NUMBER(1)
	);
/
CREATE OR REPLACE TYPE CSR.T_FLOW_FILTER_DATA_TABLE AS
	TABLE OF CSR.T_FLOW_FILTER_DATA_ROW;
/


ALTER TABLE CSR.PROJECT_INITIATIVE_METRIC DROP CONSTRAINT FK_PRJ_PRJ_INIT_MET;
ALTER TABLE CSR.PROJECT_INITIATIVE_METRIC ADD CONSTRAINT FK_PRJ_PRJ_INIT_MET 
    FOREIGN KEY (APP_SID, PROJECT_SID, FLOW_SID)
    REFERENCES CSR.INITIATIVE_PROJECT(APP_SID, PROJECT_SID, FLOW_SID)
    DEFERRABLE INITIALLY DEFERRED;
















@..\notification_pkg
@..\sustain_essentials_pkg
@..\alert_pkg
@..\delegation_pkg
@..\enable_pkg
@..\audit_pkg
@..\energy_star_pkg


@..\notification_body
@..\sustain_essentials_body
@..\initiative_project_body
@..\csr_app_body
@..\alert_body
@..\delegation_body
@..\sheet_body
@..\property_body
@..\audit_body
@..\energy_star_body



@update_tail
