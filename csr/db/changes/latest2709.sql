-- Please update version.sql too -- this keeps clean builds in sync
define version=2709
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.QS_RESPONSE_FILE(
    APP_SID					NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SURVEY_RESPONSE_ID		NUMBER(10, 0)		NOT NULL,
    FILENAME				VARCHAR2(255)		NOT NULL,
    MIME_TYPE				VARCHAR2(256)		NOT NULL,
    DATA					BLOB				NOT NULL,
    SHA1					RAW(20)				NOT NULL,
    UPLOADED_DTM			DATE				DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_QS_RESPONSE_FILE PRIMARY KEY (APP_SID, SURVEY_RESPONSE_ID, SHA1, FILENAME, MIME_TYPE),
	CONSTRAINT FK_QS_RESPONSE_FILE_RESPONSE FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID) REFERENCES CSR.QUICK_SURVEY_RESPONSE(APP_SID, SURVEY_RESPONSE_ID)
);

CREATE TABLE chain.saved_filter_alert (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	users_can_subscribe				NUMBER(1) DEFAULT 0 NOT NULL,
	customer_alert_type_id			NUMBER(10) NOT NULL,
	schedule_xml					SYS.XMLTYPE NOT NULL,
	next_fire_time					DATE NOT NULL,
	CONSTRAINT pk_saved_filter_alert PRIMARY KEY (app_sid, saved_filter_sid),
	CONSTRAINT chk_users_can_subscribe_1_0 CHECK (users_can_subscribe IN (1, 0)),
	CONSTRAINT fk_saved_fltr_alrt_fltr_sid FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid),
	CONSTRAINT fk_svd_fltr_alrt_ctmr_alrt_typ FOREIGN KEY (app_sid, customer_alert_type_id)
		REFERENCES csr.customer_alert_type (app_sid, customer_alert_type_id)
);

CREATE TABLE chain.saved_filter_alert_subscriptn (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	user_sid						NUMBER(10) NOT NULL,
	region_sid						NUMBER(10),
	has_had_initial_set				NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT uk_saved_fltr_alrt_subscriptn UNIQUE (app_sid, saved_filter_sid, user_sid, region_sid),
	CONSTRAINT chk_sv_fl_alt_sub_init_set_1_0 CHECK (has_had_initial_set IN (1, 0)),
	CONSTRAINT fk_sv_fl_alrt_subs_sv_fl_alrt FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter_alert (app_sid, saved_filter_sid),
	CONSTRAINT fk_sv_fltr_alert_subs_csr_usr FOREIGN KEY (app_sid, user_sid)
		REFERENCES csr.csr_user (app_sid, csr_user_sid),
	CONSTRAINT fk_sv_fltr_alert_subs_region FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid)
);

CREATE TABLE chain.saved_filter_sent_alert (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	user_sid						NUMBER(10) NOT NULL,
	object_id						NUMBER(10) NOT NULL,
	sent_dtm						DATE NOT NULL,
	CONSTRAINT pk_saved_filter_sent_alert PRIMARY KEY (app_sid, saved_filter_sid, object_id, user_sid),
	CONSTRAINT fk_svd_fltr_sent_alert_csr_usr FOREIGN KEY (app_sid, user_sid)
		REFERENCES csr.csr_user (app_sid, csr_user_sid),
	CONSTRAINT fk_sv_fltr_sent_alrt_fltr_sid FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);

CREATE TABLE chain.saved_filter_alert_param (
	card_group_id					NUMBER(10) NOT NULL,
	field_name						VARCHAR(100) NOT NULL,
	description						VARCHAR(200) NOT NULL,
	translatable					NUMBER(1) DEFAULT 0 NOT NULL,
	link_text						VARCHAR(200),
	CONSTRAINT pk_saved_filter_alert_param PRIMARY KEY (card_group_id, field_name),
	CONSTRAINT chk_svd_fltr_alrt_param_tr_0_1 CHECK (translatable IN (0,1)),
	CONSTRAINT fk_svd_fltr_alrt_param_crd_grp FOREIGN KEY (card_group_id)
		REFERENCES chain.card_group(card_group_id)
);

