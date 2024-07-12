define version=3197
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
CREATE SEQUENCE CSR.SSP_ID_SEQ;
CREATE SEQUENCE CSR.SSPL_ID_SEQ;
CREATE TABLE CSR.SCHEDULED_STORED_PROC_LOG (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SSP_LOG_ID						NUMBER(10, 0)	NOT NULL,
	SSP_ID							NUMBER(10, 0)	NOT NULL,
	RUN_DTM							TIMESTAMP,
	RESULT_CODE						NUMBER(10, 0),
	RESULT_MSG						VARCHAR2(1024),
	RESULT_EX						CLOB,
	ONE_OFF							NUMBER(1, 0),
	ONE_OFF_USER					NUMBER(10, 0),
	ONE_OFF_DATE					TIMESTAMP,
	CONSTRAINT PK_SSPL PRIMARY KEY (APP_SID, SSP_LOG_ID)
);
CREATE TABLE CSR.OSHA_BASE_DATA(
	OSHA_BASE_DATA_ID				NUMBER(10,0)	NOT NULL,
	DATA_ELEMENT					VARCHAR2(50)	NOT NULL,
	DEFINITION_AND_VALIDATIONS		VARCHAR2(2000)	NOT NULL,
	FORMAT							VARCHAR2(10)	NOT NULL,
	LENGTH							NUMBER(3,0)		NOT NULL,
	REQUIRED						NUMBER(1)		NOT NULL,
	CONSTRAINT PK_OSHA_BASE_DATA 	PRIMARY KEY (OSHA_BASE_DATA_ID)
)
;
CREATE TABLE CSR.OSHA_MAPPING(
	APP_SID					NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OSHA_BASE_DATA_ID		NUMBER(10,0)	NOT NULL,
	IND_SID					NUMBER(10,0),
	CMS_COL_SID				NUMBER(10,0),
CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (APP_SID, OSHA_BASE_DATA_ID, IND_SID, CMS_COL_SID),
CONSTRAINT FK_OSHA_BASE_DATA_ID FOREIGN KEY (OSHA_BASE_DATA_ID) REFERENCES CSR.OSHA_BASE_DATA (OSHA_BASE_DATA_ID),
CONSTRAINT FK_IND_SID FOREIGN KEY (IND_SID) REFERENCES CSR.IND (IND_SID)
)
;
CREATE TABLE CSRIMP.OSHA_MAPPING(
	APP_SID					NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OSHA_BASE_DATA_ID		NUMBER(10,0)	NOT NULL,
	IND_SID					NUMBER(10,0),
	CMS_COL_SID				NUMBER(10,0),
CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (APP_SID, OSHA_BASE_DATA_ID, IND_SID, CMS_COL_SID)
)
;
create index csr.ix_osha_mapping_ind_sid on csr.osha_mapping (ind_sid);
create index csr.ix_osha_mapping_osha_base_dat on csr.osha_mapping (osha_base_data_id);
CREATE TABLE CSR.DELETED_DELEGATION_DESCRIPTION(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEGATION_SID    NUMBER(10, 0)     NOT NULL,
    LANG              VARCHAR2(10)      NOT NULL,
    DESCRIPTION       VARCHAR2(1023)    NOT NULL,
    CONSTRAINT PK_DEL_DELEGATION_DESCRIPTION PRIMARY KEY (APP_SID, DELEGATION_SID, LANG)
)
;
ALTER TABLE CSR.DELETED_DELEGATION_DESCRIPTION ADD CONSTRAINT FK_DEL_DELEGATION_DESCRIPTION
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES CSR.DELETED_DELEGATION(APP_SID, DELEGATION_SID) ON DELETE CASCADE
;
CREATE INDEX CSR.IX_DELETED_DELEG_DESC_DD ON CSR.DELETED_DELEGATION_DESCRIPTION(APP_SID, DELEGATION_SID)
;


ALTER TABLE csr.automated_import_class
  ADD pending_files_limit NUMBER(3) DEFAULT 20 NOT NULL;
 
ALTER TABLE csr.automated_import_class
  ADD CONSTRAINT ck_auto_imp_cls_files_limit CHECK (pending_files_limit <= 100);
  
