-- Please update version.sql too -- this keeps clean builds in sync
define version=2202
@update_header

-- *** DDL ***

ALTER TABLE CHAIN.ACTIVITY MODIFY (ASSIGNED_TO_USER_SID NULL);
ALTER TABLE CHAIN.ACTIVITY ADD (
	ASSIGNED_TO_ROLE_SID	NUMBER(10, 0),
	TARGET_ROLE_SID			NUMBER(10, 0),
	CONSTRAINT CHK_ACTIVITY_ASSIGNED CHECK (
		(ASSIGNED_TO_USER_SID IS NOT NULL OR ASSIGNED_TO_ROLE_SID IS NOT NULL) AND NOT
		(ASSIGNED_TO_USER_SID IS NOT NULL AND ASSIGNED_TO_ROLE_SID IS NOT NULL)
	),
	CONSTRAINT CHK_ACTIVITY_TARGET CHECK (
		TARGET_USER_SID IS NULL OR TARGET_ROLE_SID IS NULL
	)
);

ALTER TABLE CSRIMP.CHAIN_ACTIVITY ADD (
	ASSIGNED_TO_ROLE_SID	NUMBER(10, 0),
	TARGET_ROLE_SID			NUMBER(10, 0)
);

CREATE TABLE CSR.SCORE_TYPE (
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SCORE_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	LABEL				VARCHAR(255)	NOT NULL,
	POS					NUMBER(10, 0)	DEFAULT 0 NOT NULL,
	HIDDEN				NUMBER(1)		DEFAULT 0 NOT NULL,
	ALLOW_MANUAL_SET	NUMBER(1)		DEFAULT 0 NOT NULL,
	LOOKUP_KEY			VARCHAR(255),
	APPLIES_TO_SUPPLIER	NUMBER(1)		DEFAULT 0 NOT NULL,
	REPORTABLE_MONTHS	NUMBER(10)		DEFAULT 36 NOT NULL,
	MEASURE_SID			NUMBER(10, 0),
	SUPPLIER_SCORE_IND_SID NUMBER(10),
	CONSTRAINT PK_SCORE_TYPE PRIMARY KEY (APP_SID, SCORE_TYPE_ID),
	CONSTRAINT CHK_SCORE_TYPE_APPL2SUP CHECK (APPLIES_TO_SUPPLIER IN (0,1)),
	CONSTRAINT CHK_SCORE_TYPE_HIDDEN CHECK (HIDDEN IN (0,1)),
	CONSTRAINT CHK_SCORE_TYPE_AL_MAN_SET CHECK (ALLOW_MANUAL_SET IN (0,1)),
	CONSTRAINT FK_SCORE_TYPE_MEASURE FOREIGN KEY (APP_SID, MEASURE_SID) REFERENCES CSR.MEASURE (APP_SID, MEASURE_SID),
	CONSTRAINT FK_SCORE_TYPE_SUP_IND FOREIGN KEY (APP_SID, SUPPLIER_SCORE_IND_SID) REFERENCES CSR.IND (APP_SID, IND_SID)
);

CREATE UNIQUE INDEX UK_SCORE_TYPE_LOOKUP_KEY ON CSR.SCORE_TYPE (APP_SID, NVL(LOOKUP_KEY, 'NULL_'||SCORE_TYPE_ID));
CREATE INDEX IX_SCORE_TYPE_MEASURE ON CSR.SCORE_TYPE (APP_SID, MEASURE_SID);
CREATE INDEX IX_SCORE_TYPE_SUP_IND ON CSR.SCORE_TYPE (APP_SID, SUPPLIER_SCORE_IND_SID);

CREATE SEQUENCE CSR.SCORE_TYPE_ID_SEQ;

ALTER TABLE CSR.SCORE_THRESHOLD ADD SCORE_TYPE_ID NUMBER(10);

INSERT INTO csr.score_type (app_sid, score_type_id, label, pos, hidden, lookup_key, applies_to_supplier)
SELECT app_sid, csr.score_type_id_seq.NEXTVAL, 'Score', 0, 0, 'SAQ', 1
  FROM (
	SELECT DISTINCT app_sid
	  FROM csr.score_threshold st
	 WHERE NOT EXISTS (
		SELECT *
		  FROM csr.score_type sty
		 WHERE st.app_sid = sty.app_sid
	 )
);

UPDATE csr.score_threshold x
   SET score_type_id = (
	SELECT st.score_type_id
	  FROM csr.score_type st
	 WHERE st.app_sid = x.app_sid
	)
 WHERE score_type_id IS NULL;

