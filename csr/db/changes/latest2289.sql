-- Please update version.sql too -- this keeps clean builds in sync
define version=2289
@update_header

-- rename this with version
@latest2289_packages

-- *** DDL ***
-- Create tables
CREATE TABLE csr.quick_survey_question_tag (
	app_sid					NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	question_id				NUMBER(10)  NOT NULL,
	survey_version			NUMBER(10)  NOT NULL,
	tag_id					NUMBER(10)  NOT NULL,
	CONSTRAINT pk_qs_question_tag PRIMARY KEY (app_sid, question_id, survey_version, tag_id),
	CONSTRAINT fk_qs_question_tag_qs_question FOREIGN KEY (app_sid, question_id, survey_version) 
		REFERENCES csr.quick_survey_question (app_sid, question_id, survey_version),
	CONSTRAINT fk_qs_question_tag_tag FOREIGN KEY (app_sid, tag_id)
		REFERENCES csr.tag (app_sid, tag_id)	
);

CREATE TABLE csrimp.quick_survey_question_tag (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	question_id				NUMBER(10)  NOT NULL,
	survey_version			NUMBER(10)  NOT NULL,
	tag_id					NUMBER(10)  NOT NULL,
	CONSTRAINT pk_qs_question_tag PRIMARY KEY (csrimp_session_id, question_id, survey_version, tag_id),
	CONSTRAINT fk_qs_question_tag_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE	
);

CREATE TABLE chain.invitation_batch (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	batch_job_id			NUMBER(10) NOT NULL,
	personal_msg			VARCHAR2(4000),
	cc_from_user			NUMBER(1) NOT NULL,
	cc_others				VARCHAR2(1000),
	std_alert_type_id		NUMBER(10) NOT NULL,
	CONSTRAINT chk_inv_batch_cc_from_0_1 CHECK (cc_from_user IN (0,1)),
	CONSTRAINT pk_invitation_batch PRIMARY KEY (app_sid, batch_job_id)
);

CREATE TABLE csr.audit_type_tab (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	internal_audit_type_id	NUMBER(10) NOT NULL,
	plugin_type_id			NUMBER(10) NOT NULL,
	plugin_id				NUMBER(10) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	tab_label				VARCHAR2(255),
	CONSTRAINT pk_audit_type_tab PRIMARY KEY (app_sid, internal_audit_type_id, plugin_id),
	CONSTRAINT fk_audit_type_tab_plugin FOREIGN KEY (plugin_type_id, plugin_id) REFERENCES csr.plugin (plugin_type_id, plugin_id),
	CONSTRAINT fk_audit_type_tab_audit_type FOREIGN KEY (app_sid, internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id),
	CONSTRAINT chk_audit_type_tab_plugin_typ CHECK (plugin_type_id = 13)
);

CREATE TABLE csr.audit_type_header (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	internal_audit_type_id	NUMBER(10) NOT NULL,
	plugin_type_id			NUMBER(10) NOT NULL,
	plugin_id				NUMBER(10) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	CONSTRAINT pk_audit_type_header PRIMARY KEY (app_sid, internal_audit_type_id, plugin_id),
	CONSTRAINT fk_audit_type_header_plugin FOREIGN KEY (plugin_type_id, plugin_id) REFERENCES csr.plugin (plugin_type_id, plugin_id),
	CONSTRAINT fk_audit_typ_header_audit_typ FOREIGN KEY (app_sid, internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id),
	CONSTRAINT chk_audit_type_head_plugin_typ CHECK (plugin_type_id = 14)
);

CREATE TABLE csrimp.audit_type_tab (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	internal_audit_type_id	NUMBER(10) NOT NULL,
	plugin_type_id			NUMBER(10) NOT NULL,
	plugin_id				NUMBER(10) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	tab_label				VARCHAR2(255),
	CONSTRAINT pk_audit_type_tab PRIMARY KEY (csrimp_session_id, internal_audit_type_id, plugin_id),
	CONSTRAINT chk_audit_type_tab_plugin_typ CHECK (plugin_type_id = 13),
	CONSTRAINT fk_audit_type_tab_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE	
);

CREATE TABLE csrimp.audit_type_header (
	csrimp_session_id		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	internal_audit_type_id	NUMBER(10) NOT NULL,
	plugin_type_id			NUMBER(10) NOT NULL,
	plugin_id				NUMBER(10) NOT NULL,
	pos						NUMBER(10) NOT NULL,
	CONSTRAINT pk_audit_type_header PRIMARY KEY (csrimp_session_id, internal_audit_type_id, plugin_id),
	CONSTRAINT chk_audit_type_head_plugin_typ CHECK (plugin_type_id = 14),
	CONSTRAINT fk_audit_type_header_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE	
);

