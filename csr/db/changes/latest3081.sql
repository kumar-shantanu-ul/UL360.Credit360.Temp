define version=3081
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
CREATE TABLE csr.schema_table (
	owner							VARCHAR2(30),
	table_name						VARCHAR2(30),
	enable_export					NUMBER(1) DEFAULT 1,
	enable_import					NUMBER(1) DEFAULT 1,
	csrimp_table_name				VARCHAR2(30) NULL,
	module_name						VARCHAR2(255) NULL,
    CONSTRAINT pk_schema_table		PRIMARY KEY (owner, table_name),
	CONSTRAINT ck_schema_table_uc	CHECK (owner = UPPER(owner) AND table_name = UPPER(table_name)),
	CONSTRAINT ck_schema_table_mod	CHECK (LOWER(module_name) NOT IN ('all', 'none'))
);
CREATE TABLE csr.schema_column (
	owner							VARCHAR2(30),
	table_name						VARCHAR2(30),
	column_name						VARCHAR2(30),
	enable_export					NUMBER(1) DEFAULT 1,
	enable_import					NUMBER(1) DEFAULT 1,
	is_map_source					NUMBER(1) DEFAULT 1,	-- save work by clearing this on non-pk tables
	is_sid							NUMBER(1) NULL,			-- NULL = guess from name 
	sequence_owner					VARCHAR2(30) NULL,		-- NULL = same as table
	sequence_name					VARCHAR2(30) NULL,
	map_table						VARCHAR2(30) NULL,		-- only need these for legacy mapping tables
	map_old_id_col					VARCHAR2(30) NULL,
	map_new_id_col					VARCHAR2(30) NULL,
    CONSTRAINT pk_schema_column		PRIMARY KEY (owner, table_name, column_name),
	CONSTRAINT ck_schema_column_uc	CHECK (owner = UPPER(owner) AND 
										   table_name = UPPER(table_name) AND 
										   column_name = UPPER(column_name) AND
										   sequence_owner = UPPER(sequence_owner))
);
CREATE TABLE csrimp.map_id (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	sequence_owner					VARCHAR2(30),
	sequence_name					VARCHAR2(30),
	old_id							NUMBER(10),
	new_id							NUMBER(10),
	CONSTRAINT pk_map_id			PRIMARY KEY (csrimp_session_id, sequence_owner, sequence_name, old_id),
	CONSTRAINT uk_map_id 			UNIQUE (csrimp_session_id, sequence_name, new_id),
	CONSTRAINT fk_map_id 			FOREIGN KEY (csrimp_session_id) 
										REFERENCES csrimp.csrimp_session (csrimp_session_id) 
										ON DELETE CASCADE,
	CONSTRAINT ck_map_id_uc			CHECK (sequence_owner = UPPER(sequence_owner) AND
										   sequence_name = UPPER(sequence_name))
);
ALTER TABLE csr.schema_column ADD (
	CONSTRAINT fk_schem_column_table 
		FOREIGN KEY (owner, table_name) 
		REFERENCES csr.schema_table(owner, table_name)
);