CREATE TABLE csrimp.chain_saved_filter_alert (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	users_can_subscribe				NUMBER(1) NOT NULL,
	customer_alert_type_id			NUMBER(10) NOT NULL,
	schedule_xml					SYS.XMLTYPE NOT NULL,
	next_fire_time					DATE NOT NULL,
	last_fire_time					DATE,
	alerts_sent_on_last_run			NUMBER(10),
	CONSTRAINT pk_saved_filter_alert PRIMARY KEY (CSRIMP_SESSION_ID, saved_filter_sid),
	CONSTRAINT chk_users_can_subscribe_1_0 CHECK (users_can_subscribe IN (1, 0)),
	CONSTRAINT FK_CHAIN_SAVED_FIL_ALERT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.chain_saved_fltr_alrt_sbscrptn (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	user_sid						NUMBER(10) NOT NULL,
	region_sid						NUMBER(10),
	CONSTRAINT uk_saved_fltr_alrt_subscriptn UNIQUE (CSRIMP_SESSION_ID, saved_filter_sid, user_sid, region_sid),
	CONSTRAINT FK_CHAIN_SVD_FIL_ALRT_SUB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE GLOBAL TEMPORARY TABLE CSR.TT_ALERT_FLOW_ITEMS(
	FLOW_ITEM_ID  NUMBER(10)	NOT NULL, 
	CONSTRAINT PK_TT_ALERT_FLOW_ITEM PRIMARY KEY (FLOW_ITEM_ID)
)
ON COMMIT PRESERVE ROWS
;

CREATE TABLE CSR.CMS_IMP_MANUAL_FILE(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CMS_IMP_INSTANCE_ID       NUMBER(10, 0)    NOT NULL,
    STEP_NUMBER               NUMBER(10, 0)    NOT NULL,
    FILE_BLOB                 BLOB             NOT NULL,
    FILE_NAME                 VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_CMS_IMP_MAN_FILE PRIMARY KEY (APP_SID, CMS_IMP_INSTANCE_ID, STEP_NUMBER)
)
;

CREATE TABLE CSR.APP_DASH_SUP_REPORT_PORTLET(
	PORTLET_TYPE           VARCHAR2(255)    	   NOT NULL,
	MAPS_TO_TAG_TYPE 			 NUMBER(10)		   NOT NULL,
    CONSTRAINT PK_APP_DASH_SUP_REPORT_PORTLET PRIMARY KEY (PORTLET_TYPE)
);

CREATE TABLE CSR.APPROVAL_NOTE_PORTLET_NOTE (
  APP_SID                   NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  VERSION                   NUMBER(10, 0)     NOT NULL,
  TAB_PORTLET_ID            NUMBER(10, 0)     NOT NULL,
  APPROVAL_DASHBOARD_SID    NUMBER(10, 0)     NOT NULL,
  DASHBOARD_INSTANCE_ID     NUMBER(10, 0)     NOT NULL,
  REGION_SID                NUMBER(10, 0)     NOT NULL,
  NOTE                      VARCHAR2(1024),
  ADDED_DTM                 DATE,
  ADDED_BY_SID              NUMBER(10, 0)     NOT NULL,
  CONSTRAINT PK_APPROVAL_NOTE_PORTLET_NOTE PRIMARY KEY (APP_SID, VERSION, TAB_PORTLET_ID, APPROVAL_DASHBOARD_SID, DASHBOARD_INSTANCE_ID, REGION_SID)
);

CREATE TABLE CSR.TPL_REPORT_TAG_APPROVAL_NOTE (
  APP_SID                     NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  TPL_REPORT_TAG_APP_NOTE_ID  NUMBER(10)        NOT NULL,
  TAB_PORTLET_ID              NUMBER(10, 0)     NOT NULL,
  APPROVAL_DASHBOARD_SID      NUMBER(10, 0)     NOT NULL,
  CONSTRAINT PK_TPL_REPORT_TAG_APP_NOTE PRIMARY KEY (APP_SID, TPL_REPORT_TAG_APP_NOTE_ID)
);

CREATE SEQUENCE CSR.TPL_REPORT_TAG_APP_NOTE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE TABLE CSR.TPL_REPORT_TAG_APPROVAL_MATRIX (
  APP_SID                     	NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
  TPL_REPORT_TAG_APP_MATRIX_ID  NUMBER(10)        NOT NULL,
  APPROVAL_DASHBOARD_SID      	NUMBER(10, 0)     NOT NULL,
  CONSTRAINT PK_TPL_REPORT_TAG_APP_MATRIX PRIMARY KEY (APP_SID, TPL_REPORT_TAG_APP_MATRIX_ID)
);

CREATE SEQUENCE CSR.TPL_REP_TAG_APP_MATRIX_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE OR REPLACE TYPE CSR.T_QS_ANSWER_FILES_ROW AS
	OBJECT (
		SHA1				RAW(20),
		FILENAME			VARCHAR2(255),
		MIME_TYPE			VARCHAR2(256),
		CAPTION				VARCHAR2(1023)
	);
/

CREATE OR REPLACE TYPE CSR.T_QS_ANSWER_FILES_ARRAY AS TABLE OF CSR.T_QS_ANSWER_FILES_ROW;
/
	
CREATE TABLE CSRIMP.QS_RESPONSE_FILE
(
    CSRIMP_SESSION_ID 		NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SURVEY_RESPONSE_ID		NUMBER(10, 0)	NOT NULL,
    FILENAME				VARCHAR2(255)	NOT NULL,
    MIME_TYPE				VARCHAR2(256)	NOT NULL,
    DATA					BLOB			NOT NULL,
    SHA1					RAW(20)			NOT NULL,
    UPLOADED_DTM			DATE			DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_QS_RESPONSE_FILE PRIMARY KEY (CSRIMP_SESSION_ID, SURVEY_RESPONSE_ID, SHA1, FILENAME, MIME_TYPE),
    CONSTRAINT FK_QS_RESPONSE_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

create index chain.ix_svd_fltr_alrt_ctmr_alrt_typ on chain.saved_filter_alert (app_sid, customer_alert_type_id);
create index chain.ix_sv_fltr_alert_subs_csr_usr on chain.saved_filter_alert_subscriptn (app_sid, user_sid);
create index chain.ix_sv_fltr_alert_subs_region on chain.saved_filter_alert_subscriptn (app_sid, region_sid);
create index chain.ix_svd_fltr_sent_alert_csr_usr on chain.saved_filter_sent_alert (app_sid, user_sid);
create index chain.ix_svd_fltr_alrt_param_crd_grp on chain.saved_filter_alert_param (card_group_id);
CREATE INDEX CSR.IX_QS_RESP_FILE_BY_SHA1 ON CSR.QS_RESPONSE_FILE(APP_SID, SHA1, FILENAME, MIME_TYPE);

-- Alter tables
BEGIN
	FOR r IN (
		SELECT APP_SID, SURVEY_RESPONSE_ID, SHA1, FILENAME, MIME_TYPE--, CSR.QS_RESPONSE_FILE_ID_SEQ.NEXTVAL RESP_FILE_ID
		  FROM CSR.QS_ANSWER_FILE
		 GROUP BY APP_SID, SURVEY_RESPONSE_ID, SHA1, FILENAME, MIME_TYPE
	) LOOP
		INSERT INTO CSR.QS_RESPONSE_FILE (APP_SID, SURVEY_RESPONSE_ID, FILENAME, MIME_TYPE, DATA, SHA1, UPLOADED_DTM)
		SELECT r.APP_SID, r.SURVEY_RESPONSE_ID, r.FILENAME, r.MIME_TYPE, QAF.DATA, r.SHA1, UPLOADED_DTM
		  FROM CSR.QS_ANSWER_FILE QAF
		 WHERE QAF.APP_SID = r.APP_SID
		   AND QAF.SURVEY_RESPONSE_ID = r.SURVEY_RESPONSE_ID
		   AND QAF.FILENAME = r.FILENAME
		   AND QAF.MIME_TYPE = r.MIME_TYPE
		   AND QAF.SHA1 = r.SHA1
		   AND rownum = 1;
		
		FOR s IN (
			SELECT QUESTION_ID, COUNT(*) cnt
			  FROM CSR.QS_ANSWER_FILE QAF
			 WHERE QAF.APP_SID = r.APP_SID
			   AND QAF.SURVEY_RESPONSE_ID = r.SURVEY_RESPONSE_ID
			   AND QAF.FILENAME = r.FILENAME
			   AND QAF.MIME_TYPE = r.MIME_TYPE
			   AND QAF.SHA1 = r.SHA1
			 GROUP BY QUESTION_ID
			HAVING COUNT(*) > 1
		) LOOP
			DELETE FROM CSR.QS_SUBMISSION_FILE QSF
			 WHERE QSF.QS_ANSWER_FILE_ID IN (
			SELECT QAF.QS_ANSWER_FILE_ID
			  FROM CSR.QS_ANSWER_FILE QAF
			 WHERE QAF.APP_SID = r.APP_SID
			   AND QAF.SURVEY_RESPONSE_ID = r.SURVEY_RESPONSE_ID
			   AND QAF.FILENAME = r.FILENAME
			   AND QAF.MIME_TYPE = r.MIME_TYPE
			   AND QAF.SHA1 = r.SHA1
			   AND QUESTION_ID = s.QUESTION_ID
			   AND rownum < s.cnt
			);
		END LOOP;
	END LOOP;
	
	DELETE FROM CSR.QS_ANSWER_FILE QAF
	 WHERE QAF.QS_ANSWER_FILE_ID NOT IN (
		SELECT QSF.QS_ANSWER_FILE_ID
		  FROM CSR.QS_SUBMISSION_FILE QSF
	);
END;
/

ALTER TABLE CSRIMP.QS_ANSWER_FILE
DROP (DATA, UPLOADED_DTM);

ALTER TABLE CSR.QS_ANSWER_FILE ADD CONSTRAINT FK_QS_ANSWER_FILE_FILE
    FOREIGN KEY (APP_SID, SURVEY_RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
    REFERENCES CSR.QS_RESPONSE_FILE(APP_SID, SURVEY_RESPONSE_ID, SHA1, FILENAME, MIME_TYPE)
;

GRANT CREATE TABLE TO csr;
DROP INDEX csr.ix_qs_answer_file_search;
CREATE INDEX csr.ix_qs_response_file_srch on csr.qs_response_file(data) indextype is ctxsys.context
PARAMETERS('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist nopopulate');
REVOKE CREATE TABLE FROM csr;

ALTER TABLE CSR.QS_ANSWER_FILE
ADD CONSTRAINT UK_QS_ANSWER_FILE_A UNIQUE (APP_SID, SURVEY_RESPONSE_ID, QUESTION_ID, SHA1, FILENAME, MIME_TYPE);

ALTER TABLE chain.saved_filter_alert ADD (
	last_fire_time					DATE,
	alerts_sent_on_last_run			NUMBER(10)
);

ALTER TABLE chain.saved_filter_alert ADD (
	description						VARCHAR2(4000),
	every_n_minutes					NUMBER(10),
	CONSTRAINT chk_svd_fltr_alrt_n_min_schd CHECK ((every_n_minutes IS NOT NULL AND schedule_xml IS NULL) OR (every_n_minutes IS NULL AND schedule_xml IS NOT NULL))
);

ALTER TABLE chain.saved_filter_alert MODIFY schedule_xml NULL;

ALTER TABLE csrimp.chain_saved_filter_alert ADD (
	description						VARCHAR2(4000),
	every_n_minutes					NUMBER(10),
	CONSTRAINT chk_svd_fltr_alrt_n_min_schd CHECK ((every_n_minutes IS NOT NULL AND schedule_xml IS NULL) OR (every_n_minutes IS NULL AND schedule_xml IS NOT NULL))
);

ALTER TABLE csrimp.chain_saved_filter_alert MODIFY schedule_xml NULL;

ALTER TABLE chain.capability ADD (
	supplier_on_purchaser					NUMBER(1, 0)
);

ALTER TABLE chain.capability ADD (
	CONSTRAINT ck_supplier_on_purchaser CHECK (supplier_on_purchaser IN (0, 1))
);

UPDATE chain.capability
SET supplier_on_purchaser = 0
WHERE supplier_on_purchaser IS NULL;

UPDATE chain.capability
SET supplier_on_purchaser = 1
WHERE CAPABILITY_NAME IN (
	'Add company to business relationships (supplier => purchaser)',
	'View company business relationships (supplier => purchaser)',
	'Terminate company business relationships (supplier => purchaser)'
);

ALTER TABLE chain.capability MODIFY (
	  supplier_on_purchaser					DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.chain_capability ADD (
	supplier_on_purchaser					NUMBER(1, 0)
);

ALTER TABLE csr.course_schedule ADD attendance_password VARCHAR2(100);
ALTER TABLE csr.temp_course_schedule ADD attendance_password VARCHAR2(100);

ALTER TABLE CSR.CMS_IMP_INSTANCE
ADD (IS_MANUAL NUMBER (1) DEFAULT 0);

UPDATE CSR.CMS_IMP_INSTANCE
   SET is_manual = 0;
 
ALTER TABLE CSR.CMS_IMP_INSTANCE
MODIFY is_manual NOT NULL;

ALTER TABLE CSR.CMS_IMP_MANUAL_FILE ADD CONSTRAINT FK_CMS_IMP_MAN_FILE_INST 
    FOREIGN KEY (APP_SID, CMS_IMP_INSTANCE_ID)
    REFERENCES CSR.CMS_IMP_INSTANCE(APP_SID, CMS_IMP_INSTANCE_ID)
;

DROP TABLE CSR.CMS_IMP_MANUAL_INSTANCE;
DROP SEQUENCE CSR.CMS_IMP_MANUAL_INSTANCE_ID_SEQ;
DROP TABLE CSR.APPROVAL_DASH_PEND_CALC_INSTS;

ALTER TABLE CSR.APPROVAL_DASHBOARD_INSTANCE
ADD IS_SIGNED_OFF NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.PORTLET
ADD CONSTRAINT portlet_type UNIQUE (type);

ALTER TABLE CSR.APP_DASH_SUP_REPORT_PORTLET
ADD CONSTRAINT FK_APP_DASH_SUP_REP_PORTL_TYPE 
    FOREIGN KEY (PORTLET_TYPE)
    REFERENCES CSR.PORTLET("TYPE");

ALTER TABLE csr.tpl_report_tag_dataview ADD (
  approval_dashboard_sid NUMBER(10),
  ind_tag NUMBER(10)
);

ALTER TABLE csr.tpl_report_tag_dataview
ADD CONSTRAINT fk_tpl_rep_tag_dv_app_dash
    FOREIGN KEY (app_sid, approval_dashboard_sid)
    REFERENCES csr.approval_dashboard(app_sid, approval_dashboard_sid);

ALTER TABLE csr.tpl_report_tag_dataview
ADD CONSTRAINT fk_tpl_rep_tag_dv_ind_tag
    FOREIGN KEY (app_sid, ind_tag)
    REFERENCES csr.tag(app_sid, tag_id);

ALTER TABLE CSR.APPROVAL_NOTE_PORTLET_NOTE ADD CONSTRAINT FK_APP_NOTE_PORT_NOTE_APP_DASH
  FOREIGN KEY (APP_SID, APPROVAL_DASHBOARD_SID)
  REFERENCES CSR.APPROVAL_DASHBOARD(APP_SID, APPROVAL_DASHBOARD_SID);
  
ALTER TABLE CSR.APPROVAL_NOTE_PORTLET_NOTE ADD CONSTRAINT FK_AP_NOTE_POR_NOTE_AP_DAS_INS
  FOREIGN KEY (APP_SID, DASHBOARD_INSTANCE_ID, APPROVAL_DASHBOARD_SID)
  REFERENCES CSR.APPROVAL_DASHBOARD_INSTANCE(APP_SID, DASHBOARD_INSTANCE_ID, APPROVAL_DASHBOARD_SID);
  
ALTER TABLE CSR.APPROVAL_NOTE_PORTLET_NOTE ADD CONSTRAINT FK_AP_NOTE_POR_NOTE_REGION
  FOREIGN KEY (APP_SID, REGION_SID)
  REFERENCES CSR.REGION(APP_SID, REGION_SID);
  
ALTER TABLE CSR.APPROVAL_NOTE_PORTLET_NOTE ADD CONSTRAINT FK_AP_NOTE_POR_NOTE_TAB_PORT
  FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
  REFERENCES CSR.TAB_PORTLET(APP_SID, TAB_PORTLET_ID);
  
ALTER TABLE CSR.APPROVAL_NOTE_PORTLET_NOTE ADD CONSTRAINT FK_AP_NOTE_POR_NOTE_ADDED_BY
  FOREIGN KEY (APP_SID, ADDED_BY_SID)
  REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID);

ALTER TABLE CSR.TPL_REPORT_TAG_APPROVAL_NOTE ADD CONSTRAINT FK_TPL_REP_TAG_AP_NOTE_APP_DAS
  FOREIGN KEY (APP_SID, APPROVAL_DASHBOARD_SID)
  REFERENCES CSR.APPROVAL_DASHBOARD(APP_SID, APPROVAL_DASHBOARD_SID);
  
ALTER TABLE CSR.TPL_REPORT_TAG_APPROVAL_NOTE ADD CONSTRAINT FK_TPL_REP_TAG_AP_NOTE_TAB_POR
  FOREIGN KEY (APP_SID, TAB_PORTLET_ID)
  REFERENCES CSR.TAB_PORTLET(APP_SID, TAB_PORTLET_ID);

ALTER TABLE CSR.TPL_REPORT_TAG
  ADD tpl_report_tag_app_note_id NUMBER(10, 0);

ALTER TABLE CSR.TPL_REPORT_TAG_APPROVAL_MATRIX ADD CONSTRAINT FK_TPL_REP_TAG_AP_MTX_APP_DAS
  FOREIGN KEY (APP_SID, APPROVAL_DASHBOARD_SID)
  REFERENCES CSR.APPROVAL_DASHBOARD(APP_SID, APPROVAL_DASHBOARD_SID);
  
ALTER TABLE CSR.TPL_REPORT_TAG
  ADD tpl_report_tag_app_matrix_id NUMBER(10, 0);
  
ALTER TABLE CSR.TPL_REPORT_TAG DROP CONSTRAINT CT_TPL_REPORT_TAG;
ALTER TABLE CSR.TPL_REPORT_TAG ADD(
    CONSTRAINT CT_TPL_REPORT_TAG CHECK ((tag_type IN (1,4,5) AND tpl_report_tag_ind_id IS NOT NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 6 AND tpl_report_tag_eval_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type IN (2,3,101) AND tpl_report_tag_dataview_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 7 AND tpl_report_tag_logging_form_id IS NOT NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 8 AND tpl_rep_cust_tag_type_id IS NOT NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND tpl_report_tag_text_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 9 AND tpl_report_tag_text_id IS NOT NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = -1 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 10 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NOT NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 102 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NOT NULL AND tpl_report_tag_app_matrix_id IS NULL)
	OR (tag_type = 103 AND tpl_report_tag_text_id IS NULL AND tpl_rep_cust_tag_type_id IS NULL AND tpl_report_tag_logging_form_id IS NULL AND tpl_report_tag_ind_id IS NULL AND tpl_report_tag_dataview_id IS NULL AND tpl_report_tag_eval_id IS NULL AND TPL_REPORT_NON_COMPL_ID IS NULL AND tpl_report_tag_app_note_id IS NULL AND tpl_report_tag_app_matrix_id IS NOT NULL))
);

ALTER TABLE CSR.APPROVAL_DASHBOARD
  ADD publish_doc_folder_sid NUMBER(10, 0); 
  
ALTER TABLE CSR.APPROVAL_DASHBOARD ADD CONSTRAINT FK_APP_DASH_PUB_DOC_FOLDER
  FOREIGN KEY (APP_SID, PUBLISH_DOC_FOLDER_SID)
  REFERENCES CSR.DOC_FOLDER(app_sid, doc_folder_sid); 
  
ALTER TABLE CSR.FLOW_STATE_TRANSITION DROP CONSTRAINT FK_FLSTTRHELPER_FLSTTR;

UPDATE CSR.FLOW_STATE_TRANSITION
   SET helper_sp = 'csr.approval_dashboard_pkg.TransitionSignOffInstance'
 WHERE helper_sp = 'csr.approval_dashboard_pkg.TransitionToFinalState';

UPDATE CSR.FLOW_STATE_TRANS_HELPER
   SET helper_sp = 'csr.approval_dashboard_pkg.TransitionSignOffInstance'
 WHERE helper_sp = 'csr.approval_dashboard_pkg.TransitionToFinalState';
 
 
ALTER TABLE CSR.FLOW_STATE_TRANSITION ADD CONSTRAINT FK_FLSTTRHELPER_FLSTTR 
  FOREIGN KEY (APP_SID, FLOW_SID, HELPER_SP)
  REFERENCES CSR.FLOW_STATE_TRANS_HELPER(APP_SID, FLOW_SID, HELPER_SP);  
  
-- *** Grants ***
GRANT SELECT, REFERENCES ON chain.saved_filter_alert TO csr;
GRANT SELECT, REFERENCES ON chain.saved_filter_alert_subscriptn TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_saved_fltr_alrt_sbscrptn TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_saved_filter_agg_type TO web_user;
GRANT SELECT, INSERT, UPDATE ON chain.saved_filter_alert TO csrimp;
GRANT SELECT, INSERT, UPDATE ON chain.saved_filter_alert_subscriptn TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW csr.v$qs_answer_file AS
	SELECT af.app_sid, af.qs_answer_file_id, af.survey_response_id, af.question_id, af.filename,
		   af.mime_type, rf.data, af.sha1, rf.uploaded_dtm, sf.submission_id, af.caption
	  FROM qs_answer_file af
	  JOIN qs_response_file rf ON af.app_sid = rf.app_sid AND af.survey_response_id = rf.survey_response_id AND af.sha1 = rf.sha1 AND af.filename = rf.filename AND af.mime_type = rf.mime_type
	  JOIN qs_submission_file sf ON af.app_sid = sf.app_sid AND af.qs_answer_file_id = sf.qs_answer_file_id;

CREATE OR REPLACE VIEW CHAIN.v$company AS
	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.activated_dtm, c.active, c.address_1, 
		   c.address_2, c.address_3, c.address_4, c.town, c.state, pr.name state_name, c.state_id, c.city, pc.city_name, c.city_id, c.postcode, c.country_code, 
		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
		   c.user_level_messaging, c.sector_id,
		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
		   ct.lookup_key company_type_lookup, c.supp_rel_code_label, c.supp_rel_code_label_mand,
		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
		   c.country_is_hidden, cs.region_sid
	  FROM company c
	  LEFT JOIN v$country cou ON c.country_code = cou.country_code
	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
	  LEFT JOIN v$country pcou ON p.country_code = pcou.country_code
	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
	  LEFT JOIN postcode.city pc ON c.city_id = pc.city_id AND c.country_code = pc.country
	  LEFT JOIN postcode.region pr ON c.state_id = pr.region AND c.country_code = pr.country
	 WHERE c.deleted = 0
;

-- *** Data changes ***

-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner IN ('CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('QS_RESPONSE_FILE', 'CHAIN_SAVED_FILTER_ALERT', 'CHAIN_SAVED_FLTR_ALRT_SBSCRPTN')
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => 'CSRIMP',
			policy_function => 'SessionIDCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.context_sensitive);
	END LOOP;
EXCEPTION
	WHEN POLICY_ALREADY_EXISTS THEN
		DBMS_OUTPUT.PUT_LINE('Policy exists');
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
		'SAVED_FILTER_ALERT',
		'SAVED_FILTER_ALERT_SUBSCRIPTN',
		'SAVED_FILTER_SENT_ALERT'
    );
    FOR I IN 1 .. v_list.count
 	LOOP
		BEGIN
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23) || '_POLICY', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.context_sensitive);
		EXCEPTION WHEN POLICY_ALREADY_EXISTS THEN
			DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
		END;
	END LOOP;
EXCEPTION
	WHEN FEATURE_NOT_ENABLED THEN
		DBMS_OUTPUT.PUT_LINE('RLS policies not applied as feature not enabled');	
END;
/

-- Data
INSERT INTO csr.capability (NAME,ALLOW_BY_DEFAULT) VALUES ('Can manage filter alerts', 0);

-- Issues filter
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (25, 'ISSUE_ID', 'Action ID', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (25, 'LABEL', 'Label', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (25, 'DESCRIPTION', 'Action ID', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (25, 'ISSUE_URL', 'Link to action', 0, 'Go to action');
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (25, 'REGION_DESCRIPTION', 'Associated region', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (25, 'ISSUE_TYPE_LABEL', 'Action type', 1, NULL);
END;
/

-- Non-compliance filter
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'NON_COMPLIANCE_ID', 'Finding ID', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'CUSTOM_NON_COMPLIANCE_ID', 'Finding Reference', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'NON_COMPLIANCE_TYPE_LABEL', 'Finding type', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'LABEL', 'Label', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'DETAIL', 'Details', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'ROOT_CAUSE', 'Root cause', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'REGION_DESCRIPTION', 'Region', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'AUDIT_DTM', 'Audit date', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'AUDIT_LABEL', 'Audit label', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'AUDIT_URL', 'Audit url', 0, 'Go to audit');
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (42, 'AUDIT_TYPE_LABEL', 'Audit type', 1, NULL);
END;
/

-- Audit filter
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'INTERNAL_AUDIT_SID', 'Audit ID', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'CUSTOM_AUDIT_ID', 'Audit Reference', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'REGION_DESCRIPTION', 'Region', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'AUDIT_DTM', 'Audit date', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'LABEL', 'Label', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'AUDIT_TYPE_LABEL', 'Audit type', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'FLOW_STATE_LABEL', 'Status', 1, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (41, 'AUDIT_URL', 'Audit url', 0, 'Go to audit');
END;
/

-- Company filter
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'COMPANY_SID', 'Company ID', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'COMPANY_TYPE_LABEL', 'Company type', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'NAME', 'Company name', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'COUNTRY_NAME', 'Country', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'CITY_NAME', 'City', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'ADDRESS_1', 'Address line 1', 0, NULL);
	
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (23, 'ADDRESS_2', 'Address line 2', 0, NULL);
	
END;
/

BEGIN
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (71, 'Filter alert template', 
		 'This alert is used as a template when creating new filter alerts',
		 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed when setting up the alert schedule).'
	); 

	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 0, 'HOST', 'Site web address', 'The web address for your CRedit371 system', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 0, 'LIST_PAGE_URL', 'Link to list page', 'A link to the list page with the configured filter applied', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (71, 1, 'OBJECT_ID', 'Object ID', 'The ID of the object that matches the filter', 7);
END;
/

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (44, 'Filter alerts', 'EnableFilterAlerts', 'Enables alerts based on new items matching a saved filter.');

-- Enable capability for all existing sites that have the sheet export page
DECLARE
	v_capability_sid		security.security_pkg.T_SID_ID;
	v_capabilities_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT c.app_sid
		  FROM csr.customer c
		  JOIN security.securable_object so ON c.app_sid = so.application_sid_id
		  JOIN security.menu m ON so.sid_id = m.sid_id
		 WHERE LOWER(m.action)='/csr/site/delegation/browse2/sheetexport.acds'
	) LOOP	
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), r.app_sid, '/Capabilities');
				
			BEGIN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					v_capabilities_sid, 
					security.class_pkg.GetClassId('CSRCapability'),
					'Run sheet export report',
					v_capability_sid
				);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					NULL;
			END;
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END LOOP;
END;
/