ALTER TABLE CSR.SCHEDULED_STORED_PROC ADD (
	SSP_ID							NUMBER(10, 0),
	ARGS							VARCHAR2(1024),
	ONE_OFF							NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ONE_OFF_USER					NUMBER(10, 0),
	ONE_OFF_DATE					TIMESTAMP,
	LAST_SSP_LOG_ID					NUMBER(10, 0),
	ENABLED							NUMBER(1, 0) DEFAULT 0 NOT NULL,
	SCHEDULE_RUN_DTM				TIMESTAMP
);
UPDATE CSR.SCHEDULED_STORED_PROC SET SSP_ID = CSR.SSP_ID_SEQ.NEXTVAL, ENABLED = 1, SCHEDULE_RUN_DTM = NEXT_RUN_DTM;
INSERT INTO CSR.SCHEDULED_STORED_PROC_LOG
(APP_SID, SSP_LOG_ID, SSP_ID, RUN_DTM, RESULT_CODE, RESULT_MSG, RESULT_EX, ONE_OFF, ONE_OFF_USER)
SELECT APP_SID, CSR.SSPL_ID_SEQ.NEXTVAL, SSP_ID, LAST_RUN_DTM, LAST_RESULT, LAST_RESULT_MSG, LAST_RESULT_EX, 0, NULL
  FROM CSR.SCHEDULED_STORED_PROC;
ALTER TABLE CSR.SCHEDULED_STORED_PROC DROP (LAST_RUN_DTM, LAST_RESULT, LAST_RESULT_MSG, LAST_RESULT_EX);
ALTER TABLE CSR.SCHEDULED_STORED_PROC DROP CONSTRAINT PK_SSP DROP INDEX;
ALTER TABLE CSR.SCHEDULED_STORED_PROC ADD CONSTRAINT PK_SSP PRIMARY KEY (APP_SID, SSP_ID);
CREATE UNIQUE INDEX CSR.UK_SSP ON CSR.SCHEDULED_STORED_PROC(APP_SID, SP,  NVL(ARGS, ' '));
ALTER TABLE CSR.SCHEDULED_STORED_PROC_LOG ADD CONSTRAINT FK_SSPL_SSP
	FOREIGN KEY (APP_SID, SSP_ID)
	REFERENCES CSR.SCHEDULED_STORED_PROC(APP_SID, SSP_ID)
;
CREATE INDEX CSR.IX_SSPL_SSP ON CSR.SCHEDULED_STORED_PROC_LOG(APP_SID, SSP_ID);
ALTER TABLE CSR.SCHEDULED_STORED_PROC ADD CONSTRAINT FK_SSP_SSPL
	FOREIGN KEY (APP_SID, LAST_SSP_LOG_ID)
	REFERENCES CSR.SCHEDULED_STORED_PROC_LOG(APP_SID, SSP_LOG_ID)
;
CREATE INDEX CSR.IX_SSP_SSPL ON CSR.SCHEDULED_STORED_PROC(APP_SID, LAST_SSP_LOG_ID);
ALTER TABLE CSRIMP.SCHEDULED_STORED_PROC ADD (
	SSP_ID							NUMBER(10, 0),
	ONE_OFF							NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ONE_OFF_USER					NUMBER(10, 0),
	ONE_OFF_DATE					TIMESTAMP,
	LAST_SSP_LOG_ID					NUMBER(10, 0),
	ENABLED							NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	SCHEDULE_RUN_DTM				TIMESTAMP
);
ALTER TABLE CSRIMP.SCHEDULED_STORED_PROC DROP (LAST_RUN_DTM, LAST_RESULT, LAST_RESULT_MSG, LAST_RESULT_EX);
ALTER TABLE csr.osha_mapping DROP CONSTRAINT PK_OSHA_MAPPING;
ALTER TABLE csr.osha_mapping ADD CONSTRAINT PK_OSHA_MAPPING PRIMARY KEY (APP_SID, OSHA_BASE_DATA_ID);
ALTER TABLE csr.automated_import_class_step
MODIFY (days_to_retain_payload DEFAULT 90);