UPDATE csr.score_type x
   SET measure_sid = (
	SELECT measure_sid
	  FROM csr.measure m
	 WHERE m.app_sid = x.app_sid
	   AND m.name = 'score_threshold'
	)
 WHERE x.measure_sid IS NULL;

UPDATE csr.score_type x
   SET supplier_score_ind_sid = (
	SELECT ind_sid
	  FROM csr.ind i
	 WHERE i.app_sid = x.app_sid
	   AND i.lookup_key = 'SUPPLIER_SCORE_THRESHOLD'
	)
 WHERE x.supplier_score_ind_sid IS NULL;

ALTER TABLE CSR.SCORE_THRESHOLD MODIFY SCORE_TYPE_ID NOT NULL;

ALTER TABLE CSR.SCORE_THRESHOLD ADD CONSTRAINT FK_SCORE_THRESHOLD_TYPE
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE (APP_SID, SCORE_TYPE_ID);

CREATE INDEX CSR.IX_SCORE_THRESHOLD_TYPE ON CSR.SCORE_THRESHOLD (APP_SID, SCORE_TYPE_ID);

ALTER TABLE CSR.SUPPLIER_SCORE RENAME TO SUPPLIER_SCORE_LOG;

CREATE TABLE CSR.CURRENT_SUPPLIER_SCORE (
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SCORE_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	LAST_SUPPLIER_SCORE_ID NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_CURRENT_SUPPLIER_SCORE PRIMARY KEY (APP_SID, SCORE_TYPE_ID, COMPANY_SID),
	CONSTRAINT FK_CUR_SUP_SCORE_SCORE_TYPE FOREIGN KEY (APP_SID, SCORE_TYPE_ID) REFERENCES CSR.SCORE_TYPE(APP_SID, SCORE_TYPE_ID),
	CONSTRAINT FK_CUR_SUP_SCORE_COMPANY FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CSR.SUPPLIER(APP_SID, COMPANY_SID),
	CONSTRAINT FK_CUR_SUP_LAST_SCORE FOREIGN KEY (APP_SID, LAST_SUPPLIER_SCORE_ID) REFERENCES CSR.SUPPLIER_SCORE_LOG (APP_SID, SUPPLIER_SCORE_ID)
);

CREATE INDEX CSR.IX_CUR_SUP_LAST_SCORE ON CSR.CURRENT_SUPPLIER_SCORE(APP_SID, LAST_SUPPLIER_SCORE_ID);

INSERT INTO csr.current_supplier_score (app_sid, score_type_id, company_sid, last_supplier_score_id)
SELECT s.app_sid, st.score_type_id, s.company_sid, s.last_supplier_score_id
  FROM csr.supplier s
  JOIN csr.score_type st ON s.app_sid = st.app_sid
 WHERE s.last_supplier_score_id IS NOT NULL
   AND st.label = 'Score'
   AND NOT EXISTS (
	SELECT *
	  FROM csr.current_supplier_score css
	 WHERE css.app_sid = s.app_sid
	   AND css.company_sid = s.company_sid
   );

-- we're "dropping" this column, but for now rename out of the way so we keep the data
ALTER TABLE CSR.SUPPLIER RENAME COLUMN LAST_SUPPLIER_SCORE_ID TO XXX_LAST_SUPPLIER_SCORE_ID;

ALTER TABLE CSR.QUICK_SURVEY ADD SCORE_TYPE_ID NUMBER(10, 0);

ALTER TABLE CSR.QUICK_SURVEY ADD CONSTRAINT FK_QUICK_SURVEY_SCORE_TYPE
	FOREIGN KEY (APP_SID, SCORE_TYPE_ID)
	REFERENCES CSR.SCORE_TYPE (APP_SID, SCORE_TYPE_ID)
;

CREATE INDEX CSR.IX_QUICK_SURVEY_SCORE_TYPE ON CSR.QUICK_SURVEY (APP_SID, SCORE_TYPE_ID);

UPDATE csr.quick_survey x
   SET score_type_id = (
	SELECT st.score_type_id
	  FROM csr.score_type st
	 WHERE st.app_sid = x.app_sid
	   AND st.label = 'Score'
	)
 WHERE score_type_id IS NULL
   AND (app_sid, survey_sid) IN (SELECT app_sid, questionnaire_type_id FROM chain.questionnaire_type)
   AND app_sid IN (SELECT app_sid FROM csr.score_type);

DROP INDEX CSR.UK_SCORE_THRESH_MAX_SCORE;
CREATE UNIQUE INDEX CSR.UK_SCORE_THRESH_MAX_SCORE ON CSR.SCORE_THRESHOLD(APP_SID, SCORE_TYPE_ID, MAX_VALUE);