UPDATE csr.scenario
   SET data_source_sp = 'csr.approval_dashboard_pkg.getSignedOffVals'
 WHERE data_source_sp = 'csr.approval_dashboard_pkg.getLastLockedVals';
 
 UPDATE csr.scenario
   SET data_source_sp = 'csr.approval_dashboard_pkg.getActivePeriodVals'
 WHERE data_source_sp = 'csr.approval_dashboard_pkg.getLiveVals';

INSERT INTO csr.portlet (PORTLET_ID, name, type, default_state, script_path)
VALUES (1055,	'Approval note', 'Credit360.Portlets.ApprovalNote', null, '/csr/site/portal/portlets/ApprovalDashboards/ApprovalNote.js');

UPDATE csr.portlet
   SET name = 'Approval Matrix',
       type = 'Credit360.Portlets.ApprovalMatrix',
	   script_path = '/csr/site/portal/portlets/ApprovalDashboards/ApprovalMatrix.js'
 WHERE portlet_id = 1053;
 
INSERT INTO csr.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
VALUES ('Credit360.Portlets.Chart', 3); 
INSERT INTO csr.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
VALUES ('Credit360.Portlets.ApprovalChart', 101); 
INSERT INTO csr.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
VALUES ('Credit360.Portlets.Table', 2);
INSERT INTO csr.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
VALUES ('Credit360.Portlets.ApprovalNote', 102);
INSERT INTO csr.APP_DASH_SUP_REPORT_PORTLET (PORTLET_TYPE, MAPS_TO_TAG_TYPE)
VALUES ('Credit360.Portlets.ApprovalMatrix', 103);

