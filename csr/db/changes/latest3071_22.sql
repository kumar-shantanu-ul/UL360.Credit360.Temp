-- Please update version.sql too -- this keeps clean builds in sync
define version=3071
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables
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

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.auto_imp_importer_plugin
		(plugin_id, label, importer_assembly)
	VALUES
		(6, 'HR profile importer', 'Credit360.ExportImport.Automated.Import.Importers.UserImporter.UserImporter');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../user_profile_pkg
@../automated_import_pkg

@../user_profile_body
@../automated_import_body
@../csr_user_body

@update_tail