-- Alter tables
ALTER TABLE csr.plugin ADD (	
	app_sid						NUMBER(10), --nullable
    details          			VARCHAR2(4000),
    preview_image_path 			VARCHAR2(255),
	tab_sid						NUMBER(10),
	form_path					VARCHAR2(255),
	CONSTRAINT fk_plugin_app_sid FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid),
	CONSTRAINT fk_plugin_cms_tab FOREIGN KEY (app_sid, tab_sid) REFERENCES cms.tab (app_sid, tab_sid) ON DELETE CASCADE,
	CONSTRAINT chk_plugin_cms_tab_form CHECK ((tab_sid IS NULL AND form_path IS NULL) OR (app_sid IS NOT NULL AND tab_sid IS NOT NULL AND form_path IS NOT NULL))
);

ALTER TABLE csr.plugin DROP CONSTRAINT UK_PLUGIN_JS_CLASS;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, tab_sid);

ALTER TABLE csrimp.plugin ADD (	
	app_sid						NUMBER(10), --nullable
    details          			VARCHAR2(4000),
    preview_image_path 			VARCHAR2(255),
	tab_sid						NUMBER(10),
	form_path					VARCHAR2(255)
);

ALTER TABLE csr.quick_survey_version ADD (
	PUBLISHED_BY_SID	NUMBER(10)
);

ALTER TABLE chain.questionnaire_type ADD (
	EXPIRE_AFTER_MONTHS		NUMBER(10),
	AUTO_RESEND_ON_EXPIRY	NUMBER(10),
	CONSTRAINT CHK_AUTO_RESEND_ON_EXPIRY CHECK (AUTO_RESEND_ON_EXPIRY IN (0,1))
);

UPDATE chain.questionnaire_type SET AUTO_RESEND_ON_EXPIRY=0;

ALTER TABLE chain.questionnaire_type MODIFY AUTO_RESEND_ON_EXPIRY DEFAULT 0 NOT NULL;

ALTER TABLE chain.questionnaire_share ADD (
    EXPIRY_DTM				  DATE,
    EXPIRY_SENT_DTM			  DATE
);

CREATE TABLE CHAIN.QUESTIONNAIRE_EXPIRY_ALERT (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	QUESTIONNAIRE_SHARE_ID	NUMBER(10) NOT NULL,
	USER_SID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_QUESTIONNAIRE_EXPIRY_ALERT PRIMARY KEY (APP_SID, QUESTIONNAIRE_SHARE_ID, USER_SID),
	CONSTRAINT FK_QNR_EXPIRY_SHARE_ID FOREIGN KEY (APP_SID, QUESTIONNAIRE_SHARE_ID) REFERENCES CHAIN.QUESTIONNAIRE_SHARE (APP_SID, QUESTIONNAIRE_SHARE_ID),
	CONSTRAINT FK_QNR_EXPIRY_USER FOREIGN KEY (APP_SID, USER_SID) REFERENCES CHAIN.CHAIN_USER (APP_SID, USER_SID)
);

CREATE INDEX CHAIN.IX_QNR_EXPIRY_SHARE_ID ON CHAIN.QUESTIONNAIRE_EXPIRY_ALERT (APP_SID, QUESTIONNAIRE_SHARE_ID);
CREATE INDEX CHAIN.IX_QNR_EXPIRY_USER ON CHAIN.QUESTIONNAIRE_EXPIRY_ALERT (APP_SID, USER_SID);

ALTER TABLE CSR.TAG_GROUP ADD (
	APPLIES_TO_QUICK_SURVEY NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_APPLIES_TO_QK_SURVEY_1_0 CHECK (APPLIES_TO_QUICK_SURVEY IN (1, 0))
);

ALTER TABLE CSRIMP.TAG_GROUP ADD (
	APPLIES_TO_QUICK_SURVEY NUMBER(1)
);
UPDATE CSRIMP.TAG_GROUP SET APPLIES_TO_QUICK_SURVEY=0;
ALTER TABLE CSRIMP.TAG_GROUP MODIFY APPLIES_TO_QUICK_SURVEY NOT NULL;
ALTER TABLE CSRIMP.TAG_GROUP ADD (CONSTRAINT CHK_APPLIES_TO_QK_SURVEY_1_0 CHECK (APPLIES_TO_QUICK_SURVEY IN (1, 0)));