INSERT INTO csr.flow_capability (FLOW_CAPABILITY_ID, FLOW_ALERT_CLASS, DESCRIPTION, PERM_TYPE, DEFAULT_PERMISSION_SET)
VALUES (2001, 'approvaldashboard', 'Refresh data', 1, 0);
INSERT INTO csr.flow_capability (FLOW_CAPABILITY_ID, FLOW_ALERT_CLASS, DESCRIPTION, PERM_TYPE, DEFAULT_PERMISSION_SET)
VALUES (2002, 'approvaldashboard', 'Run templated report', 1, 0);
INSERT INTO csr.flow_capability (FLOW_CAPABILITY_ID, FLOW_ALERT_CLASS, DESCRIPTION, PERM_TYPE, DEFAULT_PERMISSION_SET)
VALUES (2003, 'approvaldashboard', 'Edit matrix notes', 1, 0);

BEGIN
  FOR r IN (
    select f.flow_sid, f.app_sid
      from CSR.FLOW_STATE_TRANS_HELPER fsth
      join CSR.FLOW f on f.flow_sid = fsth.flow_sid
     where f.flow_alert_class = 'approvaldashboard'
  )
  LOOP
    BEGIN
      INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
        VALUES (r.app_sid, r.flow_sid, 'csr.approval_dashboard_pkg.TransitionLockInstance', 'Lock instance');	
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    
    BEGIN
      INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
        VALUES (r.app_sid, r.flow_sid, 'csr.approval_dashboard_pkg.TransitionSignOffInstance', 'Sign off instance');	
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    
    BEGIN
      INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
        VALUES (r.app_sid, r.flow_sid, 'csr.approval_dashboard_pkg.TransitionUnlockInstance', 'Unlock instance');	
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    
    BEGIN
      INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
        VALUES (r.app_sid, r.flow_sid, 'csr.approval_dashboard_pkg.TransitionReopenSignedOffInst', 'Reopen instance (from signed off)');	
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
    
    BEGIN
      INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
        VALUES (r.app_sid, r.flow_sid, 'csr.approval_dashboard_pkg.TransitionPublish', 'Publish');	
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        NULL;
    END;
  END LOOP;
