-- Please update version.sql too -- this keeps clean builds in sync
define version=1960
@update_header

ALTER TABLE CHAIN.QUESTIONNAIRE ADD (DESCRIPTION VARCHAR2(255));

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD (SECURITY_SCHEME_ID NUMBER(10, 0));

CREATE TABLE CHAIN.ACTION_SECURITY_TYPE(
    ACTION_SECURITY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_ACTION_SECURITY_TYPE PRIMARY KEY (ACTION_SECURITY_TYPE_ID)
)
;

CREATE TABLE CHAIN.COMPANY_FUNC_QNR_ACTION(
    COMPANY_FUNCTION_ID        NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_COMPANY_FUNC_QNR_ACTION PRIMARY KEY (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
)
;

CREATE TABLE CHAIN.COMPANY_FUNCTION(
    COMPANY_FUNCTION_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION            VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_COMPANY_FUNCTION PRIMARY KEY (COMPANY_FUNCTION_ID)
)
;

CREATE TABLE CHAIN.QNR_ACTION_SECURITY_MASK(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    ACTION_SECURITY_TYPE_ID    NUMBER(10, 0)    DEFAULT 1 NOT NULL,
    COMPANY_FUNCTION_ID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_QNR_ACTION_SECURITY_MASK PRIMARY KEY (APP_SID, QUESTIONNAIRE_TYPE_ID, QUESTIONNAIRE_ACTION_ID, COMPANY_FUNCTION_ID)
)
;

CREATE TABLE CHAIN.QUESTIONNAIRE_ACTION(
    QUESTIONNAIRE_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_QUESTIONNAIRE_ACTION PRIMARY KEY (QUESTIONNAIRE_ACTION_ID)
)
;

CREATE TABLE CHAIN.QUESTIONNAIRE_SECURITY_SCHEME(
    SECURITY_SCHEME_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_QNR_SECURITY_SCHEME PRIMARY KEY (SECURITY_SCHEME_ID)
)
;

CREATE TABLE CHAIN.QUESTIONNAIRE_USER(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_ID       NUMBER(10, 0)    NOT NULL,
    USER_SID               NUMBER(10, 0)    NOT NULL,
    COMPANY_FUNCTION_ID    NUMBER(10, 0)    NOT NULL,
	COMPANY_SID            NUMBER(10, 0)    NOT NULL,
    ADDED_DTM              TIMESTAMP(6)     DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_QUESTIONNAIRE_USER PRIMARY KEY (APP_SID, QUESTIONNAIRE_ID, USER_SID, COMPANY_FUNCTION_ID, COMPANY_SID)
)
;

CREATE TABLE CHAIN.QUESTIONNAIRE_USER_ACTION(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_ID           NUMBER(10, 0)    NOT NULL,
    USER_SID                   NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    COMPANY_FUNCTION_ID        NUMBER(10, 0)    NOT NULL,
	COMPANY_SID                NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_QUESTIONNAIRE_USER_ACTION PRIMARY KEY (APP_SID, QUESTIONNAIRE_ID, USER_SID, QUESTIONNAIRE_ACTION_ID, COMPANY_FUNCTION_ID, COMPANY_SID)
)
;

CREATE TABLE CHAIN.QUESTIONNAIRE_INVITATION(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    QUESTIONNAIRE_ID    NUMBER(10, 0)    NOT NULL,
    INVITATION_ID       NUMBER(10, 0)    NOT NULL,
    ADDED_DTM           TIMESTAMP(6)     DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_QUESTIONNAIRE_INVITATION PRIMARY KEY (APP_SID, QUESTIONNAIRE_ID, INVITATION_ID)
)
;

CREATE TABLE CHAIN.QNR_SECURITY_SCHEME_CONFIG(
    SECURITY_SCHEME_ID         NUMBER(10, 0)    NOT NULL,
    ACTION_SECURITY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    COMPANY_FUNCTION_ID        NUMBER(10, 0)    NOT NULL,
    QUESTIONNAIRE_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT CHK_VALID_AST CHECK (ACTION_SECURITY_TYPE_ID IN (2)),--,4, 8...)),
    CONSTRAINT PK_QNR_SECURITY_SCHEME_CONFIG PRIMARY KEY (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
)
;

-- 
-- TABLE: CHAIN.COMPANY_FUNC_QNR_ACTION 
--

ALTER TABLE CHAIN.COMPANY_FUNC_QNR_ACTION ADD CONSTRAINT FK_CF_CFAQ 
    FOREIGN KEY (COMPANY_FUNCTION_ID)
    REFERENCES CHAIN.COMPANY_FUNCTION(COMPANY_FUNCTION_ID)
