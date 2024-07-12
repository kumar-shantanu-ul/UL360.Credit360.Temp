-- Please update version.sql too -- this keeps clean builds in sync
define version=716
@update_header

CREATE SEQUENCE csr.EXPR_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.QS_EXPR_ACTION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.QS_EXPR_MSG_ACTION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.QS_EXPR_NC_ACTION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.QS_EXPR_STATUS_ACTION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;

CREATE SEQUENCE csr.QUICK_SURVEY_STATUS_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER;
 

ALTER TABLE csr.internal_audit RENAME COLUMN assigned_to_user_sid TO auditor_user_sid;
ALTER TABLE csr.internal_audit ADD (AUDIT_CONTACT_USER_SID    NUMBER(10, 0));

ALTER TABLE csr.INTERNAL_AUDIT_TYPE ADD (
    EVERY_N_MONTHS            NUMBER(10, 0),
    AUDITOR_ROLE_SID          NUMBER(10, 0),
    AUDIT_CONTACT_ROLE_SID    NUMBER(10, 0)
 );
 
ALTER TABLE csr.NON_COMPLIANCE ADD (
    QS_EXPR_NON_COMPL_ACTION_ID    NUMBER(10, 0)
);

 
CREATE TABLE csr.QS_EXPR_MSG_ACTION(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_EXPR_MSG_ACTION_ID    NUMBER(10, 0)     NOT NULL,
    MSG                      VARCHAR2(4000)    NOT NULL,
    CSS_CLASS                VARCHAR2(255)     NOT NULL,
    CONSTRAINT PK_QS_EXPR_MSG_ACTION PRIMARY KEY (APP_SID, QS_EXPR_MSG_ACTION_ID)
);

CREATE TABLE csr.QS_EXPR_NC_ACTION_INVOLVE_ROLE(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_EXPR_NON_COMPL_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    INVOLVE_ROLE_SID               NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_QS_EXPR_NC_ACTION_INV PRIMARY KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID, INVOLVE_ROLE_SID)
);

CREATE TABLE csr.QS_EXPR_NON_COMPL_ACTION(
    APP_SID                        NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_EXPR_NON_COMPL_ACTION_ID    NUMBER(10, 0)     NOT NULL,
    ASSIGN_TO_ROLE_SID             NUMBER(10, 0)     NOT NULL,
    DUE_DTM_ABS                    DATE,
    DUE_DTM_RELATIVE               NUMBER(10, 0),
    DUE_DTM_RELATIVE_UNIT          VARCHAR2(1),
    TITLE                          VARCHAR2(4000)    NOT NULL,
    CONSTRAINT CHK_QS_EXPR_NC_ACT_DUE_DTM CHECK (DUE_DTM_ABS IS NOT NULL OR 
(DUE_DTM_RELATIVE IS NOT NULL AND DUE_DTM_RELATIVE_UNIT IS NOT NULL)),
    CONSTRAINT CHK_NC_DUE_DTM_REL_UNIT CHECK (DUE_DTM_RELATIVE_UNIT IN ('d','m')),
    CONSTRAINT PK_QS_EXPR_NC_ACTION PRIMARY KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
);

CREATE TABLE csr.QS_EXPR_STATUS_ACTION(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QS_EXPR_STATUS_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    QUICK_SURVEY_STATUS_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_QS_EXPR_STATUS_ACTION PRIMARY KEY (APP_SID, QS_EXPR_STATUS_ACTION_ID)
);
 
ALTER TABLE csr.QUICK_SURVEY ADD (
    QUICK_SURVEY_STATUS_ID    NUMBER(10, 0));
 
CREATE TABLE csr.QUICK_SURVEY_EXPR(
    APP_SID       NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SURVEY_SID    NUMBER(10, 0)     NOT NULL,
    EXPR_ID       NUMBER(10, 0)     NOT NULL,
    EXPR          VARCHAR2(4000)    NOT NULL,
    DESCRIPTION   VARCHAR2(4000),
    CONSTRAINT PK_QS_EXPR PRIMARY KEY (APP_SID, SURVEY_SID, EXPR_ID)
)
;