END;
/

-- ** New package grants **
GRANT SELECT ON CSR.QS_RESPONSE_FILE TO CHAIN;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.qs_response_file TO web_user;
GRANT INSERT ON csr.qs_response_file TO csrimp;

-- *** Packages ***
@..\schema_pkg
@..\audit_pkg
@..\quick_survey_pkg
@..\training_pkg
@..\csr_user_pkg
@..\cms_data_imp_pkg
@..\approval_dashboard_pkg
@..\templated_report_pkg
@..\audit_report_pkg
@..\issue_report_pkg
@..\non_compliance_report_pkg
@..\csr_data_pkg
@..\enable_pkg

@..\..\..\aspen2\cms\db\filter_pkg

@..\chain\filter_pkg
@..\chain\company_filter_pkg
@..\chain\business_relationship_pkg

@..\schema_body
@..\audit_body
@..\quick_survey_body
@..\training_body
@..\csr_user_body
@..\cms_data_imp_body
@..\approval_dashboard_body
@..\templated_report_body
@..\audit_report_body
@..\issue_report_body
@..\non_compliance_report_body
@..\flow_body
@..\enable_body
@..\imp_body
@..\stored_calc_datasource_body
@..\campaign_body
@..\csr_app_body
@..\supplier_body

@..\..\..\aspen2\cms\db\filter_body
@..\..\..\aspen2\cms\db\tab_body

@..\chain\filter_body
@..\chain\company_filter_body
@..\chain\business_relationship_body
@..\chain\type_capability_body
@..\chain\company_body
@..\chain\chain_body
@..\chain\helper_body

@..\csrimp\imp_body

@update_tail