CREATE TABLE csr.user_profile (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	primary_key						VARCHAR2(128) NOT NULL,
	csr_user_sid					NUMBER(10) NOT NULL,
	employee_ref					VARCHAR2(128),
	payroll_ref						NUMBER(10),
	first_name						VARCHAR2(256) NOT NULL,
	last_name						VARCHAR2(256),
	middle_name						VARCHAR2(256),
	friendly_name					VARCHAR2(256),
	email_address					VARCHAR2(256) NOT NULL,
	work_phone_number				VARCHAR2(32),
	work_phone_extension			VARCHAR2(8),
	home_phone_number				VARCHAR2(32),
	mobile_phone_number				VARCHAR2(32),
	manager_employee_ref			VARCHAR2(128),
	manager_payroll_ref				NUMBER(10),
	manager_primary_key				VARCHAR2(128),
	employment_start_date			DATE,
	employment_leave_date			DATE,
	date_of_birth					DATE,
	gender							VARCHAR2(8),
	job_title						VARCHAR2(128),
	contract						VARCHAR2(256),
	employment_type					VARCHAR2(256),
	pay_grade						VARCHAR2(256),
	business_area_ref				VARCHAR2(256),
	business_area_code				NUMBER(10),
	business_area_name				VARCHAR2(256),
	business_area_description		VARCHAR2(1024),
	division_ref					VARCHAR2(256),
	division_code					NUMBER(10),
	division_name					VARCHAR2(256),
	division_description			VARCHAR2(1024),
	department						VARCHAR2(256),
	number_hours					NUMBER(10),
	country							VARCHAR2(128),
	location						VARCHAR2(256),
	building						VARCHAR2(256),
	cost_centre_ref					VARCHAR2(256),
	cost_centre_code				NUMBER(10),
	cost_centre_name				VARCHAR2(256),
	cost_centre_description			VARCHAR2(1024),
	work_address_1					VARCHAR2(256),
	work_address_2					VARCHAR2(256),
	work_address_3					VARCHAR2(256),
	work_address_4					VARCHAR2(256),
	home_address_1					VARCHAR2(256),
	home_address_2					VARCHAR2(256),
	home_address_3					VARCHAR2(256),
	home_address_4					VARCHAR2(256),
	location_region_sid				NUMBER(10),
	internal_username				VARCHAR2(256),
	manager_username				VARCHAR2(256),
	activate_on						DATE,
	deactivate_on					DATE,
	creation_instance_step_id		NUMBER(10),
	created_dtm						DATE NOT NULL,
	created_user_sid				NUMBER(10) NOT NULL,
	creation_method					VARCHAR(256) NOT NULL,
	updated_instance_step_id		NUMBER(10),
	last_updated_dtm				DATE,
	last_updated_user_sid			NUMBER(10),
	last_update_method				VARCHAR(256),
	CONSTRAINT pk_user_profile PRIMARY KEY (app_sid, primary_key),
	CONSTRAINT ck_user_profile_gender CHECK (gender IN ('Male', 'Female')),
	CONSTRAINT uk_user_profile_user_sid UNIQUE (app_sid, csr_user_sid)
);
ALTER TABLE csr.user_profile
	ADD CONSTRAINT fk_user_profile_location_sid 
	FOREIGN KEY (app_sid, location_region_sid) REFERENCES csr.region (app_sid, region_sid);
ALTER TABLE csr.user_profile
	ADD CONSTRAINT fk_user_prfl_crtd_instnc_stp 
	FOREIGN KEY (app_sid, creation_instance_step_id) REFERENCES csr.automated_import_instance_step (app_sid, auto_import_instance_step_id);
ALTER TABLE csr.user_profile
	ADD CONSTRAINT fk_user_prfl_crtd_updated_stp
	FOREIGN KEY (app_sid, updated_instance_step_id) REFERENCES csr.automated_import_instance_step (app_sid, auto_import_instance_step_id);
CREATE TABLE csr.user_profile_staged_record (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	primary_key						VARCHAR2(128) NOT NULL,
	employee_ref					VARCHAR2(128),
	payroll_ref						NUMBER(10),
	first_name						VARCHAR2(256),
	last_name						VARCHAR2(256),
	middle_name						VARCHAR2(256),
	friendly_name					VARCHAR2(256),
	email_address					VARCHAR2(256),
	username						VARCHAR2(256),
	work_phone_number				VARCHAR2(32),
	work_phone_extension			VARCHAR2(8),
	home_phone_number				VARCHAR2(32),
	mobile_phone_number				VARCHAR2(32),
	manager_employee_ref			VARCHAR2(128),
	manager_payroll_ref				NUMBER(10),
	manager_primary_key				VARCHAR2(128),
	employment_start_date			DATE,
	employment_leave_date			DATE,
	profile_active					NUMBER(1),
	date_of_birth					DATE,
	gender							VARCHAR2(8),
	job_title						VARCHAR2(128),
	contract						VARCHAR2(256),
	employment_type					VARCHAR2(256),
	pay_grade						VARCHAR2(256),
	business_area_ref				VARCHAR2(256),
	business_area_code				NUMBER(10),
	business_area_name				VARCHAR2(256),
	business_area_description		VARCHAR2(1024),
	division_ref					VARCHAR2(256),
	division_code					NUMBER(10),
	division_name					VARCHAR2(256),
	division_description			VARCHAR2(1024),
	department						VARCHAR2(256),
	number_hours					NUMBER(10),
	country							VARCHAR2(128),
	location						VARCHAR2(256),
	building						VARCHAR2(256),
	cost_centre_ref					VARCHAR2(256),
	cost_centre_code				NUMBER(10),
	cost_centre_name				VARCHAR2(256),
	cost_centre_description			VARCHAR2(1024),
	work_address_1					VARCHAR2(256),
	work_address_2					VARCHAR2(256),
	work_address_3					VARCHAR2(256),
	work_address_4					VARCHAR2(256),
	home_address_1					VARCHAR2(256),
	home_address_2					VARCHAR2(256),
	home_address_3					VARCHAR2(256),
	home_address_4					VARCHAR2(256),
	location_region_ref				VARCHAR(1024),
	internal_username				VARCHAR2(256),
	manager_username				VARCHAR2(256),
	activate_on						DATE,
	deactivate_on					DATE,
	instance_step_id				NUMBER(10),
	last_updated_dtm				DATE,
	last_updated_user_sid			NUMBER(10),
	last_update_method				VARCHAR(256),
	error_message					VARCHAR(1024),
	CONSTRAINT pk_user_profile_staged PRIMARY KEY (app_sid, primary_key)
);
ALTER TABLE csr.user_profile_staged_record
	ADD CONSTRAINT fk_usr_prfl_stgd_rcrd_inst_stp 
	FOREIGN KEY (app_sid, instance_step_id) REFERENCES csr.automated_import_instance_step (app_sid, auto_import_instance_step_id);