ALTER TABLE CHAIN.INVITATION MODIFY SENT_DTM DEFAULT NULL NULL;
ALTER TABLE CHAIN.INVITATION ADD (
	BATCH_JOB_ID					 NUMBER(10, 0)
);

ALTER TABLE CHAIN.INVITATION ADD CONSTRAINT FK_INVITATION_BATCH_JOB
	FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CHAIN.INVITATION_BATCH(APP_SID, BATCH_JOB_ID);

CREATE INDEX CHAIN.IX_INVITATION_BATCH_JOB ON CHAIN.INVITATION(APP_SID, BATCH_JOB_ID);

ALTER TABLE csr.quick_survey_response ADD (
	question_xml_override			SYS.XMLTYPE
);

ALTER TABLE csrimp.quick_survey_response ADD (
	question_xml_override			SYS.XMLTYPE
);

ALTER TABLE CSR.ALERT_MAIL DROP CONSTRAINT REFALERT_MAIL_CHAIN_COMPANY;
ALTER TABLE csr.alert_mail DROP COLUMN to_company_sid;

ALTER TABLE csr.tag_group RENAME COLUMN applies_to_chain_products TO applies_to_chain_product_types;
ALTER TABLE csrimp.tag_group RENAME COLUMN applies_to_chain_products TO applies_to_chain_product_types;

alter table csr.tag_group rename constraint chk_applies_to_chain_prod_1_0 to chk_applies_to_chain_prd_t_1_0;
alter table csrimp.tag_group rename constraint chk_applies_to_chain_prod_1_0 to chk_applies_to_chain_prd_t_1_0;

create index csr.ix_quick_survey__tag_id on csr.quick_survey_question_tag (app_sid, tag_id);

ALTER TABLE csr.flow_item ADD CONSTRAINT uq_flow_item_response_id UNIQUE (survey_response_id);

ALTER TABLE csr.quick_survey_response ADD hidden NUMBER(10);
ALTER TABLE csr.quick_survey_response ADD CONSTRAINT chk_qs_response_hidden_0_1 CHECK (hidden IN (0,1));
UPDATE csr.quick_survey_response SET hidden = 0 WHERE hidden IS NULL;
ALTER TABLE csr.quick_survey_response MODIFY hidden DEFAULT 0 NOT NULL;

-- *** Grants ***
grant insert on csr.quick_survey_question_tag to csrimp;
grant select,insert,update,delete on csrimp.quick_survey_question_tag to web_user;
grant select,insert,update,delete on csrimp.audit_type_tab to web_user;
grant select,insert,update,delete on csrimp.audit_type_header to web_user;
grant insert on csr.audit_type_tab to csrimp;
grant insert on csr.audit_type_header to csrimp;
GRANT SELECT, REFERENCES ON CSR.BATCH_JOB TO CHAIN;
GRANT EXECUTE ON csr.batch_job_pkg TO chain;
grant execute on csr.campaign_pkg to security;


grant select, references on csr.tag to chain with grant option;
grant select, references on csr.tag_group to chain with grant option;
grant select on csr.tag_group_member to chain with grant option;
grant select on csr.region_tag to chain with grant option;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.INVITATION_BATCH ADD CONSTRAINT FK_INVITATION_BATCH_BATCH_JOB
	FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID);