CREATE SEQUENCE CHAIN.COMPANY_HEADER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CHAIN.COMPANY_HEADER(
    APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_HEADER_ID      NUMBER(10, 0)     NOT NULL,
    PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
    PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
    POS                    NUMBER(10, 0)     NOT NULL,
    PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
    USER_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
    CONSTRAINT COMPANY_HEADER_PK PRIMARY KEY (APP_SID, COMPANY_HEADER_ID)
);

ALTER TABLE CHAIN.COMPANY_HEADER ADD CONSTRAINT FK_PAGE_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, PAGE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_HEADER ADD CONSTRAINT FK_USER_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, USER_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

ALTER TABLE CHAIN.COMPANY_HEADER ADD CONSTRAINT FK_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;

ALTER TABLE CHAIN.COMPANY_HEADER ADD CONSTRAINT FK_PLUGIN_TYPE_ID_PLUGIN_TYPE
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID)
;

ALTER TABLE chain.customer_options add activity_mail_account_sid NUMBER(10);
ALTER TABLE CHAIN.ACTIVITY_LOG ADD CORRESPONDENT_NAME VARCHAR2(256);
ALTER TABLE CHAIN.ACTIVITY_LOG ADD IS_FROM_EMAIL NUMBER(1, 0);
UPDATE CHAIN.ACTIVITY_LOG SET IS_FROM_EMAIL=0;
ALTER TABLE CHAIN.ACTIVITY_LOG MODIFY IS_FROM_EMAIL DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.ACTIVITY_LOG ADD CONSTRAINT CHK_ACT_LOG_FROM_EMAIL CHECK (IS_FROM_EMAIL IN (0,1));

-- CSRIMP
CREATE TABLE CSRIMP.SCORE_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SCORE_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	LABEL				VARCHAR(255)	NOT NULL,
	POS					NUMBER(10, 0)	NOT NULL,
	HIDDEN				NUMBER(1)		NOT NULL,
	ALLOW_MANUAL_SET	NUMBER(1)		NOT NULL,
	LOOKUP_KEY			VARCHAR(255),
	APPLIES_TO_SUPPLIER	NUMBER(1)		NOT NULL,
	REPORTABLE_MONTHS	NUMBER(10)		NOT NULL,
	MEASURE_SID			NUMBER(10, 0),
	SUPPLIER_SCORE_IND_SID NUMBER(10),
	CONSTRAINT PK_SCORE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, SCORE_TYPE_ID),
	CONSTRAINT CHK_SCORE_TYPE_APPL2SUP CHECK (APPLIES_TO_SUPPLIER IN (0,1)),
	CONSTRAINT CHK_SCORE_TYPE_HIDDEN CHECK (HIDDEN IN (0,1)),
	CONSTRAINT CHK_SCORE_TYPE_AL_MAN_SET CHECK (ALLOW_MANUAL_SET IN (0,1)),
	CONSTRAINT FK_SCORE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CURRENT_SUPPLIER_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SCORE_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	COMPANY_SID			NUMBER(10, 0)	NOT NULL,
	LAST_SUPPLIER_SCORE_ID NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_CURRENT_SUPPLIER_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, SCORE_TYPE_ID, COMPANY_SID),
	CONSTRAINT FK_CURRENT_SUPPLIER_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

ALTER TABLE CSRIMP.SUPPLIER_SCORE RENAME TO SUPPLIER_SCORE_LOG;

ALTER TABLE CSRIMP.SUPPLIER DROP COLUMN LAST_SUPPLIER_SCORE_ID;

ALTER TABLE CSRIMP.QUICK_SURVEY ADD SCORE_TYPE_ID NUMBER(10, 0);

ALTER TABLE CSRIMP.SCORE_THRESHOLD ADD SCORE_TYPE_ID NUMBER(10);

CREATE TABLE csrimp.map_score_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_score_type_id			NUMBER(10)	NOT NULL,
	new_score_type_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_score_type PRIMARY KEY (old_score_type_id) USING INDEX,
	CONSTRAINT uk_map_score_type UNIQUE (new_score_type_id) USING INDEX,
    CONSTRAINT FK_MAP_SCORE_type_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
alter table csrimp.MAP_SCORE_TYPE drop constraint UK_MAP_SCORE_TYPE;
alter table csrimp.MAP_SCORE_TYPE add constraint UK_MAP_SCORE_TYPE unique (csrimp_session_id, NEW_SCORE_TYPE_ID);
alter table csrimp.MAP_SCORE_TYPE drop constraint PK_MAP_SCORE_TYPE;
alter table csrimp.MAP_SCORE_TYPE add constraint PK_MAP_SCORE_TYPE primary key (csrimp_session_id, OLD_SCORE_TYPE_ID);
alter table csrimp.SCORE_TYPE drop constraint PK_SCORE_TYPE;
alter table csrimp.SCORE_TYPE add constraint PK_SCORE_TYPE primary key (csrimp_session_id, SCORE_TYPE_ID);