CREATE SEQUENCE CSR.auto_imp_user_setngs_id_seq;
CREATE TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS(
	APP_SID								NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUTO_IMP_USER_IMP_SETTINGS_ID		NUMBER(10)		NOT NULL,
	AUTOMATED_IMPORT_CLASS_SID			NUMBER(10)		NOT NULL,
	STEP_NUMBER							NUMBER(10)		NOT NULL,
	MAPPING_XML							SYS.XMLTYPE		NOT NULL,
	AUTOMATED_IMPORT_FILE_TYPE_ID		NUMBER(10)		NOT NULL,
	DSV_SEPARATOR						CHAR,
	DSV_QUOTES_AS_LITERALS				NUMBER(1),
	EXCEL_WORKSHEET_INDEX				NUMBER(10),
	ALL_OR_NOTHING						NUMBER(1),
	HAS_HEADINGS						NUMBER(1)		DEFAULT 1 NOT NULL,
	CONCATENATOR						VARCHAR2(3)		DEFAULT '_' NOT NULL,
	ACTIVE_STATUS_METHOD_TXT			VARCHAR2(32)	DEFAULT 'ALWAYS_ACTIVE' NOT NULL,
	USE_LOC_REGION_AS_START_PT			NUMBER(1) 		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_AUTO_IMP_USER_IMP_SETTINGS PRIMARY KEY (APP_SID, AUTO_IMP_USER_IMP_SETTINGS_ID),
	CONSTRAINT CK_AUTO_IMP_USER_SET_QUO CHECK (dsv_quotes_as_literals IN (0,1) OR dsv_quotes_as_literals IS NULL),
	CONSTRAINT CK_AUTO_IMP_USER_SET_ALLORNO CHECK (all_or_nothing IN (0,1) OR all_or_nothing IS NULL),
	CONSTRAINT CK_AUTO_IMP_USER_SET_HASHEADS CHECK (has_headings IN (0,1)),
	CONSTRAINT CK_AUTO_IMP_USER_SET_ACTIVMETH CHECK (active_status_method_txt IN ('ALWAYS_ACTIVE', 'ALWAYS_INACTIVE', 'STATUS_IN_COLUMN', 'ACTIVATION_DATE', 'INACTIVATION_DATE', 'EMPLOYMENT_DATE_COLS')),
	CONSTRAINT CK_AUTO_IMP_USER_SET_REGSTART CHECK (use_loc_region_as_start_pt IN (0,1)),
	CONSTRAINT UK_AUTO_IMP_USER_SET_STEP UNIQUE (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
)
;
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_USER_SET_STEP
    FOREIGN KEY (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
    REFERENCES CSR.AUTOMATED_IMPORT_CLASS_STEP(APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
;
ALTER TABLE CSR.AUTO_IMP_USER_IMP_SETTINGS ADD CONSTRAINT FK_AUTO_IMP_USER_SET_FILETYPE
    FOREIGN KEY (AUTOMATED_IMPORT_FILE_TYPE_ID)
    REFERENCES CSR.AUTOMATED_IMPORT_FILE_TYPE(AUTOMATED_IMPORT_FILE_TYPE_ID)
;
CREATE TABLE csr.user_profile_default_group (
	app_sid                           NUMBER(10)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	group_sid						  NUMBER(10) NOT NULL,
	automated_import_class_sid		  NUMBER(10),
	step_number						  NUMBER(10),
	CONSTRAINT pk_user_profile_default_group PRIMARY KEY (app_sid, group_sid, automated_import_class_sid, step_number),
	CONSTRAINT ck_user_profile_auto_imp_class CHECK (automated_import_class_sid IS NULL or step_number IS NOT NULL)
);
ALTER TABLE CSR.user_profile_default_group ADD CONSTRAINT FK_USER_PROF_DEF_GRP_STEP
    FOREIGN KEY (APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
    REFERENCES CSR.AUTOMATED_IMPORT_CLASS_STEP(APP_SID, AUTOMATED_IMPORT_CLASS_SID, STEP_NUMBER)
;
CREATE OR REPLACE TYPE CSR.T_USER_PROFILE_STAGED_ROW AS 
	OBJECT (
	PRIMARY_KEY						VARCHAR2(128),
	EMPLOYEE_REF					VARCHAR2(128),
	PAYROLL_REF						NUMBER(10),
	FIRST_NAME						VARCHAR2(256),
	LAST_NAME						VARCHAR2(256),
	MIDDLE_NAME						VARCHAR2(256),
	FRIENDLY_NAME					VARCHAR2(256),
	EMAIL_ADDRESS					VARCHAR2(256),
	USERNAME						VARCHAR2(256),
	WORK_PHONE_NUMBER				VARCHAR2(32),
	WORK_PHONE_EXTENSION			VARCHAR2(8),
	HOME_PHONE_NUMBER				VARCHAR2(32),
	MOBILE_PHONE_NUMBER				VARCHAR2(32),
	MANAGER_EMPLOYEE_REF			VARCHAR2(128),
	MANAGER_PAYROLL_REF				NUMBER(10),
	MANAGER_PRIMARY_KEY				VARCHAR2(128),
	EMPLOYMENT_START_DATE			DATE,
	EMPLOYMENT_LEAVE_DATE			DATE,
	PROFILE_ACTIVE					NUMBER(1),
	DATE_OF_BIRTH					DATE,
	GENDER							VARCHAR2(8),
	JOB_TITLE						VARCHAR2(128),
	CONTRACT						VARCHAR2(256),
	EMPLOYMENT_TYPE					VARCHAR2(256),
	PAY_GRADE						VARCHAR2(256),
	BUSINESS_AREA_REF				VARCHAR2(256),
	BUSINESS_AREA_CODE				NUMBER(10),
	BUSINESS_AREA_NAME				VARCHAR2(256),
	BUSINESS_AREA_DESCRIPTION		VARCHAR2(1024),
	DIVISION_REF					VARCHAR2(256),
	DIVISION_CODE					NUMBER(10),
	DIVISION_NAME					VARCHAR2(256),
	DIVISION_DESCRIPTION			VARCHAR2(1024),
	DEPARTMENT						VARCHAR2(256),
	NUMBER_HOURS					NUMBER(10),
	COUNTRY							VARCHAR2(128),
	LOCATION						VARCHAR2(256),
	BUILDING						VARCHAR2(256),
	COST_CENTRE_REF					VARCHAR2(256),
	COST_CENTRE_CODE				NUMBER(10),
	COST_CENTRE_NAME				VARCHAR2(256),
	COST_CENTRE_DESCRIPTION			VARCHAR2(1024),
	WORK_ADDRESS_1					VARCHAR2(256),
	WORK_ADDRESS_2					VARCHAR2(256),
	WORK_ADDRESS_3					VARCHAR2(256),
	WORK_ADDRESS_4					VARCHAR2(256),
	HOME_ADDRESS_1					VARCHAR2(256),
	HOME_ADDRESS_2					VARCHAR2(256),
	HOME_ADDRESS_3					VARCHAR2(256),
	HOME_ADDRESS_4					VARCHAR2(256),
	LOCATION_REGION_REF				VARCHAR(1024),
	INTERNAL_USERNAME				VARCHAR2(256),
	MANAGER_USERNAME				VARCHAR2(256),
	ACTIVATE_ON						DATE,
	DEACTIVATE_ON					DATE,
	INSTANCE_STEP_ID				NUMBER(10),
	LAST_UPDATED_DTM				DATE,
	LAST_UPDATED_USER_SID			NUMBER(10),
	LAST_UPDATE_METHOD				VARCHAR(256),
	ERROR_MESSAGE					VARCHAR(1024)
	);
/
create index csr.ix_auto_imp_user_automated_imp on csr.auto_imp_user_imp_settings (automated_import_file_type_id);
create index csr.ix_user_profile_creation_inst on csr.user_profile (app_sid, creation_instance_step_id);
create index csr.ix_user_profile_updated_insta on csr.user_profile (app_sid, updated_instance_step_id);
create index csr.ix_user_profile_location_regi on csr.user_profile (app_sid, location_region_sid);
create index csr.ix_user_profile__automated_imp on csr.user_profile_default_group (app_sid, automated_import_class_sid, step_number);
create index csr.ix_user_profile__instance_step on csr.user_profile_staged_record (app_sid, instance_step_id);
CREATE TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS (
	APP_SID							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	AUTOMATED_EXPORT_CLASS_SID		NUMBER(10)	NOT NULL,
	BATCHED_EXPORT_TYPE_ID			NUMBER(10)	NOT NULL,
	SETTINGS_XML					XMLTYPE		NOT NULL,
	CONVERT_TO_DSV					NUMBER(1) DEFAULT 0 NOT NULL,
	PRIMARY_DELIMITER				VARCHAR2(1) DEFAULT ',' NOT NULL,
	SECONDARY_DELIMITER				VARCHAR2(1) DEFAULT '|' NOT NULL,
	CONSTRAINT PK_AUTO_EXP_BATCH_EXP_SETTINGS PRIMARY KEY (APP_SID, AUTOMATED_EXPORT_CLASS_SID),
	CONSTRAINT CK_AUTO_EXP_BATCH_EXP_CONV_DSV CHECK (CONVERT_TO_DSV IN (0, 1))
);
ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS ADD CONSTRAINT FK_AUTO_EXP_BTCH_SET_CLS_SID
	FOREIGN KEY (APP_SID, AUTOMATED_EXPORT_CLASS_SID)
	REFERENCES CSR.AUTOMATED_EXPORT_CLASS(APP_SID, AUTOMATED_EXPORT_CLASS_SID)
;
ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS ADD CONSTRAINT FK_AUTO_EXP_BTCH_SET_EXPORTER
	FOREIGN KEY (BATCHED_EXPORT_TYPE_ID)
	REFERENCES CSR.BATCHED_EXPORT_TYPE(BATCH_JOB_TYPE_ID)
;
CREATE INDEX csr.ix_auto_exp_batc_batched_expor ON csr.auto_exp_batched_exp_settings (batched_export_type_id);
CREATE TABLE chain.supplier_involvement_type (
	app_sid							NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	user_company_type_id			NUMBER(10)	NULL,
	page_company_type_id			NUMBER(10)	NULL,
	purchaser_type					NUMBER(2)	NOT NULL,
	restrict_to_role_sid			NUMBER(10)	NULL,
	CONSTRAINT pk_supplier_involvement_type PRIMARY KEY (app_sid, flow_involvement_type_id),
	CONSTRAINT fk_supp_inv_type_sup_rel FOREIGN KEY (app_sid, user_company_type_id, page_company_type_id)
	REFERENCES chain.company_type_relationship (app_sid, primary_company_type_id, secondary_company_type_id),
	CONSTRAINT fk_supp_inv_type_co_type_role FOREIGN KEY (app_sid, user_company_type_id, restrict_to_role_sid)
	REFERENCES chain.company_type_role (app_sid, company_type_id, role_sid),
	CONSTRAINT uk_supp_inv_type UNIQUE (app_sid, user_company_type_id, page_company_type_id, purchaser_type, restrict_to_role_sid),
	CONSTRAINT chk_supp_inv_type_pur_type CHECK (purchaser_type IN (1,2,3))
);
CREATE TABLE csrimp.chain_supplier_inv_type (
	csrimp_session_id 				NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	flow_involvement_type_id		NUMBER(10)	NOT NULL,
	user_company_type_id			NUMBER(10)	NULL,
	page_company_type_id			NUMBER(10)	NULL,
	purchaser_type					NUMBER(2)	NOT NULL,
	restrict_to_role_sid			NUMBER(10)	NULL,
	CONSTRAINT pk_chain_supp_inv_type PRIMARY KEY (csrimp_session_id, flow_involvement_type_id),
	CONSTRAINT fk_chain_supp_inv_type_ses FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);


ALTER TABLE csr.quick_survey ADD (
	from_question_library NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_from_question_library_0_1 CHECK (from_question_library IN (0,1))
);
ALTER TABLE csrimp.quick_survey ADD (
	from_question_library NUMBER(1) NOT NULL,
	CONSTRAINT chk_from_question_library_0_1 CHECK (from_question_library IN (0,1))
);
ALTER TABLE CSR.QUESTION_TAG DROP CONSTRAINT CHK_QT_QUESTION_DRAFT;
ALTER TABLE CSR.QUESTION_TAG ADD  CONSTRAINT CHK_QT_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));
ALTER TABLE CSRIMP.QUESTION_TAG DROP CONSTRAINT CHK_QT_QUESTION_DRAFT;
ALTER TABLE CSRIMP.QUESTION_TAG ADD  CONSTRAINT CHK_QT_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));
ALTER TABLE CSR.QS_QUESTION_OPTION DROP CONSTRAINT CHK_QSQO_QUESTION_DRAFT;
ALTER TABLE CSR.QS_QUESTION_OPTION ADD  CONSTRAINT CHK_QSQO_QUESTION_DRAFT CHECK (QUESTION_DRAFT in (0,1));
ALTER TABLE CSR.QUICK_SURVEY_QUESTION DROP CONSTRAINT CHK_QSQ_QUESTION_DRAFT;
ALTER TABLE CSR.QUICK_SURVEY_QUESTION ADD  CONSTRAINT CHK_QSQ_QUESTION_DRAFT CHECK (QUESTION_DRAFT in (0,1));
ALTER TABLE CSR.NON_COMPLIANCE DROP CONSTRAINT CHK_NC_QUESTION_DRAFT;
ALTER TABLE CSR.NON_COMPLIANCE ADD  CONSTRAINT CHK_NC_QUESTION_DRAFT CHECK (QUESTION_DRAFT in (0,1));
ALTER TABLE CHAIN.HIGG_QUESTION_OPTION_SURVEY DROP CONSTRAINT CHK_HQOS_QUESTION_DRAFT;
ALTER TABLE CHAIN.HIGG_QUESTION_OPTION_SURVEY ADD  CONSTRAINT CHK_HQOS_QUESTION_DRAFT CHECK (QS_QUESTION_DRAFT IN (0,1));
ALTER TABLE CSRIMP.QS_QUESTION_OPTION DROP CONSTRAINT CHK_QSQO_QUESTION_DRAFT;
ALTER TABLE CSRIMP.QS_QUESTION_OPTION ADD  CONSTRAINT CHK_QSQO_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION DROP CONSTRAINT CHK_QSQ_QUESTION_DRAFT;
ALTER TABLE CSRIMP.QUICK_SURVEY_QUESTION ADD  CONSTRAINT CHK_QSQ_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));
ALTER TABLE CSRIMP.NON_COMPLIANCE DROP CONSTRAINT CHK_NC_QUESTION_DRAFT;
ALTER TABLE CSRIMP.NON_COMPLIANCE ADD  CONSTRAINT CHK_NC_QUESTION_DRAFT CHECK (QUESTION_DRAFT IN (0,1));
ALTER TABLE CSRIMP.HIGG_QUESTION_OPTION_SURVEY DROP CONSTRAINT CHK_HQOS_QUESTION_DRAFT;
ALTER TABLE CSRIMP.HIGG_QUESTION_OPTION_SURVEY ADD  CONSTRAINT CHK_HQOS_QUESTION_DRAFT CHECK (QS_QUESTION_DRAFT IN (0,1));
	
