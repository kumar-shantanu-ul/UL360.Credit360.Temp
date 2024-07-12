-- Please update version.sql too -- this keeps clean builds in sync
define version=2743
@update_header

-- *** DDL ***
-- Create tables
BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_alias
	 DROP CONSTRAINT fk_autom_exp_alias';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_inst_files
	 DROP CONSTRAINT fk_auto_exp_ins_file';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_region_member
	 DROP CONSTRAINT fk_autom_exp_reg_member';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_ind_member
	 DROP CONSTRAINT fk_autom_exp_ind_member';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

 BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_ind_columns
	 DROP CONSTRAINT fk_autom_exp_ind_cols';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

 BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_ind_conf
	 DROP CONSTRAINT fk_autom_exp_ind_conf';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

 BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_inst_message
	 DROP CONSTRAINT fk_autom_exprt_instance_mes';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_instance
	 DROP CONSTRAINT fk_automated_export_instance';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.automated_export_class
	 DROP CONSTRAINT fk_automated_export_class';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'ALTER TABLE csr.ftp_profile
	 DROP CONSTRAINT fk_ftp_profile';

EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -942 OR SQLCODE = -2443) THEN
		null; -- No worries, table or constraint doesn't exist yet
	ELSE
		RAISE;
	END IF;
END;
/

-- CSR.FTP_PROFILE
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'FTP_PROFILE'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.ftp_profile';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.ftp_profile(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		ftp_profile_id                NUMBER(10, 0)    NOT NULL,
		label                         VARCHAR2(255),
		cms_imp_protocol_id           NUMBER(10,0)     NOT NULL,
		host_name                     VARCHAR2(1024)   NOT NULL,
		secure_credentials            CLOB,
		fingerprint                   VARCHAR2(1024),
		username                      VARCHAR2(255),
		password                      VARCHAR2(255),
		port_number                   NUMBER(10,0),
		payload_path                  VARCHAR2(1024),
		CONSTRAINT pk_ftp_profile PRIMARY KEY (app_sid, ftp_profile_id),
		CONSTRAINT fk_ftp_profile FOREIGN KEY (cms_imp_protocol_id)
			REFERENCES csr.cms_imp_protocol(cms_imp_protocol_id)
	)';
END;
/

 -- CSR.AUTOMATED_EXPORT_CLASS
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_CLASS'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_class';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_class(
		app_sid                     NUMBER(10, 0)     DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		automated_export_class_sid  NUMBER(10, 0)     NOT NULL,
		label                       VARCHAR2(255)     NOT NULL,
		export_file_format          VARCHAR2(255)     NOT NULL,
		export_type                 VARCHAR2(255)     NOT NULL,
		db_data_exporter_function   VARCHAR2(255),
		data_exporter_class         VARCHAR2(255),
		ftp_profile_id              NUMBER(10, 0)     NOT NULL,
		file_mask                   VARCHAR2(255)     NOT NULL,
		schedule_xml                SYS.XMLType,
		last_scheduled_dtm          DATE,
		email_on_error              VARCHAR2(2048),
		email_on_success            VARCHAR2(2048),
		CONSTRAINT pk_automated_export_class PRIMARY KEY (app_sid, automated_export_class_sid),
		CONSTRAINT chk_export_type_format CHECK (export_file_format IN (''CSV'',''PIPE'',''XLS'', ''TSV'')),
		CONSTRAINT fk_automated_export_class FOREIGN KEY (app_sid, ftp_profile_id)
			REFERENCES csr.ftp_profile(app_sid, ftp_profile_id)
	)';
END;
/

 -- SEQUENCE FOR AUTOMATED_EXPORT_INSTANCE_ID
BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE csr.aut_export_inst_id_seq';
EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -2289) THEN
		null; -- No worries, the sequence doesn't exist YET!.
	ELSE
		RAISE;
	END IF;
END;
/
CREATE SEQUENCE csr.aut_export_inst_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

 -- CSR.AUTOMATED_EXPORT_INSTANCE
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_INSTANCE'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_instance';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_instance(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		automated_export_instance_id  NUMBER(10, 0)    NOT NULL,
		automated_export_class_sid    NUMBER(10, 0)    NOT NULL,
		batch_job_id                  NUMBER(10, 0)    NOT NULL,
		CONSTRAINT pk_automated_export_instance PRIMARY KEY (app_sid, automated_export_instance_id),
		CONSTRAINT fk_automated_export_instance FOREIGN KEY (app_sid, automated_export_class_sid)
			REFERENCES csr.automated_export_class(app_sid, automated_export_class_sid),
		CONSTRAINT uk_automated_export_instance  UNIQUE (app_sid, automated_export_instance_id, automated_export_class_sid)
	)';
END;
/

 -- SEQUENCE FOR INSTANCE_FILE_ID
BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE csr.aut_exp_ins_file_id_seq';
EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -2289) THEN
		null; -- No worries, the sequence doesn't exist YET!.
	ELSE
		RAISE;
	END IF;