ALTER TABLE csrimp.chain_customer_options add activity_mail_account_sid NUMBER(10);
ALTER TABLE CSRIMP.CHAIN_ACTIVITY_LOG ADD CORRESPONDENT_NAME VARCHAR2(256);
ALTER TABLE CSRIMP.CHAIN_ACTIVITY_LOG ADD IS_FROM_EMAIL NUMBER(1, 0);
UPDATE CSRIMP.CHAIN_ACTIVITY_LOG SET IS_FROM_EMAIL=0;
ALTER TABLE CSRIMP.CHAIN_ACTIVITY_LOG MODIFY IS_FROM_EMAIL NOT NULL;
ALTER TABLE CSRIMP.CHAIN_ACTIVITY_LOG ADD CONSTRAINT CHK_ACT_LOG_FROM_EMAIL CHECK (IS_FROM_EMAIL IN (0,1));


-- *** Grants ***
grant select, references on csr.score_type to chain;
grant select on mail.account to chain;

--csrimp
grant select,insert,update,delete on csrimp.score_type to web_user;
grant insert on csr.score_type to csrimp;
grant select on csr.score_type_id_seq to csrimp;
grant select,insert,update,delete on csrimp.current_supplier_score to web_user;
grant insert on csr.current_supplier_score to csrimp;
grant select,insert,update,delete on csrimp.internal_audit_file to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
CREATE OR REPLACE VIEW chain.v$activity AS
SELECT a.activity_id, a.description, a.target_company_sid, a.created_by_company_sid, 
       a.activity_type_id, at.label activity_type_label, at.lookup_key activity_type_lookup_key,
	   a.assigned_to_user_sid, acu.full_name assigned_to_user_name,
	   a.assigned_to_role_sid, acr.name assigned_to_role_name,
	   a.target_user_sid, tcu.full_name target_user_name, 
	   a.target_role_sid, tcr.name target_role_name, 
	   a.activity_dtm, a.original_activity_dtm, 
	   a.created_dtm, a.created_by_activity_id, a.created_by_sid, ccu.full_name created_by_user_name,
	   a.outcome_type_id, ot.label outcome_type_label, ot.is_success, ot.is_failure, ot.is_deferred,
	   a.outcome_reason, a.location, a.location_type,
	   CASE WHEN a.activity_dtm <= SYSDATE AND a.outcome_type_id IS NULL THEN 'Overdue'
	   WHEN a.activity_dtm > SYSDATE AND a.outcome_type_id IS NULL THEN 'Up-coming'
	   ELSE 'Completed' END status
  FROM activity a
  JOIN activity_type at ON at.activity_type_id = a.activity_type_id
  LEFT JOIN outcome_type ot ON ot.outcome_type_id = a.outcome_type_id
  LEFT JOIN csr.csr_user acu ON acu.csr_user_sid = a.assigned_to_user_sid
  LEFT JOIN csr.role acr ON acr.role_sid = a.assigned_to_role_sid
  LEFT JOIN csr.csr_user tcu ON tcu.csr_user_sid = a.target_user_sid
  LEFT JOIN csr.role tcr ON tcr.role_sid = a.target_role_sid
  JOIN csr.csr_user ccu ON ccu.csr_user_sid = a.created_by_sid;

CREATE OR REPLACE VIEW chain.v$activity_log AS
SELECT al.activity_log_id, al.activity_id, al.message, al.logged_dtm, al.is_system_generated,
       al.logged_by_user_sid, al.param_1, al.param_2, al.param_3, al.is_visible_to_supplier,
	   al.reply_to_activity_log_id, NVL(al.correspondent_name,cu.full_name) logged_by_full_name,
	   cu.email logged_by_email, al.is_from_email
  FROM activity_log al
  JOIN activity a ON al.activity_id = a.activity_id
  JOIN csr.csr_user cu ON al.logged_by_user_sid = cu.csr_user_sid
 WHERE a.app_sid = SYS_CONTEXT('SECURITY', 'APP')
   AND (a.created_by_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		OR (al.is_visible_to_supplier = 1
			AND a.target_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		)
	);

DROP VIEW csr.v$supplier;