drop package csr.as2_pkg;
drop table csr.as2_inbound_receipt cascade constraints;
drop table csr.batch_job_as2_outbound_message cascade constraints;
drop table csr.batch_job_as2_outbound_receipt cascade constraints;
drop table CSR.AS2_OUTBOUND_MESSAGE cascade constraints;
drop table CSR.AS2_OUTBOUND_RECEIPT;
ALTER TABLE csr.all_property DROP CONSTRAINT FK_FUND_PROPERTY;
ALTER TABLE csr.flow_involvement_type
ADD lookup_key VARCHAR2(100);
ALTER TABLE csrimp.flow_involvement_type
ADD lookup_key VARCHAR2(100);
ALTER TABLE csr.flow_involvement_type
RENAME CONSTRAINT UK_LABEL TO UK_FLOW_INV_TYPE_LABEL;
CREATE UNIQUE INDEX CSR.UK_FLOW_INV_TYPE_KEY ON CSR.FLOW_INVOLVEMENT_TYPE (APP_SID, NVL(UPPER(LOOKUP_KEY), FLOW_INVOLVEMENT_TYPE_ID))
;


GRANT SELECT ON csr.schema_column TO csrimp;
GRANT SELECT ON csr.schema_table TO csrimp;
grant references on csr.flow_involvement_type to chain;
grant select, insert, update, delete on csrimp.chain_supplier_inv_type to tool_user;
grant select, insert, update on chain.supplier_involvement_type to csrimp;
grant select on chain.supplier_involvement_type to csr;