;

ALTER TABLE CHAIN.COMPANY_FUNC_QNR_ACTION ADD CONSTRAINT FK_QA_CFAQ 
    FOREIGN KEY (QUESTIONNAIRE_ACTION_ID)
    REFERENCES CHAIN.QUESTIONNAIRE_ACTION(QUESTIONNAIRE_ACTION_ID)
;

-- 
-- TABLE: CHAIN.QNR_ACTION_SECURITY_MASK 
--

ALTER TABLE CHAIN.QNR_ACTION_SECURITY_MASK ADD CONSTRAINT FK_AST_QASM 
    FOREIGN KEY (ACTION_SECURITY_TYPE_ID)
    REFERENCES CHAIN.ACTION_SECURITY_TYPE(ACTION_SECURITY_TYPE_ID)
;

ALTER TABLE CHAIN.QNR_ACTION_SECURITY_MASK ADD CONSTRAINT FK_CGQA_QSM 
    FOREIGN KEY (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
    REFERENCES CHAIN.COMPANY_FUNC_QNR_ACTION(COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
;

ALTER TABLE CHAIN.QNR_ACTION_SECURITY_MASK ADD CONSTRAINT FK_QNRTYPE_QASM 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_TYPE_ID)
    REFERENCES CHAIN.QUESTIONNAIRE_TYPE(APP_SID, QUESTIONNAIRE_TYPE_ID)
;

-- 
-- TABLE: CHAIN.QUESTIONNAIRE_TYPE 
--

ALTER TABLE CHAIN.QUESTIONNAIRE_TYPE ADD CONSTRAINT FK_QSS_QNRTYPE 
    FOREIGN KEY (SECURITY_SCHEME_ID)
    REFERENCES CHAIN.QUESTIONNAIRE_SECURITY_SCHEME(SECURITY_SCHEME_ID)
;

-- 
-- TABLE: CHAIN.QUESTIONNAIRE_USER 
--

ALTER TABLE CHAIN.QUESTIONNAIRE_USER ADD CONSTRAINT FK_CF_QU 
    FOREIGN KEY (COMPANY_FUNCTION_ID)
    REFERENCES CHAIN.COMPANY_FUNCTION(COMPANY_FUNCTION_ID)
;

ALTER TABLE CHAIN.QUESTIONNAIRE_USER ADD CONSTRAINT FK_CHAIN_USER_QU 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE CHAIN.QUESTIONNAIRE_USER ADD CONSTRAINT FK_QUESTIONNAIRE_QU 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_ID)
    REFERENCES CHAIN.QUESTIONNAIRE(APP_SID, QUESTIONNAIRE_ID)
;

ALTER TABLE CHAIN.QUESTIONNAIRE_USER ADD CONSTRAINT FK_COMPANY_QUESTIONNAIRE_USER 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

-- 
-- TABLE: CHAIN.QUESTIONNAIRE_USER_ACTION 
--