END;
/
CREATE SEQUENCE csr.aut_exp_ins_file_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

-- CSR.AUTOMATED_EXPORT_INST_FILES
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_INST_FILES'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_inst_files';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_inst_files(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		instance_file_id              NUMBER(10, 0)    NOT NULL,
		automated_export_instance_id  NUMBER(10, 0)    NOT NULL,
		payload                       BLOB             NOT NULL,
		payload_filename              VARCHAR2(255)    NOT NULL,
		CONSTRAINT pk_auto_exp_ins_file PRIMARY KEY (app_sid, automated_export_instance_id, instance_file_id),
		CONSTRAINT fk_auto_exp_ins_file FOREIGN KEY (app_sid, automated_export_instance_id)
			REFERENCES csr.automated_export_instance(app_sid, automated_export_instance_id)
	)';
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE csr.aut_export_message_id_seq';
EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -2289) THEN
		null; -- No worries, the sequence doesn't exist YET!.
	ELSE
		RAISE;
	END IF;
END;
/
CREATE SEQUENCE csr.aut_export_message_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

 -- CSR.AUTOMATED_EXPORT_INST_MESSAGE
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_INST_MESSAGE'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_inst_message';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_inst_message(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		instance_message_id           NUMBER(10, 0)    NOT NULL,
		automated_export_instance_id  NUMBER(10, 0)    NOT NULL,
		message                       VARCHAR2(2048)   NOT NULL,
		result                        VARCHAR2(255)    NOT NULL,
		CONSTRAINT pk_autom_exprt_instance_mes PRIMARY KEY (app_sid, automated_export_instance_id, instance_message_id),
		CONSTRAINT fk_autom_exprt_instance_mes FOREIGN KEY (app_sid, automated_export_instance_id)
			REFERENCES csr.automated_export_instance(app_sid, automated_export_instance_id),
		CONSTRAINT uk_instance_message_id  UNIQUE (instance_message_id)
	)';
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE csr.aut_export_ind_conf_id_seq';
EXCEPTION
	WHEN OTHERS THEN
	IF (SQLCODE = -2289) THEN
		null; -- No worries, the sequence doesn't exist YET!.
	ELSE
		RAISE;
	END IF;
END;
/
CREATE SEQUENCE csr.aut_export_ind_conf_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

 -- CSR.AUTOMATED_EXPORT_IND_CONF
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_IND_CONF'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_ind_conf';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_ind_conf(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		automated_exp_ind_config_id   NUMBER(10, 0)    NOT NULL,
		automated_export_class_sid    NUMBER(10, 0)    NOT NULL,
		period_pattern                VARCHAR2(255)    NOT NULL,
		period_interval_id            NUMBER(10, 0)    NOT NULL,
		scenario_run_sid              NUMBER(10, 0)    NOT NULL,
		CONSTRAINT pk_autom_exp_ind_conf PRIMARY KEY (app_sid, automated_exp_ind_config_id),
		CONSTRAINT fk_autom_exp_ind_conf FOREIGN KEY (app_sid, automated_export_class_sid)
			REFERENCES csr.automated_export_class(app_sid, automated_export_class_sid),
		CONSTRAINT chk_period_pattern CHECK (period_pattern IN (''PREV_YEAR_AND_YEAR_TO_DATE'')),
		CONSTRAINT uk_autom_exp_ind_conf UNIQUE (automated_exp_ind_config_id)
	)';
END;
/

 -- CSR.AUTOMATED_EXPORT_IND_COLUMNS
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_IND_COLUMNS'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_ind_columns';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_ind_columns(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		automated_exp_ind_config_id   NUMBER(10, 0)    NOT NULL,
		position                      NUMBER(10, 0)    NOT NULL,
		label                         VARCHAR2(255)    NOT NULL,
		filler_property               VARCHAR2(255)    NOT NULL,
		CONSTRAINT pk_autom_exp_ind_cols PRIMARY KEY (app_sid, automated_exp_ind_config_id, filler_property),
		CONSTRAINT fk_autom_exp_ind_cols FOREIGN KEY (app_sid, automated_exp_ind_config_id)
			REFERENCES csr.automated_export_ind_conf(app_sid, automated_exp_ind_config_id)
	)';
END;
/

 -- CSR.AUTOMATED_EXPORT_IND_MEMBER
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_IND_MEMBER'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_ind_member';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_ind_member(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		automated_exp_ind_config_id   NUMBER(10, 0)    NOT NULL,
		ind_sid                       NUMBER(10, 0)    NOT NULL,
		CONSTRAINT pk_autom_exp_ind_member PRIMARY KEY (app_sid, automated_exp_ind_config_id, ind_sid),
		CONSTRAINT fk_autom_exp_ind_member FOREIGN KEY (app_sid, automated_exp_ind_config_id)
			REFERENCES csr.automated_export_ind_conf(app_sid, automated_exp_ind_config_id)
	)';
