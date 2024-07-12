-- Please update version.sql too -- this keeps clean builds in sync
define version=3018
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL (
	APP_SID						NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	VAL_ID						NUMBER(10) NOT NULL,
	INSTANCE_ID					NUMBER(10) NOT NULL,
	INSTANCE_STEP_ID			NUMBER(10) NOT NULL,
	IND_SID						NUMBER(10),
	IND_TEXT					VARCHAR2(1024) NOT NULL,
	REGION_SID					NUMBER(10),
	REGION_TEXT					VARCHAR2(1024) NOT NULL,
	MEASURE_CONVERSION_ID		NUMBER(10),
	MEASURE_TEXT				VARCHAR2(1024),
	VAL_NUMBER					NUMBER(24, 10),
	NOTE						CLOB,
	SOURCE_FILE_REF				VARCHAR2(1024),
	START_DTM					DATE NOT NULL,
	END_DTM						DATE NOT NULL,
	CONSTRAINT PK_AUTO_IMP_CORE_DATA_VAL_FAIL PRIMARY KEY (APP_SID, VAL_ID)
);

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_REG 
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION (APP_SID, REGION_SID)
;

ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_IND 
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES CSR.IND (APP_SID, IND_SID)
;

ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_MEAS 
	FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID)
	REFERENCES CSR.MEASURE_CONVERSION (APP_SID, MEASURE_CONVERSION_ID)
;

ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL ADD CONSTRAINT FK_AUTIMP_CR_DT_VL_FAIL_STEP 
	FOREIGN KEY (APP_SID, INSTANCE_STEP_ID)
	REFERENCES CSR.AUTOMATED_IMPORT_INSTANCE_STEP (APP_SID, AUTO_IMPORT_INSTANCE_STEP_ID)
;

ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE_STEP
ADD CUSTOM_URL VARCHAR2(1024);

ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE_STEP
ADD CUSTOM_URL_TITLE VARCHAR(255);

ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE_STEP
ADD CONSTRAINT CK_AUTO_IMP_INST_STP_URL_TITLE CHECK ((CUSTOM_URL IS NOT NULL AND CUSTOM_URL_TITLE IS NOT NULL) OR (CUSTOM_URL IS NULL AND CUSTOM_URL_TITLE IS NULL));

create index csr.ix_auto_imp_core_instance_step on csr.auto_imp_core_data_val_fail (app_sid, instance_step_id);
create index csr.ix_auto_imp_core_ind_sid on csr.auto_imp_core_data_val_fail (app_sid, ind_sid);
create index csr.ix_auto_imp_core_region_sid on csr.auto_imp_core_data_val_fail (app_sid, region_sid);
create index csr.ix_auto_imp_core_measure_conve on csr.auto_imp_core_data_val_fail (app_sid, measure_conversion_id);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_pkg
@../automated_import_body

@update_tail