ALTER TABLE chain.supplier_involvement_type 
ADD CONSTRAINT fk_supp_inv_type_inv_type FOREIGN KEY (app_sid, flow_involvement_type_id)
REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);
ALTER TABLE chain.supplier_involvement_type 
ADD CONSTRAINT fk_supp_inv_type_role FOREIGN KEY (app_sid, restrict_to_role_sid)
REFERENCES csr.role(app_sid, role_sid);
CREATE INDEX chain.ix_sup_inv_t_ct_rel ON chain.supplier_involvement_type (app_sid, user_company_type_id, page_company_type_id);
CREATE INDEX chain.ix_sup_inv_t_co_type_role ON chain.supplier_involvement_type (app_sid, user_company_type_id, restrict_to_role_sid);
CREATE INDEX chain.ix_sup_inv_t_role ON chain.supplier_involvement_type (app_sid, restrict_to_role_sid);


CREATE OR REPLACE VIEW csr.v$quick_survey AS
	SELECT qs.app_sid, qs.survey_sid, d.label draft_survey_label, l.label live_survey_label,
		   NVL(l.label, d.label) label, qs.audience, qs.group_key, qs.created_dtm, qs.auditing_audit_type_id,
		   CASE WHEN l.survey_sid IS NOT NULL THEN 1 ELSE 0 END survey_is_published,
		   CASE WHEN qs.last_modified_dtm > l.published_dtm THEN 1 ELSE 0 END survey_has_unpublished_changes,
		   qs.score_type_id, st.label score_type_label, st.format_mask score_format_mask,
		   qs.quick_survey_type_id, qst.description quick_survey_type_desc, qs.current_version,
		   qs.from_question_library
	  FROM csr.quick_survey qs
	  JOIN csr.quick_survey_version d ON qs.app_sid = d.app_sid AND qs.survey_sid = d.survey_sid
	  LEFT JOIN csr.quick_survey_version l ON qs.app_sid = l.app_sid AND qs.survey_sid = l.survey_sid AND qs.current_version = l.survey_version
	  LEFT JOIN csr.score_type st ON st.score_type_id = qs.score_type_id AND st.app_sid = qs.app_sid
	  LEFT JOIN csr.quick_survey_type qst ON qst.quick_survey_type_id = qs.quick_survey_type_id AND qst.app_sid = qs.app_sid
	 WHERE d.survey_version = 0;