-- *** Views ***
CREATE OR REPLACE VIEW CHAIN.v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.component_id, q.questionnaire_type_id, q.created_dtm,
		   qs.due_by_dtm, qs.overdue_events_sent, qs.qnr_owner_company_sid, qs.share_with_company_sid,
		   qsle.share_log_entry_index, qsle.entry_dtm, qs.questionnaire_share_id, qs.reminder_sent_dtm,
		   qs.overdue_sent_dtm, qsle.share_status_id, ss.description share_status_name,
		   qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes,
		   qt.class qt_class, CASE WHEN qsa.first_accepted_index IS NOT NULL THEN 1 ELSE 0 END has_been_accepted,
		   qt.name questionnaire_name, qs.expiry_dtm, CASE WHEN qs.expiry_dtm < SYSDATE THEN 1 ELSE 0 END has_expired
	  FROM questionnaire q
	  JOIN questionnaire_share qs ON q.app_sid = qs.app_sid AND q.questionnaire_id = qs.questionnaire_id
	  JOIN qnr_share_log_entry qsle ON qs.app_sid = qsle.app_sid AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	  JOIN share_status ss ON qsle.share_status_id = ss.share_status_id
	  JOIN company s ON q.app_sid = s.app_sid AND q.company_sid = s.company_sid
	  JOIN questionnaire_type qt ON q.app_sid = qt.app_sid AND q.questionnaire_type_id = qt.questionnaire_type_id
	  LEFT JOIN (
			SELECT app_sid, questionnaire_share_id, MIN(share_log_entry_index) first_accepted_index
			  FROM qnr_share_log_entry
			 WHERE share_status_id = 14 --chain_pkg.SHARED_DATA_ACCEPTED
			 GROUP BY app_sid, questionnaire_share_id
		 ) qsa ON qs.app_sid = qsa.app_sid AND qs.questionnaire_share_id = qsa.questionnaire_share_id
	 WHERE s.deleted = 0
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND (qsle.app_sid, qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT app_sid, questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 GROUP BY app_sid, questionnaire_share_id
			)
;

CREATE OR REPLACE VIEW CHAIN.v$company_tag AS
	SELECT c.app_sid, c.company_sid, c.name company_name, ct.source, tg.name tag_group_name, t.tag, tg.tag_group_id, t.tag_id, t.lookup_key tag_lookup_key, c.active
	  FROM company c
	  JOIN (
		SELECT s.app_sid, s.company_sid, rt.tag_id, 'Supplier region tag' source
		  FROM csr.supplier s
		  JOIN csr.region_tag rt ON s.region_sid = rt.region_sid AND s.app_sid = rt.app_sid
		 UNION
		SELECT cpt.app_sid, cpt.company_sid, ptt.tag_id, 'Product type tag' source
		  FROM company_product_type cpt
		  JOIN product_type_tag ptt ON cpt.product_type_id = ptt.product_type_id AND cpt.app_sid = ptt.app_sid
	  ) ct ON c.company_sid = ct.company_sid AND c.app_sid = ct.app_sid
	  JOIN csr.tag t ON ct.tag_id = t.tag_id AND ct.app_sid = t.app_sid
	  JOIN csr.tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
	  JOIN csr.tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
;

CREATE OR REPLACE VIEW CSR.v$audit_tag AS
	SELECT ia.app_sid, ia.internal_audit_sid, ia.label audit_label, at.source, tg.name tag_group_name, t.tag, tg.tag_group_id, t.tag_id, t.lookup_key tag_lookup_key
	  FROM internal_audit ia
	  JOIN (
		SELECT iia.app_sid, iia.internal_audit_sid, rt.tag_id, 'Region tag' source
		  FROM internal_audit iia
		  JOIN region_tag rt ON iia.region_sid = rt.region_sid AND iia.app_sid = rt.app_sid
	  ) at ON ia.internal_audit_sid = at.internal_audit_sid AND ia.app_sid = at.app_sid
	  JOIN tag t ON at.tag_id = t.tag_id AND at.app_sid = t.app_sid
	  JOIN tag_group_member tgm ON t.tag_id = tgm.tag_id AND t.app_sid = tgm.app_sid
	  JOIN tag_group tg ON tgm.tag_group_id = tg.tag_group_id AND tgm.app_sid = tg.app_sid
	  AND ia.deleted = 0
;

CREATE OR REPLACE VIEW csr.v$quick_survey_response AS
	SELECT qsr.app_sid, qsr.survey_response_id, qsr.survey_sid, qsr.user_sid, qsr.user_name,
		   qsr.created_dtm, qsr.guid, qss.submitted_dtm, qsr.qs_campaign_sid, qss.overall_score,
		   qss.overall_max_score, qss.score_threshold_id, qss.submission_id, qss.survey_version
	  FROM quick_survey_response qsr 
	  JOIN quick_survey_submission qss ON qsr.survey_response_id = qss.survey_response_id
	   AND NVL(qsr.last_submission_id, 0) = qss.submission_id
	   AND qsr.survey_version > 0 -- filter out draft submissions
	   AND qsr.hidden = 0 -- filter out hidden responses
;