CREATE TABLE csr.QUICK_SURVEY_EXPR_ACTION(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QUICK_SURVEY_EXPR_ACTION_ID    NUMBER(10, 0)    NOT NULL,
    ACTION_TYPE                    VARCHAR2(20)     NOT NULL,
    SURVEY_SID                     NUMBER(10, 0)    NOT NULL,
    EXPR_ID                        NUMBER(10, 0)    NOT NULL,
    QS_EXPR_NON_COMPL_ACTION_ID    NUMBER(10, 0),
    QS_EXPR_MSG_ACTION_ID          NUMBER(10, 0),
    QS_EXPR_STATUS_ACTION_ID       NUMBER(10, 0),
    CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK ((ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
  AND QS_EXPR_MSG_ACTION_ID IS NULL AND QS_EXPR_STATUS_ACTION_ID IS NULL)
OR
(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND QS_EXPR_STATUS_ACTION_ID IS NULL)
OR
(ACTION_TYPE = 'status' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
  AND QS_EXPR_MSG_ACTION_ID IS NULL AND QS_EXPR_STATUS_ACTION_ID IS NOT NULL)),
    CONSTRAINT CHK_QS_EXPR_ACTION_TYPE CHECK (ACTION_TYPE IN ('nc','msg','status')),
    CONSTRAINT PK_QS_EXPR_ACTION PRIMARY KEY (APP_SID, QUICK_SURVEY_EXPR_ACTION_ID)
);


CREATE TABLE csr.QUICK_SURVEY_STATUS(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    QUICK_SURVEY_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                     VARCHAR2(255)    NOT NULL,
    CSS_CLASS                 VARCHAR2(255),
    CONSTRAINT PK_QUICK_SURVEY_STATUS PRIMARY KEY (APP_SID, QUICK_SURVEY_STATUS_ID)
);
  
CREATE TABLE csr.REGION_INTERNAL_AUDIT(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    INTERNAL_AUDIT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    REGION_SID                NUMBER(10, 0)    NOT NULL,
    NEXT_AUDIT_DTM            DATE,
    CONSTRAINT PK_REGION_INTERNAL_AUDIT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, REGION_SID)
);

 
ALTER TABLE csr.INTERNAL_AUDIT DROP CONSTRAINT RefCSR_USER1350;
  --    was FOREIGN KEY (APP_SID, ASSIGNED_TO_USER_SID) REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
 
 
ALTER TABLE csr.INTERNAL_AUDIT ADD CONSTRAINT FK_IA_USER_AUDIT_CONTACT 
    FOREIGN KEY (APP_SID, AUDIT_CONTACT_USER_SID)
    REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
;
 
ALTER TABLE csr.INTERNAL_AUDIT ADD CONSTRAINT FK_IA_USER_AUDITOR 
    FOREIGN KEY (APP_SID, AUDITOR_USER_SID)
    REFERENCES csr.CSR_USER(APP_SID, CSR_USER_SID)