CREATE OR REPLACE VIEW chain.v$all_purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.purchaser_company_sid, sr.supplier_company_sid,
		rrm.user_sid ct_role_user_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN v$company_user cu -- this will do for now, but it probably performs horribly
	    ON cu.company_sid = pc.company_sid
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = cu.user_sid
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.deleted = 0
	   AND sc.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL);
CREATE OR REPLACE VIEW chain.v$purchaser_involvement AS
	SELECT flow_involvement_type_id, supplier_company_sid
	  FROM v$all_purchaser_involvement
	 WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND NVL(ct_role_user_sid, SYS_CONTEXT('SECURITY', 'SID')) = SYS_CONTEXT('SECURITY', 'SID');
CREATE OR REPLACE VIEW CHAIN.v$supplier_capability AS
	SELECT sr.supplier_company_sid,
		   fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + --security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set --security_pkg.PERMISSION_WRITE
	  FROM v$supplier_relationship sr
	  JOIN csr.flow_item fi ON fi.flow_item_id = sr.flow_item_id
	  JOIN csr.flow_state_role_capability fsrc ON fsrc.flow_state_id = fi.current_state_id
	  JOIN csr.supplier s ON s.company_sid = sr.supplier_company_sid
	  LEFT JOIN csr.region_role_member rrm
			 ON rrm.region_sid = s.region_sid
			AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN v$purchaser_involvement inv
		ON inv.flow_involvement_type_id = fsrc.flow_involvement_type_id
	   AND inv.supplier_company_sid = sr.supplier_company_sid
	 WHERE (sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			OR sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	   AND (inv.flow_involvement_type_id IS NOT NULL
	    OR (fsrc.flow_involvement_type_id = 1002 /*csr.csr_data_pkg.FLOW_INV_TYPE_SUPPLIER*/
			AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))
	    OR rrm.role_sid IS NOT NULL)
	GROUP BY sr.supplier_company_sid, fsrc.flow_capability_id;