-- *** Data changes ***
-- RLS
CREATE OR REPLACE FUNCTION csr.nullableAppSidCheck (
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
	
	-- Only show data if you are logged on and data is for the current application, or app_sid is null
	RETURN 'app_sid IS NULL OR app_sid = sys_context(''SECURITY'', ''APP'')';	
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
        'QUICK_SURVEY_QUESTION_TAG',
        'AUDIT_TYPE_TAB',
        'AUDIT_TYPE_HEADER'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CSR',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CSR',
                policy_function => 'appSidCheck',
                statement_types => 'select, insert, update, delete',
                update_check    => true,
                policy_type     => dbms_rls.context_sensitive );
                DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
        EXCEPTION
            WHEN POLICY_ALREADY_EXISTS THEN
                DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
            WHEN FEATURE_NOT_ENABLED THEN
                DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
        END;
    END LOOP;
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
        'PLUGIN'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CSR',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CSR',
                policy_function => 'nullableAppSidCheck',
                statement_types => 'select, insert, update, delete',
                update_check    => true,
                policy_type     => dbms_rls.context_sensitive );
                DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
        EXCEPTION
            WHEN POLICY_ALREADY_EXISTS THEN
                DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
            WHEN FEATURE_NOT_ENABLED THEN
                DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
        END;
    END LOOP;
END;
/

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'QUESTIONNAIRE_EXPIRY_ALERT',
		'INVITATION_BATCH'
	);
	for i in 1 .. v_list.count loop
		begin
			dbms_rls.add_policy(
				object_schema   => 'CHAIN',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26) || '_POL', 
				function_schema => 'CHAIN',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> true,
				policy_type     => dbms_rls.static);
		exception
			when policy_already_exists then
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' already exists');
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' not applied as feature not enabled');
		end;
	end loop;
end;
/

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
		 WHERE t.owner IN ('CMS', 'CSRIMP') AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'CSRIMP_SESSION_ID'
		   AND t.table_name IN ('QUICK_SURVEY_QUESTION_TAG', 'AUDIT_TYPE_TAB', 'AUDIT_TYPE_HEADER')
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

-- Data
INSERT INTO chain.share_status (share_status_id, description)
VALUES (19, 'Shared data resent');


INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (13, 'Audit tab');
INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (14, 'Audit header');

DECLARE
	v_full_audit_tab_id		NUMBER(10);
	v_full_audit_header_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
			 VALUES (csr.plugin_id_seq.nextval, 13, 'Full audit details tab',  '/csr/site/audit/controls/FullAuditTab.js', 'Audit.Controls.FullAuditTab', 'Credit360.Audit.Plugins.FullAuditTab')
		  RETURNING plugin_id INTO v_full_audit_tab_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin 
		   SET description = 'Full audit details tab',
		   	   js_include = '/csr/site/audit/controls/FullAuditTab.js',
		   	   cs_class = 'Credit360.Audit.Plugins.FullAuditTab'
		 WHERE plugin_type_id = 13
		   AND js_class = 'Audit.Controls.FullAuditTab'
	 		   RETURNING plugin_id INTO v_full_audit_tab_id;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class)
			 VALUES (csr.plugin_id_seq.nextval, 14, 'Full audit details header',  '/csr/site/audit/controls/FullAuditHeader.js', 'Audit.Controls.FullAuditHeader', 'Credit360.Audit.Plugins.FullAuditHeader')
		  RETURNING plugin_id INTO v_full_audit_header_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin 
		   SET description = 'Full audit details header',
		   	   js_include = '/csr/site/audit/controls/FullAuditHeader.js',
		   	   cs_class = 'Credit360.Audit.Plugins.FullAuditHeader'
		 WHERE plugin_type_id = 14
		   AND js_class = 'Audit.Controls.FullAuditHeader'
	 		   RETURNING plugin_id INTO v_full_audit_header_id;
	END;
	
	INSERT INTO csr.audit_type_tab (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, tab_label, pos)
		SELECT app_sid, internal_audit_type_id, 13, v_full_audit_tab_id, 'Audit details', 0
		  FROM csr.internal_audit_type;
	
	INSERT INTO csr.audit_type_header (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, pos)
		SELECT app_sid, internal_audit_type_id, 14, v_full_audit_header_id, 0
		  FROM csr.internal_audit_type;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (4, 'No Questionnaire Invitation');
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
	BEGIN
		INSERT INTO chain.invitation_type (invitation_type_id, description) VALUES (5, 'Request questionnaire from an existing company');
	EXCEPTION WHEN dup_val_on_index THEN
		NULL;
	END;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RESENT -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please review and re-submit {reQuestionnaire} data for {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_RESENT -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} was re-sent to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RESENT -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please review and re-submit {reQuestionnaire} ({componentDescription}) data for {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RESENT -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({componentDescription}) was re-sent to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RESENT, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG (Update repeat type)
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} data submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG (Update repeat type)
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} ({componentDescription}) data submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_repeat_type				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);
	
	----------------------------------------------------------------------------
	--		QNR_SUBMITTED_NO_REVIEW -> PURCHASER_MSG (Update repeat type)
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.QNR_SUBMITTED_NO_REVIEW,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_repeat_type				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
	----------------------------------------------------------------------------
	--		COMP_QNR_SUBMITTED_NO_REVIEW -> PURCHASER_MSG (Update repeat type)
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_repeat_type				=> chain.temp_chain_pkg.REPEAT_IF_CLOSED,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_EXPIRED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_EXPIRED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} has expired.',
		in_repeat_type 				=> chain.temp_chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_EXPIRED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_EXPIRED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) has expired.',
		in_repeat_type 				=> chain.temp_chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_EXPIRED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);