END;
/

-- CSR.AUTOMATED_EXPORT_REGION_MEMBER
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_REGION_MEMBER'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_region_member';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_region_member(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		automated_exp_ind_config_id   NUMBER(10, 0)    NOT NULL,
		region_sid                    NUMBER(10, 0)    NOT NULL,
		CONSTRAINT pk_autom_exp_reg_member PRIMARY KEY (app_sid, automated_exp_ind_config_id, region_sid),
		CONSTRAINT fk_autom_exp_reg_member FOREIGN KEY (app_sid, automated_exp_ind_config_id)
			REFERENCES csr.automated_export_ind_conf(app_sid, automated_exp_ind_config_id)
	)';
END;
/

-- CSR.AUTOMATED_EXPORT_ALIAS
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM all_tables
	 WHERE table_name = 'AUTOMATED_EXPORT_ALIAS'
	   AND owner = 'CSR';

	IF v_exists != 0 THEN
		EXECUTE IMMEDIATE 'DROP TABLE csr.automated_export_alias';
	END IF;

	EXECUTE IMMEDIATE 'CREATE TABLE csr.automated_export_alias(
		app_sid                       NUMBER(10, 0)    DEFAULT SYS_CONTEXT(''SECURITY'',''APP'') NOT NULL,
		sid                           NUMBER(10, 0)    NOT NULL,
		automated_exp_ind_config_id   NUMBER(10, 0)    NOT NULL,
		label                         VARCHAR2(255)    NOT NULL,
		CONSTRAINT pk_autom_exp_alias PRIMARY KEY (app_sid, automated_exp_ind_config_id, sid),
		CONSTRAINT fk_autom_exp_alias FOREIGN KEY (app_sid, automated_exp_ind_config_id)
			REFERENCES csr.automated_export_ind_conf(app_sid, automated_exp_ind_config_id)
	)';
END;
/

-- Alter tables
ALTER TABLE csr.tpl_report_tag_dataview DROP CONSTRAINT chk_filter_result_mode;
ALTER TABLE csr.tpl_report_tag_dataview ADD CONSTRAINT chk_filter_result_mode CHECK (filter_result_mode IN (2, 3, 4, 5, 6));
ALTER TABLE csrimp.tpl_report_tag_dataview DROP CONSTRAINT chk_filter_result_mode;
ALTER TABLE csrimp.tpl_report_tag_dataview ADD CONSTRAINT chk_filter_result_mode CHECK (filter_result_mode IN (2, 3, 4, 5, 6));

ALTER TABLE chain.tt_filter_object_data MODIFY val_number NUMBER(24, 10);

ALTER TABLE chain.filter_value ADD (pos NUMBER(10));
ALTER TABLE csrimp.chain_filter_value ADD (pos NUMBER(10));

ALTER TABLE CHAIN.REFERENCE ADD SHOW_IN_FILTER NUMBER(10, 0) DEFAULT 1 NULL;
UPDATE CHAIN.REFERENCE SET SHOW_IN_FILTER = 1 WHERE SHOW_IN_FILTER IS NULL;

ALTER TABLE CHAIN.REFERENCE MODIFY SHOW_IN_FILTER NOT NULL;
ALTER TABLE CHAIN.REFERENCE ADD CONSTRAINT CHK_SHOW_IN_FILTER CHECK (SHOW_IN_FILTER IN (0,1));

ALTER TABLE CSRIMP.CHAIN_REFERENCE ADD SHOW_IN_FILTER NUMBER(1) NULL;
UPDATE CSRIMP.CHAIN_REFERENCE SET SHOW_IN_FILTER = 1 WHERE SHOW_IN_FILTER IS NULL;
ALTER TABLE CSRIMP.CHAIN_REFERENCE MODIFY SHOW_IN_FILTER NOT NULL;


ALTER TABLE CMS.TAB ADD SHOW_IN_COMPANY_FILTER NUMBER(1) DEFAULT 0;
UPDATE CMS.TAB SET SHOW_IN_COMPANY_FILTER = 0 WHERE SHOW_IN_COMPANY_FILTER IS NULL;
ALTER TABLE CMS.TAB MODIFY SHOW_IN_COMPANY_FILTER NOT NULL;
ALTER TABLE CMS.TAB ADD CONSTRAINT CHK_SHOW_IN_COMPANY_FILTER CHECK (SHOW_IN_COMPANY_FILTER IN (0,1));

ALTER TABLE CSRIMP.CMS_TAB ADD SHOW_IN_COMPANY_FILTER NUMBER(1) NULL;
UPDATE CSRIMP.CMS_TAB SET SHOW_IN_COMPANY_FILTER = 0 WHERE SHOW_IN_COMPANY_FILTER IS NULL;
ALTER TABLE CSRIMP.CMS_TAB MODIFY SHOW_IN_COMPANY_FILTER NOT NULL;