BEGIN
	INSERT INTO csr.audit_type (audit_type_id, label, audit_type_group_id)
	VALUES (303, 'Automated export change', 1);
END;
/
BEGIN
	INSERT INTO csr.auto_imp_importer_plugin
		(plugin_id, label, importer_assembly)
	VALUES
		(6, 'HR profile importer', 'Credit360.ExportImport.Automated.Import.Importers.UserImporter.UserImporter');
END;
/
BEGIN
	INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly) 
	VALUES (20, 'ELC - Incident export (xml)', 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentExporter', 'Credit360.ExportImport.Automated.Export.Exporters.ELC.IncidentXmlOutputter');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO csr.auto_exp_exporter_plugin (plugin_id, label, exporter_assembly, outputter_assembly)
	VALUES (19, 'Batched exporter',	'Credit360.ExportImport.Automated.Export.Exporters.Batched.AutomatedBatchedExporter', 'Credit360.ExportImport.Automated.Export.Exporters.Batched.AutomatedBatchedOutputter');
	-- Clear out unimplemented crap
	DELETE FROM CSR.AUTO_EXP_FILE_WRITER_PLUGIN
	 WHERE PLUGIN_ID IN (2, 3, 4);
END;
/
UPDATE POSTCODE.COUNTRY 
   SET name = 'Libya'
 WHERE name = 'Libyan Arab Jamahiriya';
UPDATE csr.module 
   SET description = 'Enables the Permits module.',
   	   license_warning = 1
 WHERE module_name = 'Permits';
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE chain.filter_field
	   SET name = REPLACE(name, 'PropertyCmsFilter', 'CmsFilter')
	 WHERE name LIKE 'PropertyCmsFilter%';
	
	UPDATE chain.filter_field
	   SET name = REPLACE(name, 'CompanyCmsFilter', 'CmsFilter')
	 WHERE name LIKE 'CompanyCmsFilter%';
	
	UPDATE chain.filter_field
	   SET name = REPLACE(name, 'ProductCmsFilter', 'CmsFilter')
	 WHERE name LIKE 'ProductCmsFilter%';
END;
/
DECLARE
	v_flow_involvement_type_id				NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.flow_involvement_type
	   SET lookup_key = 'PURCHASER' /*PURCHASER_INV_TYPE_KEY*/
	 WHERE flow_involvement_type_id = 1001 /* csr.csr_data_pkg.FLOW_INV_TYPE_PURCHASER */;
	INSERT INTO chain.supplier_involvement_type(app_sid, flow_involvement_type_id, purchaser_type)
	SELECT app_sid, 1001, 1 /*  */
	  FROM csr.flow_involvement_type
	 WHERE flow_involvement_type_id = 1001;
END;
/






@..\quick_survey_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\question_library_pkg
@..\batch_job_pkg
@..\testdata_pkg
@..\chain\company_pkg
@..\csrimp\imp_pkg
@..\schema_pkg
@..\csr_data_pkg
@..\automated_export_pkg
@..\user_profile_pkg
@..\automated_import_pkg
@..\property_report_pkg
@..\chain\product_report_pkg
@..\chain\company_filter_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\compliance_pkg
@..\batch_exporter_pkg
@..\chain\chain_pkg
@..\chain\type_capability_pkg
@..\chain\supplier_flow_pkg
@..\flow_pkg


@..\schema_body
@..\csrimp\imp_body
@..\quick_survey_body
@..\property_report_body
@..\factor_body
@..\..\..\aspen2\cms\db\filter_body
@..\flow_body
@..\chain\scheduled_alert_body
@..\..\..\aspen2\cms\db\tab_body
@..\question_library_body
@..\chain\company_dedupe_body
@..\audit_body
@..\property_body
@..\testdata_body
@..\alert_body
@..\chain\chain_body
@..\csr_app_body
@..\chain\company_body
@..\region_body
@..\pending_body
@..\delegation_body
@..\automated_export_body
@..\user_profile_body
@..\automated_import_body
@..\csr_user_body
@..\compliance_body
@..\chain\product_report_body
@..\chain\company_filter_body
@..\issue_report_body
@..\batch_exporter_body
@..\supplier_body
@..\user_cover_body
@..\chain\certification_report_body
@..\initiative_report_body
@..\meter_list_body
@..\user_report_body
@..\sheet_body
@..\enable_body
@..\chain\type_capability_body
@..\chain\setup_body
@..\chain\supplier_flow_body
@..\chain\test_chain_utils_body
@..\doc_lib_body



@update_tail