END;
/

BEGIN
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5025,
		'Questionnaire Expired',
		'Sent to all supplier users when a questionnaire has expired and needs to be resent.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Questionnaire Expired',
				send_trigger = 'Sent to all supplier users when a questionnaire has expired and needs to be resent.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5025;
	END;
	
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 1);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_NAME', 'To name', 'The name of the user the alert is being sent to', 2);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 3);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'HOST', 'Site web address', 'The web address for your CRedit360 system', 4);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'TO_COMPANY', 'To company', 'The name of the company filling out the questionnaire', 5);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'FROM_COMPANY', 'From company', 'The name of the company the questionnaire is for', 6);
	INSERT INTO CSR.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5025, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The name of the questionnaire that has expired', 7);
END;
/

BEGIN
	DELETE FROM csr.std_alert_type_param
	 WHERE std_alert_type_id IN (5000, 5005, 5010, 5013)
	   AND field_name = 'QUESTIONNAIRE_DESCRIPTION';
END;
/

BEGIN
	insert into csr.batch_job_type (batch_job_type_id, description, plugin_name)
	values (11, 'Supply chain invitations', 'chain-invitations');
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- every hour
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'chain.ExpireQuestionnaires',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'questionnaire_pkg.ExpireQuestionnaires;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=HOURLY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Trigger jobs to expire questionnaires');
       COMMIT;
END;
/

-- Fix supplier tag groups that don't apply to regions
UPDATE csr.tag_group
   SET applies_to_regions = 1
 WHERE applies_to_suppliers = 1;
 
 
insert into cms.col_type values (33, 'Role');
insert into cms.col_type values (34, 'Survey response');

-- ** New package grants **

-- *** Packages ***
@..\chain\questionnaire_pkg
@..\chain\chain_pkg
@..\chain\chain_link_pkg
@..\chain\questionnaire_security_pkg
@..\chain\message_pkg
@..\chain\company_tag_pkg
@..\chain\company_user_pkg
@..\chain\company_pkg
@..\chain\product_pkg
@..\chain\component_pkg
@..\quick_survey_pkg
@..\campaign_pkg
@..\tag_pkg
@..\schema_pkg
@..\chain\invitation_pkg
@..\chain\setup_pkg
@..\batch_job_pkg
@..\alert_pkg
@..\flow_pkg
@..\plugin_pkg
@..\audit_pkg
--ahh!
@..\csr_data_pkg
@..\..\..\aspen2\cms\db\tab_pkg

@..\..\..\aspen2\cms\db\tab_body
@..\chain\questionnaire_body
@..\chain\invitation_body
@..\chain\chain_body
@..\chain\chain_link_body
@..\chain\questionnaire_security_body
@..\chain\message_body
@..\chain\company_tag_body
@..\chain\dev_body
@..\chain\company_body
@..\chain\company_filter_body
@..\chain\product_body
@..\chain\setup_body
@..\chain\component_body
@..\chain\company_user_body
@..\csrimp\imp_body
@..\alert_body
@..\quick_survey_body
@..\campaign_body
@..\tag_body
@..\supplier_body
@..\schema_body
@..\flow_body
@..\plugin_body
@..\audit_body
@..\property_body
@..\measure_body
@..\csr_app_body

DROP PACKAGE chain.temp_message_pkg;
DROP PACKAGE chain.temp_chain_pkg;

@update_tail