ALTER TABLE csr.non_comp_default_issue ADD (
	due_dtm_relative			NUMBER(10),
	due_dtm_relative_unit		VARCHAR2(1),
	CONSTRAINT chk_non_comp_def_iss_due_unit CHECK (due_dtm_relative_unit IN ('d','m')), -- to match qs_expr_non_compl_action
	CONSTRAINT chk_non_comp_def_iss_due_rel CHECK ((due_dtm_relative IS NULL AND due_dtm_relative_unit IS NULL) OR (due_dtm_relative IS NOT NULL AND due_dtm_relative_unit IS NOT NULL))
);

ALTER TABLE csrimp.non_comp_default_issue ADD (
	due_dtm_relative			NUMBER(10),
	due_dtm_relative_unit		VARCHAR2(1),
	CONSTRAINT chk_non_comp_def_iss_due_unit CHECK (due_dtm_relative_unit IN ('d','m')),
	CONSTRAINT chk_non_comp_def_iss_due_rel CHECK ((due_dtm_relative IS NULL AND due_dtm_relative_unit IS NULL) OR (due_dtm_relative IS NOT NULL AND due_dtm_relative_unit IS NOT NULL))
);

ALTER TABLE csr.quick_survey_expr_action
ADD MANDATORY_QUESTION_ID NUMBER(10) NULL;

ALTER TABLE csr.quick_survey_expr_action
DROP CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK;

ALTER TABLE csr.quick_survey_expr_action
ADD CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK (
	(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL)
	OR
	(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
	  AND MANDATORY_QUESTION_ID IS NULL)
	OR
	(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NOT NULL)
  );

ALTER TABLE csr.issue_type ADD (
	show_one_issue_popup				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_show_one_issue_popup CHECK (show_one_issue_popup IN (1, 0))
);

ALTER TABLE csr.issue_sheet_value DROP CONSTRAINT UK_ISSUE_SHEET_VALUE;

ALTER TABLE csrimp.issue_sheet_value DROP CONSTRAINT UK_ISSUE_SHEET_VALUE;

DECLARE
 v_id  NUMBER;
BEGIN
 FOR r IN (
  SELECT c.app_sid, c.host, COUNT(*) cnt
    FROM csr.customer c 
    JOIN csr.all_property p ON c.app_sid =p.app_sid 
   WHERE p.property_type_Id IS NULL 
   GROUP BY c.app_sid, c.host 
   ORDER BY COUNT(*) DESC
 )
 loop
  dbms_output.put_line('Fixing '||r.host);
  BEGIN
	SELECT property_type_id 
			INTO v_id
		FROM csr.property_type
		WHERE label = 'Default'
		AND app_sid = r.app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			 INSERT INTO csr.property_type (app_sid, property_type_id, label) VALUES (r.app_sid, csr.property_type_Id_seq.nextval, 'Default') returning property_Type_id INTO v_id;
	END;
 
	UPDATE csr.all_property SET property_type_id = v_id WHERE property_type_id IS NULL AND app_sid = r.app_sid;
 END LOOP;
END;
/

ALTER TABLE csr.all_property MODIFY property_type_id NUMBER(10) NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$filter_value AS
       SELECT f.app_sid, f.filter_id, ff.filter_field_id, ff.name, fv.filter_value_id, fv.str_value,
		   fv.num_value, fv.min_num_val, fv.max_num_val, fv.start_dtm_value, fv.end_dtm_value, fv.region_sid, fv.user_sid,
		   fv.compound_filter_id_value, fv.saved_filter_sid_value, fv.pos,
		   NVL(NVL(fv.description, CASE fv.user_sid WHEN -1 THEN 'Me' WHEN -2 THEN 'My roles' WHEN -3 THEN 'My staff' ELSE
		   NVL(NVL(r.description, cu.full_name), cr.name) END), fv.str_value) description, ff.group_by_index,
		   f.compound_filter_id, ff.show_all
	  FROM filter f
	  JOIN filter_field ff ON f.app_sid = ff.app_sid AND f.filter_id = ff.filter_id
	  JOIN filter_value fv ON ff.app_sid = fv.app_sid AND ff.filter_field_id = fv.filter_field_id
	  LEFT JOIN csr.v$region r ON fv.region_sid = r.region_sid AND fv.app_sid = r.app_sid
	  LEFT JOIN csr.csr_user cu ON fv.user_sid = cu.csr_user_sid AND fv.app_sid = cu.app_sid
	  LEFT JOIN csr.role cr ON fv.user_sid = cr.role_sid AND fv.app_sid = cr.app_sid;

CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_be_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;