UPDATE csr.automated_import_class
   SET pending_files_limit = 0
 WHERE automated_import_class_sid IN (
	SELECT automated_import_class_sid 
	  FROM csr.automated_import_class_step 
	 WHERE importer_plugin_id = 2
	 );
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Rerun Scheduled Scripts (SSPs)', 0, 'Allow user to rerun scheduled database scripts (SSPs)');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Disable Scheduled Scripts (SSPs)', 0, 'Allow user to enable and disable scheduled database scripts (SSPs)');
DECLARE
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
	security.user_pkg.logonAdmin();
	FOR r IN (
		SELECT DISTINCT host
		  FROM csr.scheduled_stored_proc ssp
		  JOIN csr.customer c ON ssp.app_sid = c.app_sid
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		
		EnableCapability('Rerun Scheduled Scripts (SSPs)');
		EnableCapability('Disable Scheduled Scripts (SSPs)');
		
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/
BEGIN
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (1, 'establishment_name', 'The name of the establishment reporting data. The system matches the data in your file to existing establishments based on establishment name. <b><u>Each establishment MUST have a unique name.</u></b>', 'Character', 100, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (2, 'company_name', 'The name of the company that owns the establishment.', 'Character', 100, 0);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (3, 'street_address', 'The street address of the establishment. <ul><li>Should not contain a PO Box address</li></ul>', 'Character', 100, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (4, 'city', 'The city where the establishment is located.', 'Character', 100, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (5, 'state', 'The state where the establishment is located. <ul><li>Enter the two character postal code for the U.S. State or Territory in which the establishment is located.</li></ul>', 'Character', 2, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (6, 'zip', 'The full zip code for the establishment. <ul><li>Must be a five or nine digit number</li></ul>', 'Text', 9, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (7, 'naics_code', 'The North American Industry Classification System (NAICS) code which classifies an establishment’s business. Use a 2012 code, found here:<a href="http://www.census.gov/cgibin/sssd/naics/naicsrch?chart=2012">http://www.census.gov/cgibin/sssd/naics/naicsrch?chart=2012</a><ul><li>Must be a number and be 6 digits in length</li></ul>', 'Integer', 6, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (8, 'industry_description', 'Industry Description <ul><li>You may provide an industry description in addition to your NAICS code.</li></ul>', 'Character', 300, 0);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (9, 'size', 'The size of the establishment based on the maximum number of employees which worked there <b><u>at any point</u></b> in the year you are submitting data for.<ul><li>Enter 1 if the establishment has < 20 employees</li><li>Enter 2 if the establishment has 20-249 employees</li><li>Enter 3 if the establishment has 250+ employees</li></ul>', 'Integer', 1, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (10, 'establishment_type', 'Identify if the establishment is part of a state or local government. <ul><li>Enter 1 if the establishment is not a government entity</li><li>Enter 2 if the establishment is a State Government entity</li><li>Enter 3 if the establishment is a Local Government entity</li></ul>', 'Integer', 1, 0);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (11, 'year_filing_for', 'The calendar year in which the injuries and illnesses being reported occurred at the establishment. <ul><li>Must be a four digit number</li><li>Cannot be earlier than 2016</li></ul>', 'Integer', 4, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (12, 'annual_average_employees', 'Annual Average Number of Employees<ul><li>Must be > 0</li><li>Must be a number</li><li>Should be < 25,000</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (13, 'total_hours_worked', 'Total hours worked by all employees last year <ul><li>Must be > 0</li><li>Must be numeric</li><li>total_hours_worked divided by annual_average_employees  must be < 8760</li><li>total_hours_worked divided by annual_average_employees should be > 500</li></ul>', 'Integer', 10, 1); 
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (14, 'no_injuries_illnesses', 'Whether the establishment had any OSHA recordable work-related injuries or illnesses during the year.<ul><li>Enter 1 if the establishment had injuries or illnesses</li><li>Enter 2 if the establishment did not have injuries or illnesses</li></ul>', 'Integer', 1, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (15, 'total_deaths', 'Total number of deaths (Form 300A Field G) <ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1); 
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (16, 'total_dafw_cases', 'Total number of cases with days away from work (Form 300A Field H)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (17, 'total_djtr_cases', 'Total number of cases with job transfer or restriction (Form 300A Field I)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (18, 'total_other_cases', 'Total number of other recordable cases (Form 300A Field J)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (19, 'total_dafw_days', 'Total number of days away from work (Form 300A Field K)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (20, 'total_djtr_days', 'Total number of days of job transfer or restriction (Form 300A Field L)<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (21, 'total_injuries', 'Total number of injuries (Form 300A Field M(1))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (22, 'total_skin_disorders', 'Total number of skin disorders (Form 300A Field M(2))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (23, 'total_respiratory_conditions', 'Total number of respiratory conditions (Form 300A Field M(3))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (24, 'total_poisonings', 'Total number of poisonings (Form 300A Field M(4))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (25, 'total_hearing_loss', 'Total number of hearing loss (Form 300A Field M(5))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (26, 'total_other_illnesses', 'Total number of all other illnesses (Form 300A Field M(6))<ul><li>Must be >= 0</li><li>Must be a number</li></ul>', 'Integer', 10, 1);
	INSERT INTO CSR.OSHA_BASE_DATA(osha_base_data_id, data_element, definition_and_validations, format, length, required)
		VALUES (27, 'change_reason', 'The reason why an establishment’s injury and illness summary was changed, if applicable', 'Character', 100, 0);
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		VALUES (105, 'OSHA', 'EnableOSHAModule', 'Enables the OSHA module.');
END;
/
BEGIN
	BEGIN
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
		VALUES (83, 'Indicator validation rules export', null, 'batch-exporter', 0, null, 120);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.batch_job_type
			   SET description = 'Indicator validation rules export',
				   sp = NULL,
				   plugin_name = 'batch-exporter',
				   in_order = 0,
				   file_data_sp = NULL,
				   timeout_mins = 120
			 WHERE BATCH_JOB_TYPE_ID = 83;
	END;
	BEGIN 
		INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
		VALUES (83, 'Indicator validation rules export', 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorValidationRulesExporter');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.batched_export_type
			   SET LABEL = 'Indicator validation rules export',
				   ASSEMBLY = 'Credit360.ExportImport.Export.Batched.Exporters.IndicatorValidationRulesExporter'
			 WHERE BATCH_JOB_TYPE_ID = 83;
	END;
END;
/
UPDATE csr.osha_base_data
SET definition_and_validations = 'The name of the establishment reporting data. The system matches the data in your file to existing establishments based on establishment name. <b>Each establishment MUST have a unique name.</b>'
WHERE osha_base_data_id = 1;
UPDATE csr.osha_base_data
SET definition_and_validations = 'The North American Industry Classification System (NAICS) code which classifies an establishment’s business. Use a 2012 code, found here: <a href="http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012">http://www.census.gov/cgi-bin/sssd/naics/naicsrch?chart=2012</a><ul><li>Must be a number and be 6 digits in length</li></ul>'
WHERE osha_base_data_id = 7;
BEGIN
	INSERT INTO CSR.FLOW_STATE_NATURE (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (37, 'campaign', 'Promoted to Submission');
EXCEPTION WHEN dup_val_on_index THEN
	NULL;
END;
/
	UPDATE CSR.OSHA_BASE_DATA 
	   SET definition_and_validations = 'The reason why an establishment''s injury and illness summary was changed, if applicable'
	 WHERE osha_base_data_id = 27;

grant select,insert, update on csr.osha_mapping to csrimp;

create or replace package csr.osha_pkg as end;
/
grant execute on csr.osha_pkg to web_user;


@..\automated_import_pkg
@..\ssp_pkg
@..\osha_pkg
@..\indicator_pkg
@..\enable_pkg
@..\csr_data_pkg
@..\automated_export_pkg


@..\compliance_body
@..\automated_import_body
@..\csr_app_body
@..\ssp_body
@..\schema_body
@..\csrimp\imp_body
@..\quick_survey_body
@..\enable_body
@..\automated_export_body
@..\osha_body
@..\indicator_body
@..\delegation_body
@..\sheet_body
@..\user_profile_body
@..\audit_body
@..\permit_body
@..\chain\filter_body



@update_tail