;


 
ALTER TABLE csr.INTERNAL_AUDIT_TYPE ADD CONSTRAINT FK_ROLE_IA_AUDIT_CONTACT 
    FOREIGN KEY (APP_SID, AUDIT_CONTACT_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

 
ALTER TABLE csr.INTERNAL_AUDIT_TYPE ADD CONSTRAINT FK_ROLE_IA_AUDITOR 
    FOREIGN KEY (APP_SID, AUDITOR_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;
 
 
ALTER TABLE csr.NON_COMPLIANCE ADD CONSTRAINT FK_QS_EXPR_NC_ACT_NC 
    FOREIGN KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
    REFERENCES csr.QS_EXPR_NON_COMPL_ACTION(APP_SID, QS_EXPR_NON_COMPL_ACTION_ID) ON DELETE SET NULL
;
 
ALTER TABLE csr.QS_EXPR_MSG_ACTION ADD CONSTRAINT FK_CUS_QS_EXPR_MSG_ACTION 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;
ALTER TABLE csr.QS_EXPR_NC_ACTION_INVOLVE_ROLE ADD CONSTRAINT RefQS_EXPR_NON_COMPL_ACTIO2241 
    FOREIGN KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
    REFERENCES csr.QS_EXPR_NON_COMPL_ACTION(APP_SID, QS_EXPR_NON_COMPL_ACTION_ID) ON DELETE CASCADE
;

ALTER TABLE csr.QS_EXPR_NC_ACTION_INVOLVE_ROLE ADD CONSTRAINT FK_ROLE_QS_EXPR_NC_ACT_INV 
    FOREIGN KEY (APP_SID, INVOLVE_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE csr.QS_EXPR_NON_COMPL_ACTION ADD CONSTRAINT FK_CUS_QS_EXPR_NC_ACTION 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.QS_EXPR_NON_COMPL_ACTION ADD CONSTRAINT FK_ROLE_QS_EXPR_NC_ACTION 
    FOREIGN KEY (APP_SID, ASSIGN_TO_ROLE_SID)
    REFERENCES csr.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE csr.QS_EXPR_STATUS_ACTION ADD CONSTRAINT FK_CUS_QS_EXPR_STATUS_ACTION 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.QS_EXPR_STATUS_ACTION ADD CONSTRAINT FK_QS_STATUS_EXPR_ST_ACT 
    FOREIGN KEY (APP_SID, QUICK_SURVEY_STATUS_ID)
    REFERENCES csr.QUICK_SURVEY_STATUS(APP_SID, QUICK_SURVEY_STATUS_ID)
;


 
ALTER TABLE csr.QUICK_SURVEY ADD CONSTRAINT FK_QS_STATUS_QS 
    FOREIGN KEY (APP_SID, QUICK_SURVEY_STATUS_ID)
    REFERENCES csr.QUICK_SURVEY_STATUS(APP_SID, QUICK_SURVEY_STATUS_ID)
;
 

ALTER TABLE csr.QUICK_SURVEY_EXPR ADD CONSTRAINT FK_QS_QS_EXPR 
    FOREIGN KEY (APP_SID, SURVEY_SID)
    REFERENCES csr.QUICK_SURVEY(APP_SID, SURVEY_SID)
;


-- 
-- TABLE: QUICK_SURVEY_EXPR_ACTION 
--

ALTER TABLE csr.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT FK_CUS_QS_EXPR_ACTION
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;

ALTER TABLE csr.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT FK_QS_EXPR_MSG_ACTION 
    FOREIGN KEY (APP_SID, QS_EXPR_MSG_ACTION_ID)
    REFERENCES csr.QS_EXPR_MSG_ACTION(APP_SID, QS_EXPR_MSG_ACTION_ID) ON DELETE SET NULL
;

ALTER TABLE csr.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT FK_QS_EXPR_NON_COMPL_ACTION 
    FOREIGN KEY (APP_SID, QS_EXPR_NON_COMPL_ACTION_ID)
    REFERENCES csr.QS_EXPR_NON_COMPL_ACTION(APP_SID, QS_EXPR_NON_COMPL_ACTION_ID) ON DELETE SET NULL
;

ALTER TABLE csr.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT FK_QS_EXPR_QS_EXPR_ACTION 
    FOREIGN KEY (APP_SID, SURVEY_SID, EXPR_ID)
    REFERENCES csr.QUICK_SURVEY_EXPR(APP_SID, SURVEY_SID, EXPR_ID) ON DELETE CASCADE
;

ALTER TABLE csr.QUICK_SURVEY_EXPR_ACTION ADD CONSTRAINT FK_QS_EXPR_STATUS_ACTION 
    FOREIGN KEY (APP_SID, QS_EXPR_STATUS_ACTION_ID)
    REFERENCES csr.QS_EXPR_STATUS_ACTION(APP_SID, QS_EXPR_STATUS_ACTION_ID) ON DELETE SET NULL
;


ALTER TABLE csr.QUICK_SURVEY_STATUS ADD CONSTRAINT FK_CUS_QS_STATUS 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;


-- 
-- TABLE: REGION_INTERNAL_AUDIT 
--

ALTER TABLE csr.REGION_INTERNAL_AUDIT ADD CONSTRAINT FK_IAT_REGION_IA 
    FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
    REFERENCES csr.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID)
;

ALTER TABLE csr.REGION_INTERNAL_AUDIT ADD CONSTRAINT FK_REGION_REGION_IA 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.REGION(APP_SID, REGION_SID)
;



DECLARE
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
BEGIN	
	v_list := t_tabs(
		'INTERNAL_AUDIT_TYPE',
		'INTERNAL_AUDIT_POSTIT',
		'QS_ANSWER_FILE',
		'QS_EXPR_MSG_ACTION',
		'QS_EXPR_NC_ACTION_INVOLVE_ROLE',
		'QS_EXPR_NON_COMPL_ACTION',
		'QS_EXPR_STATUS_ACTION',
		'QUICK_SURVEY_EXPR',
		'QUICK_SURVEY_EXPR_ACTION',
		'QUICK_SURVEY_STATUS',
		'REGION_INTERNAL_AUDIT'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
END;
/

@..\audit_pkg
@..\audit_body

@update_tail