-- *** Data changes ***
-- RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
	
	-- CSR.AUTOMATED_EXPORT_CLASS
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_CLASS',
			policy_name     => 'AUTOMATED_EXPORT_CLS_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_CLASS');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_CLASS');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_CLASS as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_INSTANCE
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_INSTANCE',
			policy_name     => 'AUTOMATED_EXPORT_INST_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_INSTANCE');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_INSTANCE');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_INSTANCE as feature not enabled');
	END;

	-- CSR.FTP_PROFILE
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'FTP_PROFILE',
			policy_name     => 'FTP_PROFILE_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to FTP_PROFILE');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for FTP_PROFILE');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for FTP_PROFILE as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_INST_MESSAGE
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_INST_MESSAGE',
			policy_name     => 'AUTOM_EXPRT_INST_MES_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_INST_MESSAGE');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_INST_MESSAGE');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_INST_MESSAGE as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_IND_CONF
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_IND_CONF',
			policy_name     => 'AUTOM_EXPRT_IND_CONF_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_IND_CONF');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_IND_CONF');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_IND_CONF as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_IND_COLUMNS
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_IND_COLUMNS',
			policy_name     => 'AUTOM_EXPRT_IND_COLS_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_IND_COLUMNS');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_IND_COLUMNS');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_IND_COLUMNS as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_IND_MEMBER
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_IND_MEMBER',
			policy_name     => 'AUTOM_EXPRT_IND_MEM_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_IND_MEMBER');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_IND_MEMBER');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_IND_MEMBER as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_REGION_MEMBER
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_REGION_MEMBER',
			policy_name     => 'AUTOM_EXPRT_REG_MEM_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_REGION_MEMBER');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_REGION_MEMBER');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_REGION_MEMBER as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_INST_FILES
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_INST_FILES',
			policy_name     => 'AUTOM_EXPRT_INST_FILES_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_INST_FILES');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_INST_FILES');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_INST_FILES as feature not enabled');
	END;

	-- CSR.AUTOMATED_EXPORT_ALIAS
	BEGIN
		DBMS_RLS.ADD_POLICY(
			object_schema   => 'CSR',
			object_name     => 'AUTOMATED_EXPORT_ALIAS',
			policy_name     => 'AUTOM_EXPRT_ALIAS_POLICY',
			function_schema => 'CSR',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check    => true,
			policy_type     => dbms_rls.context_sensitive );
		DBMS_OUTPUT.PUT_LINE('Policy added to AUTOMATED_EXPORT_ALIAS');
	EXCEPTION
		WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for AUTOMATED_EXPORT_ALIAS');
		WHEN FEATURE_NOT_ENABLED THEN
			DBMS_OUTPUT.PUT_LINE('RLS policies not applied for AUTOMATED_EXPORT_ALIAS as feature not enabled');
	END;

END;
/

	-- Setup the schedule to create import jobs
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM dba_scheduler_jobs
	 WHERE job_name = 'AUTOMATEDEXPORT';
	
	IF v_exists = 0 THEN
		dbms_scheduler.create_job (
			job_name        => 'AutomatedExport',
			job_type        => 'PLSQL_BLOCK',
			job_action      => '
				BEGIN
				  csr.user_pkg.logonadmin();
				  csr.automated_export_import_pkg.CheckForNewJobs();
				  commit;
				END;
			',
			start_date      => SYSTIMESTAMP,
			repeat_interval => 'freq=daily; byhour=2; byminute=0; bysecond=0;',
			end_date        => NULL,
			enabled         => TRUE,
			comments        => 'Automated export schedule'
		);
	END IF;
END;  
/

-- Data
UPDATE chain.card
   SET js_class_type='Credit360.Filters.Issues.StandardIssuesFilter'
 WHERE js_class_type='Credit360.Issues.Filters.StandardIssuesFilter';

UPDATE chain.card
   SET js_class_type='Credit360.Filters.Issues.IssuesCustomFieldsFilter'
 WHERE js_class_type='Credit360.Issues.Filters.IssuesCustomFieldsFilter';

UPDATE chain.card
   SET js_class_type='Credit360.Filters.Issues.IssuesFilterAdapter'
 WHERE js_class_type='Credit360.Issues.Filters.IssuesFilterAdapter';

CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2, 
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER DEFAULT 0
)
AS
	v_count						NUMBER(10);
	v_ct						NUMBER(10);
BEGIN
	IF in_capability_type = 3 /*chain_pkg.CT_COMPANIES*/ THEN
		Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
		Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
		RETURN;	
	END IF;
	
	IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
	ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
		RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;
	
	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.capability
	 WHERE capability_name = in_capability
	   AND (
			(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   		 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
	   	   );
	
	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;
	
	INSERT INTO chain.capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
END;
/

BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 0,  		/* CT_COMMON*/
		in_capability	=> 'Filter on company audits', 
		in_perm_type	=> 1 			/* BOOLEAN_PERMISSION */
	);
	
	chain.Temp_RegisterCapability(
		in_capability_type	=> 0,  		/* CT_COMMON*/
		in_capability	=> 'Filter on cms companies', 
		in_perm_type	=> 1 			/* BOOLEAN_PERMISSION */
	);

END;
/