CREATE OR REPLACE VIEW csr.v$supplier_score AS
	SELECT css.app_sid, css.company_sid, css.score_type_id, css.last_supplier_score_id,
		   ss.score, ss.set_dtm score_last_changed, ss.score_threshold_id,
		   st.description score_threshold_description, t.label score_type_label, t.pos
	  FROM csr.current_supplier_score css
	  JOIN csr.supplier_score_log ss ON css.company_sid = css.company_sid AND css.last_supplier_score_id = ss.supplier_score_id
	  LEFT JOIN csr.score_threshold st ON ss.score_threshold_id = st.score_threshold_id
	  JOIN csr.score_type t ON css.score_type_id = t.score_type_id;

GRANT SELECT ON csr.v$supplier_score TO chain;

-- *** Data changes ***
--RLS
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'SCORE_TYPE',
        'CURRENT_SUPPLIER_SCORE'
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

-- clean these up from latest2176 if not created properly the first time
DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'ACTIVITY',
		'ACTIVITY_OUTCOME_TYPE',
		'ACTIVITY_OUTCOME_TYPE_ACTION',
		'ACTIVITY_TAG',
		'ACTIVITY_TYPE_ALERT',
		'ACTIVITY_TYPE_ALERT_ROLE',
		'ACTIVITY_TYPE_DEFAULT_USER',
		'ACTIVITY_TYPE_TAG_GROUP',
		'ACTIVITY_USER',
		'ACTIVITY_LOG',
		'ACTIVITY_LOG_FILE',
		'ACTIVITY_TYPE',
		'ACTIVITY_TYPE_ACTION',
		'OUTCOME_TYPE',
		'COMPANY_TYPE_ROLE',
		'COMPANY_HEADER',
		'VALIDATED_PURCHASED_COMPONENT',
		'URL_OVERRIDES',
		'PURCHASE_TAG',
		'INVITATION_QNR_TYPE_COMPONENT',
		'DEFAULT_SUPP_REL_CODE_LABEL',
		'COMPONENT_TAG',
		'COMPANY_TAG_GROUP',
		'ALERT_ENTRY_PARAM'
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
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'SCORE_TYPE',
        'CURRENT_SUPPLIER_SCORE',
		'MAP_SCORE_TYPE'
    );
    FOR I IN 1 .. v_list.count
	LOOP		
		-- CSRIMP RLS
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 26)||'_POL',
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
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

-- Data
BEGIN		
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (11, 'Chain Company Header');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

INSERT INTO CSR.customer_alert_type_param (app_sid, customer_alert_type_id, repeats, field_name, description, help_text, display_pos)
SELECT app_sid, customer_alert_type_id, 0, 'ACTIVITY_ID', 'Activity ID', 'The ID of the activity', 6
  FROM chain.activity_type_alert;

CREATE OR REPLACE PROCEDURE chain.temp_RegisterCapability (
	in_capability_type			IN  NUMBER,
	in_capability				IN  VARCHAR2,
	in_perm_type				IN  NUMBER,
	in_is_supplier				IN  NUMBER
)
AS
	v_count						NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND capability_type_id = in_capability_type
	   AND perm_type = in_perm_type;

	IF v_count > 0 THEN
		-- this is already registered
		RETURN;
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND perm_type <> in_perm_type;

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM capability
	 WHERE capability_name = in_capability
	   AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 1 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
			 OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
		   );

	IF v_count > 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
	END IF;

	INSERT INTO capability 
	(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
	VALUES 
	(capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);

END;
/

-- New chain capabilities
BEGIN
	security.user_pkg.logonadmin;
	
	BEGIN
		--chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.SET_COMPANY_SCORES, chain.chain_pkg.BOOLEAN_PERMISSION);
		-- internally the above call makes 2 calls like this:
		chain.temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, 'Set company scores', 1, 0);
		chain.temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, 'Set company scores', 1, 1);
	END;
END;
/

DROP PROCEDURE chain.temp_RegisterCapability;

-- ** New package grants **
-- dummy procs for grant

-- *** Packages ***

@..\quick_survey_pkg
@..\supplier_pkg
@..\chain\activity_pkg
@..\chain\company_pkg
@..\chain\report_pkg
@..\chain\chain_pkg
@..\chain\plugin_pkg
@..\csr_data_pkg
@..\schema_pkg

@..\region_body
@..\quick_survey_body
@..\supplier_body
@..\chain\activity_body
@..\chain\company_body
@..\chain\report_body
@..\chain\dashboard_body
@..\chain\company_filter_body
@..\chain\plugin_body
@..\chain\setup_body
@..\csr_data_body
@..\schema_body
@..\csr_app_body
@..\alert_body
@..\chain\chain_body
@..\csrimp\imp_body

@update_tail