ALTER TABLE CHAIN.QUESTIONNAIRE_USER_ACTION ADD CONSTRAINT FK_CFQA_QUA 
    FOREIGN KEY (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
    REFERENCES CHAIN.COMPANY_FUNC_QNR_ACTION(COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
;

ALTER TABLE CHAIN.QUESTIONNAIRE_USER_ACTION ADD CONSTRAINT FK_QU_QUA 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_ID, USER_SID, COMPANY_FUNCTION_ID, COMPANY_SID)
    REFERENCES CHAIN.QUESTIONNAIRE_USER(APP_SID, QUESTIONNAIRE_ID, USER_SID, COMPANY_FUNCTION_ID, COMPANY_SID)
;

-- 
-- TABLE: CHAIN.QUESTIONNAIRE_INVITATION 
--

ALTER TABLE CHAIN.QUESTIONNAIRE_INVITATION ADD CONSTRAINT FK_INVITATION_QNR_INVITATION 
    FOREIGN KEY (APP_SID, INVITATION_ID)
    REFERENCES CHAIN.INVITATION(APP_SID, INVITATION_ID)
;

ALTER TABLE CHAIN.QUESTIONNAIRE_INVITATION ADD CONSTRAINT FK_QNR_QNR_INVITATION 
    FOREIGN KEY (APP_SID, QUESTIONNAIRE_ID)
    REFERENCES CHAIN.QUESTIONNAIRE(APP_SID, QUESTIONNAIRE_ID)
;

-- 
-- TABLE: CHAIN.QNR_SECURITY_SCHEME_CONFIG 
--

ALTER TABLE CHAIN.QNR_SECURITY_SCHEME_CONFIG ADD CONSTRAINT FK_AST_QSSC 
    FOREIGN KEY (ACTION_SECURITY_TYPE_ID)
    REFERENCES CHAIN.ACTION_SECURITY_TYPE(ACTION_SECURITY_TYPE_ID)
;

ALTER TABLE CHAIN.QNR_SECURITY_SCHEME_CONFIG ADD CONSTRAINT FK_CFQA_QSSC 
    FOREIGN KEY (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
    REFERENCES CHAIN.COMPANY_FUNC_QNR_ACTION(COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID)
;

ALTER TABLE CHAIN.QNR_SECURITY_SCHEME_CONFIG ADD CONSTRAINT FK_CSS_QSSC 
    FOREIGN KEY (SECURITY_SCHEME_ID)
    REFERENCES CHAIN.QUESTIONNAIRE_SECURITY_SCHEME(SECURITY_SCHEME_ID)
;


BEGIN
	INSERT INTO CHAIN.COMPANY_FUNCTION (COMPANY_FUNCTION_ID, DESCRIPTION) VALUES (1, 'Procurer');
	INSERT INTO CHAIN.COMPANY_FUNCTION (COMPANY_FUNCTION_ID, DESCRIPTION) VALUES (2, 'Supplier');
	
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (1, 'View');
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (2, 'Edit');
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (3, 'Submit');
	INSERT INTO CHAIN.QUESTIONNAIRE_ACTION (QUESTIONNAIRE_ACTION_ID, DESCRIPTION) VALUES (4, 'Approve');
	
	INSERT INTO CHAIN.ACTION_SECURITY_TYPE (ACTION_SECURITY_TYPE_ID, DESCRIPTION) VALUES (1, 'Capabilities');
	INSERT INTO CHAIN.ACTION_SECURITY_TYPE (ACTION_SECURITY_TYPE_ID, DESCRIPTION) VALUES (2, 'Users');
	INSERT INTO CHAIN.ACTION_SECURITY_TYPE (ACTION_SECURITY_TYPE_ID, DESCRIPTION) VALUES (3, 'Capabilities or Users');
	
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 1); -- PROCURER, VIEW
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 2); -- PROCURER, EDIT
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 3); -- PROCURER, SUBMIT
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 4); -- PROCURER, APPROVE
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 1); -- SUPPLIER, VIEW
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 2); -- SUPPLIER, EDIT
	INSERT INTO CHAIN.COMPANY_FUNC_QNR_ACTION (COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (2, 3); -- SUPPLIER, SUBMIT
		
	INSERT INTO CHAIN.QUESTIONNAIRE_SECURITY_SCHEME (SECURITY_SCHEME_ID, DESCRIPTION) VALUES (1, 'PROCURER: USER APPROVE; SUPPLIER: USER EDIT, USER SUBMIT');
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 2, 1, 4); -- PROCURER: USER APPROVE
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 2, 2, 2); -- SUPPLIER: USER EDIT
	INSERT INTO CHAIN.QNR_SECURITY_SCHEME_CONFIG (SECURITY_SCHEME_ID, ACTION_SECURITY_TYPE_ID, COMPANY_FUNCTION_ID, QUESTIONNAIRE_ACTION_ID) VALUES (1, 2, 2, 3); -- SUPPLIER: USER SUBMIT
		   
	/* chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.EDIT_USERS_EMAIL_ADDRESS, chain.chain_pkg.BOOLEAN_PERMISSION); */
	INSERT INTO chain.capability(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Manage questionnaire security', 1, 1, 0);
	
	INSERT INTO chain.capability (capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Manage questionnaire security', 2, 1, 1);
END;
/

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.QuestionnaireSecurity
	v_desc := 'Allows viewing and editing of questionnaire security';
	v_class := 'Credit360.Chain.Cards.QuestionnaireSecurity';
	v_js_path := '/csr/site/chain/cards/questionnaireSecurity.js';
	v_js_class := 'Chain.Cards.QuestionnaireSecurity';
	v_css_path := '';
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN	
		UPDATE chain.card
		   SET description = v_desc, 
		       class_type = v_class, 
			   js_include = v_js_path, 
			   css_include = v_css_path
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

commit;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_QNR_SECURITY_ACTION
( 
	QUESTIONNAIRE_ID			NUMBER(10)  NOT NULL,
	QUESTIONNAIRE_TYPE_ID		NUMBER(10)  NOT NULL,
	COMPANY_FUNCTION_ID			NUMBER(10)  NOT NULL,
	COMPANY_SID					NUMBER(10)  NOT NULL,
	ACTION_SECURITY_TYPE_ID		NUMBER(10)  NOT NULL,
	QUESTIONNAIRE_ACTION_ID		NUMBER(10)  NOT NULL
)
ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_QNR_SECURITY_ENTRY
( 
	QUESTIONNAIRE_ID			NUMBER(10)  NOT NULL,
	QUESTIONNAIRE_TYPE_ID		NUMBER(10)  NOT NULL,
	COMPANY_FUNCTION_ID			NUMBER(10)  NOT NULL,
	COMPANY_SID					NUMBER(10)  NOT NULL,
	ACTION_SECURITY_TYPE_ID		NUMBER(10)  NOT NULL,
	ID							NUMBER(10)  NOT NULL,
	DESCRIPTION					VARCHAR2(500) NOT NULL,
	POSITION					NUMBER(10)
) 
ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_QNR_SECURITY_ENTRY_ACTION
( 
	QUESTIONNAIRE_ID			NUMBER(10)  NOT NULL,
	COMPANY_FUNCTION_ID			NUMBER(10)  NOT NULL,
	COMPANY_SID					NUMBER(10)  NOT NULL,
	ACTION_SECURITY_TYPE_ID		NUMBER(10)  NOT NULL,
	ID							NUMBER(10)  NOT NULL,
	QUESTIONNAIRE_ACTION_ID		NUMBER(10)  NOT NULL
) 
ON COMMIT DELETE ROWS;

CREATE OR REPLACE VIEW CHAIN.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.component_id, q.questionnaire_type_id, q.created_dtm,
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, NVL(q.description, qt.name) description, qt.db_class, qt.group_name, qt.position, 
		   qsle.status_log_entry_index, qsle.questionnaire_status_id, qs.description questionnaire_status_name, qsle.entry_dtm status_update_dtm
	  FROM questionnaire q, questionnaire_type qt, qnr_status_log_entry qsle, questionnaire_status qs
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qt.app_sid
	   AND q.app_sid = qsle.app_sid
       AND q.questionnaire_type_id = qt.questionnaire_type_id
       AND qsle.questionnaire_status_id = qs.questionnaire_status_id
       AND q.questionnaire_id = qsle.questionnaire_id
       AND (qsle.questionnaire_id, qsle.status_log_entry_index) IN (   
			SELECT questionnaire_id, MAX(status_log_entry_index)
			  FROM qnr_status_log_entry
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY questionnaire_id
			);

CREATE OR REPLACE VIEW CHAIN.v$qnr_action_security_mask AS
    SELECT app_sid, questionnaire_type_id, company_function_id, questionnaire_action_id, action_security_type_id,
		   CASE WHEN  security.bitwise_pkg.bitand(action_security_type_id, 1) = 1 THEN 1 ELSE 0 END capability_check, -- CAPABILITY
		   CASE WHEN  security.bitwise_pkg.bitand(action_security_type_id, 2) = 2 THEN 1 ELSE 0 END user_check	      -- USER
--		   CASE WHEN  security.bitwise_pkg.bitand(action_security_type_id, 4) = 4 THEN 1 ELSE 0 END other_check	      -- OTHER
	  FROM (
			SELECT x.app_sid, x.questionnaire_type_id, x.company_function_id, x.questionnaire_action_id, NVL(m.action_security_type_id, x.action_security_type_id) action_security_type_id
			  FROM chain.qnr_action_security_mask m, (
					SELECT qt.app_sid, qt.questionnaire_type_id, cfqa.company_function_id, cfqa.questionnaire_action_id, ast.action_security_type_id
					  FROM chain.company_func_qnr_action cfqa, chain.questionnaire_type qt, chain.action_security_type ast
					 WHERE ast.action_security_type_id = 1 -- chain_pkg.AST_CAPABILITIES
					   AND NVL(SYS_CONTEXT('SECURITY', 'APP'), qt.app_sid) = qt.app_sid
				  ) x
			 WHERE x.app_sid = m.app_sid(+)
			   AND x.questionnaire_type_id = m.questionnaire_type_id(+)
			   AND x.company_function_id = m.company_function_id(+)
			   AND x.questionnaire_action_id = m.questionnaire_action_id(+)
			);


CREATE OR REPLACE VIEW chain.v$qnr_action_capability
AS
    SELECT questionnaire_action_id, description,
           CASE WHEN questionnaire_action_id = 1 THEN 'Questionnaire'
            WHEN questionnaire_action_id = 2 THEN 'Questionnaire'
            WHEN questionnaire_action_id = 3 THEN 'Submit questionnaire'
            WHEN questionnaire_action_id = 4 THEN 'Approve questionnaire' 
           END capability_name,
           CASE WHEN questionnaire_action_id = 1 THEN 1 --security_pkg.PERMISSION_READ -- SPECIFIC
            WHEN questionnaire_action_id = 2 THEN 2 --security_pkg.PERMISSION_WRITE -- SPECIFIC
            WHEN questionnaire_action_id = 3 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
            WHEN questionnaire_action_id = 4 THEN 2 --security_pkg.PERMISSION_WRITE -- BOOLEAN
           END permission_set,
           CASE WHEN questionnaire_action_id = 1 THEN 0 -- SPECIFIC
            WHEN questionnaire_action_id = 2 THEN 0 -- SPECIFIC
            WHEN questionnaire_action_id = 3 THEN 1 -- BOOLEAN
            WHEN questionnaire_action_id = 4 THEN 1 -- BOOLEAN
           END permission_type
		  FROM chain.questionnaire_action;
			
CREATE OR REPLACE VIEW chain.v$company_action_capability
AS
    SELECT c.capability_id, x.company_function_id, x.company_sid, x.id company_group_type_id, qa.questionnaire_action_id, x.action_security_type_id, qa.permission_set
	  FROM capability c, company_func_qnr_action cfqa, (
			 SELECT company_sid, company_function_id, action_security_type_id, id, CASE WHEN company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND company_function_id = 1 THEN 1 ELSE 0 END is_supplier
			   FROM (SELECT DISTINCT action_security_type_id, id, company_sid, company_function_id FROM TT_QNR_SECURITY_ENTRY WHERE action_security_type_id = 1)
		   ) x, chain.v$qnr_action_capability qa
	 WHERE qa.capability_name = c.capability_name
	   AND qa.questionnaire_action_id = cfqa.questionnaire_action_id
	   AND x.company_function_id = cfqa.company_function_id
	   AND x.is_supplier = c.is_supplier;
			
CREATE OR REPLACE VIEW chain.v$qnr_security_scheme_summary
AS
	SELECT NVL(p.security_scheme_id, s.security_scheme_id) security_scheme_id, 
       NVL(p.action_security_type_id, s.action_security_type_id) action_security_type_id,
       CASE WHEN p.company_function_id > 0 THEN 1 ELSE 0 END has_procurer_config, 
       CASE WHEN s.company_function_id > 0 THEN 1 ELSE 0 END has_supplier_config
	  FROM (
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 1
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) p
	 FULL OUTER JOIN (           
			  SELECT security_scheme_id, action_security_type_id, company_function_id
				FROM qnr_security_scheme_config
			   WHERE company_function_id = 2
			   GROUP BY security_scheme_id, action_security_type_id, company_function_id
		   ) s
	   ON p.security_scheme_id = s.security_scheme_id AND p.action_security_type_id = s.action_security_type_id;
	   
	   
	  
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'QNR_ACTION_SECURITY_MASK',
		policy_name     => (SUBSTR('QNR_ACTION_SECURITY_MASK', 1, 26) || '_POL'), 
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);

	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'QUESTIONNAIRE_USER',
		policy_name     => (SUBSTR('QUESTIONNAIRE_USER', 1, 26) || '_POL'), 
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
	
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'QUESTIONNAIRE_INVITATION',
		policy_name     => (SUBSTR('QUESTIONNAIRE_INVITATION', 1, 26) || '_POL'), 
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
		
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'QUESTIONNAIRE_USER_ACTION',
		policy_name     => (SUBSTR('QUESTIONNAIRE_USER_ACTION', 1, 26) || '_POL'), 
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static);
END;
/	
   
@..\chain\chain_pkg
@..\chain\questionnaire_security_pkg
@..\chain\company_pkg
@..\chain\questionnaire_pkg

@..\chain\questionnaire_security_body
@..\chain\company_body
@..\chain\invitation_body
@..\chain\questionnaire_body

@..\quick_survey_body


grant execute on chain.questionnaire_security_pkg to csr;   
grant execute on chain.questionnaire_security_pkg to web_user;

@update_tail