/* chain.card_pkg.RegisterCard(
	'Chain Company Audit Adapter', 
	'Credit360.Chain.Cards.Filters.CompanyAuditFilterAdapter',
	'/csr/site/chain/cards/filters/companyAuditFilterAdapter.js', 
	'Chain.Cards.Filters.CompanyAuditFilterAdapter'
); */
DECLARE
    v_card_id         chain.card.card_id%TYPE;
    v_desc            chain.card.description%TYPE;
    v_class           chain.card.class_type%TYPE;
    v_js_path         chain.card.js_include%TYPE;
    v_js_class        chain.card.js_class_type%TYPE;
    v_css_path        chain.card.css_include%TYPE;
    v_actions         chain.T_STRING_LIST;
BEGIN
    -- Chain.Cards.Filters.CompanyAuditFilterAdapter
    v_desc := 'Chain Company Audit Adapter';
    v_class := 'Credit360.Chain.Cards.Filters.CompanyAuditFilterAdapter';
    v_js_path := '/csr/site/chain/cards/filters/companyAuditFilterAdapter.js';
    v_js_class := 'Chain.Cards.Filters.CompanyAuditFilterAdapter';
    v_css_path := '';
    
    BEGIN
        INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
        VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
        RETURNING card_id INTO v_card_id;
    EXCEPTION 
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE chain.card 
               SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
             WHERE js_class_type = v_js_class
         RETURNING card_id INTO v_card_id;
    END;
    
    DELETE FROM chain.card_progression_action 
     WHERE card_id = v_card_id 
       AND action NOT IN ('default');
    
    v_actions := chain.T_STRING_LIST('default');
    
    FOR i IN v_actions.FIRST .. v_actions.LAST
    LOOP
        BEGIN
            INSERT INTO chain.card_progression_action (card_id, action)
            VALUES (v_card_id, v_actions(i));
        EXCEPTION 
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;
        END;
    END LOOP;
END;
/

/* chain.card_pkg.RegisterCard(
		'Chain Company CMS Adapter', 
		'Credit360.Chain.Cards.Filters.CompanyCmsFilterAdapter',
		'/csr/site/chain/cards/filters/companyCmsFilterAdapter.js', 
		'Chain.Cards.Filters.CompanyCmsFilterAdapter'
	);
*/	
DECLARE
    v_card_id         chain.card.card_id%TYPE;
    v_desc            chain.card.description%TYPE;
    v_class           chain.card.class_type%TYPE;
    v_js_path         chain.card.js_include%TYPE;
    v_js_class        chain.card.js_class_type%TYPE;
    v_css_path        chain.card.css_include%TYPE;
    v_actions         chain.T_STRING_LIST;
BEGIN
    -- Chain.Cards.Filters.CompanyCmsFilterAdapter
    v_desc := 'Chain Company CMS Adapter';
    v_class := 'Credit360.Chain.Cards.Filters.CompanyCmsFilterAdapter';
    v_js_path := '/csr/site/chain/cards/filters/companyCmsFilterAdapter.js';
    v_js_class := 'Chain.Cards.Filters.CompanyCmsFilterAdapter';
    v_css_path := '';

    BEGIN
        INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
        VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
        RETURNING card_id INTO v_card_id;
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            UPDATE chain.card
               SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
             WHERE js_class_type = v_js_class
         RETURNING card_id INTO v_card_id;
    END;
	
    DELETE FROM chain.card_progression_action
     WHERE card_id = v_card_id
       AND action NOT IN ('default');

    v_actions := chain.T_STRING_LIST('default');

    FOR i IN v_actions.FIRST .. v_actions.LAST
    LOOP
        BEGIN
            INSERT INTO chain.card_progression_action (card_id, action)
            VALUES (v_card_id, v_actions(i));
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                NULL;
        END;
    END LOOP;
END;
/

BEGIN
	/* 
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Audit Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyAuditFilterAdapter'
	);
*/
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'Chain Company Audit Filter Adapter',
				'chain.company_filter_pkg',
				chain.card_pkg.GetCardId('Chain.Cards.Filters.CompanyAuditFilterAdapter')
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'Chain Company Audit Filter Adapter',
					   helper_pkg = 'chain.company_filter_pkg'
				 WHERE card_id = chain.card_pkg.GetCardId('Chain.Cards.Filters.CompanyAuditFilterAdapter');
	END;
	/* 
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Cms Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCmsFilterAdapter'
	);
*/
	BEGIN
		INSERT INTO chain.filter_type (
				filter_type_id,
				description,
				helper_pkg,
				card_id
			) VALUES (
				chain.filter_type_id_seq.NEXTVAL,
				'Chain Company Cms Filter',
				'chain.company_filter_pkg',
				chain.card_pkg.GetCardId('Chain.Cards.Filters.CompanyCmsFilterAdapter')
			);
		EXCEPTION
			WHEN dup_val_on_index THEN
				UPDATE chain.filter_type
				   SET description = 'Chain Company Cms Filter',
					   helper_pkg = 'chain.company_filter_pkg'
				 WHERE card_id = chain.card_pkg.GetCardId('Chain.Cards.Filters.CompanyCmsFilterAdapter');
	END;
END;
/



--Add CompanyAuditFilterAdapter to Basic Company Filter group
DECLARE
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
	v_capability_id			NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyAuditFilterAdapter');

	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Basic Company Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;
	
	BEGIN
		SELECT capability_id
		  INTO v_capability_id
		  FROM chain.capability
		 WHERE LOWER(capability_name) = LOWER('Filter on company audits');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a capability with name = Filter on company audits');
	END;
	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL, v_capability_id);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/


--Add CompanyCmsFilterAdapter to Basic Company Filter group
DECLARE
	v_card_id				NUMBER(10);
	v_group_id				NUMBER(10);
	v_capability_id			NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE LOWER(js_class_type) = LOWER('Chain.Cards.Filters.CompanyCmsFilterAdapter');

	
	BEGIN
		SELECT card_group_id
		  INTO v_group_id
		  FROM chain.card_group
		 WHERE LOWER(name) = LOWER('Basic Company Filter');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a card group with name = Basic Company Filter');
	END;
	
	BEGIN
		SELECT capability_id
		  INTO v_capability_id
		  FROM chain.capability
		 WHERE LOWER(capability_name) = LOWER('Filter on cms companies');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a capability with name = Filter on cms companies');
	END;
	
	
	FOR r IN (
		SELECT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = v_group_id
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card(app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			     VALUES (r.app_sid, v_group_id, v_card_id, r.pos, NULL, v_capability_id);
		EXCEPTION
			WHEN dup_val_on_index THEN
				NULL;
		END;
	END LOOP;
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;

update csr.std_alert_type 
   set send_trigger = 'The state of a sheet changes (by submitting or approving)'
 where std_alert_type_id = 4;

update csr.std_alert_type
   set send_trigger = 'The state of a sheet changes (by submitting or approving). Notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.'
 where std_alert_type_id = 30;

INSERT INTO CSR.MODULE (MODULE_ID, MODULE_NAME, ENABLE_SP, DESCRIPTION)
VALUES ((SELECT MAX(MODULE_ID)+1 FROM CSR.MODULE), 'Initiatives', 'EnableInitiatives', 'Enables Initiatives module');
INSERT INTO CSR.MODULE (MODULE_ID, MODULE_NAME, ENABLE_SP, DESCRIPTION)
VALUES ((SELECT MAX(MODULE_ID)+1 FROM CSR.MODULE), 'Initiatives Audit', 'EnableInitiativesAuditTab', 'Enables Initiatives Audit Log tab for new projects');

 -- Adding new type of batch job
DECLARE
	v_exists		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM csr.batch_job_type
	 WHERE description = 'Automated export';
	
	IF v_exists = 0 THEN
		INSERT INTO csr.batch_job_type
		  (BATCH_JOB_TYPE_ID, DESCRIPTION, SP, PLUGIN_NAME, ONE_AT_A_TIME, FILE_DATA_SP)
		VALUES
		  (16, 'Automated export', NULL, 'automated-export', 0, NULL );
	END IF;
END;  
/

 -- Create new securable object class
DECLARE
    v_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'AutomatedExport', 'csr.automated_export_import_pkg', null, v_Id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
        NULL;
END;
/

 -- New alert type
DECLARE
	v_exists						NUMBER;
	v_alert_type_id					NUMBER := 72;
	v_default_alert_frame_id		NUMBER;
BEGIN
	SELECT count(*)
	  INTO v_exists
	  FROM csr.std_alert_type
	 WHERE description = 'Automated export completed';
	
	IF v_exists = 0 THEN
		INSERT INTO csr.std_alert_type
			(std_alert_type_id, description, send_trigger, sent_from)
		VALUES
			(v_alert_type_id, 'Automated export completed', 'An automated export has completeted',
				'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');

		INSERT INTO csr.std_alert_type_param
			(std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES
			(v_alert_type_id, 0, 'EXPORT_CLASS_LABEL', 'Export class label', 'The name/description of the export', 1);

		INSERT INTO csr.std_alert_type_param
			(std_alert_type_id, repeats, field_name, description, help_text, display_pos)
		VALUES
			(v_alert_type_id, 0, 'RESULT', 'Result of the export', 'The result of the export instance', 2);

		SELECT MAX(default_alert_frame_id)
		  INTO v_default_alert_frame_id
		  FROM csr.default_alert_frame;

		INSERT INTO csr.default_alert_template
			(std_alert_type_id, default_alert_frame_id, send_type)
		VALUES
			(v_alert_type_id, v_default_alert_frame_id, 'automatic');

		INSERT INTO CSR.default_alert_template_body 
			(std_alert_type_id, lang, subject, body_html, item_html)
		VALUES
			(v_alert_type_id, 'en', '<template>An automated export has completed</template>',
			'<template><p><mergefield name="EXPORT_CLASS_LABEL"/> export has completed with the following result;</p><p><mergefield name="RESULT"/></p></template>', 
			'<template/>'
		);
	END IF;
END;
/

BEGIN
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class,
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 1, 'Meter Raw Data',  '/csr/site/property/properties/controls/MeterRawDataTab.js', 'Controls.MeterRawDataTab',
			         'Credit360.Plugins.PluginDto', 'This tab shows raw data for real time metering.', NULL, NULL, NULL);
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin
		   SET description = 'Meter Raw Data',
		   	   js_include = '/csr/site/property/properties/controls/MeterRawDataTab.js',
		   	   details = 'This tab shows raw data for real time metering.',
		   	   form_path = NULL
		 WHERE plugin_type_id = 1
		   AND js_class = 'Controls.MeterRawDataTab'
		   AND app_sid IS NULL
		   AND tab_sid IS NULL;
	END;
END;
/

INSERT INTO csr.portlet (portlet_id, name, type, default_state, script_path)
VALUES (1056,'Training Matrix','Credit360.Portlets.TrainingMatrix',null,'/csr/site/portal/portlets/TrainingMatrix.js');

DELETE
  FROM csr.branding_availability
 WHERE client_folder_name IN
(
	'aberdeen', 'alium', 'amex', 'autodesk', 'bbp', 'bmw-en', 'boliden', 'bostonproperties', 'brita', 'camtrust',
	'colasrail', 'copel', 'csm', 'csresolutions', 'danstrategy', 'diageo', 'disney', 'eiffage', 'firstrand',
	'fletcherbuilding', 'gdfsuez', 'gea', 'goldfields', 'gpe', 'greggs', 'hugoboss', 'hvc', 'imageconsultant',
	'internationalpower', 'jkx', 'kemira', 'learnfromtheleaders', 'lfl', 'liffe', 'lonza', 'magic', 'metrogroup',
	'microsoft', 'ngers', 'omv', 'orange-fr', 'oriflame', 'potential', 'prrg', 'raytheon', 'reedelsevier', 'roundys',
	'saintgobain', 'sauce', 'tarmac', 'tbi', 'thames', 'tikkurila', 'virginatlantic', 'visa', 'willsono'
);

DELETE
  FROM csr.branding
 WHERE client_folder_name IN
(
	'aberdeen', 'alium', 'amex', 'autodesk', 'bbp', 'bmw-en', 'boliden', 'bostonproperties', 'brita', 'camtrust',
	'colasrail', 'copel', 'csm', 'csresolutions', 'danstrategy', 'diageo', 'disney', 'eiffage', 'firstrand',
	'fletcherbuilding', 'gdfsuez', 'gea', 'goldfields', 'gpe', 'greggs', 'hugoboss', 'hvc', 'imageconsultant',
	'internationalpower', 'jkx', 'kemira', 'learnfromtheleaders', 'lfl', 'liffe', 'lonza', 'magic', 'metrogroup',
	'microsoft', 'ngers', 'omv', 'orange-fr', 'oriflame', 'potential', 'prrg', 'raytheon', 'reedelsevier', 'roundys',
	'saintgobain', 'sauce', 'tarmac', 'tbi', 'thames', 'tikkurila', 'virginatlantic', 'visa', 'willsono'
);

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.automated_export_import_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.automated_export_import_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/

GRANT EXECUTE ON csr.automated_export_import_pkg TO security;
GRANT EXECUTE ON csr.automated_export_import_pkg TO web_user;

--** Jobs **
-- Queue a job for RunChainJobs (UpdateExpirations, CheckForOverdueQuestionnaires, UpdateTasksForReview) running hourly
DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every hour
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.RunChainJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'scheduled_alert_pkg.RunChainJobs;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=HOURLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Triggers job for running chain jobs');
       COMMIT;
END;
/

-- *** Packages ***
@../chain/chain_pkg
@../chain/filter_pkg
@../audit_pkg
@../../../aspen2/cms/db/filter_pkg
@..\delegation_pkg
@..\quick_survey_pkg
@..\batch_job_pkg
@..\automated_export_import_pkg
@..\enable_pkg
@../issue_pkg
@../meter_monitor_pkg
@..\chain\company_pkg

@..\chain\company_body
@../csr_app_body
@../meter_monitor_body
@../sheet_body
@..\automated_export_import_body
@..\quick_survey_body
@..\delegation_body
@..\deleg_plan_body
@../chain/company_filter_body
@../chain/helper_body
@../chain/setup_body
@../chain/filter_body
@../chain/scheduled_alert_body
@../non_compliance_report_body
@../issue_body
@../issue_report_body
@../audit_body
@../audit_report_body
@../enable_body
@../../../aspen2/cms/db/filter_body
@../schema_body
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_body

@update_tail
