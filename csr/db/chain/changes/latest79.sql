define version=79
@update_header

--
-- ER/Studio 8.0 SQL Code Generation
-- Company :      Microsoft
-- Project :      caseyschema.dm1
-- Author :       Microsoft
--
-- Date Created : Monday, May 16, 2011 14:37:35
-- Target DBMS : Oracle 10g
--

-- 
-- SEQUENCE: MESSAGE_COMPLETION_ID_SEQ 
--

CREATE SEQUENCE chain.MESSAGE_COMPLETION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- SEQUENCE: MESSAGE_DEFINITION_ID_SEQ 
--

CREATE SEQUENCE chain.MESSAGE_DEFINITION_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- SEQUENCE: MESSAGE_ID_SEQ 
--

CREATE SEQUENCE chain.MESSAGE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- SEQUENCE: RECIPIENT_ID_SEQ 
--

CREATE SEQUENCE chain.RECIPIENT_ID_SEQ
    START WITH 10000
    INCREMENT BY 1
    MINVALUE 10000
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- 
-- TABLE: ADDRESSING_TYPE 
--

CREATE TABLE chain.ADDRESSING_TYPE(
    ADDRESSING_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK243 PRIMARY KEY (ADDRESSING_TYPE_ID)
)
;



-- 
-- TABLE: COMPLETION_TYPE 
--

CREATE TABLE chain.COMPLETION_TYPE(
    COMPLETION_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK283 PRIMARY KEY (COMPLETION_TYPE_ID)
)
;



-- 
-- TABLE: DEFAULT_MESSAGE_DEFINITION 
--

CREATE TABLE chain.DEFAULT_MESSAGE_DEFINITION(
    MESSAGE_DEFINITION_ID    NUMBER(10, 0)     NOT NULL,
    MESSAGE_TEMPLATE         VARCHAR2(4000)    NOT NULL,
    MESSAGE_PRIORITY_ID      NUMBER(10, 0)     NOT NULL,
    REPEAT_TYPE_ID           NUMBER(10, 0)     NOT NULL,
    ADDRESSING_TYPE_ID       NUMBER(10, 0)     NOT NULL,
    COMPLETION_TYPE_ID       NUMBER(10, 0)     NOT NULL,
    COMPLETED_TEMPLATE       VARCHAR2(255),
    HELPER_PKG               VARCHAR2(100),
    CSS_CLASS                VARCHAR2(255),
    CONSTRAINT PK241 PRIMARY KEY (MESSAGE_DEFINITION_ID)
)
;



-- 
-- TABLE: DEFAULT_MESSAGE_PARAM 
--

CREATE TABLE chain.DEFAULT_MESSAGE_PARAM(
    MESSAGE_DEFINITION_ID    NUMBER(10, 0)     NOT NULL,
    PARAM_NAME               VARCHAR2(255)     NOT NULL,
    LOWER_PARAM_NAME         VARCHAR2(255)     NOT NULL,
    VALUE                    VARCHAR2(1000),
    HREF                     VARCHAR2(1000),
    CSS_CLASS                VARCHAR2(255),
    CONSTRAINT CHK_LOWER_PARAM_MATCH CHECK (LOWER_PARAM_NAME = LOWER(PARAM_NAME)),
    CONSTRAINT CHK_IS_ALPHA_NUM CHECK (TRIM(TRANSLATE(REPLACE(LOWER_PARAM_NAME, ' ', '_'), 'abcdefghijklmnopqrstuvwxyz0123456789', ' ')) IS NULL),
    CONSTRAINT PK247 PRIMARY KEY (MESSAGE_DEFINITION_ID, PARAM_NAME)
)
;



-- 
-- TABLE: MESSAGE 
--

CREATE TABLE chain.MESSAGE(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    MESSAGE_ID                  NUMBER(10, 0)    NOT NULL,
    ACTION_ID                   NUMBER(10, 0),
    EVENT_ID                    NUMBER(10, 0),
    MESSAGE_DEFINITION_ID       NUMBER(10, 0)    NOT NULL,
    RE_COMPANY_SID              NUMBER(10, 0),
    RE_USER_SID                 NUMBER(10, 0),
    RE_QUESTIONNAIRE_TYPE_ID    NUMBER(10, 0),
    RE_COMPONENT_ID             NUMBER(10, 0),
    DUE_DTM                     TIMESTAMP(6),
    COMPLETED_DTM               TIMESTAMP(6),
    COMPLETED_BY_USER_SID       NUMBER(10, 0),
    CONSTRAINT PK246 PRIMARY KEY (APP_SID, MESSAGE_ID)
)
;



-- 
-- TABLE: MESSAGE_DEFINITION 
--

CREATE TABLE chain.MESSAGE_DEFINITION(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    MESSAGE_DEFINITION_ID    NUMBER(10, 0)     NOT NULL,
    MESSAGE_TEMPLATE         VARCHAR2(4000),
    MESSAGE_PRIORITY_ID      NUMBER(10, 0),
    COMPLETED_TEMPLATE       VARCHAR2(255),
    HELPER_PKG               VARCHAR2(100),
    CSS_CLASS                VARCHAR2(255),
    CONSTRAINT PK242 PRIMARY KEY (APP_SID, MESSAGE_DEFINITION_ID)
)
;



-- 
-- TABLE: MESSAGE_DEFINITION_LOOKUP 
--

CREATE TABLE chain.MESSAGE_DEFINITION_LOOKUP(
    MESSAGE_DEFINITION_ID    NUMBER(10, 0)    NOT NULL,
    PRIMARY_LOOKUP_ID        NUMBER(10, 0)    NOT NULL,
    SECONDARY_LOOKUP_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_MSG_DFN_LOOKUP PRIMARY KEY (MESSAGE_DEFINITION_ID)
)
;



-- 
-- TABLE: MESSAGE_PARAM 
--

CREATE TABLE chain.MESSAGE_PARAM(
    APP_SID                  NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    MESSAGE_DEFINITION_ID    NUMBER(10, 0)     NOT NULL,
    PARAM_NAME               VARCHAR2(255)     NOT NULL,
    VALUE                    VARCHAR2(1000),
    HREF                     VARCHAR2(1000),
    CSS_CLASS                VARCHAR2(255),
    CONSTRAINT PK247_1 PRIMARY KEY (APP_SID, MESSAGE_DEFINITION_ID, PARAM_NAME)
)
;



-- 
-- TABLE: MESSAGE_PRIORITY 
--

CREATE TABLE chain.MESSAGE_PRIORITY(
    MESSAGE_PRIORITY_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION            VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK244 PRIMARY KEY (MESSAGE_PRIORITY_ID)
)
;



-- 
-- TABLE: MESSAGE_RECIPIENT 
--

CREATE TABLE chain.MESSAGE_RECIPIENT(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    MESSAGE_ID      NUMBER(10, 0)    NOT NULL,
    RECIPIENT_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK306 PRIMARY KEY (APP_SID, MESSAGE_ID, RECIPIENT_ID)
)
;



-- 
-- TABLE: MESSAGE_REFRESH_LOG 
--

CREATE TABLE chain.MESSAGE_REFRESH_LOG(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    MESSAGE_ID             NUMBER(10, 0)    NOT NULL,
    REFRESH_INDEX          NUMBER(10, 0)    NOT NULL,
    REFRESH_DTM            TIMESTAMP(6)     DEFAULT SYSDATE NOT NULL,
    REFRESH_USER_SID       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CONSTRAINT PK315 PRIMARY KEY (APP_SID, MESSAGE_ID, REFRESH_INDEX)
)
;



-- 
-- TABLE: RECIPIENT 
--

CREATE TABLE chain.RECIPIENT(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    RECIPIENT_ID      NUMBER(10, 0)    NOT NULL,
    TO_COMPANY_SID    NUMBER(10, 0),
    TO_USER_SID       NUMBER(10, 0),
    CONSTRAINT CHK_RECIPIENT_HAS_VALUE CHECK (to_company_sid IS NOT NULL OR to_user_sid IS NOT NULL),
    CONSTRAINT PK249 PRIMARY KEY (APP_SID, RECIPIENT_ID)
)
;



-- 
-- TABLE: REPEAT_TYPE 
--

CREATE TABLE chain.REPEAT_TYPE(
    REPEAT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION       VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK256_1 PRIMARY KEY (REPEAT_TYPE_ID)
)
;



-- 
-- TABLE: TEMP_MESSAGE_MAP 
--

CREATE TABLE chain.TEMP_MESSAGE_MAP(
    MESSAGE_DEFINITION_ID    NUMBER(10, 0)     NOT NULL,
    MESSAGE_TEMPLATE         VARCHAR2(4000)    NOT NULL,
    ACTION_TYPE_ID           NUMBER(10, 0),
    EVENT_TYPE_ID            NUMBER(10, 0),
    MAPPING_DONE             NUMBER(10, 0),
    CONSTRAINT PK_TMP_MSG_MAP PRIMARY KEY (MESSAGE_DEFINITION_ID)
)
;



-- 
-- TABLE: USER_MESSAGE_LOG 
--

CREATE TABLE chain.USER_MESSAGE_LOG(
    APP_SID       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    USER_SID      NUMBER(10, 0)    NOT NULL,
    MESSAGE_ID    NUMBER(10, 0)    NOT NULL,
    VIEWED_DTM    TIMESTAMP(6),
    CONSTRAINT PK252 PRIMARY KEY (APP_SID, USER_SID, MESSAGE_ID)
)
;



-- 
-- INDEX: UNIQUE_PARAM 
--

CREATE UNIQUE INDEX chain.UNIQUE_PARAM ON chain.DEFAULT_MESSAGE_PARAM(MESSAGE_DEFINITION_ID, LOWER_PARAM_NAME)
;
-- 
-- INDEX: UNIQUE_LOOKUP_IDS 
--

CREATE UNIQUE INDEX chain.UNIQUE_LOOKUP_IDS ON chain.MESSAGE_DEFINITION_LOOKUP(PRIMARY_LOOKUP_ID, SECONDARY_LOOKUP_ID)
;
-- 
-- TABLE: DEFAULT_MESSAGE_DEFINITION 
--

ALTER TABLE chain.DEFAULT_MESSAGE_DEFINITION ADD CONSTRAINT RefADDRESSING_TYPE619 
    FOREIGN KEY (ADDRESSING_TYPE_ID)
    REFERENCES chain.ADDRESSING_TYPE(ADDRESSING_TYPE_ID)
;

ALTER TABLE chain.DEFAULT_MESSAGE_DEFINITION ADD CONSTRAINT RefMESSAGE_PRIORITY620 
    FOREIGN KEY (MESSAGE_PRIORITY_ID)
    REFERENCES chain.MESSAGE_PRIORITY(MESSAGE_PRIORITY_ID)
;

ALTER TABLE chain.DEFAULT_MESSAGE_DEFINITION ADD CONSTRAINT RefREPEAT_TYPE653 
    FOREIGN KEY (REPEAT_TYPE_ID)
    REFERENCES chain.REPEAT_TYPE(REPEAT_TYPE_ID)
;

ALTER TABLE chain.DEFAULT_MESSAGE_DEFINITION ADD CONSTRAINT RefCOMPLETION_TYPE703 
    FOREIGN KEY (COMPLETION_TYPE_ID)
    REFERENCES chain.COMPLETION_TYPE(COMPLETION_TYPE_ID)
;

ALTER TABLE chain.DEFAULT_MESSAGE_DEFINITION ADD CONSTRAINT RefMESSAGE_DEFINITION_LOOKU705 
    FOREIGN KEY (MESSAGE_DEFINITION_ID)
    REFERENCES chain.MESSAGE_DEFINITION_LOOKUP(MESSAGE_DEFINITION_ID)
;


-- 
-- TABLE: DEFAULT_MESSAGE_PARAM 
--

ALTER TABLE chain.DEFAULT_MESSAGE_PARAM ADD CONSTRAINT RefDEFAULT_MESSAGE_DEFINITI627 
    FOREIGN KEY (MESSAGE_DEFINITION_ID)
    REFERENCES chain.DEFAULT_MESSAGE_DEFINITION(MESSAGE_DEFINITION_ID)
;


-- 
-- TABLE: MESSAGE 
--

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefCUSTOMER_OPTIONS626 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefDEFAULT_MESSAGE_DEFINITI630 
    FOREIGN KEY (MESSAGE_DEFINITION_ID)
    REFERENCES chain.DEFAULT_MESSAGE_DEFINITION(MESSAGE_DEFINITION_ID)
;

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefCOMPANY632 
    FOREIGN KEY (APP_SID, RE_COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefCHAIN_USER634 
    FOREIGN KEY (APP_SID, RE_USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefQUESTIONNAIRE_TYPE707 
    FOREIGN KEY (APP_SID, RE_QUESTIONNAIRE_TYPE_ID)
    REFERENCES chain.QUESTIONNAIRE_TYPE(APP_SID, QUESTIONNAIRE_TYPE_ID)
;

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefCOMPONENT712 
    FOREIGN KEY (APP_SID, RE_COMPONENT_ID)
    REFERENCES chain.COMPONENT(APP_SID, COMPONENT_ID)
;

ALTER TABLE chain.MESSAGE ADD CONSTRAINT RefCHAIN_USER774 
    FOREIGN KEY (APP_SID, COMPLETED_BY_USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;


-- 
-- TABLE: MESSAGE_DEFINITION 
--

ALTER TABLE chain.MESSAGE_DEFINITION ADD CONSTRAINT RefDEFAULT_MESSAGE_DEFINITI617 
    FOREIGN KEY (MESSAGE_DEFINITION_ID)
    REFERENCES chain.DEFAULT_MESSAGE_DEFINITION(MESSAGE_DEFINITION_ID)
;

ALTER TABLE chain.MESSAGE_DEFINITION ADD CONSTRAINT RefCUSTOMER_OPTIONS618 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.MESSAGE_DEFINITION ADD CONSTRAINT RefMESSAGE_PRIORITY621 
    FOREIGN KEY (MESSAGE_PRIORITY_ID)
    REFERENCES chain.MESSAGE_PRIORITY(MESSAGE_PRIORITY_ID)
;


-- 
-- TABLE: MESSAGE_PARAM 
--

ALTER TABLE chain.MESSAGE_PARAM ADD CONSTRAINT RefCUSTOMER_OPTIONS628 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.MESSAGE_PARAM ADD CONSTRAINT RefMESSAGE_DEFINITION629 
    FOREIGN KEY (APP_SID, MESSAGE_DEFINITION_ID)
    REFERENCES chain.MESSAGE_DEFINITION(APP_SID, MESSAGE_DEFINITION_ID)
;

ALTER TABLE chain.MESSAGE_PARAM ADD CONSTRAINT RefDEFAULT_MESSAGE_PARAM631 
    FOREIGN KEY (MESSAGE_DEFINITION_ID, PARAM_NAME)
    REFERENCES chain.DEFAULT_MESSAGE_PARAM(MESSAGE_DEFINITION_ID, PARAM_NAME)
;


-- 
-- TABLE: MESSAGE_RECIPIENT 
--

ALTER TABLE chain.MESSAGE_RECIPIENT ADD CONSTRAINT RefRECIPIENT775 
    FOREIGN KEY (APP_SID, RECIPIENT_ID)
    REFERENCES chain.RECIPIENT(APP_SID, RECIPIENT_ID)
;

ALTER TABLE chain.MESSAGE_RECIPIENT ADD CONSTRAINT RefMESSAGE776 
    FOREIGN KEY (APP_SID, MESSAGE_ID)
    REFERENCES chain.MESSAGE(APP_SID, MESSAGE_ID)
;


-- 
-- TABLE: MESSAGE_REFRESH_LOG 
--

ALTER TABLE chain.MESSAGE_REFRESH_LOG ADD CONSTRAINT RefCHAIN_USER803 
    FOREIGN KEY (APP_SID, REFRESH_USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE chain.MESSAGE_REFRESH_LOG ADD CONSTRAINT RefMESSAGE804 
    FOREIGN KEY (APP_SID, MESSAGE_ID)
    REFERENCES chain.MESSAGE(APP_SID, MESSAGE_ID)
;

-- 
-- TABLE: RECIPIENT 
--

ALTER TABLE chain.RECIPIENT ADD CONSTRAINT RefCUSTOMER_OPTIONS638 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.RECIPIENT ADD CONSTRAINT RefCHAIN_USER639 
    FOREIGN KEY (APP_SID, TO_USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE chain.RECIPIENT ADD CONSTRAINT RefCOMPANY640 
    FOREIGN KEY (APP_SID, TO_COMPANY_SID)
    REFERENCES chain.COMPANY(APP_SID, COMPANY_SID)
;


-- 
-- TABLE: TEMP_MESSAGE_MAP 
--

ALTER TABLE chain.TEMP_MESSAGE_MAP ADD CONSTRAINT RefDEFAULT_MESSAGE_DEFINITI693 
    FOREIGN KEY (MESSAGE_DEFINITION_ID)
    REFERENCES chain.DEFAULT_MESSAGE_DEFINITION(MESSAGE_DEFINITION_ID)
;


-- 
-- TABLE: USER_MESSAGE_LOG 
--

ALTER TABLE chain.USER_MESSAGE_LOG ADD CONSTRAINT RefMESSAGE795 
    FOREIGN KEY (APP_SID, MESSAGE_ID)
    REFERENCES chain.MESSAGE(APP_SID, MESSAGE_ID)
;

ALTER TABLE chain.USER_MESSAGE_LOG ADD CONSTRAINT RefCHAIN_USER796 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;




CREATE GLOBAL TEMPORARY TABLE chain.TT_MESSAGE_SEARCH
(
	MESSAGE_ID                  NUMBER(10)    NOT NULL,
	MESSAGE_DEFINITION_ID       NUMBER(10)    NOT NULL,
	TO_COMPANY_SID				NUMBER(10),
	TO_USER_SID					NUMBER(10),
	RE_COMPANY_SID              NUMBER(10),
	RE_USER_SID                 NUMBER(10),
	RE_QUESTIONNAIRE_TYPE_ID    NUMBER(10),
	RE_COMPONENT_ID             NUMBER(10),
	ORDER_BY_DTM				TIMESTAMP,
	LAST_REFRESHED_BY_USER_SID  NUMBER(10),
	COMPLETED_BY_USER_SID       NUMBER(10),
	VIEWED_DTM					TIMESTAMP
)
ON COMMIT DELETE ROWS;



CREATE OR REPLACE VIEW chain.v$message_definition AS
	SELECT dmd.message_definition_id,  
	       NVL(md.message_template, dmd.message_template) message_template,
	       NVL(md.message_priority_id, dmd.message_priority_id) message_priority_id,
	       dmd.repeat_type_id,
	       dmd.addressing_type_id,
	       dmd.completion_type_id,
	       NVL(md.completed_template, dmd.completed_template) completed_template,
	       NVL(md.helper_pkg, dmd.helper_pkg) helper_pkg,
	       NVL(md.css_class, dmd.css_class) css_class
	  FROM default_message_definition dmd, (
	          SELECT *
	            FROM message_definition
	           WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	       ) md
	 WHERE dmd.message_definition_id = md.message_definition_id(+)
;

CREATE OR REPLACE VIEW chain.v$message_param AS
	SELECT dmp.message_definition_id,  
		   dmp.param_name,
		   NVL(mp.value, dmp.value) value,
		   NVL(mp.href, dmp.href) href,
		   NVL(mp.css_class, dmp.css_class) css_class
	  FROM default_message_param dmp, (
	  		SELECT * 
	  		  FROM message_param 
	  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   ) mp
	 WHERE dmp.message_definition_id = mp.message_definition_id(+)
	   AND dmp.param_name = mp.param_name(+)
;

CREATE OR REPLACE VIEW chain.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id,
			m.due_dtm, m.completed_dtm, m.completed_by_user_sid,
			mrl0.refresh_dtm created_dtm, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message m, message_refresh_log mrl0, message_refresh_log mrl
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = mrl0.app_sid
	   AND m.app_sid = mrl.app_sid
	   AND m.message_id = mrl0.message_id
	   AND m.message_id = mrl.message_id
	   AND mrl0.refresh_index = 0
	   AND (mrl.app_sid, mrl.message_id, mrl.refresh_index) IN (
				SELECT app_sid, message_id, MAX(refresh_index)
				  FROM message_refresh_log 
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 GROUP BY app_sid, message_id
  		)
;

CREATE OR REPLACE VIEW chain.v$message_recipient AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, m.completed_dtm,
			m.completed_by_user_sid, r.recipient_id, r.to_company_sid, r.to_user_sid, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message_recipient mr, message m, recipient r, message_refresh_log mrl
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.app_sid = m.app_sid
	   AND mr.app_sid = r.app_sid
	   AND mr.app_sid = mrl.app_sid
	   AND mr.message_id = m.message_id
	   AND mr.message_id = mrl.message_id
	   AND mr.recipient_id = r.recipient_id
	   AND (mrl.app_sid, mrl.message_id, mrl.refresh_index) IN (
			SELECT app_sid, message_id, MAX(refresh_index)
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY app_sid, message_id
  		)
;


/***********************************************************/
-- no change here - just needs to be recompiled
CREATE OR REPLACE VIEW chain.v$company AS
	SELECT c.*, cou.name country_name
	  FROM company c, v$country cou
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.country_code = cou.country_code(+)
	   AND c.deleted = 0
;
/***********************************************************/

DROP PACKAGE chain.action_pkg;
DROP PACKAGE chain.event_pkg;

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MISC VIEWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$country - a dummy country lookup
***********************************************************************/
PROMPT >> Creating v$country

CREATE OR REPLACE VIEW chain.v$country AS
	SELECT country country_code, name
	  FROM postcode.country
	 WHERE latitude IS NOT NULL AND longitude IS NOT NULL
;

/***********************************************************************
	v$active_invite
***********************************************************************/
PROMPT >> Creating v$active_invite

CREATE OR REPLACE VIEW chain.v$active_invite AS
	SELECT *
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id = 1
;

/***********************************************************************
	v$chain_host - gives the app_sid, host and chain implmentation
***********************************************************************/
PROMPT >> Creating v$chain_host
CREATE OR REPLACE VIEW chain.v$chain_host AS
	SELECT c.app_sid, c.host, co.chain_implementation
	  FROM csr.customer c, customer_options co
	 WHERE c.app_sid = co.app_sid
;

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COMPANY RELATIONSHIPS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$supplier_relationship - a view of all active supplier relationships

***********************************************************************/
PROMPT >> Creating v$supplier_relationship

CREATE OR REPLACE VIEW chain.v$supplier_relationship AS
	SELECT *
	  FROM supplier_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
-- either the relationship is active, or it is virtually active for a very short period so that we can send invitations
	   AND (active = 1 OR SYSDATE < virtually_active_until_dtm)
;


/***********************************************************************
	v$company_relationship - a view of all companies that I
	am in a relationship with, whether it be as a purchaser or a supplier 
***********************************************************************/
PROMPT >> Creating v$company_relationship

CREATE OR REPLACE VIEW chain.v$company_relationship AS
	SELECT UNIQUE app_sid, company_sid
	  FROM (  
			SELECT app_sid, purchaser_company_sid company_sid 
			  FROM v$supplier_relationship 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			 UNION ALL
			SELECT app_sid,  supplier_company_sid company_sid 
			  FROM v$supplier_relationship 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			)
	 WHERE company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
;
 
 

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COMPANY AND USER VIEWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$company = all companies that have not been flagged as deleted
***********************************************************************/
PROMPT >> Creating v$company

CREATE OR REPLACE VIEW chain.v$company AS
	SELECT c.*, cou.name country_name
	  FROM company c, v$country cou
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.country_code = cou.country_code(+)
	   AND c.deleted = 0
;


/***********************************************************************
	v$chain_user - a combined view of csr_user and chain_user
	with defaults set where the entry does not exist in chain_user
***********************************************************************/
PROMPT >> Creating v$chain_user

CREATE OR REPLACE VIEW chain.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email,                    -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title,   -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								-- CHAIN_USER data
		   cu.next_scheduled_alert_dtm, cu.receive_scheduled_alerts, cu.details_confirmed
	  FROM csr.csr_user csru, chain_user cu
	 WHERE csru.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;


/***********************************************************************
	v$company_user_group - a simple view of app_sid, company_sid, 
	user_group_sid
***********************************************************************/
PROMPT >> Creating v$company_user_group

CREATE OR REPLACE VIEW chain.v$company_user_group AS
	SELECT c.app_sid, c.company_sid, so.sid_id user_group_sid
	  FROM security.securable_object so, company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = so.application_sid_id
	   AND so.parent_sid_id = c.company_sid
	   AND so.name = 'Users'
;   


/***********************************************************************
	v$company_pending_group - a simple view of app_sid, company_sid, 
	pending_group_sid
***********************************************************************/
PROMPT >> Creating v$company_pending_group

CREATE OR REPLACE VIEW chain.v$company_pending_group AS
	SELECT c.app_sid, c.company_sid, so.sid_id pending_group_sid
	  FROM security.securable_object so, company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = so.application_sid_id
	   AND so.parent_sid_id = c.company_sid
	   AND so.name = 'Pending Users'
;   


/***********************************************************************
	v$company_admin_group - a simple view of app_sid, company_sid, 
	admin_group_sid
***********************************************************************/
PROMPT >> Creating v$company_admin_group

CREATE OR REPLACE VIEW chain.v$company_admin_group AS
	SELECT c.app_sid, c.company_sid, so.sid_id admin_group_sid
	  FROM security.securable_object so, company c
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND c.app_sid = so.application_sid_id
	   AND so.parent_sid_id = c.company_sid
	   AND so.name = 'Administrators'
;   


/***********************************************************************
	v$company_user - a simple view of all direct users for all companies
	app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_user

CREATE OR REPLACE VIEW chain.v$company_user AS
  SELECT cug.app_sid, cug.company_sid, vcu.user_sid
    FROM v$company_user_group cug, v$chain_user vcu, security.group_members gm
   WHERE cug.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cug.app_sid = vcu.app_sid
     AND cug.user_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_pending_user - a simple view of all direct pending users 
	for all companies - app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_pending_user

CREATE OR REPLACE VIEW chain.v$company_pending_user AS        
  SELECT cpg.app_sid, cpg.company_sid, vcu.user_sid
    FROM v$company_pending_group cpg, v$chain_user vcu, security.group_members gm
   WHERE cpg.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cpg.app_sid = vcu.app_sid
     AND cpg.pending_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_admin - a simple view of all direct admins for all companies
	app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_admin

CREATE OR REPLACE VIEW chain.v$company_admin AS
  SELECT cag.app_sid, cag.company_sid, vcu.user_sid
    FROM v$company_admin_group cag, v$chain_user vcu, security.group_members gm
   WHERE cag.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND cag.app_sid = vcu.app_sid
     AND cag.admin_group_sid = gm.group_sid_id
     AND vcu.user_sid = gm.member_sid_id
;


/***********************************************************************
	v$company_member - a simple view of all direct amdmin, user and pending users
	for all companies - app_sid, company_sid, user_sid
***********************************************************************/
PROMPT >> Creating v$company_member

CREATE OR REPLACE VIEW chain.v$company_member AS        
	SELECT DISTINCT app_sid, company_sid, user_sid
	  FROM (
		SELECT app_sid, company_sid, user_sid
		  FROM v$company_admin
		 UNION ALL
		SELECT app_sid, company_sid, user_sid
		  FROM v$company_user
		 UNION ALL
		SELECT app_sid, company_sid, user_sid
		  FROM v$company_pending_user
			)
;


/***********************************************************************
	v$chain_company_user - a view which restricts which system users 
	the currently logged in user is allowed to see.
	
	The view follows four "I am allowed to see" rules:
	
	1. the details of any user that my company currently has an "active invitation" with
	2. all details of all users of my company
	3. all details of all administrators of my company
	4. the details of users of my existing supplier AND purchaser companies
		who have chosen to share details with users of other companies
		
	Where applicable, the rules of the "visibility" table are implemented.
***********************************************************************/
PROMPT >> Creating v$chain_company_user

CREATE OR REPLACE VIEW chain.v$chain_company_user AS
	/**********************************************************************************************************/
	/****************** any invitations from someone in my company to a user in my company  *******************/
	/**********************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid = vai.from_company_sid -- an invitation to ourselves
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************************/
	/****************** I can see all of my users *******************/
	/****************************************************************/
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, vcu.email, 
	       vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$chain_user vcu, v$company_user cu
	 WHERE vcu.app_sid = cu.app_sid
	   AND vcu.user_sid = cu.user_sid
	   AND cu.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (cu.company_sid, vcu.user_sid) NOT IN (
	   		SELECT to_company_sid, to_user_sid
	   		  FROM v$active_invite
	   		 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   		   AND to_company_sid = from_company_sid
	   	   )
	 UNION ALL
	/*****************************************************************/
	/****************** I can see all of my admins *******************/
	/*****************************************************************/
	SELECT ca.app_sid, ca.company_sid, vcu.user_sid, vcu.visibility_id, 
	       vcu.email, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title
	  FROM v$chain_user vcu, v$company_admin ca
	 WHERE vcu.app_sid = ca.app_sid
	   AND vcu.user_sid = ca.user_sid
	   AND ca.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND (ca.company_sid, vcu.user_sid) NOT IN (
			SELECT to_company_sid, to_user_sid
			  FROM v$active_invite
			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND to_company_sid = from_company_sid
	   	   )
	 UNION 
	/***************************************************************************************************************/
	/****************** any invitations from someone in my company to someone in another company *******************/
	/***************************************************************************************************************/
	SELECT vai.app_sid, vai.to_company_sid company_sid, vcu.user_sid, vcu.visibility_id,
			vcu.email, vcu.full_name, vcu.friendly_name, -- we can always see these if there's a pending invitation as we've probably filled it in ourselves
			CASE WHEN vcu.visibility_id = 3 THEN vcu.phone_number ELSE NULL END phone_number, 
			CASE WHEN vcu.visibility_id >= 1 THEN vcu.job_title ELSE NULL END job_title			
	  FROM v$active_invite vai, v$chain_user vcu
	 WHERE vai.app_sid = vcu.app_sid
	   AND vai.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND vai.to_company_sid <> vai.from_company_sid -- not an invitation to ourselves (handled above)
	   AND vai.to_user_sid = vcu.user_sid
	 UNION ALL
	/****************************************************/
	/****************** everyone else *******************/
	/****************************************************/
	SELECT cu.app_sid, cu.company_sid, vcu.user_sid, vcu.visibility_id, 
			CASE WHEN vcu.visibility_id = 3 THEN vcu.email ELSE NULL END email, 
			CASE WHEN vcu.visibility_id >= 2 THEN vcu.full_name ELSE NULL END full_name, 
			CASE WHEN vcu.visibility_id >= 2 THEN vcu.friendly_name ELSE NULL END friendly_name, 
			CASE WHEN vcu.visibility_id = 3 THEN vcu.phone_number ELSE NULL END phone_number, 
			vcu.job_title -- we always see this as we've filtered 'hidden' users
	  FROM v$chain_user vcu, v$company_user cu, v$company_relationship cr
	 WHERE vcu.app_sid = cu.app_sid
	   AND vcu.app_sid = cr.app_sid
	   AND vcu.user_sid = cu.user_sid
	   AND cu.company_sid = cr.company_sid -- we can see companies that we are in a relationship with
	   AND vcu.visibility_id <> 0 -- don't show hidden users
	   AND NOT (vcu.visibility_id = 1 AND vcu.job_title IS NULL)
	   AND (cu.company_sid, cu.user_sid) NOT IN (					-- minus any active questionnaire invitations as these have already been dealt with
	   			SELECT to_company_sid, to_user_sid 
	   			  FROM v$active_invite
	   			 WHERE from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   )
;


/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
MESSAGING
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$event = all event's with all join data (users, companies, questionnaires) needed
***********************************************************************/
PROMPT >> Creating v$event

CREATE OR REPLACE VIEW chain.v$event AS
	SELECT 
		e.app_sid,
		-- for company
		for_company_sid, c1.name for_company_name, et.for_company_url,
		-- for user
		for_user_sid, cu1.full_name for_user_full_name, cu1.friendly_name for_user_friendly_name, et.for_user_url,
		-- related company
		related_company_sid, c2.name related_company_name, et.related_company_url,
		-- related user
		related_user_sid, cu2.full_name related_user_full_name, cu2.friendly_name related_user_friendly_name, et.related_user_url,
		-- related questionnaire
		related_questionnaire_id, q.name related_questionnaire_name, et.related_questionnaire_url,
		-- other data
		e.event_id, e.created_dtm, 
		et.other_url_1, et.other_url_2, et.other_url_3, 
		-- event type
		et.event_type_id, message_template, priority,
		-- who is the event for
		NVL2(for_user_sid, cu1.full_name, c1.name) for_whom,
		NVL2(for_user_sid, 1, 0) is_for_user,
		css_class
	FROM 
		event e, event_type et, 
		csr.csr_user cu1, csr.csr_user cu2, 
		company c1, company c2,
		(
			SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, qt.name
			  FROM questionnaire q, questionnaire_type qt 
			 WHERE q.app_sid = qt.app_sid
			   AND q.questionnaire_type_id = qt.questionnaire_type_id
		) q
	WHERE e.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), e.app_sid)
	  --
	  AND e.app_sid = et.app_sid
	  AND e.event_type_id = et.event_type_id
	  --
	  AND e.app_sid = c1.app_sid
	  AND e.for_company_sid = c1.company_sid
	  --
	  AND e.app_sid = c2.app_sid(+)
	  AND e.related_company_sid = c2.company_sid(+)
	  --
	  AND e.app_sid = cu1.app_sid(+)
	  AND e.for_user_sid = cu1.csr_user_sid(+)
	  --
	  AND e.app_sid = cu2.app_sid(+)
	  AND e.related_user_sid = cu2.csr_user_sid(+)
	  --
	  AND e.app_sid = q.app_sid(+)
	  AND e.related_questionnaire_id = q.questionnaire_id(+)
;

/***********************************************************************
	v$action = all actions with all join data (users, companies, questionnaires) needed
***********************************************************************/
PROMPT >> Creating v$action

CREATE OR REPLACE VIEW chain.v$action AS
	SELECT
		a.app_sid,
		-- for company
		for_company_sid, c1.name for_company_name, at.for_company_url,
		-- for user
		for_user_sid, cu1.full_name for_user_full_name, cu1.friendly_name for_user_friendly_name, at.for_user_url,
		-- related company
		related_company_sid, c2.name related_company_name, at.related_company_url,
		-- related user
		related_user_sid, cu2.full_name related_user_full_name, cu2.friendly_name related_user_friendly_name, at.related_user_url,
		-- related questionnaire
		related_questionnaire_id, q.name related_questionnaire_name, 
		REPLACE(
			REPLACE(at.related_questionnaire_url,'{viewQuestionnaireUrl}',q.view_url), 
			'{editQuestionnaireUrl}', q.edit_url
		) related_questionnaire_url,
		-- other data
		action_id, A.created_dtm, due_date, is_complete, completion_dtm,
		at.other_url_1, at.other_url_2, at.other_url_3,
		-- reason for action
		ra.reason_for_action_id, reason_name reason_for_action_name, reason_description reason_for_action_description,
		-- to do - fill this in later
		-- action type
		at.action_type_id, message_template, priority,
		-- who is the action for
		NVL2(for_user_sid, cu1.full_name, c1.name) for_whom,
		NVL2(for_user_sid, 1, 0) is_for_user,
		css_class
	  FROM
		action a, action_type at, reason_for_action ra,
		csr.csr_user cu1, csr.csr_user cu2,
		company c1, company c2,
		(
			  SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, qt.name, qt.view_url, qt.edit_url
				FROM questionnaire q, questionnaire_type qt
			   WHERE q.app_sid = qt.app_sid
			     AND q.questionnaire_type_id = qt.questionnaire_type_id
		) q
	 WHERE a.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), a.app_sid)
	   --
	   AND a.app_sid = at.app_sid
	   AND ra.action_type_id = at.action_type_id
	   --
	   AND a.app_sid = ra.app_sid
	   AND a.reason_for_action_id = ra.reason_for_action_id
	   --
	   AND a.app_sid = c1.app_sid
	   AND a.for_company_sid = c1.company_sid
	   --	   
	   AND a.app_sid = c2.app_sid(+)
	   AND a.related_company_sid = c2.company_sid(+)
	   --
	   AND a.app_sid = cu1.app_sid(+)
	   AND a.for_user_sid = cu1.csr_user_sid(+)
	   --
	   AND a.app_sid = cu2.app_sid(+)
	   AND a.related_user_sid = cu2.csr_user_sid(+)
	   --
	   AND a.app_sid = q.app_sid(+)
	   AND a.related_questionnaire_id = q.questionnaire_id(+)
;

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
CAPABILITIES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$capability
***********************************************************************/
PROMPT >> Creating v$capability

CREATE OR REPLACE VIEW chain.v$capability AS
	SELECT capability_id, capability_name, perm_type, capability_type_id
	  FROM capability
	 WHERE app_sid IS NULL
	    OR app_sid = SYS_CONTEXT('SECURITY', 'APP')
;
	    
/***********************************************************************
	v$group_capability_permission
***********************************************************************/
PROMPT >> Creating v$group_capability_permission

CREATE OR REPLACE VIEW chain.v$group_capability_permission AS
	SELECT gc.group_capability_id, gc.company_group_name, gc.capability_id, ps.permission_set
	  FROM group_capability gc, (
			SELECT group_capability_id, 0 hide_group_capability, permission_set
			  FROM group_capability_perm
			 WHERE group_capability_id NOT IN (
					SELECT group_capability_id
					  FROM group_capability_override
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				)
			UNION ALL
			SELECT group_capability_id, hide_group_capability, permission_set_override permission_set
			  FROM group_capability_override
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			) ps
	 WHERE ps.hide_group_capability = 0
	   AND ps.group_capability_id = gc.group_capability_id
;
	  

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
COMPONENTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$ccomponent_type - all activated components types in the application
***********************************************************************/
PROMPT >> Creating v$component_type
CREATE OR REPLACE VIEW chain.v$component_type AS
	SELECT ct.app_sid, act.component_type_id, act.handler_class, act.handler_pkg, 
			act.node_js_path, act.description, act.editor_card_group_id
	  FROM component_type ct, all_component_type act
	 WHERE ct.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ct.component_type_id = act.component_type_id
;


/***********************************************************************
	v$ccomponent - all components with component type id folded in
***********************************************************************/
PROMPT >> Creating v$component
CREATE OR REPLACE VIEW chain.v$component AS
	SELECT cmp.app_sid, cmp.component_id, ctb.component_type_id, 
			cmp.description, cmp.component_code, cmp.deleted,
			ctb.company_sid, cmp.created_by_sid, cmp.created_dtm
	  FROM component cmp, component_bind ctb
	 WHERE cmp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cmp.app_sid = ctb.app_sid
	   AND cmp.component_id = ctb.component_id
;

/***********************************************************************
	v$product - all products bound with underlying component 
***********************************************************************/
PROMPT >> Creating v$product
CREATE OR REPLACE VIEW chain.v$product AS
	SELECT cmp.app_sid, p.product_id, p.pseudo_root_component_id, 
			p.active, cmp.component_code code1, p.code2, p.code3, p.need_review,
			cmp.description, cmp.component_code, cmp.deleted,
			p.company_sid, cmp.created_by_sid, cmp.created_dtm
	  FROM product p, component cmp
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.app_sid = cmp.app_sid
	   AND p.product_id = cmp.component_id
;

/***********************************************************************
	v$purchased_componet - all purchased components bound with underlying component 
***********************************************************************/
PROMPT >> Creating v$purchased_component

CREATE OR REPLACE VIEW chain.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp.country_name supplier_country_name, 
			pc.purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur.country_name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id
	  FROM purchased_component pc, component cmp, v$company supp, v$company pur, uninvited_supplier unv
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = cmp.app_sid
	   AND pc.component_id = cmp.component_id
	   AND pc.supplier_company_sid = supp.company_sid(+)
	   AND pc.purchaser_company_sid = pur.company_sid(+)
	   AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid(+)
;

/***********************************************************************
	v$purchased_component_supplier - purchased component -> supplier data 
***********************************************************************/
PROMPT >> Creating v$purchased_component_supplier
CREATE OR REPLACE VIEW chain.v$purchased_component_supplier AS
	--
	--SUPPLIER_NOT_SET (basic data, nulled supplier data)
	--
	SELECT app_sid, component_id, component_supplier_type_id, 
			NULL supplier_company_sid, NULL uninvited_supplier_sid, 
			NULL supplier_name, NULL supplier_country_code, NULL supplier_country_name
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_supplier_type_id = 0 -- SUPPLIER_NOT_SET
	--
	 UNION
	--
	--EXISTING_SUPPLIER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 1 -- EXISTING_SUPPLIER
	   AND pc.supplier_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--EXISTING_PURCHASER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.purchaser_company_sid supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 2 -- EXISTING_PURCHASER
	   AND pc.purchaser_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--UNINVITED_SUPPLIER (basic data, uninvited supplier data bound)
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			NULL supplier_company_sid, us.uninvited_supplier_sid, 
			us.name supplier_name, us.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, uninvited_supplier us, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = us.app_sid
	   AND pc.component_supplier_type_id = 3 -- UNINVITED_SUPPLIER
	   AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
	   AND us.country_code = coun.country_code
;

/***********************************************************************
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
QUESTIONNAIRES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
***********************************************************************/

/***********************************************************************
	v$questionnaire_status_log - a view of all questionnaire status log entries in an app
***********************************************************************/
PROMPT >> Creating v$questionnaire_status_log

CREATE OR REPLACE VIEW chain.v$questionnaire_status_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, qsle.status_log_entry_index, 
  		 qsle.entry_dtm, qsle.questionnaire_status_id, qs.description status_description, qsle.user_sid entry_by_user_sid, qsle.user_notes user_entry_notes
    FROM questionnaire q, qnr_status_log_entry qsle, questionnaire_status qs
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qsle.app_sid
     AND q.questionnaire_id = qsle.questionnaire_id
     AND qs.questionnaire_status_id = qsle.questionnaire_status_id
   ORDER BY q.questionnaire_id, qsle.status_log_entry_index
;

/***********************************************************************
	v$questionnaire_share_log - a view of all questionnaire share log entries in an app
***********************************************************************/
PROMPT >> Creating v$questionnaire_share_log

CREATE OR REPLACE VIEW chain.v$questionnaire_share_log AS
  SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm,
         qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, qsle.share_status_id, 
         ss.description share_description, qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
    FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss
   WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
     AND q.app_sid = qs.app_sid
     AND q.app_sid = qsle.app_sid
     AND q.company_sid = qs.qnr_owner_company_sid
     AND q.questionnaire_id = qs.questionnaire_id
     AND qs.questionnaire_share_id = qsle.questionnaire_share_id
     AND qsle.share_status_id = ss.share_status_id
   ORDER BY q.questionnaire_id, qsle.share_log_entry_index
;

/***********************************************************************
	v$questionnaire - a view of all questionnaires with their current status ids exposed
***********************************************************************/
PROMPT >> Creating v$questionnaire

CREATE OR REPLACE VIEW chain.v$questionnaire AS
	SELECT q.app_sid, q.questionnaire_id, q.company_sid, q.questionnaire_type_id, q.created_dtm, 
		   qt.view_url, qt.edit_url, qt.owner_can_review, qt.class, qt.name, qt.db_class, qt.group_name, qt.position, 
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
			)
;

/***********************************************************************
	v$questionnaire_share - a view of all supplier questionnaires by current status
***********************************************************************/
PROMPT >> Creating v$questionnaire_share

CREATE OR REPLACE VIEW chain.v$questionnaire_share AS
	SELECT q.app_sid, q.questionnaire_id, q.questionnaire_type_id, q.created_dtm, qs.due_by_dtm, qs.overdue_events_sent,
		   qs.qnr_owner_company_sid, qs.share_with_company_sid, qsle.share_log_entry_index, qsle.entry_dtm, 
		   qs.questionnaire_share_id, qsle.share_status_id, ss.description share_status_name,
           qsle.company_sid entry_by_company_sid, qsle.user_sid entry_by_user_sid, qsle.user_notes
	  FROM questionnaire q, questionnaire_share qs, qnr_share_log_entry qsle, share_status ss
	 WHERE q.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND q.app_sid = qs.app_sid
	   AND q.app_sid = qsle.app_sid
	   AND q.company_sid = qs.qnr_owner_company_sid
	   AND (								-- allows builtin admin to see relationships as well for debugging purposes
	   			qs.share_with_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.share_with_company_sid)
	   		 OR qs.qnr_owner_company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), qs.qnr_owner_company_sid)
	   	   )
	   AND q.questionnaire_id = qs.questionnaire_id
	   AND qs.questionnaire_share_id = qsle.questionnaire_share_id
	   AND qsle.share_status_id = ss.share_status_id
	   AND (qsle.questionnaire_share_id, qsle.share_log_entry_index) IN (   
	   			SELECT questionnaire_share_id, MAX(share_log_entry_index)
	   			  FROM qnr_share_log_entry
	   			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   			 GROUP BY questionnaire_share_id
			)
;

/***********************************************************************
	v$card_manager - utility view to see which cards are used in each card manager
***********************************************************************/
CREATE OR REPLACE VIEW chain.v$card_manager AS
	SELECT cgc.app_sid, cg.card_group_id, cg.name card_group_name, c.js_class_type, c.class_type, cgc.position
	  FROM card_group cg, card_group_card cgc, card c
	 WHERE cgc.app_sid = NVL(SYS_CONTEXT('SECURITY', 'APP'), cgc.app_sid)
	   AND cgc.card_group_id = cg.card_group_id
	   AND cgc.card_id = c.card_id
	 ORDER BY cgc.card_group_id, cgc.app_sid, cgc.position
;





CREATE OR REPLACE VIEW chain.v$message_definition AS
	SELECT dmd.message_definition_id,  
	       NVL(md.message_template, dmd.message_template) message_template,
	       NVL(md.message_priority_id, dmd.message_priority_id) message_priority_id,
	       dmd.repeat_type_id,
	       dmd.addressing_type_id,
	       dmd.completion_type_id,
	       NVL(md.completed_template, dmd.completed_template) completed_template,
	       NVL(md.helper_pkg, dmd.helper_pkg) helper_pkg,
	       NVL(md.css_class, dmd.css_class) css_class
	  FROM default_message_definition dmd, (
	          SELECT *
	            FROM message_definition
	           WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	       ) md
	 WHERE dmd.message_definition_id = md.message_definition_id(+)
;

CREATE OR REPLACE VIEW chain.v$message_param AS
	SELECT dmp.message_definition_id,  
		   dmp.param_name,
		   NVL(mp.value, dmp.value) value,
		   NVL(mp.href, dmp.href) href,
		   NVL(mp.css_class, dmp.css_class) css_class
	  FROM default_message_param dmp, (
	  		SELECT * 
	  		  FROM message_param 
	  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  	   ) mp
	 WHERE dmp.message_definition_id = mp.message_definition_id(+)
	   AND dmp.param_name = mp.param_name(+)
;

CREATE OR REPLACE VIEW chain.v$message AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id,
			m.due_dtm, m.completed_dtm, m.completed_by_user_sid,
			mrl0.refresh_dtm created_dtm, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message m, message_refresh_log mrl0, message_refresh_log mrl
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.app_sid = mrl0.app_sid
	   AND m.app_sid = mrl.app_sid
	   AND m.message_id = mrl0.message_id
	   AND m.message_id = mrl.message_id
	   AND mrl0.refresh_index = 0
	   AND (mrl.app_sid, mrl.message_id, mrl.refresh_index) IN (
				SELECT app_sid, message_id, MAX(refresh_index)
				  FROM message_refresh_log 
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				 GROUP BY app_sid, message_id
  		)
;

CREATE OR REPLACE VIEW chain.v$message_recipient AS
	SELECT m.app_sid, m.message_id, m.message_definition_id, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, m.completed_dtm,
			m.completed_by_user_sid, r.recipient_id, r.to_company_sid, r.to_user_sid, mrl.refresh_dtm last_refreshed_dtm, mrl.refresh_user_sid last_refreshed_by_user_sid
	  FROM message_recipient mr, message m, recipient r, message_refresh_log mrl
	 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND mr.app_sid = m.app_sid
	   AND mr.app_sid = r.app_sid
	   AND mr.app_sid = mrl.app_sid
	   AND mr.message_id = m.message_id
	   AND mr.message_id = mrl.message_id
	   AND mr.recipient_id = r.recipient_id
	   AND (mrl.app_sid, mrl.message_id, mrl.refresh_index) IN (
			SELECT app_sid, message_id, MAX(refresh_index)
			  FROM message_refresh_log 
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 GROUP BY app_sid, message_id
  		)
;











	  CREATE OR REPLACE PACKAGE  chain.chain_pkg
IS

TYPE   T_STRINGS                	IS TABLE OF VARCHAR2(2000) INDEX BY PLS_INTEGER;

-- a general use code
UNDEFINED							CONSTANT NUMBER := 0;
HIDE_HELP_TEXT						CONSTANT VARCHAR2(1) := NULL;

SUBTYPE T_ACTIVE					IS NUMBER;
ACTIVE 								CONSTANT T_ACTIVE := 1;
INACTIVE 							CONSTANT T_ACTIVE := 0;

SUBTYPE T_DELETED					IS NUMBER;
DELETED 							CONSTANT T_DELETED := 1;
NOT_DELETED 						CONSTANT T_DELETED := 0;

INVERTED_CHECK						CONSTANT BOOLEAN := TRUE;
NORMAL_CHECK						CONSTANT BOOLEAN := FALSE;

SUBTYPE T_GROUP						IS VARCHAR2(100);
ADMIN_GROUP							CONSTANT T_GROUP := 'Administrators';
USER_GROUP							CONSTANT T_GROUP := 'Users';
PENDING_GROUP						CONSTANT T_GROUP := 'Pending Users';
CHAIN_ADMIN_GROUP					CONSTANT T_GROUP := 'Chain '||ADMIN_GROUP;
CHAIN_USER_GROUP					CONSTANT T_GROUP := 'Chain '||USER_GROUP;

COMPANY_UPLOADS						CONSTANT security.securable_object.name%TYPE := 'Uploads';
UNINVITED_SUPPLIERS					CONSTANT security.securable_object.name%TYPE := 'Uninvited Suppliers';

SUBTYPE T_CAPABILITY_PERM_TYPE		IS NUMBER(10);
SPECIFIC_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 0;
BOOLEAN_PERMISSION					CONSTANT T_CAPABILITY_PERM_TYPE := 1;

SUBTYPE T_CAPABILITY_TYPE			IS NUMBER(10);
CT_ROOT								CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMMON							CONSTANT T_CAPABILITY_TYPE := 0;
CT_COMPANY							CONSTANT T_CAPABILITY_TYPE := 1; 
CT_SUPPLIERS						CONSTANT T_CAPABILITY_TYPE := 2; 
CT_COMPANIES						CONSTANT T_CAPABILITY_TYPE := 3; -- both the CT_COMPANY and CT_SUPPLIERS nodes

/****************************************************************************************************/
SUBTYPE T_CAPABILITY				IS VARCHAR2(100);

-- treated as a either a COMPANY or SUPPLIER capability check depending on sid 
-- that is passed in with it compared with the company sid set in session
COMPANYorSUPPLIER					CONSTANT T_CAPABILITY := 'VIRTUAL.COMPANYorSUPPLIER';

/**** Root capabilities ****/
CAPABILITIES						CONSTANT T_CAPABILITY := 'Capabilities';
COMPANY								CONSTANT T_CAPABILITY := 'Company';
SUPPLIERS							CONSTANT T_CAPABILITY := 'Suppliers';

/**** Company/Suppliers nodes capabilities ****/
SPECIFY_USER_NAME					CONSTANT T_CAPABILITY := 'Specify user name';
QUESTIONNAIRE						CONSTANT T_CAPABILITY := 'Questionnaire';
SUBMIT_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Submit questionnaire';
SETUP_STUB_REGISTRATION				CONSTANT T_CAPABILITY := 'Setup stub registration';
RESET_PASSWORD						CONSTANT T_CAPABILITY := 'Reset password';
CREATE_USER							CONSTANT T_CAPABILITY := 'Create user';
EVENTS								CONSTANT T_CAPABILITY := 'Events';
ACTIONS								CONSTANT T_CAPABILITY := 'Actions';
TASKS								CONSTANT T_CAPABILITY := 'Tasks';
METRICS								CONSTANT T_CAPABILITY := 'Metrics';
PRODUCTS							CONSTANT T_CAPABILITY := 'Products';
COMPONENTS							CONSTANT T_CAPABILITY := 'Components';
PROMOTE_USER						CONSTANT T_CAPABILITY := 'Promote user';
PRODUCT_CODE_TYPES					CONSTANT T_CAPABILITY := 'Product code types';
UPLOADED_FILE						CONSTANT T_CAPABILITY := 'Uploaded file';

/**** Common capabilities ****/
IS_TOP_COMPANY						CONSTANT T_CAPABILITY := 'Is top company';
SEND_QUESTIONNAIRE_INVITE			CONSTANT T_CAPABILITY := 'Send questionnaire invitation';
SEND_NEWSFLASH						CONSTANT T_CAPABILITY := 'Send newsflash';
RECEIVE_USER_TARGETED_NEWS			CONSTANT T_CAPABILITY := 'Receive user-targeted newsflash';
APPROVE_QUESTIONNAIRE				CONSTANT T_CAPABILITY := 'Approve questionnaire';

/****************************************************************************************************/

SUBTYPE T_VISIBILITY				IS NUMBER;
HIDDEN 								CONSTANT T_VISIBILITY := 0;
JOBTITLE 							CONSTANT T_VISIBILITY := 1;
NAMEJOBTITLE						CONSTANT T_VISIBILITY := 2;
FULL 								CONSTANT T_VISIBILITY := 3;

SUBTYPE T_REGISTRATION_STATUS		IS NUMBER;
PENDING								CONSTANT T_REGISTRATION_STATUS := 0;
REGISTERED 							CONSTANT T_REGISTRATION_STATUS := 1;
REJECTED							CONSTANT T_REGISTRATION_STATUS := 2;
MERGED								CONSTANT T_REGISTRATION_STATUS := 3;

SUBTYPE T_INVITATION_TYPE			IS NUMBER;
QUESTIONNAIRE_INVITATION			CONSTANT T_INVITATION_TYPE := 1;
STUB_INVITATION						CONSTANT T_INVITATION_TYPE := 2;

SUBTYPE T_INVITATION_STATUS			IS NUMBER;
-- ACTIVE = 1 (defined above)
EXPIRED								CONSTANT T_INVITATION_STATUS := 2;
CANCELLED							CONSTANT T_INVITATION_STATUS := 3;
PROVISIONALLY_ACCEPTED				CONSTANT T_INVITATION_STATUS := 4;
ACCEPTED							CONSTANT T_INVITATION_STATUS := 5;
REJECTED_NOT_EMPLOYEE				CONSTANT T_INVITATION_STATUS := 6;
REJECTED_NOT_SUPPLIER				CONSTANT T_INVITATION_STATUS := 7;

SUBTYPE T_GUID_STATE				IS NUMBER;
GUID_OK 							CONSTANT T_GUID_STATE := 0;
--GUID_INVALID						CONSTANT T_GUID_STATE := 1; -- probably only used in cs class
GUID_NOTFOUND						CONSTANT T_GUID_STATE := 2;
GUID_EXPIRED						CONSTANT T_GUID_STATE := 3;
GUID_ALREADY_USED					CONSTANT T_GUID_STATE := 4;

SUBTYPE T_ALERT_ENTRY_TYPE			IS NUMBER;
EVENT_ALERT							CONSTANT T_ALERT_ENTRY_TYPE := 1;
ACTION_ALERT						CONSTANT T_ALERT_ENTRY_TYPE := 2;

SUBTYPE T_ALERT_ENTRY_PARAM_TYPE	IS NUMBER;
ORDERED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 1;
NAMED_PARAMS						CONSTANT T_ALERT_ENTRY_TYPE := 2;

/****************************************************************************************************/

SUBTYPE T_SHARE_STATUS				IS NUMBER;
NOT_SHARED 							CONSTANT T_SHARE_STATUS := 11;
SHARING_DATA 						CONSTANT T_SHARE_STATUS := 12;
SHARED_DATA_RETURNED 				CONSTANT T_SHARE_STATUS := 13;
SHARED_DATA_ACCEPTED 				CONSTANT T_SHARE_STATUS := 14;
SHARED_DATA_REJECTED 				CONSTANT T_SHARE_STATUS := 15;

SUBTYPE T_QUESTIONNAIRE_STATUS		IS NUMBER;
ENTERING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 1;
REVIEWING_DATA 						CONSTANT T_QUESTIONNAIRE_STATUS := 2;
READY_TO_SHARE 						CONSTANT T_QUESTIONNAIRE_STATUS := 3;

/****************************************************************************************************/
SUBTYPE T_FLAG						IS BINARY_INTEGER;

ALLOW_NONE							CONSTANT T_FLAG := 0;
ALLOW_ADD_EXISTING					CONSTANT T_FLAG := 1;
ALLOW_ADD_NEW						CONSTANT T_FLAG := 2;
--ALLOW_EDIT							CONSTANT T_FLAG := 4;
ALLOW_ALL							CONSTANT T_FLAG := 3;

/****************************************************************************************************/
SUBTYPE T_ACCEPTANCE_STATUS			IS NUMBER;

ACCEPT_PENDING						CONSTANT T_ACCEPTANCE_STATUS := 1;
ACCEPT_ACCEPTED						CONSTANT T_ACCEPTANCE_STATUS := 2;
ACCEPT_REJECTED						CONSTANT T_ACCEPTANCE_STATUS := 3;

/****************************************************************************************************/
SUBTYPE T_SUPPLIER_TYPE				IS NUMBER;

SUPPLIER_NOT_SET					CONSTANT T_SUPPLIER_TYPE := 0;
EXISTING_SUPPLIER					CONSTANT T_SUPPLIER_TYPE := 1;
EXISTING_PURCHASER					CONSTANT T_SUPPLIER_TYPE := 2;
UNINVITED_SUPPLIER					CONSTANT T_SUPPLIER_TYPE := 3;

/****************************************************************************************************/
SUBTYPE T_REPEAT_TYPE				IS NUMBER;
NEVER_REPEAT						CONSTANT T_REPEAT_TYPE := 0;
REPEAT_IF_CLOSED					CONSTANT T_REPEAT_TYPE := 1;
REFRESH_OR_REPEAT					CONSTANT T_REPEAT_TYPE := 2;
ALWAYS_REPEAT						CONSTANT T_REPEAT_TYPE := 3;

SUBTYPE T_ADDRESS_TYPE				IS NUMBER;
USER_ADDRESS						CONSTANT T_ADDRESS_TYPE := 0;
COMPANY_USER_ADDRESS				CONSTANT T_ADDRESS_TYPE := 1;
COMPANY_ADDRESS						CONSTANT T_ADDRESS_TYPE := 2;

SUBTYPE T_ADDRESSING_PSEUDO_USER	IS security_pkg.T_SID_ID;
FOLLOWERS							CONSTANT T_ADDRESSING_PSEUDO_USER := -1;

SUBTYPE T_PRIORITY_TYPE				IS NUMBER;
--HIDDEN (defined above)			CONSTANT T_PRIORITY_TYPE := 0;
NEUTRAL								CONSTANT T_PRIORITY_TYPE := 1;
SHOW_STOPPER						CONSTANT T_PRIORITY_TYPE := 2;

SUBTYPE T_COMPLETION_TYPE			IS NUMBER;
NO_COMPLETION						CONSTANT T_COMPLETION_TYPE := 0;
ACKNOWLEDGE							CONSTANT T_COMPLETION_TYPE := 1;
CODE_ACTION							CONSTANT T_COMPLETION_TYPE := 2;

/****************************************************************************************************/
SUBTYPE T_MESSAGE_DEFINITION_LOOKUP	IS NUMBER;
-- Secondary directional stuff --
NONE_IMPLIED						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 0;
PURCHASER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 1;
SUPPLIER_MSG						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 2;

-- Administrative messaging --
CONFIRM_COMPANY_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 100;
CONFIRM_YOUR_DETAILS				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 101;

-- Invitation messaging --
INVITATION_SENT						CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 200;
INVITATION_ACCEPTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 201;
INVITATION_REJECTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 202;
INVITATION_EXPIRED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 203;

-- Questionnaire messaging --
COMPLETE_QUESTIONNAIRE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 300;
QUESTIONNAIRE_SUBMITTED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 301;
QUESTIONNAIRE_APPROVED				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 302;
QUESTIONNAIRE_OVERDUE				CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 303;

-- Component messaging --
PRODUCT_MAPPING_REQUIRED			CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 400;

-- MAERSK --
CHANGED_SUPPLIER_REG_DETAILS		CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 10000;
ACTION_PLAN_STARTED					CONSTANT T_MESSAGE_DEFINITION_LOOKUP := 10001;

/****************************************************************************************************/
SUBTYPE T_COMPONENT_CODE			IS component.component_code%TYPE;

SUBTYPE T_COMPONENT_TYPE			IS NUMBER;

-- COMPONENT types
PRODUCT_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 1;
LOGICAL_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 2;
PURCHASED_COMPONENT					CONSTANT T_COMPONENT_TYPE := 3;
NOTSURE_COMPONENT					CONSTANT T_COMPONENT_TYPE := 4;

-- CLIENT SPECIFC COMPONENT TYPES 
RA_ROOT_PROD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 48;
RA_ROOT_WOOD_COMPONENT 				CONSTANT T_COMPONENT_TYPE := 49;
RA_WOOD_COMPONENT 					CONSTANT T_COMPONENT_TYPE := 50;
RA_WOOD_ESTIMATE_COMPONENT			CONSTANT T_COMPONENT_TYPE := 51;

/****************************************************************************************************/

ERR_QNR_NOT_FOUND	CONSTANT NUMBER := -20500;
QNR_NOT_FOUND EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_FOUND, -20500);

ERR_QNR_ALREADY_EXISTS	CONSTANT NUMBER := -20501;
QNR_ALREADY_EXISTS EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_EXISTS, -20501);

ERR_QNR_NOT_SHARED CONSTANT NUMBER := -20502;
QNR_NOT_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_NOT_SHARED, -20502);

ERR_QNR_ALREADY_SHARED CONSTANT NUMBER := -20503;
QNR_ALREADY_SHARED EXCEPTION;
PRAGMA EXCEPTION_INIT(QNR_ALREADY_SHARED, -20503);



PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
);

PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE;


PROCEDURE IsChainAdmin(
	out_result				OUT  NUMBER
);

FUNCTION IsChainAdmin
RETURN BOOLEAN;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
);

FUNCTION IsElevatedAccount
RETURN BOOLEAN;

PROCEDURE LogonUCD (
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL
);

PROCEDURE RevertLogonUCD;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID;

FUNCTION Flag (
	in_flags			IN T_FLAG,
	in_flag				IN T_FLAG
) RETURN T_FLAG;

END chain_pkg;
/

CREATE OR REPLACE PACKAGE  chain.chain_link_pkg
IS

PROCEDURE AddCompanyUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE InviteCreated (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
);

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetWizardTitles (
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	out_titles					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddProduct (
	in_product_id				IN  product.product_id%TYPE
);

PROCEDURE KillProduct (
	in_product_id				IN  product.product_id%TYPE
);

-- subscribers of this method are expected to modify data in the tt_component_type_containment table
PROCEDURE FilterComponentTypeContainment;

FUNCTION FindMessageRecipient (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
) RETURN recipient.recipient_id%TYPE;

PROCEDURE MessageRefreshed (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

PROCEDURE MessageCreated (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

PROCEDURE MessageCompleted (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

END chain_link_pkg;
/
CREATE OR REPLACE PACKAGE  chain.company_pkg
IS


/************************************************************
	SYS_CONTEXT handlers
************************************************************/

FUNCTION TrySetCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN number;

PROCEDURE SetCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE SetCompany(
	in_name						IN  security_pkg.T_SO_NAME
);

FUNCTION GetCompany
RETURN security_pkg.T_SID_ID;


/************************************************************
	Securable object handlers
************************************************************/
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID
);

/************************************************************
	Company Management Handlers
************************************************************/
-- this can be used to trigger a verification of each company's so structure during updates
PROCEDURE VerifySOStructure;

PROCEDURE CreateCompany(	
	in_name						IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE CreateUniqueCompany(
	in_name						IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE DeleteCompanyFully(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UndeleteCompany(
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (	
	in_company_sid				IN  security_pkg.T_SID_ID, 
	in_name						IN  company.name%TYPE,
	in_address_1				IN  company.address_1%TYPE,
	in_address_2				IN  company.address_2%TYPE,
	in_address_3				IN  company.address_3%TYPE,
	in_address_4				IN  company.address_4%TYPE,
	in_town						IN  company.town%TYPE,
	in_state					IN  company.state%TYPE,
	in_postcode					IN  company.postcode%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	in_phone					IN  company.phone%TYPE,
	in_fax						IN  company.fax%TYPE,
	in_website					IN  company.website%TYPE
);
	
FUNCTION GetCompanySid (	
	in_company_name				IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetCompanySid (	
	in_company_name				IN  company.name%TYPE,
	in_country_code				IN  company.country_code%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE GetCompany (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION GetCompanyName (
	in_company_sid 				IN security_pkg.T_SID_ID
) RETURN company.name%TYPE;

PROCEDURE SearchCompanies ( 
	in_search_term  			IN  varchar2,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanies ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchSuppliers ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	in_only_active				IN  number,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetSupplierNames (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPurchaserNames (
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchMyCompanies ( 
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_search_term  			IN  varchar2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN
);

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE ActivateVirtualRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE DeactivateVirtualRelationship (
	in_key						IN  supplier_relationship.virtually_active_key%TYPE
);

PROCEDURE AddPurchaserFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE AddSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

FUNCTION GetPurchaserFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION GetSupplierFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST;

FUNCTION IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsMember(
	in_company_sid				IN	security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
);

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER;


PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCompanies (
	in_user_sid					IN  security_pkg.T_SID_ID,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetStubSetupDetails (
	in_active					IN  company.allow_stub_registration%TYPE,
	in_approve					IN  company.approve_stub_registration%TYPE,
	in_stubs					IN  chain_pkg.T_STRINGS
);

PROCEDURE GetStubSetupDetails (
	out_options_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanyFromStubGuid (
	in_guid						IN  company.stub_registration_guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ConfirmCompanyDetails (
	in_company_sid				IN  security_pkg.T_SID_ID
);

/*
PROCEDURE ForceSetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
);
*/

END company_pkg;
/

CREATE OR REPLACE PACKAGE  chain.company_user_pkg
IS

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE SetMergedStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_merged_to_user_sid	IN  security_pkg.T_SID_ID
);

PROCEDURE SetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_status				IN  chain_pkg.T_REGISTRATION_STATUS
);

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE GetUserSid (
	in_user_name			IN  security_pkg.T_SO_NAME,
	out_user_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE SetVisibility (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_visibility			IN  chain_pkg.T_VISIBILITY
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_search_term  		IN  VARCHAR2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_page   				IN  NUMBER,
	in_page_size    		IN  NUMBER,
	in_search_term  		IN  VARCHAR2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE ApproveUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE MakeAdmin (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION RemoveAdmin (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE CheckPasswordComplexity (
	in_email				IN  security_pkg.T_SO_NAME,
	in_password				IN  security_pkg.T_USER_PASSWORD
);

PROCEDURE CompleteRegistration (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_password				IN  Security_Pkg.T_USER_PASSWORD
);

PROCEDURE BeginUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
);

PROCEDURE EndUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUser (
	in_act					IN	security_pkg.T_ACT_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS;

PROCEDURE GetUser (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE PreparePasswordReset (
	in_param				IN  VARCHAR2,
	in_accept_guid			IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE StartPasswordReset (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetPassword (
	in_guid					IN  security_pkg.T_ACT_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetPassword (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD
);

PROCEDURE CheckEmailAvailability (
	in_email					IN  security_pkg.T_SO_NAME
);

PROCEDURE ActivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE ConfirmUserDetails (
	in_user_sid				IN  security_pkg.T_SID_ID
);

END company_user_pkg;
/
CREATE OR REPLACE PACKAGE  chain.invitation_pkg
IS

PROCEDURE AnnounceSids;

PROCEDURE UpdateExpirations;

FUNCTION GetInvitationTypeByGuid (
	in_guid						IN  invitation.guid%TYPE
) RETURN chain_pkg.T_INVITATION_TYPE;


PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS
) RETURN invitation.invitation_id%TYPE;


PROCEDURE GetInvitationForLanding (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qt_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
);

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD
);


PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
);

FUNCTION CanAcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_guid_error_val			IN  NUMBER
) RETURN NUMBER;


/*** not to be called unless external validity checks have been done ***/
FUNCTION CanAcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION GetInvitationId (
	in_guid						IN  invitation.guid%TYPE
) RETURN invitation.invitation_id%TYPE;

PROCEDURE GetSupplierInvitationSummary (
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	out_invite_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_questionnaire_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetToCompanySidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
);

PROCEDURE ExtendExpiredInvitations(
	in_expiration_dtm invitation.expiration_dtm%TYPE
);

PROCEDURE SearchInvitations (
	in_search					IN	VARCHAR2,
	in_invitation_status_id		IN	invitation.invitation_status_id%TYPE,
	in_from_user_sid			IN	security_pkg.T_SID_ID,
	in_sent_dtm_from			IN	invitation.sent_dtm%TYPE,
	in_sent_dtm_to				IN	invitation.sent_dtm%TYPE,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	in_sort_by					IN	VARCHAR2,
	in_sort_dir					IN	VARCHAR2,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DownloadInvitations (
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE CancelInvitation (
  in_invitation_id				IN	invitation.invitation_id%TYPE
);

PROCEDURE ReSendInvitation (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQnrTypesForInvitation (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetInvitationStatuses (
	in_for_filter				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END invitation_pkg;
/

CREATE OR REPLACE PACKAGE CHAIN.questionnaire_pkg
IS

PROCEDURE GetQuestionnaireFilterClass (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireGroups (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireTypes (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireType (
	in_qt_class					IN   questionnaire_type.CLASS%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireTypeId (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

PROCEDURE StartShareQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_due_by_dtm				IN  questionnaire_share.DUE_BY_DTM%TYPE
);

FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
);

FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER;

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_SHARE_STATUS;

PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
);

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
);

PROCEDURE GetQManagementData (
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQManagementData (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyQuestionnaires (
	in_status			IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_view_url					IN	questionnaire_type.view_url%TYPE,
	in_edit_url					IN	questionnaire_type.edit_url%TYPE,
	in_owner_can_review			IN	questionnaire_type.owner_can_review%TYPE,
	in_name						IN	questionnaire_type.name%TYPE,
	in_class					IN	questionnaire_type.CLASS%TYPE,
	in_db_class					IN	questionnaire_type.db_class%TYPE,
	in_group_name				IN	questionnaire_type.group_name%TYPE,
	in_position					IN	questionnaire_type.position%TYPE
);

PROCEDURE DeleteQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
);

PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CheckForOverdueQuestionnaires;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID
);

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
);

PROCEDURE MessageCreated (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN	message.message_id%TYPE
);

END questionnaire_pkg;
/
CREATE OR REPLACE PACKAGE chain.component_pkg
IS

/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 *
 * NOTE: Component types registered using this method cannot be editted in the UI. See next overload for more info.
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
);

/**
 * Create or update a component type
 *
 * @param in_type_id			The type of component to create
 * @param in_handler_class		The C# class that handles data management of this type
 * @param in_handler_pkg		The package that provides GetComponent(id) and GetComponents(top_id, type) functions
 * @param in_node_js_path		The path of the JS Component Node handler class
 * @param in_description		The translatable description of this type
 * @param in_editor_card_group_id	The card group that handles editting of this type
 */
PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
);


/**********************************************************************************
	APP MANAGEMENT
**********************************************************************************/
/**
 * Activates this type for the session application
 *
 * @param in_type_id			The type of component to activate
 */
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
);

/**********************************************************************************/
/* Component sources are application level UI configurations that allow us to set */
/* specific text and help data in a ComponentSource card. 						  */
/*                                                       . 						  */

/**
 * Clears component source data
 */
PROCEDURE ClearSources;

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 *
 * NOTE: Component source data added using this method will be used for all card groups.
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
);

/**
 * Adds component source data
 *
 * @param in_type_id			The type of component to activate
 * @param in_action				The card action to invoke when this option is selected
 * @param in_text				A short text block that describes the intent of the source 
 * @param in_description		A longer xml helper description explaining in what circumstances we'd choose this option
 * @param in_card_group_id		The card group to include this source data for
 *
 * NOTE: This method will ensure that ActivateType is called for the type.
 */
PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
);

/**
 * Gets component sources for a specific card manager
 *
 * @param in_card_group_id			The id of the card group to collect that sources for
 * @returns							The source data cursor
 */
PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************/
/* Component type containment acts as both a UI helper and database ri for which  */
/* types of components can house other types.									  */
/* This is set at application level.				 . 						      */
/*                                                       . 						  */

/**
 * Clears component type containment for this application
 */
PROCEDURE ClearTypeContainment;

/**
 * Sets component type containment with UI helper flags for a single container/child pair
 *
 * @param in_container_type_id		The container component type
 * @param in_child_type_id			The child component type
 * @param in_allow_flags			See chain_pkg for valid allow flags
 *
 * NOTE: This method will ensure that ActivateType is called for both 
 *		 the container and child types.
 */
PROCEDURE SetTypeContainment (
	in_container_type_id	IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id		IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags			IN chain_pkg.T_FLAG
);

/**
 * Gets type containment data for output to the ui
 *
 * @returns							The containment data cursor
 */
PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	UTILITY
**********************************************************************************/
/**
 * Checks if a component is of a specific type
 *
 * @param in_component_id			The id of the component to check
 * @param in_type_id				The presumed type
 * @returns							TRUE if the type matches, FALSE if not
 */
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN;

/**
 * Gets the owner company sid for given component id
 *
 * @param in_component_id			The id of the component
 * @returns							The company sid that owns the component
 */
FUNCTION GetCompanySid (
	in_component_id			IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID;

/**
 * Checks to see if a component is deleted
 *
 * @param in_component_id			The id of the component to check
 */
FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN;

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_id		The top id of the component in the tree
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
);

/**
 * Records the component tree data into TT_COMPONENT_TREE
 *
 * @param in_top_component_ids		The top ids of the components in the trees
 */
PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
);

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
/**
 * Gets the components types that are active in this application
 *
 * @returns							A cursor of (as above)
 */
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets the specific component type requested
 *
 * @param in_type_id				The specific component type to get
 * @returns							A cursor of (as above)
 */
PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
/**
 * Saves a component. If in_component_id <= 0, a new component is created.
 * If in_component_id > 0, the component is updated, provided that the type
 * passed in matches the expected type.
 *
 * @param in_component_id			The id (actual for existing, < 0 for new)
 * @param in_type_id				The type 
 * @param in_type_id				The description
 * @param in_type_id				The component code
 * @returns							The actual id of the component
 */
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE;

/**
 * Marks a component as deleted
 *
 * @param in_component_id			The id of the component to delete
 */
PROCEDURE DeleteComponent (
	in_component_id			IN component.component_id%TYPE
);

/**
 * Gets basic component data by component id
 *
 * @param in_component_id			The id of the component to get
 * @returns							A cursor containing the basic component data
 */
PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Gets child component data of a specific type for a top_component
 *
 * @param in_top_component_id		The top component of the tree to get
 * @param in_type_id				The type of component that we're looking for
 * @returns							A cursor containing the component data
 *
 * NOTE: The type is passed in because we allow a single method to collect data
 * for more than one type of component. You must ensure that you only return
 * components of the requested type, as this method may be called again
 * using an alternate type
 */
PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Searchs all components that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

/**
 * Searchs all components of a specific type that are valid for the specified container type
 *
 * @param in_page					The page number to get
 * @param in_page_size				The size of a page
 * @param in_container_type_id		The type of container that we're searching for
 * @param in_search_term			The search term
 * @param in_of_type				The specific type to search for
 * @returns out_count_cur			The search statistics
 * @returns out_result_cur			The page limited search results
 */
PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE SearchComponentsPurchased (
	in_search					IN  VARCHAR2,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

/**
 * Attaches one component to another component
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Fully detaches a component from all container and child components
 *
 * @param in_component_id		The component id to detach
 */
PROCEDURE DetachComponent (
	in_component_id				IN component.component_id%TYPE	
);

/**
 * Detaches all child components from this component
 *
 * @param in_container_id			The component id to detach children from
 */
PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
);

/**
 * Detaches a specific container / child component pair
 *
 * @param in_container_id			The container component id
 * @param in_child_id				The child component id
 */
PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
);

/**
 * Gets a table of all component ids that are children of the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE;

/**
 * Gets a table of all component ids that are children of the top component ids
 *
 * @param in_top_component_ids		An array of all top component ids to include
 * @returns A numeric table of component ids in this branch
 *
FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE;


/**
 * Gets a heirarchy cursor of all parent id / component id relationships 
 * starting with the top component id
 *
 * @param in_top_component_id		The top component in the branch
 * @returns out_cur					The cursor (as above)
 */
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/

/**
 * Changes a not sure component type into another component type
 *
 * @param in_component_id			The id of the not sure component to change
 * @param in_to_type_id				The type to change the component to
 * @returns out_cur					A cursor the basic component data
 */
PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

END component_pkg;
/
CREATE OR REPLACE PACKAGE chain.purchased_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
);

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE MigrateUninvitedComponents (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
);

END purchased_component_pkg;
/
CREATE OR REPLACE PACKAGE chain.product_pkg
IS

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE
) RETURN NUMBER;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
);

PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
);

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
);

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetProductCodes (
    in_company_sid      	IN  security_pkg.T_SID_ID,
	in_code_label1			IN  product_code_type.code_label1%TYPE,
	in_code_label2			IN  product_code_type.code_label2%TYPE,
	in_code_label3			IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory		IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory		IN 	product_code_type.code3_mandatory%TYPE
);

PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
);

PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
);

PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product.active%TYPE
);

PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product.need_review%TYPE
);

PROCEDURE SetPseudoRootComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.pseudo_root_component_id%TYPE
);

END product_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.chain_pkg
IS

PROCEDURE AddUserToChain (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	BEGIN
		INSERT INTO chain_user
		(user_sid, registration_status_id)
		VALUES
		(in_user_sid, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;


PROCEDURE SetUserSetting (
	in_name					IN  user_setting.name%TYPE,
	in_number_value			IN  user_setting.number_value%TYPE,
	in_string_value			IN  user_setting.string_value%TYPE
)
AS
BEGIN
	-- NO SEC CHECKS - you can only set default settings for the user that you're logged in as in the current application
	
	BEGIN
		INSERT INTO user_setting
		(name, number_value, string_value)
		VALUES
		(LOWER(TRIM(in_name)), in_number_value, in_string_value);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE user_setting
			   SET number_value = in_number_value,
			   	   string_value = in_string_value
			 WHERE name = LOWER(TRIM(in_name))
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');
	END;

END;

-- we need to pass in dummy because for some very very strange reason, we get an exception if we pass in a string array as the first param 
PROCEDURE GetUserSettings (
	in_dummy				IN  NUMBER,
	in_names				IN  security_pkg.T_VARCHAR2_ARRAY,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_t_names				security.T_VARCHAR2_TABLE DEFAULT security_pkg.Varchar2ArrayToTable(in_names);
BEGIN
	-- NO SEC CHECKS - you can only get default settings for the user that you're logged in as in the current application
	OPEN out_cur FOR
		SELECT name, number_value, string_value
		  FROM user_setting
		 WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')
		   AND name IN (SELECT LOWER(TRIM(value)) FROM TABLE(v_t_names));
END;


PROCEDURE GetChainAppSids (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT app_sid
		  FROM customer_options;
END;

PROCEDURE GetCustomerOptions (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT 	invitation_expiration_days,
				site_name,
				admin_has_dev_access,
				support_email,
				newsflash_summary_sp,
				questionnaire_filter_class,
				last_generate_alert_dtm,
				scheduled_alert_intvl_minutes,
				chain_implementation,
				company_helper_sp,
				default_receive_sched_alerts,
				override_send_qi_path,
				login_page_message,
				invite_from_name_addendum,
				sched_alerts_enabled,
				link_host,
				NVL(top_company_sid, 0) top_company_sid,
				product_url,
				NVL(default_url, '/') default_url
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;


FUNCTION GetCompaniesContainer
RETURN security_pkg.T_SID_ID
AS
	v_sid_id 				security_pkg.T_SID_ID;
BEGIN
	v_sid_id := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies');
	RETURN v_sid_id;
END;

PROCEDURE GetCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM v$country
		 ORDER BY LOWER(name);
END;

FUNCTION StringToDate (
	in_str_val				IN  VARCHAR2
) RETURN DATE
AS
BEGIN
	RETURN TO_DATE(in_str_val, 'DD/MM/YY HH24:MI:SS');
END;

PROCEDURE IsChainAdmin  (
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsChainAdmin THEN
		out_result := chain_pkg.ACTIVE;
	ELSE
		out_result := chain_pkg.INACTIVE;
	END IF;
END;


FUNCTION IsChainAdmin 
RETURN BOOLEAN
AS
BEGIN
	RETURN IsChainAdmin(security_pkg.GetSid);
END;

FUNCTION IsChainAdmin (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_count					NUMBER(10) DEFAULT 0;
	v_cag_sid				security_pkg.T_SID_ID;
BEGIN
	BEGIN
		v_cag_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'Groups/'||chain_pkg.CHAIN_ADMIN_GROUP);
	EXCEPTION
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;

	IF v_cag_sid <> 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, in_user_sid)) T
		 WHERE T.sid_id = v_cag_sid;

		 IF v_count > 0 THEN
			RETURN TRUE;
		 END IF;			 
	END IF;	
	
	RETURN FALSE;
END;

FUNCTION IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN in_sid = securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, SYS_CONTEXT('SECURITY', 'APP'), 'Chain/BuiltIn/Invitation Respondent');
END;

PROCEDURE IsInvitationRespondant (
	in_sid					IN  security_pkg.T_SID_ID,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsInvitationRespondant(in_sid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;


FUNCTION IsElevatedAccount
RETURN BOOLEAN
AS
BEGIN
	IF security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RETURN TRUE;
	END IF;
	
	IF IsInvitationRespondant(security_pkg.GetSid) THEN
		RETURN TRUE;
	END IF;
	
	IF security_pkg.GetSid = securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, SYS_CONTEXT('SECURITY', 'APP'), 'Users/UserCreatorDaemon') THEN
		RETURN TRUE;
	END IF;
	
	RETURN FALSE;
END;

PROCEDURE LogonUCD (
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL
)
AS
	v_act_id				security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP');
	v_prev_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY', 'ACT');
	v_prev_user_sid			security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
	v_prev_company_sid		security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
BEGIN
	
	user_pkg.LogonAuthenticatedPath(v_app_sid, 'users/UserCreatorDaemon', 300, v_app_sid, v_act_id);
	
	IF in_company_sid IS NOT NULL THEN
		company_pkg.SetCompany(in_company_sid);
	END IF;
	
	INSERT INTO ucd_logon
	(app_sid, ucd_act_id, previous_act_id, previous_user_sid, previous_company_sid)
	VALUES
	(v_app_sid, v_act_id, v_prev_act_id, v_prev_user_sid, v_prev_company_sid);
END;

PROCEDURE RevertLogonUCD
AS
	v_row					ucd_logon%ROWTYPE;
BEGIN
	-- let this blow up if nothing's found
	SELECT *
	  INTO v_row
	  FROM ucd_logon
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ucd_act_id = SYS_CONTEXT('SECURITY', 'ACT');
	
	Security_pkg.SetACTAndSID(v_row.previous_act_id, v_row.previous_user_sid);
	Security_pkg.SetApp(v_row.app_sid);
	
	IF v_row.previous_company_sid IS NOT NULL THEN
		company_pkg.SetCompany(v_row.previous_company_sid);
	END IF;
	
	user_pkg.Logoff(v_row.ucd_act_id);
END;

FUNCTION GetTopCompanySid
RETURN security_pkg.T_SID_ID
AS
	v_company_sid		security_pkg.T_SID_ID;
BEGIN

	SELECT top_company_sid
	  INTO v_company_sid
	  FROM customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'Top company sid is not set');
	END IF;

	RETURN v_company_sid;
END;

FUNCTION Flag (
	in_flags			IN T_FLAG,
	in_flag				IN T_FLAG
) RETURN T_FLAG
AS
BEGIN
	IF security.bitwise_pkg.bitand(in_flags, in_flag) = 0 THEN
		RETURN 0;
	END IF;
	
	RETURN 1;
END;


END chain_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.chain_link_pkg
IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

/******************************************************************
	PRIVATE WORKER METHODS
******************************************************************/
FUNCTION GetGlobalLinkPkg
RETURN customer_options.company_helper_sp%TYPE
AS
	v_helper_pkg		customer_options.company_helper_sp%TYPE;
BEGIN
	BEGIN
		SELECT company_helper_sp
		  INTO v_helper_pkg 
		  FROM customer_options co
		 WHERE app_sid = security_pkg.getApp;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_helper_pkg;
END;

FUNCTION GetQuestionnaireLinkPkg (
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE
)
RETURN customer_options.company_helper_sp%TYPE
AS
	v_helper_pkg				customer_options.company_helper_sp%TYPE;
BEGIN
	BEGIN
		SELECT db_class
		  INTO v_helper_pkg
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND questionnaire_id = in_questionnaire_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_helper_pkg;
END;


PROCEDURE ExecuteProcedure (
	in_helper_pkg				IN  customer_options.company_helper_sp%TYPE,
	in_proc_call				IN  VARCHAR2
)
AS
BEGIN
	IF in_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
			'BEGIN ' || in_helper_pkg || '.' || in_proc_call || ';END;');
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
END;

PROCEDURE ExecuteProcedure (
	in_proc_call				IN  VARCHAR2
)
AS
BEGIN
	ExecuteProcedure(GetGlobalLinkPkg, in_proc_call);
END;


FUNCTION ExecuteFuncReturnNumber (
	in_helper_pkg				IN  customer_options.company_helper_sp%TYPE,
	in_func_call				IN  VARCHAR2
) RETURN NUMBER
AS
	v_result					NUMBER(10);
BEGIN
	IF in_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE
				'BEGIN ' || in_helper_pkg || '.' || in_func_call || ';END;'
			USING OUT v_result;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	
	RETURN v_result;
END;

FUNCTION ExecuteFuncReturnNumber (
	in_func_call				IN  VARCHAR2
) RETURN NUMBER
AS
BEGIN
	RETURN ExecuteFuncReturnNumber(GetGlobalLinkPkg, in_func_call);
END;

PROCEDURE ExecuteMessageProcedure (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_proc						IN  VARCHAR2,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteProcedure(in_helper_pkg, in_proc||'('||in_to_company_sid||','||in_message_id||')');
END;


/******************************************************************
	PUBLIC IMPLEMENTATION CALLS
******************************************************************/
PROCEDURE AddCompanyUser (
	in_user_sid					IN  security_pkg.T_SID_ID,
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('AddCompanyUser(' || in_user_sid || ', ' || 
									in_company_sid || ')');
END;

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('AddCompany(' || in_company_sid || ')');
END;

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('DeleteCompany(' || in_company_sid || ')');
END;

PROCEDURE InviteCreated (
	in_invitation_id				IN	invitation.invitation_id%TYPE,
	in_from_company_sid				IN  security_pkg.T_SID_ID,
	in_from_user_sid				IN  security_pkg.T_SID_ID,
	in_to_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('InviteCreated(' || in_invitation_id || ', ' ||
									in_from_company_sid || ', ' ||
									in_from_user_sid || ', ' ||
									in_to_user_sid || ')');
END;

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
)
AS
BEGIN
	ExecuteProcedure(GetQuestionnaireLinkPkg(in_questionnaire_id), 
		'QuestionnaireAdded(' || in_from_company_sid || ', ' ||
								 in_to_company_sid || ', ' ||
								 in_to_user_sid || ', ' ||
								 in_questionnaire_id || ')');
END;

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ActivateCompany(' || in_company_sid || ')');
END;


PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ActivateUser(' || in_user_sid || ')');
END;


PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ApproveUser(' || in_company_sid || ', ' ||
									in_user_sid || ')');
END;

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
)
AS
BEGIN
	ExecuteProcedure('ActivateRelationship(' || in_purchaser_company_sid || ', ' ||
												in_supplier_company_sid || ')');
END;

PROCEDURE GetWizardTitles (
	in_card_group_id		IN  card_group.card_group_id%TYPE,
	out_titles				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_helper_pkg				customer_options.company_helper_sp%TYPE;
	/*
		For some reason, if you pass out_titles in to the execute immediate statement
		it barfs on linux with an invalid cursor exception when returning the cursor
		to the webserver, although it works fine on Win7 x64.
		The solution appears to be declaring another cursor locally, assigning it to
		that and then passing it back out
	*/
	c_titles					security_pkg.T_OUTPUT_CUR;
BEGIN
	v_helper_pkg := GetGlobalLinkPkg;
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
            EXECUTE IMMEDIATE (
				'BEGIN ' || v_helper_pkg || '.GetWizardTitles(:card_group,:out_titles);END;'
			) USING in_card_group_id, c_titles;
			
			out_titles := c_titles;
			
			RETURN;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	
	OPEN out_titles FOR 
		SELECT NULL AS WIZARD_TITLE, NULL AS WIZARD_SUB_TITLE FROM dual;
END;

PROCEDURE AddProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	ExecuteProcedure('AddProduct(' || in_product_id || ')');
END;

PROCEDURE KillProduct (
	in_product_id		IN  product.product_id%TYPE
)
AS
BEGIN
	ExecuteProcedure('KillProduct(' || in_product_id || ')');
END;

PROCEDURE FilterComponentTypeContainment
AS
BEGIN
	ExecuteProcedure('FilterComponentTypeContainment()');
END;

FUNCTION FindMessageRecipient (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
) RETURN recipient.recipient_id%TYPE
AS
BEGIN
	RETURN ExecuteFuncReturnNumber('FindMessageRecipient('||
					in_message_id 	|| ', ' ||
					in_company_sid 	|| ', ' ||
					in_user_sid 	|| ') ');
END;

PROCEDURE MessageRefreshed (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteMessageProcedure(in_helper_pkg, 'MessageRefreshed', in_to_company_sid, in_message_id);
END;

PROCEDURE MessageCreated (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteMessageProcedure(in_helper_pkg, 'MessageCreated', in_to_company_sid, in_message_id);
END;


PROCEDURE MessageCompleted (
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
)
AS
BEGIN
	ExecuteMessageProcedure(in_helper_pkg, 'MessageCompleted', in_to_company_sid, in_message_id);
END;



END chain_link_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.company_pkg
IS

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/


FUNCTION GenerateSOName (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SO_NAME
AS
	v_cc					company.country_code%TYPE DEFAULT in_country_code;
BEGIN
	RETURN REPLACE(TRIM(REGEXP_REPLACE(TRANSLATE(in_company_name, '.,-()/\''', '        '), '  +', ' ')) || ' (' || v_cc || ')', '/', '\');
END;

FUNCTION TrySplitSOName (
	in_name					IN  security_pkg.T_SO_NAME,
	out_company_name		OUT company.name%TYPE,
	out_country_code		OUT company.country_code%TYPE
) RETURN BOOLEAN
AS
	v_idx	NUMBER;
BEGIN
	v_idx := LENGTH(in_name);

	
	IF SUBSTR(in_name, v_idx, 1) <> ')' THEN
		RETURN FALSE;
	END IF;
	
	WHILE v_idx > 1 LOOP
		v_idx := v_idx - 1;

		IF SUBSTR(in_name, v_idx, 1) = '(' THEN
			out_company_name := SUBSTR(in_name, 1, v_idx - 2);
			out_country_code := SUBSTR(in_name, v_idx + 1, LENGTH(in_name) - v_idx - 1);
	
			RETURN GenerateSOName(out_company_name, out_country_code) = in_name;
		END IF;
	END LOOP;

	RETURN FALSE;
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_sid				IN  security_pkg.T_SID_ID,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
BEGIN
	acl_pkg.AddACE(
		v_act_id, 
		Acl_pkg.GetDACLIDForSID(in_on_sid), 
		security_pkg.ACL_INDEX_LAST, 
		security_pkg.ACE_TYPE_ALLOW,
		0,  
		in_to_sid, 
		in_permission_set
	);
END;

-- shorthand helper
PROCEDURE AddPermission (
	in_on_sid				IN  security_pkg.T_SID_ID,
	in_to_path				IN  varchar2,
	in_permission_set		IN  security_Pkg.T_PERMISSION
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	AddPermission(
		in_on_sid, 
		securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, in_to_path), 
		in_permission_set
	);	
END;


/**
 *	The purpose of the procedure is to be a single point of company based securable object setup. 
 *  Any changes to this procedure should be flexible enough to deal with situations where the
 *  object may or may not already exists, already have permissions etc. so that it can
 *  be called during any update scripts.
 */
PROCEDURE CreateSOStructure (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_is_new_company		IN  BOOLEAN
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_ucd_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
	v_group_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups');
	v_everyone_sid			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_group_sid, 'Everyone');
	v_chain_admins_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_ADMIN_GROUP);
	v_chain_users_sid		security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSidFromPath(v_act_id, v_group_sid, chain_pkg.CHAIN_USER_GROUP);
	v_capabilities_sid		security_pkg.T_SID_ID;
	v_capability_sid		security_pkg.T_SID_ID;
	v_admins_sid			security_pkg.T_SID_ID;
	v_users_sid				security_pkg.T_SID_ID;
	v_pending_sid			security_pkg.T_SID_ID;
	v_uploads_sid			security_pkg.T_SID_ID;
	v_uninvited_sups_sid	security_pkg.T_SID_ID;
BEGIN
		
	/********************************************
		CREATE OBJECTS AND ADD PERMISSIONS
	********************************************/
	
	-- ADMIN GROUP
	BEGIN
		v_admins_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.ADMIN_GROUP, v_admins_sid);
	END;
	
	-- USER GROUP
	BEGIN
		v_users_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.USER_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.USER_GROUP, v_users_sid);
	END;
	
	-- PENDING USER GROUP 
	BEGIN
		v_pending_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.PENDING_GROUP);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			group_pkg.CreateGroup(v_act_id, in_company_sid, security_pkg.GROUP_TYPE_SECURITY, chain_pkg.PENDING_GROUP, v_pending_sid);
	END;
	
	-- UPLOADS CONTAINER
	BEGIN
		v_uploads_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.COMPANY_UPLOADS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.COMPANY_UPLOADS, v_uploads_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uploads_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
	
	-- UNINVITED SUPPLIERS CONTAINER
	BEGIN
		v_uninvited_sups_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.UNINVITED_SUPPLIERS);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.UNINVITED_SUPPLIERS, v_uninvited_sups_sid);
			acl_pkg.AddACE(
				v_act_id, 
				acl_pkg.GetDACLIDForSID(v_uninvited_sups_sid), 
				security_pkg.ACL_INDEX_LAST, 
				security_pkg.ACE_TYPE_ALLOW,
				security_pkg.ACE_FLAG_DEFAULT,
				v_chain_users_sid, 
				security_pkg.PERMISSION_STANDARD_ALL
			);
	END;
	
	-- SETUP CAPABILITIES
	BEGIN
		v_capabilities_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.CAPABILITIES);
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			securableobject_pkg.CreateSO(v_act_id, in_company_sid, security_pkg.SO_CONTAINER, chain_pkg.CAPABILITIES, v_capabilities_sid);
		
			-- don't inherit dacls
			securableobject_pkg.SetFlags(v_act_id, v_capabilities_sid, 0);
			-- clean existing ACE's
			acl_pkg.DeleteAllACEs(v_act_id, Acl_pkg.GetDACLIDForSID(v_capabilities_sid));
			
			AddPermission(v_capabilities_sid, v_everyone_sid, security_pkg.PERMISSION_STANDARD_READ + security_pkg.PERMISSION_ADD_CONTENTS);
	END;
	
	capability_pkg.RefreshCompanyCapabilities(in_company_sid);	

	/********************************************
		ADD OBJECTS TO GROUPS
	********************************************/
	-- add the users group to the Chain Users group
	group_pkg.AddMember(v_act_id, v_users_sid, v_chain_users_sid);
	
	-- add the administrators group to the users group
	-- our group, so we're hacking this in
	--group_pkg.AddMember(v_act_id, v_admins_sid, v_users_sid);
	BEGIN
		INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (v_admins_sid, v_users_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;

END;


FUNCTION GetGroupMembers(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_name			IN  chain_pkg.T_GROUP
)
RETURN security.T_SO_TABLE
AS
	v_group_sid				security_pkg.T_SID_ID;
BEGIN	
	RETURN group_pkg.GetDirectMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, in_group_name));
END;

-- collects a paged cursor of companies based on sids passed in as a T_ORDERED_SID_TABLE
PROCEDURE CollectSearchResults (
	in_all_results			IN  security.T_ORDERED_SID_TABLE,
	in_page   				IN  number,
	in_page_size    		IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_all_results);
	
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
		 	SELECT *
		 	  FROM v$company c, TABLE(in_all_results) T
		 	 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND c.company_sid = T.SID_ID
		 	 ORDER BY LOWER(c.name);
	
	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*, NVL(sr.active, chain_pkg.inactive) active_supplier
						  FROM v$company c, (SELECT * FROM v$supplier_relationship WHERE purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) sr, TABLE(in_all_results) T
		 	 			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	 			   AND c.app_sid = sr.app_sid(+)
		 	 			   AND c.company_sid = sr.supplier_company_sid(+)
		 	 			   AND c.company_sid = T.SID_ID
		 	 			 ORDER BY LOWER(c.name)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

FUNCTION VerifyMembership (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_group_type			IN  chain_pkg.T_GROUP,
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_g_sid					security_pkg.T_SID_ID;
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	BEGIN
		-- leave this in here so things don't blow up when we clean
		v_g_sid := securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, in_group_type);
		
		SELECT COUNT(*)
		  INTO v_count
		  FROM TABLE(group_pkg.GetMembersAsTable(v_act_id, v_g_sid))
		 WHERE sid_id = in_user_sid;
	EXCEPTION 
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN FALSE;
		WHEN security_pkg.ACCESS_DENIED THEN
			RETURN FALSE;
	END;
	
	IF v_count > 0 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
	END IF;
	
	RETURN v_count > 0;
END;

/****************************************************************************************
****************************************************************************************
	PUBLIC 
****************************************************************************************
****************************************************************************************/

/************************************************************
	SYS_CONTEXT handlers
************************************************************/
FUNCTION TrySetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
) RETURN number
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT in_company_sid;
BEGIN
	
	-- if v_company_sid is 0, try to get the existing company sid out of the context
	IF NVL(v_company_sid, 0) = 0 THEN
		v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	END IF;

	IF chain_pkg.IsElevatedAccount THEN
		SetCompany(v_company_sid);
		RETURN v_company_sid;
	END IF;
	
	-- first, verify that this user exists as a chain_user (ensures that views work at bare minimum)
	chain_pkg.AddUserToChain(SYS_CONTEXT('SECURITY', 'SID'));
		
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE
		   AND company_sid = v_company_sid;
	EXCEPTION 
		WHEN NO_DATA_FOUND THEN
			v_company_sid := NULL;
	END;

	-- if we've got a company sid, verify that the user is a member
	IF v_company_sid IS NOT NULL THEN
		-- is this user a group member?
		IF NOT chain_pkg.IsChainAdmin AND
		   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
		   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
			v_company_sid := NULL;
		END IF;
	END IF;
	
	-- if we don't have a company yet, check to see if a default company sid is set
	IF v_company_sid IS NULL THEN
		
		-- most users will belong to one company
		-- super users / admins may belong to more than 1 
		
		BEGIN
			-- try to get a default company
			SELECT cu.default_company_sid
			  INTO v_company_sid
			  FROM chain_user cu, v$company c
			 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cu.app_sid = c.app_sid
			   AND cu.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND cu.default_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;
		
		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;
		
	-- if we don't have a company yet, check to see if there is a top company set in customer options
	IF v_company_sid IS NULL THEN
		
		-- most users will belong to one company
		-- super users / admins may belong to more than 1 
		
		BEGIN
			-- try to get a default company
			SELECT co.top_company_sid
			  INTO v_company_sid
			  FROM customer_options co, company c
			 WHERE co.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND co.app_sid = c.app_sid
			   AND co.top_company_sid = c.company_sid
			   AND c.active = chain_pkg.ACTIVE;
		EXCEPTION 
			WHEN NO_DATA_FOUND THEN
				v_company_sid := NULL;
		END;
		
		-- verify that they are actually group members
		IF v_company_sid IS NOT NULL THEN
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
				v_company_sid := NULL;
			END IF;
		END IF;
	END IF;
		
	-- if we don't have a company yet, grab the first company we're a member of alphabetically
	IF v_company_sid IS NULL THEN
		-- ok, no valid default set - might as well just sort them alphabetically by company name and 
		-- 		pick the first, at least it's predictable		
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c, (
					SELECT DISTINCT so.parent_sid_id company_sid
					  FROM security.securable_object so, TABLE(group_pkg.GetGroupsForMemberAsTable(v_act_id, security_pkg.GetSid)) ug -- user group sids
					 WHERE application_sid_id = SYS_CONTEXT('SECURITY', 'APP')
					   AND so.sid_id = ug.sid_id
					   ) uc -- user companies
				 WHERE c.company_sid = uc.company_sid
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					) 
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;
	END IF;
	
	-- if there's still no company set and we're a chain admin, pick the first company alphabetically.
	IF v_company_sid IS NULL AND chain_pkg.IsChainAdmin THEN
		BEGIN
			SELECT company_sid
			  INTO v_company_sid
			  FROM (
				SELECT c.company_sid
				  FROM v$company c
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND c.active = chain_pkg.ACTIVE
				 ORDER BY LOWER(c.name)
					) 
			 WHERE ROWNUM = 1;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;	
	END IF;

	-- set the company sid in the context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
	-- return the company sid (or 0 if it's been cleared)
	RETURN NVL(v_company_sid, 0);
	
END;


PROCEDURE SetCompany(
	in_company_sid			IN	security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(in_company_sid, 0);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	IF v_company_sid = 0 THEN
		v_company_sid := NULL;
	END IF;
	
	IF v_company_sid IS NOT NULL THEN
		IF chain_pkg.IsElevatedAccount THEN
			-- just make sure that the company exists
			SELECT COUNT(*)
			  INTO v_count
			  FROM company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = v_company_sid;
			
			IF v_count = 0 THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		ELSE
			-- is this user a group member?
			IF NOT chain_pkg.IsChainAdmin AND
			   NOT VerifyMembership(v_company_sid, chain_pkg.USER_GROUP, security_pkg.GetSid) AND 
			   NOT VerifyMembership(v_company_sid, chain_pkg.PENDING_GROUP, security_pkg.GetSid) THEN
					security_pkg.SetContext('CHAIN_COMPANY', NULL);
					RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Could not set the company sid to '||v_company_sid||' for user with sid '||security_pkg.GetSid);
			END IF;
		END IF;
	END IF;
		
	-- set the value in sys context
	security_pkg.SetContext('CHAIN_COMPANY', v_company_sid);
	
END;

PROCEDURE SetCompany(
	in_name					IN  security_pkg.T_SO_NAME
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	SELECT company_sid
	  INTO v_company_sid
	  FROM v$company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND LOWER(name) = LOWER(in_name);
	
	SetCompany(v_company_sid);
END;


FUNCTION GetCompany
RETURN security_pkg.T_SID_ID
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	v_company_sid := SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	IF v_company_sid IS NULL THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_OBJECT_NOT_FOUND, 'The company sid is not set in the session context');
	END IF;
	RETURN v_company_sid;
END;

/************************************************************
	Securable object handlers
************************************************************/

PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
	v_chain_admins 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Administrators');
	v_chain_users 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Groups/Chain Users');
BEGIN
	
	IF in_parent_sid_id <> chain_pkg.GetCompaniesContainer THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain companies MUST be created under the application Chain/Companies container');
	END IF;
	
	IF NOT TrySplitSOName(in_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, '"'||in_name||'", "'||v_company_name||'", "'||v_country_code||'"Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
	
	-- Getting the securable object handler to create the company is a really bad idea. There are restrictions on the the characters that an SO name can comprise (and they need to
	-- be unique) - restrictions that are not applicable to company names.
	
    INSERT INTO company
    (company_sid, name, country_code)
    VALUES 
    (in_sid_id, v_company_name, TRIM(v_country_code));
    
	-- causes the groups and containers to get created
	CreateSOStructure(in_sid_id, TRUE);
	
	AddPermission(in_sid_id, security_pkg.SID_BUILTIN_ADMINISTRATOR, security_pkg.PERMISSION_STANDARD_ALL);
	AddPermission(in_sid_id, v_chain_admins, security_pkg.PERMISSION_WRITE);
	AddPermission(in_sid_id, v_chain_users, security_pkg.PERMISSION_WRITE);
	
	-- if we are creating a company add a company wide "check my details" action
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_to_company_sid           => in_sid_id
	);


	-- callout to customised systems
	chain_link_pkg.AddCompany(in_sid_id);
	
	-- add product codes defaults for the new company
	product_pkg.SetProductCodeDefaults(in_sid_id);
END;


PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
	v_company_name			company.name%TYPE;
	v_country_code			company.country_code%TYPE;
BEGIN
	IF (in_new_name IS NULL) THEN -- this is actually a virtual deletion - lets leave the name as is, but set the deleted flag
		UPDATE company
		   SET deleted = 1
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id;
		
		RETURN;
	END IF;
		
	IF NOT TrySplitSOName(in_new_name, v_company_name, v_country_code) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Chain SO Company Names must in the format: CountryName (CCC) - where CCC is three letter country code or a space with a two letter country code');
	END IF;
		
	UPDATE company
	   SET name = v_company_name,
	       country_code = TRIM(v_country_code)
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;
END;


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
	v_helper_pkg	VARCHAR2(50); 
BEGIN

	--clean up all questionnaires
	FOR r IN (
		SELECT DISTINCT qt.db_class pkg
		  FROM questionnaire q, questionnaire_type qt 
		 WHERE q.questionnaire_type_id = qt.questionnaire_type_id 
		   AND q.app_sid = qt.app_sid
		   AND q.company_sid = in_sid_id
		   AND q.app_sid = security_pkg.GetApp
	)
	LOOP
		-- clear questionnaire types for this company
		IF r.pkg IS NOT NULL THEN
			EXECUTE IMMEDIATE 'begin '||r.pkg||'.DeleteQuestionnaires(:1);end;'
				USING in_sid_id; -- company sid
		END IF;	   
	
	END LOOP;
	
	-- now clean up all things linked to company
	
	DELETE FROM applied_company_capability
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_sid_id;


	DELETE FROM event_user_status 
	 WHERE event_id IN
	(
		SELECT event_id
		  FROM event 
		 WHERE ((for_company_sid = in_sid_id) 
			OR (related_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM event
	 WHERE ((for_company_sid = in_sid_id) 
		OR (related_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	  
	
	
	
	-- clean up actions
	DELETE FROM action_user_status 
	 WHERE action_id IN
	(
		SELECT action_id
		  FROM action 
		 WHERE ((for_company_sid = in_sid_id) 
			OR (related_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action 
	 WHERE ((for_company_sid = in_sid_id) 
		OR (related_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;

	   
	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN
	(
		SELECT questionnaire_share_id
		  FROM questionnaire_share 
		 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
		   AND app_sid = security_pkg.GetApp
	)
	AND app_sid = security_pkg.GetApp;
	
	DELETE FROM questionnaire_share 
	 WHERE (qnr_owner_company_sid = in_sid_id OR share_with_company_sid = in_sid_id)
	   AND app_sid = security_pkg.GetApp;
	   
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN
	(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE company_sid = in_sid_id
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	
	DELETE FROM questionnaire
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	   
	
	DELETE FROM company_cc_email
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM company_metric
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
	  
	DELETE FROM invitation_qnr_type 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_company_sid = in_sid_id) 
			OR (to_company_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
  
  UPDATE invitation 
     SET reinvitation_of_invitation_id = NULL
   WHERE reinvitation_of_invitation_id IN (
      SELECT invitation_id 
	    FROM invitation 
	   WHERE ((from_company_sid = in_sid_id) 
          OR (to_company_sid = in_sid_id))	
         AND app_sid = security_pkg.GetApp);
	   
	DELETE FROM invitation
	 WHERE ((from_company_sid = in_sid_id) 
		OR (to_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;


	DELETE FROM supplier_relationship
	 WHERE ((supplier_company_sid = in_sid_id) 
		OR (purchaser_company_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	   
	   
	-- are we OK blanking this? I think so as this is reset sensibly when ever a chain page is loaded
	UPDATE chain_user 
	   SET default_company_sid = NULL
	 WHERE default_company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM newsflash_company WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	/* PRODUCT RELATED ITEMS TO CLEAR */
	-- clear the default product codes
	DELETE FROM product_code_type WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	
	-- clear all products and components and any links between them
	-- TODO: we'll need to fix this up...
	--DELETE FROM cmpnt_prod_rel_pending WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));	
	--DELETE FROM cmpnt_prod_relationship WHERE app_sid = security_pkg.getApp AND ((purchaser_company_sid = in_sid_id) OR (supplier_company_sid = in_sid_id));
	/* NOTE TO DO - this may be too simplistic as just clears any links where one company is deleted */
	--DELETE FROM product WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;
	--DELETE FROM component WHERE app_sid = security_pkg.getApp AND company_sid = in_sid_id;

	-- clear tasks
	FOR tn IN (
		SELECT task_node_id
		  FROM task_node
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_sid_id 
		 ORDER BY parent_task_node_id DESC
	)
	LOOP
		FOR T IN (
			SELECT task_id
			  FROM task
			 WHERE app_sid = security_pkg.GetApp
			   AND company_sid = in_sid_id 
			   AND task_node_id = tn.task_node_id
		)
		LOOP
			DELETE FROM task_doc
			 WHERE app_sid = security_pkg.GetApp
			   AND task_entry_id IN 
				(
					SELECT task_entry_id
					  FROM task_entry
					 WHERE app_sid = security_pkg.GetApp
					   AND task_id = T.task_id
				);
		
			 DELETE FROM task_entry
			  WHERE app_sid = security_pkg.GetApp
				AND task_id = T.task_id;

			
			 DELETE FROM task
			  WHERE app_sid = security_pkg.GetApp
			    AND task_id = T.task_id;
			  
		END LOOP;	
		
		DELETE FROM task_node
		 WHERE app_sid = security_pkg.GetApp
		   AND task_node_id = tn.task_node_id;
	END LOOP;
	
	chain_link_pkg.DeleteCompany(in_sid_id);
	
	DELETE FROM company
	 WHERE company_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;
END;


PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

/************************************************************
	Company Management Handlers
************************************************************/

PROCEDURE VerifySOStructure
AS
BEGIN
	FOR r IN (
		SELECT company_sid
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	) LOOP
		CreateSOStructure(r.company_sid, FALSE);
	END LOOP;
END;

PROCEDURE CreateCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT chain_pkg.GetCompaniesContainer;
BEGIN	
	-- createSO does the sec check
	SecurableObject_Pkg.CreateSO(security_pkg.GetAct, v_container_sid, class_pkg.getClassID('Chain Company'), GenerateSOName(in_name, in_country_code), out_company_sid);
	
	UPDATE company
	   SET name = in_name
	 WHERE company_sid = out_company_sid;
END;

PROCEDURE CreateUniqueCompany(
	in_name					IN  company.name%TYPE,	
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
	v_container_sid			security_pkg.T_SID_ID DEFAULT chain_pkg.GetCompaniesContainer;
BEGIN	
	BEGIN
		SELECT company_sid INTO out_company_sid FROM company WHERE name=in_name AND country_code=in_country_code;
	EXCEPTION
		WHEN no_data_found THEN
			CreateCompany(in_name, in_country_code, out_company_sid);
			RETURN;
	END;		
	RAISE dup_val_on_index;
END;

PROCEDURE DeleteCompanyFully(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	-- user groups undder the company
	v_admin_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_pending_grp_sid		security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_users_grp_sid			security_pkg.T_SID_ID := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
	v_other_company_grp_cnt	NUMBER;

BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	-- Now we need to delete all users from this company
	-- We cannot do this in DeleteSO for company as
	--		the users are NOT under the company in the tree - they are just members of groups under the company
	-- 		All the info we need to indentify which users to delete (group structure under company) is cleared by the security DeleteSO before the DeleteSO call is made above
	FOR r IN (
		SELECT DISTINCT user_sid 
		  FROM v$company_member 
		 WHERE company_sid = in_company_sid 
		   AND app_sid = security_pkg.GetApp
	)
	LOOP

		-- TO DO - this is not a full implementation but is to get round a current issue and will work currently
		-- we may need to implement a chain user SO type to do properly
		-- but - to prevent non chain users getting trashed this relies on 
		-- 		only chain users will be direct members unless we add people for no good reason via secmgr
		-- 		only users who have logged on to chain should be in chain user table  - though this could incluse superusers
	
		-- is this user in the groups of any other company
		SELECT COUNT(*) 
		INTO v_other_company_grp_cnt
		FROM 
		(
			-- this should just return chain company groups
			SELECT sid_id 
			  FROM TABLE(group_pkg.GetGroupsForMemberAsTable(security_pkg.GetAct, r.user_sid))
			 WHERE sid_id NOT IN (v_admin_grp_sid, v_pending_grp_sid, v_users_grp_sid)
			 AND parent_sid_id IN (SELECT company_sid FROM company WHERE app_sid = security_pkg.GetApp)
		);
			
		IF v_other_company_grp_cnt = 0 THEN			
			-- this user is not a member of any other companies/groups so delete them
			chain.company_user_pkg.DeleteObject(security_pkg.GetAct, r.user_sid);
		END IF;
		
	END LOOP;
	
	-- finally delete the company
	securableobject_pkg.DeleteSO(security_pkg.GetAct, in_company_sid);
END;

PROCEDURE DeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to company with sid '||in_company_sid);
	END IF;
	
	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, NULL);
END;


PROCEDURE UndeleteCompany(
	in_company_sid			IN  security_pkg.T_SID_ID
)
AS
	v_name					company.name%TYPE;
	v_cc					company.country_code%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_company_sid, security_pkg.PERMISSION_DELETE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Undelete access denied to company with sid '||in_company_sid);
	END IF;
	
	UPDATE company
	   SET deleted = 0
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid
	RETURNING name, country_code
	  INTO v_name, v_cc;
	
	securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, GenerateSOName(v_name, v_cc));	
END;


PROCEDURE UpdateCompany (
	in_company_sid			IN  security_pkg.T_SID_ID, 
	in_name					IN  company.name%TYPE,
	in_address_1			IN  company.address_1%TYPE,
	in_address_2			IN  company.address_2%TYPE,
	in_address_3			IN  company.address_3%TYPE,
	in_address_4			IN  company.address_4%TYPE,
	in_town					IN  company.town%TYPE,
	in_state				IN  company.state%TYPE,
	in_postcode				IN  company.postcode%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	in_phone				IN  company.phone%TYPE,
	in_fax					IN  company.fax%TYPE,
	in_website				IN  company.website%TYPE
)
AS
	v_cur_details			company%ROWTYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	SELECT *
	  INTO v_cur_details
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	IF v_cur_details.name <> in_name OR v_cur_details.country_code <> in_country_code THEN
		securableobject_pkg.RenameSO(security_pkg.GetAct, in_company_sid, GenerateSOName(in_name, in_country_code));
	END IF;
	
	UPDATE company
	   SET address_1 = in_address_1, 
		   address_2 = in_address_2, 
		   address_3 = in_address_3, 
		   address_4 = in_address_4, 
		   town = in_town, 
		   state = in_state, 
		   postcode = in_postcode, 
		   phone = in_phone, 
		   fax = in_fax, 
	 	   website = in_website
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
END;

FUNCTION GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, chain_pkg.GetCompaniesContainer, GenerateSOName(in_company_name, in_country_code));
END;

PROCEDURE GetCompanySid (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	out_company_sid := GetCompanySid(in_company_name, in_country_code); 
END;

PROCEDURE GetCompany (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	GetCompany(GetCompany(), out_cur);
END;

PROCEDURE GetCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF IsPurchaser(in_company_sid) THEN 
		-- default allow this to happen as this only implies read,and we
		-- don't really need a purchasers capability for anything other than this
		NULL;
	ELSE
		IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
		END IF;
	END IF;

	OPEN out_cur FOR
		SELECT c.*, code_label1, code_label2, code2_mandatory, code_label3, code3_mandatory	
		  FROM v$company c, product_code_type pct
		 WHERE c.company_sid = pct.company_sid(+) 
		   AND c.app_sid = pct.app_sid(+)
		   AND c.company_sid = in_company_sid
		   AND c.app_sid = security_pkg.GetApp;
END;

FUNCTION GetCompanyName (
	in_company_sid 			IN security_pkg.T_SID_ID
) RETURN company.name%TYPE
AS
	v_n			company.name%TYPE;
BEGIN
	
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		SELECT name
		  INTO v_n
		  FROM v$company
		 WHERE app_sid = security_pkg.GetApp
		   AND company_sid = in_company_sid;
	ELSE	
		BEGIN
			SELECT c.name
			  INTO v_n
			  FROM v$company c, v$company_relationship cr
			 WHERE c.app_sid = security_pkg.GetApp
			   AND c.app_sid = cr.app_sid
			   AND c.company_sid = in_company_sid
			   AND c.company_sid = cr.company_sid;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				v_n := ' ';
		END;
	END IF;

	RETURN v_n;
END;

	 
PROCEDURE SearchCompanies ( 
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanies(0, 0, in_search_term, v_count_cur, out_result_cur);
END;

PROCEDURE SearchCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, v$company_relationship cr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = cr.app_sid
		   AND c.company_sid = cr.company_sid 
		   AND LOWER(name) LIKE v_search
	  );
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF (NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ)) THEN
		OPEN out_count_cur FOR
			SELECT 0 total_count, 0 total_pages FROM DUAL;
		
		OPEN out_result_cur FOR
			SELECT * FROM DUAL WHERE 0 = 1;
		
		RETURN;
	END IF;
	
	-- bulk collect company sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT DISTINCT c.company_sid
		  FROM v$company c, supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND ((in_only_active = chain_pkg.active AND sr.active = chain_pkg.active) OR (in_only_active = chain_pkg.inactive))
		   AND LOWER(name) LIKE v_search
	  );
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE GetSupplierNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: This method already exists in company_pkg as SearchSuppliers (you can search with text = '' and page_size 0 for all results)
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.supplier_company_sid 
		   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
	
END;

PROCEDURE GetPurchaserNames (
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
-- TODO: this method should be moved to company_pkg	 
	OPEN out_cur FOR
	  	SELECT c.company_sid, c.name
		  FROM v$company c, v$supplier_relationship sr
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.app_sid = sr.app_sid
		   AND c.company_sid = sr.purchaser_company_sid 
		   AND sr.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND sr.purchaser_company_sid <> sr.supplier_company_sid
		 ORDER BY LOWER(name) ASC;
	
END;


PROCEDURE SearchMyCompanies ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF chain_pkg.IsChainAdmin(SYS_CONTEXT('SECURITY', 'SID')) THEN
		SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
		  BULK COLLECT INTO v_results
		  FROM (
				SELECT company_sid
				  FROM v$company
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND active = chain_pkg.ACTIVE
				   AND LOWER(name) LIKE v_search
				);
	ELSE
		-- bulk collect company sid's that match our search result
		SELECT security.T_ORDERED_SID_ROW(company_sid, NULL)
		  BULK COLLECT INTO v_results
		  FROM (
			SELECT c.company_sid
			  FROM v$company_member cm, v$company c
			 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND cm.app_sid = c.app_sid
			   AND cm.company_sid = c.company_sid
			   AND cm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND LOWER(c.name) LIKE v_search
		  );
	END IF;
	  
	CollectSearchResults(v_results, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE StartRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
		
	BEGIN
		INSERT INTO supplier_relationship
		(purchaser_company_sid, supplier_company_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE supplier_relationship
			   SET deleted = chain_pkg.NOT_DELETED, active = chain_pkg.PENDING
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND deleted = chain_pkg.DELETED
			   AND purchaser_company_sid = in_purchaser_company_sid
			   AND supplier_company_sid = in_supplier_company_sid;
	END;
END;

PROCEDURE ActivateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
	
	UPDATE supplier_relationship
	   SET active = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	purchased_component_pkg.RelationshipActivated(in_purchaser_company_sid, in_supplier_company_sid);
	
	chain_link_pkg.ActivateRelationship(in_purchaser_company_sid, in_supplier_company_sid);
END;

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_force					IN  BOOLEAN
)
AS
	v_force						NUMBER(1) DEFAULT 0;
BEGIN
	-- no security because I'm not really sure what to check 
	-- seems pointless checking read / write access on either company or a capability
		
	IF in_force THEN
		v_force := 1;
	END IF;
	
	UPDATE supplier_relationship
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (   active = chain_pkg.PENDING
	   		OR v_force = 1);
END;

PROCEDURE ActivateVirtualRelationship (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_key						OUT supplier_relationship.virtually_active_key%TYPE
)
AS
BEGIN
	ActivateVirtualRelationship(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid, out_key);
END;

PROCEDURE ActivateVirtualRelationship (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid			IN  security_pkg.T_SID_ID,
	out_key							OUT supplier_relationship.virtually_active_key%TYPE
)
AS
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied activating virtual relationships where you are niether the purchaser or supplier');
	END IF;
	
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = sysdate + interval '1' minute, virtually_active_key = virtually_active_key_seq.NEXTVAL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid
	   AND (virtually_active_key IS NULL
	    OR sysdate > virtually_active_until_dtm)
 RETURNING virtually_active_key INTO out_key;
END;

PROCEDURE DeactivateVirtualRelationship (
	in_key							IN  supplier_relationship.virtually_active_key%TYPE
)
AS
	v_purchaser_company_sid		security_pkg.T_SID_ID;
	v_supplier_company_sid		security_pkg.T_SID_ID;
BEGIN
	-- get company_sid's for security check
	BEGIN
		SELECT purchaser_company_sid, supplier_company_sid
		  INTO v_purchaser_company_sid, v_supplier_company_sid
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND virtually_active_key = in_key;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN RETURN;
	END;
	
	IF v_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND v_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deactivating virtual relationships where you are niether the purchaser or supplier');
	END IF;

	-- Only deactivate if in_key was the key that set up the relationship
	UPDATE supplier_relationship
	   SET virtually_active_until_dtm = NULL, virtually_active_key = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND virtually_active_key = in_key;
END;

PROCEDURE AddPurchaserFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT IsMember(in_supplier_company_sid, in_user_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding a purchaser follower user who is not a member of the supplier company');
	END IF;
	
	BEGIN
		INSERT INTO purchaser_follower
		(purchaser_company_sid, supplier_company_sid, user_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE AddSupplierFollower (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN
	IF NOT IsMember(in_purchaser_company_sid, in_user_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied adding a supplier follower user who is not a member of the purchaser company');
	END IF;
	
	BEGIN
		INSERT INTO supplier_follower
		(purchaser_company_sid, supplier_company_sid, user_sid)
		VALUES
		(in_purchaser_company_sid, in_supplier_company_sid, in_user_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION GetPurchaserFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading purchaser follower details where you are niether the purchaser or supplier');
	END IF;
	
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM purchaser_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_user_sids;
END;

FUNCTION GetSupplierFollowers (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN T_NUMBER_LIST
AS
	v_user_sids					T_NUMBER_LIST;
BEGIN
	IF in_purchaser_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND in_supplier_company_sid <> SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading supplier follower details where you are niether the purchaser or supplier');
	END IF;
	
	SELECT user_sid
	  BULK COLLECT INTO v_user_sids
	  FROM supplier_follower
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;

	RETURN v_user_sids;
END;


FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsMember(in_company_sid, security_pkg.GetSid);
END;

FUNCTION IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	in_user_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	IF NOT chain_pkg.IsChainAdmin(in_user_sid) AND
	   NOT VerifyMembership(in_company_sid, chain_pkg.USER_GROUP, in_user_sid) AND 
	   NOT VerifyMembership(in_company_sid, chain_pkg.PENDING_GROUP, in_user_sid) THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
END;

PROCEDURE IsMember(
	in_company_sid	IN	security_pkg.T_SID_ID,
	out_result		OUT NUMBER
)
AS
BEGIN
	IF IsMember(in_company_sid, security_pkg.GetSid) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;


PROCEDURE IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;	
	IF IsSupplier(in_supplier_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsSupplier (
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_supplier_company_sid);
END;

FUNCTION IsSupplier (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
	v_count						NUMBER(10);
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$supplier_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND purchaser_company_sid = in_purchaser_company_sid
	   AND supplier_company_sid = in_supplier_company_sid;
	
	RETURN v_count > 0;
END;

-- TO DO - if this gets used a lot we might need a new COMPANYorSUPPLIERorPURCHASER type capability
-- but this is only intended to be used for a specific "GetPurchaserCompany" which is a read only "get me the company details of someone I sell to"
PROCEDURE IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	out_result					OUT NUMBER
)
AS
BEGIN
	out_result := 0;
	IF IsPurchaser(in_purchaser_company_sid) THEN
		out_result := 1;
	END IF;
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsPurchaser(in_purchaser_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

FUNCTION IsPurchaser (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	RETURN IsSupplier(in_purchaser_company_sid, in_supplier_company_sid);
END;

FUNCTION GetSupplierRelationshipStatus (
	in_purchaser_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_status					supplier_relationship.active%TYPE;
BEGIN

	BEGIN
		SELECT active
		  INTO v_status
		  FROM supplier_relationship
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND purchaser_company_sid = in_purchaser_company_sid
		   AND supplier_company_sid = in_supplier_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_status := -1;
	END;
	
	RETURN v_status;
END;

PROCEDURE ActivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
)
AS
	v_active					company.active%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid||' for the user with sid '||security_pkg.GetSid);
	END IF;
	
	SELECT active
	  INTO v_active
	  FROM company
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	IF v_active = chain_pkg.ACTIVE THEN
		RETURN;
	END IF;
	
	UPDATE company
	   SET active = chain_pkg.ACTIVE,
	       activated_dtm = SYSDATE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	chain_link_pkg.ActivateCompany(in_company_sid);
END;

PROCEDURE GetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
		
	OPEN out_cur FOR
		SELECT email
		  FROM company_cc_email
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;

PROCEDURE SetCCList (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_emails					IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to company with sid '||in_company_sid);
	END IF;
	
	DELETE FROM company_cc_email
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	IF in_emails IS NULL OR in_emails.COUNT = 0 OR in_emails(1) IS NULL THEN
		RETURN;
	END IF;

	FOR i IN in_emails.FIRST .. in_emails.LAST 
	LOOP
		BEGIN
			INSERT INTO company_cc_email
			(company_sid, lower_email, email)
			VALUES
			(in_company_sid, LOWER(TRIM(in_emails(i))), TRIM(in_emails(i)));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
END;

PROCEDURE GetCompanyFromAddress (
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- this cursor should provide two colomns, one row - columns named: email_from_name, email_from_address
	-- TODO: Actually look this up (only return a valid cursor IF the email_from_address is set)
	OPEN out_cur FOR
		SELECT support_email email_from_name, support_email email_from_address FROM customer_options WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetUserCompanies (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_companies_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF chain_pkg.IsChainAdmin(in_user_sid) THEN
		OPEN out_count_cur FOR
			SELECT COUNT(*) companies_count
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = chain_pkg.ACTIVE;
		
		OPEN out_companies_cur FOR
			SELECT company_sid, name
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND active = chain_pkg.ACTIVE;
	
		RETURN;
	END IF;
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) companies_count
		  FROM v$company_member
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	
	OPEN out_companies_cur FOR
		SELECT c.company_sid, c.name
		  FROM v$company_member cm, v$company c
		 WHERE cm.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cm.app_sid = c.app_sid
		   AND cm.company_sid = c.company_sid
		   AND cm.user_sid = in_user_sid;
END;

PROCEDURE SetStubSetupDetails (
	in_active				IN  company.allow_stub_registration%TYPE,
	in_approve				IN  company.approve_stub_registration%TYPE,
	in_stubs				IN  chain_pkg.T_STRINGS
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing stub registration data');
	END IF;
	
	UPDATE company
	   SET allow_stub_registration = in_active,
	       approve_stub_registration = in_approve
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	DELETE FROM email_stub
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	IF in_stubs IS NULL OR in_stubs.COUNT = 0 OR in_stubs(1) IS NULL THEN
		RETURN;
	END IF;

	
	FOR i IN in_stubs.FIRST .. in_stubs.LAST 
		LOOP
			BEGIN
				INSERT INTO email_stub
				(company_sid, lower_stub, stub)
				VALUES
				(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), LOWER(TRIM(in_stubs(i))), TRIM(in_stubs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					NULL;
			END;
	END LOOP;
	
END;


PROCEDURE GetStubSetupDetails (
	out_options_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SETUP_STUB_REGISTRATION) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading data required for stub registration');
	END IF;
	
	UPDATE company
	   SET stub_registration_guid = user_pkg.GenerateAct
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND stub_registration_guid IS NULL;
	
	OPEN out_options_cur FOR
		SELECT stub_registration_guid, allow_stub_registration, approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
	OPEN out_stubs_cur FOR
		SELECT stub 
		  FROM email_stub 
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 ORDER BY lower_stub;

END;

PROCEDURE GetCompanyFromStubGuid (
	in_guid					IN  company.stub_registration_guid%TYPE,
	out_state_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_stubs_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	-- no sec checks (public page)
	BEGIN
		SELECT company_sid
		  INTO v_company_sid
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND active = chain_pkg.ACTIVE -- company is active
		   AND allow_stub_registration = chain_pkg.ACTIVE -- allow stub registration
		   AND LOWER(stub_registration_guid) = LOWER(in_guid) -- match guid
		   			-- email stubs are set
		   AND company_sid IN (SELECT company_sid FROM email_stub WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'));
		
		OPEN out_state_cur FOR
			SELECT chain_pkg.GUID_OK guid_state FROM DUAL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			
			RETURN;
	END;
	
	OPEN out_company_cur FOR
		SELECT company_sid, name, country_name
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid;
	
	OPEN out_stubs_cur FOR
		SELECT stub, lower_stub
		  FROM email_stub
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_company_sid
		 ORDER BY lower_stub;
END;

PROCEDURE ConfirmCompanyDetails (
	in_company_sid					IN  security_pkg.T_SID_ID
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_WRITE)  THEN
		RETURN;
	END IF;
	
	UPDATE company
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND company_sid = in_company_sid;
	
	message_pkg.CompleteMessage (
		in_primary_lookup           => chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_to_company_sid           => in_company_sid
	);
END;

END company_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.company_user_pkg
IS

/****************************************************************************************
****************************************************************************************
	SECURITY OVERRIDE FUNCTIONS
****************************************************************************************
****************************************************************************************/

PROCEDURE AddGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 
	BEGIN
	    INSERT INTO security.group_members (member_sid_id, group_sid_id)
		VALUES (in_member_sid, in_group_sid);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			-- They are already in the group
			NULL;
	END;
END; 

PROCEDURE DeleteGroupMember(
	in_member_sid	IN Security_Pkg.T_SID_ID,
    in_group_sid	IN Security_Pkg.T_SID_ID
)
AS 
BEGIN 	
	DELETE
      FROM security.group_members 
     WHERE member_sid_id = in_member_sid and group_sid_id = in_group_sid;
END;

/****************************************************************************************
****************************************************************************************
	PRIVATE
****************************************************************************************
****************************************************************************************/


/* INTERNAL ONLY */
PROCEDURE UpdatePasswordResetExpirations 
AS
BEGIN
	-- don't worry about sec checks - this needs to be done anyways
	
	-- get rid of anything that's expired
	DELETE
	  FROM reset_password
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (expiration_dtm < SYSDATE OR
		   (	expiration_dtm < SYSDATE + (1/(24*12)) -- 5 minutes
			AND expiration_grace = chain_pkg.ACTIVE
		   ));
END;

FUNCTION GetPasswordResetDetails (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_user_sid 			OUT security_pkg.T_SID_ID,
	out_invitation_id 		OUT reset_password.accept_invitation_on_reset%TYPE,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_user_name				security_pkg.T_SO_NAME;
BEGIN
	UpdatePasswordResetExpirations;
	
	BEGIN	
		SELECT rp.user_sid, rp.accept_invitation_on_reset, csru.user_name
		  INTO out_user_sid, out_invitation_id, v_user_name
		  FROM reset_password rp, csr.csr_user csru
		 WHERE rp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND rp.app_sid = csru.app_sid
		   AND rp.user_sid = csru.csr_user_sid
		   AND LOWER(rp.guid) = LOWER(in_guid);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN	
			OPEN out_state_cur FOR 
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;
	
	
	OPEN out_state_cur FOR 
		SELECT chain_pkg.GUID_OK guid_state, out_user_sid user_sid, v_user_name user_name, out_invitation_id invitation_id FROM DUAL;
		
	RETURN TRUE;
END;


-- collects a paged cursor of users based on sids passed in as a T_ORDERED_SID_TABLE
PROCEDURE CollectSearchResults (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_all_results			IN  security.T_ORDERED_SID_TABLE,
	in_show_admins			IN  BOOLEAN,
	in_page   				IN  number,
	in_page_size    		IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_show_admins			NUMBER(1) DEFAULT 0;
BEGIN
	IF in_show_admins THEN
		v_show_admins := 1;
	END IF;
	
	-- count the total search results found
	OPEN out_count_cur FOR
	 	SELECT COUNT(*) total_count,
			   CASE WHEN in_page_size = 0 THEN 1 
			   	    ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
	      FROM TABLE(in_all_results);
	
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
			SELECT * FROM (
				SELECT ccu.*, CASE WHEN v_show_admins = 1 THEN NVL(ca.user_sid, 0) ELSE 0 END is_admin
				  FROM v$chain_company_user ccu, TABLE(in_all_results) T, v$company_admin ca
				 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND ccu.app_sid = ca.app_sid(+)
				   AND ccu.company_sid = in_company_sid
				   AND ccu.company_sid = ca.company_sid(+)
				   AND ccu.user_sid = T.SID_ID
				   AND ccu.user_sid = ca.user_sid(+)
			 	)
		 	 ORDER BY is_admin DESC, LOWER(full_name);
	
	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT * FROM (
							SELECT ccu.*, CASE WHEN v_show_admins = 1 THEN NVL(ca.user_sid, 0) ELSE 0 END is_admin
							  FROM v$chain_company_user ccu, TABLE(in_all_results) T, v$company_admin ca
							 WHERE ccu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
							   AND ccu.app_sid = ca.app_sid(+)
							   AND ccu.company_sid = in_company_sid
							   AND ccu.company_sid = ca.company_sid(+)
				   			   AND ccu.user_sid = T.SID_ID
				   			   AND ccu.user_sid = ca.user_sid(+)
							)
						 ORDER BY is_admin DESC, LOWER(full_name)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

PROCEDURE InternalUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
)
AS
	v_cur_details			csr.csr_user%ROWTYPE;
BEGIN
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
	
	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> security_pkg.GetAct,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_cur_details.user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> in_friendly_name,
		in_email					=> v_cur_details.email,
		in_job_title				=> in_job_title,
		in_phone_number				=> in_phone_number,
		in_region_mount_point_sid	=> v_cur_details.region_mount_point_sid,
		in_active					=> NULL,
		in_info_xml					=> v_cur_details.info_xml,
		in_send_alerts				=> v_cur_details.send_alerts
	);
	
	UPDATE chain_user
	   SET visibility_id = in_visibility_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid
	   AND in_visibility_id <> -1;
END;

FUNCTION CreateUserINTERNAL (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_skip_capability_check IN  BOOLEAN
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_rsa					customer_options.default_receive_sched_alerts%TYPE;
BEGIN
	
	IF NOT in_skip_capability_check AND NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.CREATE_USER)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied creating users in the company with sid '||in_company_sid);
	END IF;
	
	BEGIN
		csr.csr_user_pkg.createUser(
			in_act						=> security_pkg.GetAct, 
			in_app_sid					=> security_pkg.GetApp, 
			in_user_name				=> TRIM(in_user_name),
			in_password					=> TRIM(in_password),
			in_full_name				=> TRIM(in_full_name),
			in_friendly_name			=> TRIM(in_friendly_name),
			in_email					=> TRIM(in_email),
			in_job_title				=> null,
			in_phone_number				=> null,
			in_region_mount_point_sid	=> null,
			in_info_xml					=> null,
			in_send_alerts				=> 1,
			out_user_sid				=> v_user_sid
		);		

		csr.csr_user_pkg.DeactivateUser(security_pkg.GetAct, v_user_sid);

		-- see what the app default for receiving schedualed alerts is
		SELECT default_receive_sched_alerts
		  INTO v_rsa
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
		
		INSERT INTO chain_user
		(user_sid, visibility_id, registration_status_id, default_company_sid, tmp_is_chain_user, receive_scheduled_alerts)
		VALUES
		(v_user_sid, chain_pkg.NAMEJOBTITLE, chain_pkg.PENDING, in_company_sid, chain_pkg.ACTIVE, v_rsa);
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.CONFIRM_YOUR_DETAILS,
			in_to_user_sid              => v_user_sid
		);

		
		-- callout to customised systems
		chain_link_pkg.AddCompanyUser (in_company_sid, v_user_sid); 
	EXCEPTION
		-- if we've got a dup object name, check to see if they're pending
		WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN
			GetUserSid(in_user_name, v_user_sid);
			-- verify that they're pending, otherwise it's a problem
			BEGIN
				SELECT user_sid
				  INTO v_user_sid
				  FROM chain_user
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND registration_status_id = chain_pkg.PENDING
				   AND user_sid = v_user_sid;
			EXCEPTION
				-- if they're not pending, rethrow the error
				WHEN NO_DATA_FOUND THEN
					RAISE_APPLICATION_ERROR(security_pkg.ERR_DUPLICATE_OBJECT_NAME, 'User '||in_user_name||' already exists and is not PENDING');
			END;	
	END;
	
	RETURN v_user_sid;
END;



/************************************************************
	Securable object handlers
************************************************************/


PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN

	DELETE FROM event_user_status 
	 WHERE event_id IN
	(
		SELECT event_id
		  FROM event 
		 WHERE ((for_user_sid = in_sid_id) 
		OR (related_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM event_user_status 
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	   
	DELETE FROM event
	 WHERE ((for_user_sid = in_sid_id) 
		OR (related_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	  
	
	
	
	-- clean up actions
	DELETE FROM action_user_status 
	 WHERE action_id IN
	(
		SELECT action_id
		  FROM action 
		 WHERE ((for_user_sid = in_sid_id) 
			OR (related_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action_user_status 	
	 WHERE user_sid = in_sid_id
	   AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM action 
	 WHERE ((for_user_sid = in_sid_id) 
		OR (related_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;	
	
	DELETE FROM invitation_qnr_type 
	 WHERE invitation_id IN
	(
		SELECT invitation_id
		  FROM invitation 
		 WHERE ((from_user_sid = in_sid_id) 
			OR (to_user_sid = in_sid_id))	
		   AND app_sid = security_pkg.GetApp
	) 
	AND app_sid = security_pkg.GetApp;	

    DELETE FROM chain.alert_entry_named_param WHERE alert_entry_id IN (
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id 
    );
    DELETE FROM chain.alert_entry_ordered_param WHERE alert_entry_id IN (
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    );
    DELETE FROM chain.alert_entry_action WHERE user_sid=in_sid_id;
    DELETE FROM chain.alert_entry_action WHERE action_id IN (
        SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
            UNION
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    );
    DELETE FROM chain.alert_entry_event WHERE user_sid=in_sid_id;
    DELETE FROM chain.alert_entry_event WHERE event_id IN (
        SELECT event_id FROM chain.event WHERE for_user_sid=in_sid_id
            UNION
        SELECT alert_entry_id FROM chain.alert_entry_action WHERE action_id IN (
            SELECT action_id FROM chain.action WHERE for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry_event WHERE event_id IN (
            SELECT event_id FROM chain.action WHERE related_user_sid=in_sid_id OR for_user_sid=in_sid_id
        ) UNION
        SELECT alert_entry_id FROM chain.alert_entry WHERE user_sid=in_sid_id
    );

   UPDATE invitation 
      SET reinvitation_of_invitation_id = NULL
    WHERE reinvitation_of_invitation_id IN (
      SELECT invitation_id 
	    FROM invitation 
	   WHERE ((from_user_sid = in_sid_id) 
          OR (to_user_sid = in_sid_id))
         AND app_sid = security_pkg.GetApp);
	   
	DELETE FROM invitation
	 WHERE ((from_user_sid = in_sid_id) 
		OR (to_user_sid = in_sid_id))	
	   AND app_sid = security_pkg.GetApp;
     
   UPDATE invitation 
      SET cancelled_by_user_sid = NULL
    WHERE cancelled_by_user_sid = in_sid_id 
	  AND app_sid = security_pkg.GetApp;

	DELETE FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_sid_id;
	  
   
	csr.csr_user_pkg.DeleteUser(security_pkg.GetAct, in_sid_id);

END;

/****************************************************************************************
****************************************************************************************
	PUBLIC 
****************************************************************************************
****************************************************************************************/



FUNCTION CreateUserForInvitation (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	RETURN CreateUserINTERNAL(in_company_sid, in_email, in_full_name, NULL, in_friendly_name, in_email, TRUE);
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT CreateUser(in_company_sid, in_user_name, in_full_name, NULL, in_friendly_name, in_email);
BEGIN
	InternalUpdateUser(v_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id);
	RETURN v_user_sid;
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_user_sid				security_pkg.T_SID_ID DEFAULT CreateUser(in_company_sid, in_full_name, NULL, in_friendly_name, in_email);
BEGIN
	InternalUpdateUser(v_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id);
	RETURN v_user_sid;
END;

FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN
	-- normal chain behaviour - email is username
	RETURN CreateUser(in_company_sid, in_email, in_full_name, in_password, in_friendly_name, in_email);
END;
	
FUNCTION CreateUser (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_name			IN	csr.csr_user.user_name%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_password				IN	Security_Pkg.T_USER_PASSWORD, 	
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE
) RETURN security_pkg.T_SID_ID
AS
BEGIN	
	RETURN CreateUserINTERNAL(in_company_sid, in_user_name, in_full_name, in_password, in_friendly_name, in_email, FALSE);
END;

PROCEDURE SetMergedStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_merged_to_user_sid	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- sec checks handled by delete user
	IF in_user_sid = in_merged_to_user_sid THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging a user with themselves');
	ELSE
		
		IF GetRegistrationStatus(in_merged_to_user_sid) != chain_pkg.REGISTERED THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging to the user with sid '||in_merged_to_user_sid||' - they are not a registered user');
		END IF;
		
		IF GetRegistrationStatus(in_user_sid) != chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied merging the user with sid '||in_user_sid||' - they are not pending registration');
		END IF;
	END IF;
	
	UPDATE chain_user
	   SET registration_status_id = chain_pkg.MERGED,
		   merged_to_user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

	DeleteUser(in_user_sid);
	
	UPDATE supplier_follower
	   SET user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	UPDATE purchaser_follower
	   SET user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

	UPDATE message
	   SET re_user_sid = in_merged_to_user_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND re_user_sid = in_user_sid;
	
	-- TOOD: merge message recipients?
END;

PROCEDURE DeleteUser (
	in_act					IN	security_pkg.T_ACT_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- sec check handled in csr_user_pkg.DeleteUser 
	
	UPDATE chain_user
	   SET deleted = 1
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	csr.csr_user_pkg.DeleteUser(in_act, in_user_sid);
END;

PROCEDURE DeleteUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	DeleteUser(security_pkg.GetAct, in_user_sid);
END;

PROCEDURE SetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_status				IN  chain_pkg.T_REGISTRATION_STATUS
)
AS
	v_cur_status	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	
	IF in_status = chain_pkg.MERGED THEN
		RAISE_APPLICATION_ERROR(-20001, 'Merged status must be set using SetMergedStatus');
	END IF;
	
	-- get the current status
	SELECT registration_status_id
	  INTO v_cur_status
	  FROM chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	-- if the status isn't changing, get out
	IF in_status = v_cur_status THEN
		RETURN;
	END IF;
	
	IF in_status = chain_pkg.PENDING THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot revert a user status to pending');
	END IF;
	
	IF in_status = chain_pkg.REJECTED THEN
		IF v_cur_status <> chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied setting status to rejected when the current status is not pending (on user with sid'||in_user_sid||')');
		END IF;
		
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_DELETE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied deleting the user with sid '||in_user_sid);
		END IF;

		DeleteUser(in_user_sid);
	END IF;
	
	IF in_status = chain_pkg.REGISTERED THEN
		IF v_cur_status <> chain_pkg.PENDING THEN
			RAISE_APPLICATION_ERROR(-20001, 'Access denied setting status to registered when the current status is not pending (on user with sid'||in_user_sid||')');
		END IF;
	END IF;
	
	
	-- finally, set the new status
	UPDATE chain_user
	   SET registration_status_id = in_status
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;

END;

PROCEDURE AddUserToCompany (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_count					NUMBER(10) DEFAULT 0;
BEGIN
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;

	AddGroupMember(in_user_sid, v_pending_sid);
	
	-- URG!!!! we'll make them full users straight away for now...
	ApproveUser(in_company_sid, in_user_sid);
	
	-- if we don't have an admin user, this user will go straight to the top
	IF v_count = 0 THEN
		MakeAdmin(in_company_sid, in_user_sid);
	END IF;
END;

PROCEDURE SetVisibility (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_visibility			IN  chain_pkg.T_VISIBILITY
)
AS
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to the user with sid '||in_user_sid);
	END IF;
	
	BEGIN
		INSERT INTO chain_user
		(user_sid, visibility_id, registration_status_id)
		VALUES
		(in_user_sid, in_visibility, chain_pkg.REGISTERED);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain_user
			   SET visibility_id = in_visibility
			 WHERE app_sid =  security_pkg.GetApp
			   AND user_sid = in_user_sid;
	END;		
END;

PROCEDURE GetUserSid (
	in_user_name			IN  security_pkg.T_SO_NAME,
	out_user_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	out_user_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/'||in_user_name);
	-- we're probably getting the sid to do something with them - make sure they're in chain
	chain_pkg.AddUserToChain(out_user_sid);
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_search_term  		IN  varchar2,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_count_cur				security_pkg.T_OUTPUT_CUR;
BEGIN
	SearchCompanyUsers(in_company_sid, 0, 0, in_search_term, v_count_cur, out_result_cur);
END;

PROCEDURE SearchCompanyUsers ( 
	in_company_sid			IN security_pkg.T_SID_ID,
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
	v_show_admins			BOOLEAN;
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.COMPANYorSUPPLIER, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to company with sid '||in_company_sid);
	END IF;
			
	-- bulk collect user sid's that match our search result
	SELECT security.T_ORDERED_SID_ROW(user_sid, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT user_sid
		  FROM v$chain_company_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   	   AND company_sid = in_company_sid
	   	   AND (LOWER(full_name) LIKE v_search OR
	   	   		LOWER(job_title) LIKE v_search)
	  );
	
	v_show_admins := (in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')) 
				  OR (capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE));
	  
	CollectSearchResults(in_company_sid, v_results, v_show_admins, in_page, in_page_size, out_count_cur, out_result_cur);
END;

PROCEDURE ApproveUser (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_pending_sid 			security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.PENDING_GROUP);
	v_user_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.USER_GROUP);
	v_count					NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting a user who is not a company member');
	END IF;	
	
	DeleteGroupMember(in_user_sid, v_pending_sid); 
	AddGroupMember(in_user_sid, v_user_sid); 
	chain_link_pkg.ApproveUser(in_company_sid, in_user_sid);
END;

PROCEDURE MakeAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) 
AS
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_count					NUMBER(10);
BEGIN	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid
	   AND user_sid = in_user_sid;
	
	-- check that the user is already a member of the company in some respect
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promoting a user who is not a company member');
	END IF;
	
	ApproveUser(in_company_sid, in_user_sid);
	AddGroupMember(in_user_sid, v_admin_sid); 
END;

FUNCTION RemoveAdmin (
	in_company_sid			IN security_pkg.T_SID_ID,
	in_user_sid				IN security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_admin_sid				security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, in_company_sid, chain_pkg.ADMIN_GROUP);
	v_count					NUMBER(10);
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PROMOTE_USER) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied promting users on company sid '||in_company_sid);
	END IF;
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_admin
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	-- if the admin group only has one member, and we're trying to remove that member, block it - every company needs to have an admin
	IF v_count = 1 THEN
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_admin
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;
		   
		IF v_count = 1 THEN
			RETURN 0;
		END IF;
	END IF;
	
	DeleteGroupMember(in_user_sid, v_admin_sid); 
	
	RETURN 1;
END;

PROCEDURE CheckPasswordComplexity (
	in_email				IN  security_pkg.T_SO_NAME,
	in_password				IN  security_pkg.T_USER_PASSWORD
)
AS
BEGIN
	security.AccountPolicyHelper_Pkg.CheckComplexity(in_email, in_password);
END;

PROCEDURE CompleteRegistration (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_password				IN  Security_Pkg.T_USER_PASSWORD
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_cur_details			csr.csr_user%ROWTYPE;
	v_cur_rs			    chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	-- changes to email address are not permitted during registratino completion
	
	-- major sec checks handled by csr_user_pkg
	
	IF GetRegistrationStatus(in_user_sid) != chain_pkg.PENDING THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing the registration for the user with sid '||in_user_sid||' - they are not pending registration');
	END IF;
	
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;

	
	-- update the user details
	csr.csr_user_pkg.amendUser(
		in_act						=> v_act_id,
		in_user_sid					=> in_user_sid,
		in_user_name				=> v_cur_details.user_name,
   		in_full_name				=> TRIM(in_full_name),
   		in_friendly_name			=> v_cur_details.friendly_name,
		in_email					=> v_cur_details.email,
		in_job_title				=> v_cur_details.job_title,
		in_phone_number				=> v_cur_details.phone_number,
		in_region_mount_point_sid	=> v_cur_details.region_mount_point_sid,
		in_active					=> 1, -- set them to active
		in_info_xml					=> v_cur_details.info_xml,
		in_send_alerts				=> v_cur_details.send_alerts
	);
	
	-- set the password
	user_pkg.ChangePasswordBySID(v_act_id, in_password, in_user_sid);
	
	-- register our user
	SetRegistrationStatus(in_user_sid, chain_pkg.REGISTERED);
END;

PROCEDURE BeginUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name			IN  csr.csr_user.full_name%TYPE, 
	in_friendly_name		IN  csr.csr_user.friendly_name%TYPE, 
	in_phone_number			IN  csr.csr_user.phone_number%TYPE, 
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_visibility_id		IN  chain_user.visibility_id%TYPE
)
AS
	v_visibility_id			 chain_user.visibility_id%TYPE;
	v_count					NUMBER(10);
	v_cur_details			csr.csr_user%ROWTYPE;
BEGIN
	-- meh - just clear it out to prevent dup checks
	DELETE FROM tt_user_details;
	
	-- we can update our own stuff
	IF in_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, in_visibility_id);
		
		RETURN;
	END IF;
	
	SELECT visibility_id
	  INTO v_visibility_id
	  FROM v$chain_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND user_sid = in_user_sid;
	
	-- is the user a member of our company
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND user_sid = in_user_sid;

	IF v_count > 0 THEN
		-- can we write to our own company?
		IF NOT capability_pkg.CheckCapability(chain_pkg.COMPANY, security_pkg.PERMISSION_WRITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
		END IF;
		
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, v_visibility_id);

		RETURN;
	END IF;
	
	IF v_visibility_id = chain_pkg.HIDDEN THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
	END IF;
	
	-- ok, so they must be a supplier user...
	SELECT COUNT(*)
	  INTO v_count
	  FROM v$company_member cm, v$supplier_relationship sr
	 WHERE sr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND sr.app_sid = cm.app_sid
	   AND sr.purchaser_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND sr.supplier_company_sid = cm.company_sid
	   AND cm.user_sid = in_user_sid;

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
	END IF;
	
	-- now let's confirm that we can write to suppliers...
	IF NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid);
	END IF;
	
	-- they ARE a supplier user - let's see what we can actually updated...
	SELECT *
	  INTO v_cur_details
	  FROM csr.csr_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csr_user_sid = in_user_sid;
	
	CASE 
	WHEN v_visibility_id = chain_pkg.JOBTITLE THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, v_cur_details.full_name, v_cur_details.friendly_name, v_cur_details.phone_number, in_job_title, v_visibility_id);
	
	WHEN v_visibility_id = chain_pkg.NAMEJOBTITLE THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name,v_cur_details.phone_number, in_job_title, v_visibility_id);
	
	WHEN v_visibility_id = chain_pkg.FULL THEN
		INSERT INTO tt_user_details
		(user_sid, full_name, friendly_name, phone_number, job_title, visibility_id)
		VALUES
		(in_user_sid, in_full_name, in_friendly_name, in_phone_number, in_job_title, v_visibility_id);
	
	END CASE;	
END;

PROCEDURE EndUpdateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
	v_details				tt_user_details%ROWTYPE;
BEGIN
	IF GetRegistrationStatus(in_user_sid) != chain_pkg.REGISTERED THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied updating the user with sid '||in_user_sid||' - they are not registered');
	END IF;

	SELECT *
	  INTO v_details
	  FROM tt_user_details
	 WHERE user_sid = in_user_sid;
	
	InternalUpdateUser(in_user_sid, v_details.full_name, v_details.friendly_name, v_details.phone_number, v_details.job_title, v_details.visibility_id);
END;


FUNCTION GetRegistrationStatus (
	in_user_sid				IN  security_pkg.T_SID_ID
) RETURN chain_pkg.T_REGISTRATION_STATUS
AS
	v_rs			    	chain_pkg.T_REGISTRATION_STATUS;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_user_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading the user with sid '||in_user_sid);
	END IF;	 
	
	BEGIN
		SELECT registration_status_id
		  INTO v_rs
		  FROM chain_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			chain_pkg.AddUserToChain(in_user_sid);
			
			-- try again
			SELECT registration_status_id
			  INTO v_rs
			  FROM chain_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = in_user_sid;
	END;
	   
	RETURN v_rs;
END;		
	
	
PROCEDURE GetUser (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetUser(SYS_CONTEXT('SECURITY', 'SID'), out_cur);
END;

PROCEDURE GetUser (
	in_user_sid				IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM v$chain_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND user_sid = in_user_sid;
END;
	
PROCEDURE PreparePasswordReset (
	in_param				IN  VARCHAR2,
	in_accept_guid			IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id				security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid				security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	t_users					security.T_SO_TABLE DEFAULT securableobject_pkg.GetChildrenAsTable(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users'));
	v_sid					security_pkg.T_SID_ID;
	v_guid					security_pkg.T_ACT_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN

	
	BEGIN
		SELECT csr_user_sid
		  INTO v_sid
		  FROM TABLE(t_users) so, csr.csr_user csru
		 WHERE csru.app_sid = v_app_sid
		   AND so.sid_id = csru.csr_user_sid
		   AND LOWER(TRIM(csru.user_name)) = LOWER(TRIM(in_param));
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	IF v_sid IS NULL THEN
		-- email addresses aren't necessarily unique, so I guess we should only reset the password when they are
		BEGIN
			SELECT csr_user_sid
			  INTO v_sid
			  FROM TABLE(t_users) so, csr.csr_user csru
			 WHERE csru.app_sid = v_app_sid
			   AND so.sid_id = csru.csr_user_sid
			   AND LOWER(TRIM(csru.email)) = LOWER(TRIM(in_param));
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
			WHEN TOO_MANY_ROWS THEN
				NULL;
		END;	
	END IF;
	   
	IF v_sid IS NULL THEN
		RETURN;
	END IF;	
	
	-- do not send if the account is inactive
	IF user_pkg.GetAccountEnabled(v_act_id, v_sid) = 0 THEN
		RETURN;
	END IF;
	
	INSERT INTO reset_password
	(guid, user_sid, accept_invitation_on_reset)
	VALUES
	(user_pkg.GenerateACT, v_sid, invitation_pkg.GetInvitationId(in_accept_guid))
	RETURN guid INTO v_guid;
	
	-- TODO: Notify user that a password reset was requested
	-- this is a bit tricky because events are company specific, not user specific (doh!)
	
	OPEN out_cur FOR
		SELECT csru.friendly_name, csru.full_name, csru.email, rp.guid, rp.expiration_dtm, rp.user_sid
		  FROM csr.csr_user csru, reset_password rp
		 WHERE rp.app_sid = v_app_sid
		   AND rp.app_sid = csru.app_sid
		   AND rp.user_sid = csru.csr_user_sid
		   AND rp.guid = v_guid;
		   
END;

PROCEDURE StartPasswordReset (
	in_guid					IN  security_pkg.T_ACT_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
	v_result				BOOLEAN;
BEGIN
	UPDATE reset_password
	   SET expiration_grace = 1
	 WHERE app_sid = SYS_CONTEXT('SECURTY', 'APP')
	   AND LOWER(guid) = LOWER(in_guid)
	   AND expiration_dtm > SYSDATE;
	
	-- who cares about result...
	v_result := GetPasswordResetDetails(in_guid, v_user_sid, v_invitation_id, out_cur);
END;

PROCEDURE ResetPassword (
	in_guid					IN  security_pkg.T_ACT_ID,
	in_password				IN  Security_Pkg.T_USER_PASSWORD,
	out_state_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_invitation_id			invitation.invitation_id%TYPE;
BEGIN

	IF (GetPasswordResetDetails(in_guid, v_user_sid, v_invitation_id, out_state_cur)) THEN
		user_pkg.ChangePasswordBySID(security_pkg.GetAct, in_password, v_user_sid);	
	END IF;
	
	-- remove all outstanding resets for this user
	DELETE FROM reset_password
	 WHERE user_sid = v_user_sid; 
END;

PROCEDURE ResetPassword (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_password				IN  Security_pkg.T_USER_PASSWORD
)
AS
	v_count					NUMBER(10);
BEGIN
	-- only check this if we're trying to set the password of a different user
	IF in_user_sid <> security_pkg.GetSid THEN
		
		-- capability checks should have already take place as this may be called by the UCD
		-- we'll just verify that the user is actually a company user
	
		SELECT COUNT(*)
		  INTO v_count
		  FROM v$company_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND user_sid = in_user_sid;

		IF v_count = 0 THEN
			RAISE_APPLICATION_ERROR(Security_Pkg.ERR_ACCESS_DENIED, 'The user with sid '||in_user_sid||' is not a user of the company with sid '||in_company_sid);
		END IF;
	END IF;
	
	user_pkg.ChangePasswordBySID(security_pkg.GetAct, in_password, in_user_sid);	
	
END;

PROCEDURE CheckEmailAvailability (
	in_email					IN  security_pkg.T_SO_NAME
) 
AS
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app_sid					security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
	v_csr_users					security_pkg.T_SID_ID DEFAULT securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'Users');
	v_count						NUMBER(10);
BEGIN
	-- see if there's a duplicate name, that is not the user that the invitation is originally addressed to
	SELECT COUNT(*)
	  INTO v_count
	  FROM chain_user cu, TABLE(securableobject_pkg.GetChildrenAsTable(v_act_id, v_csr_users)) T
	 WHERE cu.app_sid = v_app_sid
	   AND cu.user_sid = T.sid_id
	   AND cu.registration_status_id <> chain_pkg.PENDING
	   AND LOWER(TRIM(T.name)) = LOWER(TRIM(in_email));
	
	-- if we've got a duplicate, let's blow up!
	IF v_count <> 0 THEN
		RAISE_APPLICATION_ERROR(Security_Pkg.ERR_DUPLICATE_OBJECT_NAME, 'Duplicate user name found');
	END IF;

END;

PROCEDURE ActivateUser (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	csr.csr_user_pkg.ActivateUser(security_pkg.GetAct, in_user_sid);
	chain_link_pkg.ActivateUser(in_user_sid);
END;

PROCEDURE ConfirmUserDetails (
	in_user_sid				IN  security_pkg.T_SID_ID
)
AS
BEGIN
	UPDATE chain_user
	   SET details_confirmed = 1
	 WHERE app_sid = security_pkg.GetApp
	   AND user_sid = in_user_sid;

	message_pkg.CompleteMessage (
		in_primary_lookup           => chain_pkg.CONFIRM_YOUR_DETAILS,
		in_to_user_sid          	=> in_user_sid
	);
END;

END company_user_pkg;
/
CREATE OR REPLACE PACKAGE BODY CHAIN.invitation_pkg
IS

PROCEDURE AnnounceSids
AS
	v_user_name			varchar2(100);
	v_company_name		varchar2(100);
BEGIN
	SELECT so.name
	  INTO v_user_name
	  FROM security.securable_object so
	 WHERE so.sid_id = SYS_CONTEXT('SECURITY', 'SID');
	  /*
	  , v_company_name
	  FROM security.securable_object so, chain.company c
	 WHERE so.sid_id = SYS_CONTEXT('SECURITY', 'SID')
	   AND c.company_sid = NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), SYS_CONTEXT('SECURITY', 'SID'));
	*/
	RAISE_APPLICATION_ERROR(-20001, '"'||v_user_name||'" of "'||v_company_name||'"');
END;

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION GetInvitationStateByGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_invitation_id			OUT invitation.invitation_id%TYPE,
	out_to_user_sid				OUT security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
BEGIN
	-- make sure that the expiration status' have been updated
	UpdateExpirations;

	BEGIN
		SELECT i.invitation_id, i.invitation_status_id, i.to_user_sid
		  INTO out_invitation_id, v_invitation_status_id, out_to_user_sid
		  FROM invitation i, v$company fc, v$company tc
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = tc.app_sid
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.to_company_sid = tc.company_sid
		   AND LOWER(i.guid) = LOWER(in_guid)
       AND i.reinvitation_of_invitation_id IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			OPEN out_state_cur FOR
				SELECT chain_pkg.GUID_NOTFOUND guid_state FROM DUAL;
			RETURN FALSE;
	END;

	IF v_invitation_status_id <> chain_pkg.ACTIVE THEN
		OPEN out_state_cur FOR
			SELECT CASE
				WHEN v_invitation_status_id = chain_pkg.EXPIRED THEN chain_pkg.GUID_EXPIRED
				ELSE chain_pkg.GUID_ALREADY_USED
				END guid_state FROM DUAL;
		RETURN FALSE;
	END IF;

	-- only include the to_user_sid if the guid is ok
	OPEN out_state_cur FOR
		SELECT chain_pkg.GUID_OK guid_state, out_to_user_sid to_user_sid FROM DUAL;

	RETURN TRUE;
END;

FUNCTION GetInvitationStateByGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_invitation_id			OUT invitation.invitation_id%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
) RETURN BOOLEAN
AS
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	RETURN GetInvitationStateByGuid(in_guid, out_invitation_id, v_to_user_sid, out_state_cur);
END;

/**********************************************************************************
	PUBLIC
**********************************************************************************/

FUNCTION GetInvitationTypeByGuid (
	in_guid						IN  invitation.guid%TYPE
) RETURN chain_pkg.T_INVITATION_TYPE
AS
	v_invitation_type_id		chain_pkg.T_INVITATION_TYPE;
BEGIN
	BEGIN
		SELECT invitation_type_id
		  INTO v_invitation_type_id
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid)
       AND reinvitation_of_invitation_id IS NULL;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_invitation_type_id := chain_pkg.UNDEFINED;
	END;

	RETURN v_invitation_type_id;
END;

PROCEDURE UpdateExpirations
AS
	v_event_id		event.event_id%TYPE;
BEGIN
	-- don't worry about sec checks - this needs to be done anyways

	-- There's a very small possibility that an invitation will expire during the time from
	-- when a user first accesses the landing page, and when they actually submit the registration (or login).
	-- Instead of confusing them, let's only count it as expired if it expired more than an hour ago.
	-- We'll track this by checking if the expriation_grace flag is set.

	FOR r IN (
		SELECT *
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_status_id = chain_pkg.ACTIVE
	       AND ((
	       		    expiration_dtm < SYSDATE
	            AND expiration_grace = chain_pkg.INACTIVE
	           ) OR (
	       	        expiration_dtm < SYSDATE - (1/24) -- one hour grace period
	       	   	AND expiration_grace = chain_pkg.ACTIVE
	       	   ))
	) LOOP
		UPDATE invitation
		   SET invitation_status_id = chain_pkg.EXPIRED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = r.invitation_id;

		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.INVITATION_EXPIRED,
			in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => r.from_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.to_company_sid,
			in_re_user_sid              => r.to_user_sid
		);
		
		-- TODO: cleanup the dead objects that were associated with the invitation
	END LOOP;
END;

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_dummy_sids				security_pkg.T_SID_IDS;
	v_dummy_strings				chain_pkg.T_STRINGS;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	v_invitation_id := CreateInvitation(in_invitation_type_id, NULL, NULL, in_to_company_sid, in_to_user_sid, in_expiration_life_days, v_dummy_sids, v_dummy_strings);

	OPEN out_cur FOR
		SELECT *
		  FROM invitation
		 WHERE invitation_id = v_invitation_id;
END;

PROCEDURE CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN

	v_invitation_id := CreateInvitation(in_invitation_type_id, NVL(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_to_company_sid), SYS_CONTEXT('SECURITY', 'SID'), in_to_company_sid, in_to_user_sid, in_expiration_life_days, in_qnr_types, in_due_dtm_strs);

	OPEN out_cur FOR
		SELECT *
		  FROM invitation
		 WHERE invitation_id = v_invitation_id;
END;


FUNCTION CreateInvitation (
	in_invitation_type_id		IN  chain_pkg.T_INVITATION_TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_from_user_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_expiration_life_days		IN  NUMBER,
	in_qnr_types				IN  security_pkg.T_SID_IDS,
	in_due_dtm_strs				IN  chain_pkg.T_STRINGS
) RETURN invitation.invitation_id%TYPE
AS
	v_invitation_id				invitation.invitation_id%TYPE DEFAULT 0;
	v_created_invite			BOOLEAN DEFAULT FALSE;
	v_event_id					event.event_id%TYPE;
	v_expiration_life_days		NUMBER;
BEGIN
	IF in_expiration_life_days = 0 THEN
		SELECT invitation_expiration_days INTO v_expiration_life_days
		  FROM customer_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	ELSE
		v_expiration_life_days := in_expiration_life_days;
	END IF;
	
	UpdateExpirations;

	BEGIN
		SELECT invitation_id
		  INTO v_invitation_id
		  FROM v$active_invite
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_type_id = in_invitation_type_id
		   AND from_company_sid = in_from_company_sid
		   AND to_company_sid = in_to_company_sid
		   AND to_user_sid = in_to_user_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;

	-- if the invitation doesn't exist, create a new one
	IF v_invitation_id = 0 THEN
		INSERT INTO invitation
		(	invitation_id, invitation_type_id, guid,
			from_company_sid, from_user_sid,
			to_company_sid, to_user_sid,
			expiration_dtm
		)
		VALUES
		(
			invitation_id_seq.NEXTVAL, in_invitation_type_id, user_pkg.GenerateACT,
			in_from_company_sid, in_from_user_sid,
			in_to_company_sid, in_to_user_sid,
			SYSDATE + v_expiration_life_days
		)
		RETURNING invitation_id INTO v_invitation_id;

		v_created_invite := TRUE;
	ELSE
		-- if it does exist, reset the expiration dtm
		UPDATE invitation
		   SET expiration_dtm = GREATEST(expiration_dtm, SYSDATE + v_expiration_life_days)
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = v_invitation_id;
	END IF;


	IF in_qnr_types.COUNT <> 0 AND NOT (in_qnr_types.COUNT = 1 AND in_qnr_types(in_qnr_types.FIRST) IS NULL) THEN

		IF NOT capability_pkg.CheckCapability(in_from_company_sid, chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invitations');
		END IF;

		IF in_qnr_types.COUNT <> in_due_dtm_strs.COUNT THEN
			RAISE_APPLICATION_ERROR(-20001, 'Questionnaire Type Id array has a different number of elements than the Due Date Array');
		END IF;

		FOR i IN in_qnr_types.FIRST .. in_qnr_types.LAST
		LOOP
			BEGIN
				INSERT INTO invitation_qnr_type
				(invitation_id, questionnaire_type_id, added_by_user_sid, requested_due_dtm)
				VALUES
				(v_invitation_id, in_qnr_types(i), in_from_user_sid, chain_pkg.StringToDate(in_due_dtm_strs(i)));
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					-- TODO: Notify in_from_user_sid that added_by_user_sid had
					-- already sent the invite, otherwise, just ignore it
					-- (in normal circumstances we should be checking if this exists already,
					-- so let's just assume that it's been a race overlap)
					NULL;
			END;
		END LOOP;
	END IF;

	IF v_created_invite THEN
		CASE
			WHEN in_invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
				-- start the company relationship (it will be inactive if not already present, but in there)
				company_pkg.StartRelationship(in_from_company_sid, in_to_company_sid);
				company_pkg.AddSupplierFollower(in_from_company_sid, in_to_company_sid, in_from_user_sid);

				message_pkg.TriggerMessage (
					in_primary_lookup	  	 	=> chain_pkg.INVITATION_SENT,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	  	 	=> in_from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	  	 	=> in_to_company_sid,
					in_re_user_sid		  		=> in_to_user_sid
				);
				
				-- hook to customised system	
				chain_link_pkg.InviteCreated(v_invitation_id, in_from_company_sid, in_to_company_sid, in_to_user_sid);
			WHEN in_invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- TODO: Do we need to let anyone know that anything has happened?
				NULL;
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||in_invitation_type_id||') event notification not handled');
		END CASE;
	END IF;

	RETURN v_invitation_id;
END;


PROCEDURE GetInvitationForLanding (
	in_guid						IN  invitation.guid%TYPE,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_invitation_qt_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	-- no sec checks - if they know the guid, they've got permission

	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, out_state_cur) THEN
		RETURN;
	END IF;

	-- set the grace period allowance
	UPDATE invitation
	   SET expiration_grace = chain_pkg.ACTIVE
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = v_invitation_id;

	OPEN out_invitation_cur FOR
		SELECT opt.site_name, tc.company_sid to_company_sid, tc.name to_company_name, tu.full_name to_user_name, fc.name from_company_name, fu.full_name from_user_name,
				tu.registration_status_id, i.guid, tu.email to_user_email
		  FROM invitation i, company tc, v$chain_user tu, company fc, v$chain_user fu, customer_options opt
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = tc.app_sid
		   AND i.app_sid = tu.app_sid
		   AND i.app_sid = fc.app_sid(+)
		   AND i.app_sid = fu.app_sid(+)
		   AND i.app_sid = opt.app_sid
		   AND i.to_company_sid = tc.company_sid
		   AND i.to_user_sid = tu.user_sid
		   AND i.from_company_sid = fc.company_sid(+)
		   AND i.from_user_sid = fu.user_sid(+)
		   AND i.invitation_id = v_invitation_id;

	OPEN out_invitation_qt_cur FOR
		SELECT qt.name
		  FROM invitation_qnr_type iqt, questionnaire_type qt
		 WHERE iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND iqt.app_sid = qt.app_sid
		   AND iqt.questionnaire_type_id = qt.questionnaire_type_id
		   AND iqt.invitation_id = v_invitation_id;
END;

PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_act_id						security_pkg.t_act_id;
BEGIN
	-- this is just a dummy check - it will get properly filled in later
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;

	AcceptInvitation(v_invitation_id, in_as_user_sid, NULL, NULL);
END;


PROCEDURE AcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD,
	out_state_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id				invitation.invitation_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	-- no sec checks - if they know the guid, they've got permission
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, out_state_cur) THEN
		RETURN;
	END IF;
	
	AcceptInvitation(v_invitation_id, v_to_user_sid, in_full_name, in_password);
END;

/*** not to be called unless external validity checks have been done ***/
PROCEDURE AcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	in_full_name				IN  csr.csr_user.full_name%TYPE, 
	in_password					IN  Security_Pkg.T_USER_PASSWORD
)
AS
	v_act_id					security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_invitation_status_id		invitation.invitation_status_id%TYPE;
	v_invitation_type_id		chain_pkg.T_INVITATION_TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_to_company_sid			security_pkg.T_SID_ID;
	v_from_company_sid			security_pkg.T_SID_ID;
	v_is_pending_company_user	NUMBER(1);
	v_is_company_user			NUMBER(1);
	v_is_company_admin			NUMBER(1);
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE;
	v_action_id					action.action_id%TYPE;
	v_event_id					event.event_id%TYPE;
	v_approve_stub_registration	company.approve_stub_registration%TYPE;
	v_allow_stub_registration 	company.allow_stub_registration%TYPE;
	v_share_started				BOOLEAN;
BEGIN

	-- get the details
	SELECT invitation_status_id, to_user_sid, to_company_sid, from_company_sid, invitation_type_id
	  INTO v_invitation_status_id, v_to_user_sid, v_to_company_sid, v_from_company_sid, v_invitation_type_id
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;

	IF v_invitation_type_id = chain_pkg.STUB_INVITATION THEN
		SELECT allow_stub_registration, approve_stub_registration
		  INTO v_allow_stub_registration, v_approve_stub_registration
		  FROM v$company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = v_to_company_sid;

		IF v_allow_stub_registration = chain_pkg.INACTIVE THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied completing stub registration for invitation id '||in_invitation_id);
		END IF;
	END IF;

	chain_pkg.LogonUCD(v_to_company_sid);

	IF in_as_user_sid != v_to_user_sid THEN
		company_user_pkg.SetMergedStatus(v_to_user_sid, in_as_user_sid);
	END IF;
	-- set this to null so that i stop trying to use it!
	v_to_user_sid := NULL;
	
	-- activate the company
	company_pkg.ActivateCompany(v_to_company_sid);
	-- add the user to the company
	company_user_pkg.AddUserToCompany(v_to_company_sid, in_as_user_sid);
	company_pkg.AddPurchaserFollower(v_from_company_sid, v_to_company_sid, in_as_user_sid);
	
	IF v_invitation_type_id = chain_pkg.STUB_INVITATION AND v_approve_stub_registration = chain_pkg.INACTIVE THEN
		company_user_pkg.ApproveUser(v_to_company_sid, in_as_user_sid);
	END IF;

	-- see if the accepting user is an admin user
	SELECT COUNT(*)
	  INTO v_is_company_admin
	  FROM TABLE(group_pkg.GetMembersAsTable(security_pkg.GetAct, securableobject_pkg.GetSIDFromPath(v_act_id, v_to_company_sid, chain_pkg.ADMIN_GROUP)))
	 WHERE sid_id = in_as_user_sid;

	IF v_invitation_status_id <> chain_pkg.ACTIVE AND v_invitation_status_id <> chain_pkg.PROVISIONALLY_ACCEPTED THEN
		-- TODO: decide if we want an exception here or not...
		RETURN;
	END IF;

	-- may end up doing a double update on the status, but that's by design
	IF v_invitation_status_id = chain_pkg.ACTIVE THEN

		UPDATE invitation
		   SET invitation_status_id = chain_pkg.PROVISIONALLY_ACCEPTED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   	   AND invitation_id = in_invitation_id;

		IF v_invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
			-- we can activate the relationship now
			company_pkg.ActivateRelationship(v_from_company_sid, v_to_company_sid);
		END IF;
		
		-- loop round all questionnaire types for this invite 
		FOR i IN (
			SELECT i.to_company_sid, i.to_user_sid, iqt.questionnaire_type_id, iqt.requested_due_dtm, i.from_company_sid, qt.class questionnaire_type_class
			  FROM invitation i, invitation_qnr_type iqt, questionnaire_type qt
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND i.app_sid = iqt.app_sid
			   AND i.app_sid = qt.app_sid
			   AND i.invitation_id = in_invitation_id
			   AND i.invitation_id = iqt.invitation_id
			   AND iqt.questionnaire_type_id = qt.questionnaire_type_id
			   
		) LOOP
			BEGIN
				v_questionnaire_id := questionnaire_pkg.InitializeQuestionnaire(i.to_company_sid, i.questionnaire_type_class);
			EXCEPTION
				WHEN chain_pkg.QNR_ALREADY_EXISTS THEN
					v_questionnaire_id := questionnaire_pkg.GetQuestionnaireId(i.to_company_sid, i.questionnaire_type_class);
			END;
			
			BEGIN
				questionnaire_pkg.StartShareQuestionnaire(i.to_company_sid, v_questionnaire_id, i.from_company_sid, i.requested_due_dtm);	
				v_share_started := TRUE;
			EXCEPTION
				WHEN chain_pkg.QNR_ALREADY_SHARED THEN
					v_share_started := FALSE;
			END;

			IF v_share_started THEN
				
				message_pkg.TriggerMessage (
					in_primary_lookup           => chain_pkg.COMPLETE_QUESTIONNAIRE,
					in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
					in_to_company_sid           => i.to_company_sid,
					in_to_user_sid              => chain_pkg.FOLLOWERS,
					in_re_company_sid           => i.from_company_sid,
					in_re_questionnaire_type_id => i.questionnaire_type_id,
					in_due_dtm					=> i.requested_due_dtm
				);
								
				message_pkg.TriggerMessage (
					in_primary_lookup	   		=> chain_pkg.INVITATION_ACCEPTED,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	   		=> i.from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	   		=> i.to_company_sid,
					in_re_user_sid		  		=> in_as_user_sid,
					in_re_questionnaire_type_id => i.questionnaire_type_id,
					in_due_dtm					=> i.requested_due_dtm
				);
				
				chain_link_pkg.QuestionnaireAdded(i.from_company_sid, i.to_company_sid, i.to_user_sid, v_questionnaire_id);
			END IF;	
		END LOOP;
		

		-- if the accepting user is not an admin, we'll need to set an admin message that the invite requires admin approval
		IF v_is_company_admin = 0 THEN
			-- TODO: Set the message (as commented above)
			NULL;
		END IF;
	END IF;

	-- TODO: Re-instate this if check!!!!!!!!!!!!!!
	--IF v_is_company_admin = 1 THEN
		UPDATE invitation
		   SET invitation_status_id = chain_pkg.ACCEPTED
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   	   AND invitation_id = in_invitation_id;

		-- TODO: Send a message to the supplier company that the invitation was accepted
		-- TODO: Send a message to the purchaser company that the invitation was accepted
	--END IF;

	IF in_password IS NOT NULL THEN
		company_user_pkg.CompleteRegistration(in_as_user_sid, in_full_name, in_password);
	END IF;
	
	chain_pkg.RevertLogonUCD;
END;


PROCEDURE RejectInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
)
AS
	v_sid						security_pkg.T_SID_ID;
	v_event_id					event.event_id%TYPE;
BEGIN

	IF in_reason <> chain_pkg.REJECTED_NOT_EMPLOYEE AND in_reason <> chain_pkg.REJECTED_NOT_SUPPLIER THEN
		RAISE_APPLICATION_ERROR(-20001, 'Invalid invitation rejection reason - '||in_reason);
	END IF;
	
	chain_pkg.LogonUCD;
	
	-- there's only gonna be one, but this is faster than storing the row and
	-- doing no_data_found checking (and we don't care if nothing's found)
	FOR r IN (
		SELECT *
		  FROM invitation
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND LOWER(guid) = LOWER(in_guid)
	) LOOP

		-- terminate the relationship if it is still PENDING
		company_pkg.TerminateRelationship(r.from_company_sid, r.to_company_sid, FALSE);

		-- delete the company if it's inactive
		BEGIN
			SELECT company_sid
			  INTO v_sid
			  FROM v$company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND company_sid = r.to_company_sid
			   AND active = chain_pkg.INACTIVE;
			-- login as admin user (ICK)
			
			company_pkg.DeleteCompany(v_sid);		

		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- who cares
				NULL;
		END;

		-- delete the user if they've not registered
		BEGIN
			SELECT user_sid
			  INTO v_sid
			  FROM chain_user
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = r.to_user_sid
			   AND registration_status_id = chain_pkg.PENDING;

			
			company_user_pkg.SetRegistrationStatus(v_sid, chain_pkg.REJECTED);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				-- who cares
				NULL;
		END;

		UPDATE invitation
		   SET invitation_status_id = in_reason
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND invitation_id = r.invitation_id;


		CASE
			WHEN r.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION THEN
				-- add message for the purchaser company
				message_pkg.TriggerMessage (
					in_primary_lookup	   		=> chain_pkg.INVITATION_REJECTED,
					in_secondary_lookup	 		=> chain_pkg.PURCHASER_MSG,
					in_to_company_sid	   		=> r.from_company_sid,
					in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
					in_re_company_sid	   		=> r.to_company_sid,
					in_re_user_sid		  		=> r.to_user_sid
				);

			WHEN r.invitation_type_id = chain_pkg.STUB_INVITATION THEN
				-- do nothing I guess....
				NULL;
			ELSE
				RAISE_APPLICATION_ERROR(-20001, 'Invitation type ('||r.invitation_type_id||') event notification not handled');
		END CASE;

	END LOOP;
	
	chain_pkg.RevertLogonUCD;
END;

FUNCTION CanAcceptInvitation (
	in_guid						IN  invitation.guid%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID,
	-- hmmm - this is a bit strange, but we may want to allow this to succeed if there's a problem with the guid
	-- so that we can handle the errors appropriately
	in_guid_error_val			IN  NUMBER
) RETURN NUMBER
AS
	v_dummy						security_pkg.T_OUTPUT_CUR;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_as_user_sid				security_pkg.T_SID_ID;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	IF NOT GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, v_dummy) THEN
		RETURN in_guid_error_val;
	END IF;

	RETURN CanAcceptInvitation(v_invitation_id, in_as_user_sid);
END;

/*** not to be called unless external validity checks have been done ***/
FUNCTION CanAcceptInvitation (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_as_user_sid				IN  security_pkg.T_SID_ID
) RETURN NUMBER
AS
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT to_user_sid
	  INTO v_to_user_sid
	  FROM invitation
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_id = in_invitation_id;


	IF v_to_user_sid = in_as_user_sid OR company_user_pkg.GetRegistrationStatus(v_to_user_sid) = chain_pkg.PENDING THEN
		RETURN 1;
	END IF;

	RETURN 0;
END;


FUNCTION GetInvitationId (
	in_guid						IN  invitation.guid%TYPE
) RETURN invitation.invitation_id%TYPE
AS
	v_cur						security_pkg.T_OUTPUT_CUR;
	v_to_user_sid				security_pkg.T_SID_ID;
	v_invitation_id				invitation.invitation_id%TYPE;
BEGIN
	IF GetInvitationStateByGuid(in_guid, v_invitation_id, v_to_user_sid, v_cur) THEN
		RETURN v_invitation_id;
	END IF;

	RETURN NULL;
END;

PROCEDURE GetSupplierInvitationSummary (
	in_supplier_sid				IN  security_pkg.T_SID_ID,
	out_invite_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_questionnaire_cur		OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_count						NUMBER(10);
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SUPPLIERS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading suppliers');
	END IF;
	
	UpdateExpirations;
	
	OPEN out_invite_cur FOR
		SELECT csru.csr_user_sid user_sid, i.*, csru.*, c.*
		  FROM invitation i, csr.csr_user csru, company c
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = csru.app_sid
		   AND i.app_sid = c.app_sid
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.to_company_sid = in_supplier_sid
		   AND i.to_company_sid = c.company_sid
		   AND i.to_user_sid = csru.csr_user_sid;
	
	OPEN out_questionnaire_cur FOR
		SELECT csru.csr_user_sid user_sid, i.*, csru.*, iqt.*, qt.*
		  FROM invitation i, invitation_qnr_type iqt, questionnaire_type qt, csr.csr_user csru
	     WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.app_sid = csru.app_sid
		   AND i.app_sid = iqt.app_sid
		   AND i.app_sid = qt.app_sid
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.to_company_sid = in_supplier_sid
		   AND i.invitation_id = iqt.invitation_id
		   AND iqt.added_by_user_sid = csru.csr_user_sid
		   AND iqt.questionnaire_type_id = qt.questionnaire_type_id;
END;

PROCEDURE GetToCompanySidFromGuid (
	in_guid						IN  invitation.guid%TYPE,
	out_company_sid				OUT security_pkg.T_SID_ID
)
AS
BEGIN
	SELECT to_company_sid
	  INTO out_company_sid
	  FROM invitation
	 WHERE app_sid = security_pkg.GetApp
	   AND invitation_id = GetInvitationId(in_guid);	  
END;

PROCEDURE ExtendExpiredInvitations(
	in_expiration_dtm invitation.expiration_dtm%TYPE
)
AS
BEGIN
	-- Temporary SP for Maersk to extend their own invitations because I'm fed up with having to do it for them.

	-- Security is enforced on the /maersk/site/temp/extendinvitations.acds URL via secmgr3.

	UPDATE chain.invitation SET invitation_status_id = 1, expiration_dtm = in_expiration_dtm
         WHERE invitation_status_id = 2 AND expiration_dtm < sysdate AND app_sid = security_pkg.GetApp;
END;

PROCEDURE SearchInvitations (
	in_search				IN	VARCHAR2,
	in_invitation_status_id	IN	invitation.invitation_status_id%TYPE,
	in_from_user_sid		IN	security_pkg.T_SID_ID, -- TODO: Currently this is NULL for anyone or NOT NULL for [Me]
	in_sent_dtm_from		IN	invitation.sent_dtm%TYPE,
	in_sent_dtm_to			IN	invitation.sent_dtm%TYPE,
	in_start				IN	NUMBER,
	in_page_size			IN	NUMBER,
	in_sort_by				IN	VARCHAR2,
	in_sort_dir				IN	VARCHAR2,
	out_row_count			OUT	INTEGER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_search		VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_results		T_NUMERIC_TABLE := T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	-- Find all IDs that match the search criteria
	SELECT T_NUMERIC_ROW(invitation_id, NULL)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT i.invitation_id
		  FROM invitation i --TODO - should this be in a view
		  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
		  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
		  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid -- Not using views as filters out rejected invitations as their details become deleted
		  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
		  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
		  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION
		   AND (LOWER(fcu.full_name) LIKE v_search
				OR LOWER(tcsru.full_name) LIKE v_search
				OR LOWER(tc.name) LIKE v_search 
				OR LOWER(tcsru.email) LIKE v_search)
		   AND (in_from_user_sid IS NULL OR from_user_sid = SYS_CONTEXT('SECURITY', 'SID') )
		   AND (in_invitation_status_id IS NULL
					OR in_invitation_status_id = i.invitation_status_id
					OR (in_invitation_status_id = chain_pkg.ACCEPTED AND i.invitation_status_id = chain_pkg.PROVISIONALLY_ACCEPTED)
					OR (in_invitation_status_id = chain_pkg.REJECTED_NOT_EMPLOYEE AND i.invitation_status_id = chain_pkg.REJECTED_NOT_SUPPLIER))
		   AND (in_sent_dtm_from IS NULL OR in_sent_dtm_from <= i.sent_dtm)
		   AND (in_sent_dtm_to IS NULL OR in_sent_dtm_to+1 >= i.sent_dtm)
		   AND reinvitation_of_invitation_id IS NULL
	  );
	  
	-- Return the count
	SELECT COUNT(1)
	  INTO out_row_count
	  FROM TABLE(v_results);

	-- Return a single page in the order specified
	OPEN out_cur FOR
		SELECT sub.* FROM (
			SELECT i.*, istat.description invitation_status, fc.name from_company_name, fcu.full_name from_full_name,
				   fcu.email from_email, tc.name to_company_name, tcsru.full_name to_full_name, tcsru.email to_email,
				   row_number() OVER (ORDER BY 
						CASE
							WHEN in_sort_by = 'sentDtm' AND in_sort_dir = 'DESC' THEN to_char(i.sent_dtm, 'yyyy-mm-dd HH24:MI:SS')
							WHEN in_sort_by = 'toEmail' AND in_sort_dir = 'DESC' THEN LOWER(tcsru.email)
							WHEN in_sort_by = 'toCompanyName' AND in_sort_dir = 'DESC' THEN LOWER(tc.name)
							WHEN in_sort_by = 'toFullName' AND in_sort_dir = 'DESC' THEN LOWER(tcsru.full_name)
							WHEN in_sort_by = 'fromFullName' AND in_sort_dir = 'DESC' THEN LOWER(fcu.full_name)
							WHEN in_sort_by = 'invitationStatusId' AND in_sort_dir = 'DESC' THEN to_char(i.invitation_status_id)
						END DESC,
						CASE
							WHEN in_sort_by = 'sentDtm' AND in_sort_dir = 'ASC' THEN to_char(i.sent_dtm, 'yyyy-mm-dd HH24:MI:SS')
							WHEN in_sort_by = 'toEmail' AND in_sort_dir = 'ASC' THEN LOWER(tcsru.email)
							WHEN in_sort_by = 'toCompanyName' AND in_sort_dir = 'ASC' THEN LOWER(tc.name)
							WHEN in_sort_by = 'toFullName' AND in_sort_dir = 'ASC' THEN LOWER(tcsru.full_name)
							WHEN in_sort_by = 'fromFullName' AND in_sort_dir = 'ASC' THEN LOWER(fcu.full_name)
							WHEN in_sort_by = 'invitationStatusId' AND in_sort_dir = 'ASC' THEN to_char(i.invitation_status_id)
						END ASC 
				   ) rn
			  FROM invitation i --TODO - should this be in a view
			  JOIN TABLE(v_results) r ON i.invitation_id = r.item
			  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
			  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
			  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid
			  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
			  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
			  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
			 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  ORDER BY rn
		) sub
		 WHERE rn-1 BETWEEN in_start AND in_start + in_page_size - 1;
END;

PROCEDURE DownloadInvitations (
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;

	OPEN out_cur FOR
		SELECT tcsru.full_name recipient_name, tcsru.email recipient_email, tc.name company, fcu.full_name invited_by,
			   i.sent_dtm invite_sent_date, istat.description status
		  FROM invitation i --TODO - should this be in a view
		  JOIN v$company fc ON i.from_company_sid = fc.company_sid AND i.app_sid = fc.app_sid
		  JOIN v$chain_user fcu ON i.from_user_sid = fcu.user_sid AND i.app_sid = fcu.app_sid
		  JOIN company tc ON i.to_company_sid = tc.company_sid AND i.app_sid = tc.app_sid
		  JOIN chain_user tcu ON i.to_user_sid = tcu.user_sid AND i.app_sid = tcu.app_sid
		  JOIN csr.csr_user tcsru ON tcsru.csr_user_sid = tcu.user_sid AND tcsru.app_sid = tcu.app_sid
		  JOIN invitation_status istat ON i.invitation_status_id = istat.invitation_status_id
		 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND i.from_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND i.invitation_type_id = chain_pkg.QUESTIONNAIRE_INVITATION    
	  ORDER BY sent_dtm DESC;
END;

PROCEDURE CancelInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE
)
AS
	v_row_count INTEGER;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	SELECT COUNT(*)
	  INTO v_row_count
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id IN (chain_pkg.ACTIVE);

	IF v_row_count<>1 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot cancel an invitation that is not in an active state');
	END IF;

	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED, cancelled_by_user_sid = SYS_CONTEXT('SECURITY', 'SID'),
		   cancelled_dtm = SYSDATE
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND invitation_status_id IN (chain_pkg.ACTIVE);
END;

PROCEDURE ReSendInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_invitation_id			invitation.invitation_id%TYPE;
	v_expiration_life_days	NUMBER;
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.SEND_QUESTIONNAIRE_INVITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sending questionnaire invite');
	END IF;
	
	SELECT invitation_id_seq.NEXTVAL
	  INTO v_invitation_id
	  FROM dual;

	-- Set status of origainl invitation to cancelled if it is active
	UPDATE invitation
	   SET invitation_status_id = chain_pkg.CANCELLED
	 WHERE invitation_id = in_invitation_id
	   AND invitation_status_id = chain_pkg.ACTIVE
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	SELECT invitation_expiration_days 
	  INTO v_expiration_life_days
	  FROM customer_options;

	-- copy original invitation into a new invitation
	INSERT INTO invitation (app_sid, invitation_id, from_company_sid, from_user_sid,
		to_company_sid, to_user_sid, sent_dtm, guid, expiration_grace, expiration_dtm,
		invitation_status_id, invitation_type_id)
	SELECT SYS_CONTEXT('SECURITY', 'APP'), v_invitation_id,
		   from_company_sid, -- should we use SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') or original here?
		   SYS_CONTEXT('SECURITY', 'SID'), to_company_sid, to_user_sid, SYSDATE, guid, expiration_grace,
		   SYSDATE + v_expiration_life_days, chain_pkg.ACTIVE, invitation_type_id
	  FROM invitation
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	UPDATE invitation
	   SET reinvitation_of_invitation_id = v_invitation_id
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO invitation_qnr_type (app_sid, invitation_id, questionnaire_type_id, added_by_user_sid, requested_due_dtm)
	SELECT SYS_CONTEXT('SECURITY', 'APP'), v_invitation_id, questionnaire_type_id, SYS_CONTEXT('SECURITY', 'SID'),
		   SYSDATE + v_expiration_life_days
	  FROM invitation_qnr_type
	 WHERE invitation_id = in_invitation_id
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');

	OPEN out_cur FOR
		SELECT * 
		  FROM invitation
		 WHERE invitation_id = v_invitation_id
		   AND app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetQnrTypesForInvitation (
	in_invitation_id		IN	invitation.invitation_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT qt.*
		  FROM questionnaire_type qt
		  JOIN invitation_qnr_type iqt ON iqt.questionnaire_type_id = qt.questionnaire_type_id 
		  							  AND iqt.app_sid = qt.app_sid
		 WHERE iqt.invitation_id = in_invitation_id
		   AND iqt.app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE GetInvitationStatuses (
	in_for_filter				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT invitation_status_id id,
			   CASE WHEN in_for_filter = 1 THEN filter_description ELSE description END description
		  FROM invitation_status
		 WHERE in_for_filter <> 1
			OR in_for_filter=1
		   AND filter_description IS NOT NULL;
END;


END invitation_pkg;
/
CREATE OR REPLACE PACKAGE BODY CHAIN.questionnaire_pkg
IS

/***************************************************************************************
	PRIVATE
***************************************************************************************/
PROCEDURE AddStatusLogEntry (
	in_questionnaire_id				questionnaire.questionnaire_id%TYPE,
	in_status						chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes					qnr_status_log_entry.user_notes%TYPE
)
AS
	v_index							NUMBER(10);
BEGIN
	SELECT NVL(MAX(status_log_entry_index), 0) + 1
	  INTO v_index
	  FROM qnr_status_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = questionnaire_id;		

	INSERT INTO qnr_status_log_entry
	(questionnaire_id, status_log_entry_index, questionnaire_status_id, user_notes)
	VALUES
	(in_questionnaire_id, v_index, in_status, in_user_notes);
END;

PROCEDURE AddShareLogEntry (
	in_qnr_share_id					questionnaire_share.questionnaire_share_id%TYPE,
	in_status						chain_pkg.T_SHARE_STATUS,
	in_user_notes					qnr_share_log_entry.user_notes%TYPE
)
AS
	v_index							NUMBER(10);
BEGIN
	SELECT NVL(MAX(share_log_entry_index), 0) + 1
	  INTO v_index
	  FROM qnr_share_log_entry
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_share_id = in_qnr_share_id;		
	
	INSERT INTO qnr_share_log_entry
	(questionnaire_share_id, share_log_entry_index, share_status_id, user_notes)
	VALUES
	(in_qnr_share_id, v_index, in_status, in_user_notes);
END;

/***************************************************************************************
	PUBLIC
***************************************************************************************/

-- ok
PROCEDURE GetQuestionnaireFilterClass (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT questionnaire_filter_class
		  FROM customer_options
		 WHERE app_sid = security_pkg.GetApp;
END;

-- ok
PROCEDURE GetQuestionnaireGroups (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM questionnaire_group
		 WHERE app_sid = security_pkg.GetApp;
END;

-- ok
PROCEDURE GetQuestionnaireTypes (
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		 ORDER BY position;
END;

-- ok
PROCEDURE GetQuestionnaireType (
	in_qt_class					IN   questionnaire_type.CLASS%TYPE,
	out_cur						OUT  security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		   AND LOWER(class) = LOWER(TRIM(in_qt_class));
END;

-- ok
FUNCTION GetQuestionnaireTypeId (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_ret			NUMBER;
BEGIN
	SELECT questionnaire_type_id
	  INTO v_ret
	  FROM questionnaire_type
	 WHERE app_sid = security_pkg.GetApp
	   AND LOWER(CLASS) = LOWER(in_qt_class);

	RETURN v_ret;
END;

-- ok
FUNCTION GetQuestionnaireId (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_q_id						questionnaire.questionnaire_id%TYPE;
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	BEGIN
		SELECT questionnaire_id
		  INTO v_q_id
		  FROM questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class)
		   AND company_sid = in_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_NOT_FOUND, 'No questionnaire of type '||in_qt_class||' is setup for company with sid '||in_company_sid);
	END;
	
	RETURN v_q_id;
END;

PROCEDURE GetQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT *
		  FROM v$questionnaire
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class);
END;

FUNCTION InitializeQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN NUMBER
AS
	v_q_id						questionnaire.questionnaire_id%TYPE;
BEGIN
	IF QuestionnaireExists(in_company_sid, in_qt_class) THEN
		RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_ALREADY_EXISTS, 'A questionnaire of class '||in_qt_class||' already exists for company with sid '||in_company_sid);
	END IF;
	
	INSERT INTO questionnaire
	(questionnaire_id, company_sid, questionnaire_type_id, created_dtm)
	VALUES
	(questionnaire_id_seq.nextval, in_company_sid, GetQuestionnaireTypeId(in_qt_class), SYSDATE)
	RETURNING questionnaire_id INTO v_q_id;
	
	AddStatusLogEntry(v_q_id, chain_pkg.ENTERING_DATA, NULL);
	
	RETURN v_q_id;	
END;

PROCEDURE StartShareQuestionnaire (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN  questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID,
	in_due_by_dtm				IN  questionnaire_share.DUE_BY_DTM%TYPE
)
AS
	v_qnr_share_id				questionnaire_share.questionnaire_share_id%TYPE;
	v_count						NUMBER(10);
BEGIN
	
	IF NOT company_pkg.IsSupplier(in_share_with_company_sid, in_company_sid) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - company with sid '||in_company_sid||' is not a supplier to company with sid '||in_share_with_company_sid);
	END IF;	
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM questionnaire
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND questionnaire_id = in_questionnaire_id
	   AND company_sid = in_company_sid;
	
	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - company with sid '||in_company_sid||' does not own the questionnaire with id '||in_questionnaire_id);
	END IF;	
	
	BEGIN
		INSERT INTO questionnaire_share
		(questionnaire_share_id, questionnaire_id, qnr_owner_company_sid, share_with_company_sid, due_by_dtm)
		VALUES
		(questionnaire_share_id_seq.nextval, in_questionnaire_id, in_company_sid, in_share_with_company_sid, in_due_by_dtm)
		RETURNING questionnaire_share_id INTO v_qnr_share_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			RAISE_APPLICATION_ERROR(chain_pkg.ERR_QNR_ALREADY_SHARED, 'The questionnaire with id '||in_questionnaire_id||' is already shared from company with sid '||in_company_sid||' to company with sid '||in_share_with_company_sid);
	END;
	
	AddShareLogEntry(v_qnr_share_id, chain_pkg.NOT_SHARED, NULL);
END;


FUNCTION QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN BOOLEAN
AS
	v_questionnaire_id			questionnaire.questionnaire_id%TYPE;
BEGIN
	BEGIN
		v_questionnaire_id := GetQuestionnaireId(in_company_sid, in_qt_class);
	EXCEPTION
		WHEN chain_pkg.QNR_NOT_FOUND THEN
			RETURN FALSE;
	END;
	
	RETURN TRUE;
END;

PROCEDURE QuestionnaireExists (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_exists					OUT NUMBER
)
AS
BEGIN
	out_exists := 0;
	
	IF QuestionnaireExists(in_company_sid, in_qt_class) THEN
		out_exists := 1;
	END IF;
END;

FUNCTION GetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_QUESTIONNAIRE_STATUS
AS
	v_q_status_id				chain_pkg.T_QUESTIONNAIRE_STATUS;
BEGIN
	-- perm check done in GetQuestionnaireId
	SELECT questionnaire_status_id
	  INTO v_q_status_id
	  FROM v$questionnaire
	 WHERE app_sid = security_pkg.GetApp
	   AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class);

	RETURN v_q_status_id;
END;

PROCEDURE GetQuestionnaireShareStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- perm check done in GetQuestionnaireId
	OPEN out_cur FOR
		SELECT share_with_company_sid, share_status_id
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
	       AND questionnaire_id = GetQuestionnaireId(in_company_sid, in_qt_class);
END;

FUNCTION GetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,	
	in_qt_class					IN  questionnaire_type.CLASS%TYPE
) RETURN chain_pkg.T_SHARE_STATUS
AS
	v_s_status_id			chain_pkg.T_SHARE_STATUS;
BEGIN
	-- perm check done in GetQuestionnaireId
	BEGIN
		SELECT share_status_id
		  INTO v_s_status_id
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class)
		   AND share_with_company_sid = in_share_with_company_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RAISE_APPLICATION_ERROR(-20001, 'Could not find a questionanire share status between OWNER: '||in_qnr_owner_company_sid||' SHARE WITH:'||in_share_with_company_sid||' of CLASS:"'||in_qt_class||'"');
	END;
	
	RETURN v_s_status_id;
END;


PROCEDURE SetQuestionnaireStatus (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_status_id				IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
	v_current_status			chain_pkg.T_QUESTIONNAIRE_STATUS DEFAULT GetQuestionnaireStatus(in_company_sid, in_qt_class);
	v_owner_can_review			questionnaire_type.owner_can_review%TYPE;
BEGIN
	-- validate the incoming state
	IF in_q_status_id NOT IN (
		chain_pkg.ENTERING_DATA, 
		chain_pkg.REVIEWING_DATA, 
		chain_pkg.READY_TO_SHARE
	) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unexpected questionnaire state "'||in_q_status_id||'"');
	END IF;
	
	-- we're not changing status - get out
	IF v_current_status = in_q_status_id THEN
		RETURN;
	END IF;
	
	CASE
	WHEN v_current_status = chain_pkg.ENTERING_DATA THEN
		CASE
		WHEN in_q_status_id = chain_pkg.REVIEWING_DATA THEN
			-- I suppose anyone can make this status change
			NULL;
		WHEN in_q_status_id = chain_pkg.READY_TO_SHARE THEN
			-- force the call to reviewing data for logging purposes
			SetQuestionnaireStatus(in_company_sid, in_qt_class, chain_pkg.REVIEWING_DATA, 'Automatic progression');
			v_current_status := chain_pkg.REVIEWING_DATA;
		END CASE;
	
	WHEN v_current_status = chain_pkg.REVIEWING_DATA THEN
		CASE
		WHEN in_q_status_id = chain_pkg.ENTERING_DATA THEN
			-- it's going back down, that's fine
			NULL;
		WHEN in_q_status_id = chain_pkg.READY_TO_SHARE THEN
			IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUBMIT_QUESTIONNAIRE)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sharing questionnaire for company with sid '||in_company_sid);
			END IF;
		END CASE;
	
	WHEN v_current_status = chain_pkg.READY_TO_SHARE THEN
		SELECT owner_can_review
		  INTO v_owner_can_review
		  FROM questionnaire_type
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
		
		-- we're trying to downgrade the status, so let's see if the owner can review
		IF v_owner_can_review = chain_pkg.INACTIVE THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied re-editting questionnaire for company with sid '||in_company_sid);
		END IF;
	END CASE;
	
	AddStatusLogEntry(GetQuestionnaireId(in_company_sid, in_qt_class), in_q_status_id, in_user_notes);
END;

PROCEDURE SetQuestionnaireShareStatus (
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,
	in_share_with_company_sid	IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_q_share_id				IN  chain_pkg.T_SHARE_STATUS,
	in_user_notes				IN  qnr_status_log_entry.user_notes%TYPE
)
AS
	v_qnr_share_id 				questionnaire_share.questionnaire_share_id%TYPE;
	v_isowner					BOOLEAN DEFAULT in_qnr_owner_company_sid = company_pkg.GetCompany;
	v_isPurchaser				BOOLEAN DEFAULT company_pkg.IsPurchaser(company_pkg.GetCompany, in_qnr_owner_company_sid);
	v_count						NUMBER(10);
	v_current_status			chain_pkg.T_SHARE_STATUS DEFAULT GetQuestionnaireShareStatus(in_qnr_owner_company_sid, in_share_with_company_sid, in_qt_class);
BEGIN
	IF NOT v_isowner AND NOT v_isPurchaser THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of a questionnaire where you are neither the owner or a Purchaser');
	END IF;
	
	-- validate the incoming state
	IF in_q_share_id NOT IN (
		chain_pkg.NOT_SHARED, 
		chain_pkg.SHARING_DATA, 
		chain_pkg.SHARED_DATA_RETURNED,
		chain_pkg.SHARED_DATA_ACCEPTED,
		chain_pkg.SHARED_DATA_REJECTED
	) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unexpected questionnaire share state "'||in_q_share_id||'"');
	END IF;

	-- nothing's changed - get out
	IF v_current_status = in_q_share_id THEN
		RETURN;
	END IF;
	
	-- we can only set certain states depending on who we are
	-- if we are the owner, we can only modify the questionnaire share from a not shared or sharing data retured state
	IF v_isowner AND v_current_status NOT IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of your questionnaire when it is not in the NOT SHARED or SHARED DATA RETURNED states');
	-- if we are the Purchaser, we can only modify from the other states.
	ELSIF v_isPurchaser AND v_current_status NOT IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied changing the share status of a supplier''s questionnaire when it is not in the SHARING DATA or ACCEPTED or REJECTED states');
	END IF;	
		
	CASE 
	
	-- if the current status is not shared or shared data retured, we can only go to a sharing data state
	WHEN v_current_status IN (chain_pkg.NOT_SHARED, chain_pkg.SHARED_DATA_RETURNED) THEN
		CASE
		WHEN in_q_share_id = chain_pkg.SHARING_DATA THEN
			IF NOT capability_pkg.CheckCapability(chain_pkg.SUBMIT_QUESTIONNAIRE)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied sharing questionnaire for your company ('||in_qnr_owner_company_sid||')');
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denided progressing questionnaires from NOT SHARED or SHARED DATA RETURNED to any state other than SHARING DATA');
		END CASE;
	-- if the current status is in any other sharing state, we can move to returned, accepted or rejected states
	WHEN v_current_status IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN
		CASE
		WHEN in_q_share_id IN (
			chain_pkg.SHARING_DATA, 
			chain_pkg.SHARED_DATA_RETURNED, 
			chain_pkg.SHARED_DATA_ACCEPTED, 
			chain_pkg.SHARED_DATA_REJECTED
		) THEN
			IF NOT capability_pkg.CheckCapability(chain_pkg.APPROVE_QUESTIONNAIRE)  THEN
				RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied approving questionnaires for your suppliers');
			END IF;
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denided progressing questionnaires from SHARING_DATA, SHARED_DATA_ACCEPTED or SHARED_DATA_REJECTED to states other than SHARING_DATA, SHARED_DATA_RETURNED, SHARED_DATA_ACCEPTED or SHARED_DATA_REJECTED');
		END CASE;
		
	END CASE;

	-- if we get here, we're good to go!
	SELECT questionnaire_share_id
	  INTO v_qnr_share_id
	  FROM questionnaire_share
	 WHERE app_sid = security_pkg.GetApp
	   AND qnr_owner_company_sid = in_qnr_owner_company_sid
	   AND share_with_company_sid = in_share_with_company_sid
	   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class);
	
	AddShareLogEntry(v_qnr_share_id, in_q_share_id, in_user_notes);

END;

PROCEDURE GetQManagementData (
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetQManagementData(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_start, in_page_size, in_sort_by, in_sort_dir, out_cur);
END;


PROCEDURE GetQManagementData (
	in_company_sid		security_pkg.T_SID_ID,
	in_start			NUMBER,
	in_page_size		NUMBER,
	in_sort_by			VARCHAR2,
	in_sort_dir			VARCHAR2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_sort				VARCHAR2(100) DEFAULT in_sort_by||' '||in_sort_dir;
BEGIN

	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN (
		-- add support as needed
		'name', 
		'questionnaire_status_name', 
		'status_update_dtm'
	) THEN 
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by "'||in_sort_by||'".');
	END IF;

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||in_company_sid);
	END IF;
	
	DELETE FROM tt_questionnaire_organizer;
	
	-- if it's our company, pull the ids from the questionnaire table
	IF in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm)
		SELECT questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
		   
		-- now we'll fudge any data that is sitting in a mixed shared state
		UPDATE tt_questionnaire_organizer
		   SET questionnaire_status_id = 1000, -- pseudo id
		       questionnaire_status_name = 'Mixed shared states', 
		       status_update_dtm = NULL
		 WHERE questionnaire_id IN (
		 			SELECT questionnaire_id 
		 			  FROM (SELECT questionnaire_id, COUNT(share_status_id) unique_status_count 
		 			  		  FROM (SELECT DISTINCT questionnaire_id, share_status_id FROM v$questionnaire_share) 
		 			  		 GROUP BY questionnaire_id
					) WHERE unique_status_count > 1
		       );
		
		-- now lets fix up statuses that are in unique and valid shared state
		UPDATE tt_questionnaire_organizer qo
		   SET (questionnaire_status_id, questionnaire_status_name, status_update_dtm) = (
				SELECT share_status_id, share_status_name, MAX(entry_dtm)
				  FROM v$questionnaire_share qs
				 WHERE qs.questionnaire_id = qo.questionnaire_id
				   AND qo.questionnaire_status_id = chain_pkg.READY_TO_SHARE
				 GROUP BY share_status_id, share_status_name
				)
		 WHERE qo.questionnaire_status_id = chain_pkg.READY_TO_SHARE;
		
		-- now fix up the due by dtms
		-- TODO: this probably isn't quite right - it should pick the next due dependant on share status (i.e. whether we've submitted it or not)
		UPDATE tt_questionnaire_organizer qo
		   SET due_by_dtm = (
		   		SELECT MAX(due_by_dtm)
		   		  FROM v$questionnaire_share qs
		   		 WHERE qs.questionnaire_id = qo.questionnaire_id
		   		   AND qo.questionnaire_status_id = qs.share_status_id
		   		   AND qo.questionnaire_status_id <> 1000 -- pseudo id
		   		)
		 WHERE qo.questionnaire_status_id <> 1000;	   		   
		 
	-- if it's NOT our company, pull the ids from the questionnaire share view
	ELSE
		INSERT INTO tt_questionnaire_organizer 
		(questionnaire_id, questionnaire_status_id, questionnaire_status_name, status_update_dtm, due_by_dtm)
		SELECT questionnaire_id, share_status_id, share_status_name, entry_dtm, due_by_dtm
		  FROM v$questionnaire_share
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND qnr_owner_company_sid = in_company_sid
		   AND share_status_id IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED);
	END IF;
	
	
	-- now we'll run the sort on the data, setting a position value for each questionnaire_id
	EXECUTE IMMEDIATE
		'UPDATE tt_questionnaire_organizer qo '||
		'   SET qo.position = ( '||
		'		SELECT rn '||
		'		  FROM ( '||
		'				SELECT questionnaire_id, row_number() OVER (ORDER BY '||v_sort||') rn  '||
		'				  FROM v$questionnaire '||
		'			   ) q  '||
		'		 WHERE q.questionnaire_id = qo.questionnaire_id  '||
		'	  )';

	-- we can now open a clean cursor and use the position column to order and control paging
	OPEN out_cur FOR 
		SELECT r.*, CASE WHEN 
				r.questionnaire_status_id IN (chain_pkg.ENTERING_DATA, chain_pkg.REVIEWING_DATA) 
				THEN edit_url ELSE view_url END url
		  FROM (
				SELECT q.company_sid, q.name, q.edit_url, q.view_url, qo.due_by_dtm,
						qo.questionnaire_status_id, qo.questionnaire_status_name, qo.status_update_dtm, qo.position page_position, 
						COUNT(*) OVER () AS total_rows
				  FROM v$questionnaire q, tt_questionnaire_organizer qo
				 WHERE q.questionnaire_id = qo.questionnaire_id
				 ORDER BY qo.position
			   ) r
		 WHERE page_position > in_start
		   AND page_position <= (in_start + in_page_size);
END;

PROCEDURE GetMyQuestionnaires (
	in_status			IN  chain_pkg.T_QUESTIONNAIRE_STATUS,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to questionnaire for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	OPEN out_cur FOR
		SELECT questionnaire_id, company_sid, questionnaire_type_id, created_dtm, view_url, edit_url, owner_can_review, 
				class, name, db_class, group_name, position, status_log_entry_index, questionnaire_status_id, status_update_dtm
		  FROM v$questionnaire
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND questionnaire_status_id = NVL(in_status, questionnaire_status_id)
		 ORDER BY LOWER(name);
END;


PROCEDURE CreateQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_view_url					IN	questionnaire_type.view_url%TYPE,
	in_edit_url					IN	questionnaire_type.edit_url%TYPE,
	in_owner_can_review			IN	questionnaire_type.owner_can_review%TYPE,
	in_name						IN	questionnaire_type.name%TYPE,
	in_class					IN	questionnaire_type.CLASS%TYPE,
	in_db_class					IN	questionnaire_type.db_class%TYPE,
	in_group_name				IN	questionnaire_type.group_name%TYPE,
	in_position					IN	questionnaire_type.position%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
        INSERT INTO questionnaire_type (
			questionnaire_type_id, 
			view_url, 
			edit_url, 
			owner_can_review, 
			name, 
			CLASS, 
			db_class,
			group_name,
			position
		) VALUES ( 
            in_questionnaire_type_id,
            in_view_url,
            in_edit_url,
            in_owner_can_review,
            in_name,
            in_class,
			in_db_class,	
            in_group_name,
            in_position
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE questionnaire_type
               SET	view_url=in_view_url,
                    edit_url= in_edit_url,
                    owner_can_review= in_owner_can_review,
                    name=in_name,
                    CLASS=in_class,
                    db_class=in_db_class,
                    group_name=in_group_name,
                    position=in_position
			WHERE app_sid=security_pkg.getApp
			  AND questionnaire_type_id=in_questionnaire_type_id;
	END;
END;



PROCEDURE DeleteQuestionnaireType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateQuestionnaireType can only be run as BuiltIn/Administrator');
	END IF;

	DELETE FROM qnr_status_log_entry
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	
	DELETE FROM qnr_share_log_entry
	 WHERE questionnaire_share_id IN (
		SELECT questionnaire_share_id
		  FROM questionnaire_share qs	
			JOIN questionnaire q ON qs.questionnaire_id = q.questionnaire_id
		 WHERE q.questionnaire_type_id = in_questionnaire_type_id
		   AND q.app_sid = security_pkg.GetApp
	);
	
	DELETE FROM questionnaire_share 
	 WHERE questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	 
	-- now we can clear questionaires
	DELETE FROM questionnaire_metric
	 WHERE questionnaire_id IN(
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
	);
	
	DELETE FROM event
	 WHERE related_action_id IN (
		SELECT action_id
		  FROM action a 
			JOIN questionnaire q ON a.related_questionnaire_id = q.questionnaire_id
		  WHERE q.questionnaire_type_id = in_questionnaire_type_id
		    AND q.app_sid = security_pkg.getApp
	 );
	
	DELETE FROM action
     WHERE related_questionnaire_id IN (
		SELECT questionnaire_id
		  FROM questionnaire 
		 WHERE questionnaire_type_id = in_questionnaire_type_id
		   AND app_sid = security_pkg.GetApp
     );
	
	DELETE FROM invitation_qnr_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.getApp;
	
	DELETE FROM questionnaire
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;

	DELETE FROM questionnaire_type
	 WHERE questionnaire_type_id = in_questionnaire_type_id
	   AND app_sid = security_pkg.GetApp;

END;


PROCEDURE GetQuestionnaireAbilities (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_is_owner					NUMBER(1) DEFAULT CASE WHEN in_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') THEN 1 ELSE 0 END;
	v_can_write					NUMBER(1) DEFAULT CASE WHEN capability_pkg.CheckCapability(in_company_sid, chain_pkg.QUESTIONNAIRE, security_pkg.PERMISSION_WRITE) THEN 1 ELSE 0 END;
	v_can_submit				NUMBER(1) DEFAULT CASE WHEN capability_pkg.CheckCapability(in_company_sid, chain_pkg.SUBMIT_QUESTIONNAIRE) THEN 1 ELSE 0 END;
	v_ready_to_share			NUMBER(1);
	v_is_shared					NUMBER(1) DEFAULT 0;
	v_status					chain_pkg.T_QUESTIONNAIRE_STATUS;
	v_share_status				chain_pkg.T_SHARE_STATUS;
	v_owner_can_review			questionnaire_type.owner_can_review%TYPE;
BEGIN
	-- security checks done in sub procedures
	
	IF NOT QuestionnaireExists(in_company_sid, in_qt_class) THEN
		OPEN out_cur FOR
			SELECT 
				0 questionnaire_exists, 
				0 is_ready_to_share,
				0 is_shared, 
				0 can_share, 
				0 is_read_only, 
				0 can_make_editable, 
				0 is_owner, 
				0 is_approved 
			  FROM DUAL;
		
		RETURN;
	END IF;
	
	v_status := GetQuestionnaireStatus(in_company_sid, in_qt_class);
	v_ready_to_share := CASE WHEN v_status = chain_pkg.READY_TO_SHARE THEN 1 ELSE 0 END; 
	
	IF v_is_owner = 0 THEN
		v_share_status := GetQuestionnaireShareStatus(in_company_sid, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_qt_class);
		v_is_shared := CASE WHEN v_share_status IN (chain_pkg.SHARING_DATA, chain_pkg.SHARED_DATA_ACCEPTED, chain_pkg.SHARED_DATA_REJECTED) THEN 1 ELSE 0 END;
	ELSE
		SELECT owner_can_review
		  INTO v_owner_can_review
		  FROM questionnaire_type
		 WHERE questionnaire_type_id = GetQuestionnaireTypeId(in_qt_class);
	END IF;
		
	OPEN out_cur FOR
		SELECT
			1 questionnaire_exists,
			v_ready_to_share is_ready_to_share,
			v_is_shared is_shared,
			v_can_submit can_share,
			v_is_owner is_owner,
			CASE 
				WHEN v_can_write = 0 THEN 1
				WHEN v_is_owner = 1 
				 AND v_ready_to_share = 0 THEN 0
				ELSE 1 
			END is_read_only,
			CASE 
				WHEN v_is_owner = 1 AND v_owner_can_review = 1 THEN 1
				WHEN v_is_owner = 0 AND v_can_write = 1 AND v_share_status = chain_pkg.SHARING_DATA THEN 1
				ELSE 0
			END can_make_editable,
			CASE 
				WHEN v_share_status = chain_pkg.SHARED_DATA_ACCEPTED THEN 1 
				ELSE 0 
			END is_approved
		  FROM DUAL;	  
END;

PROCEDURE CheckForOverdueQuestionnaires
AS
	v_event_id			event.event_id%TYPE;
BEGIN
	
	FOR r IN (
		SELECT *
		  FROM v$questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND due_by_dtm < SYSDATE
		   AND overdue_events_sent = 0
		   AND share_status_id = chain_pkg.NOT_SHARED
	) LOOP
		-- send the message to the Purchaser
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_OVERDUE,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => r.share_with_company_sid,
			in_to_user_sid		        => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.qnr_owner_company_sid,
			in_re_questionnaire_type_id => r.questionnaire_type_id
		);

		-- send the message to the supplier
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_OVERDUE,
			in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => r.qnr_owner_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.share_with_company_sid,
			in_re_questionnaire_type_id => r.questionnaire_type_id
		);

		
		UPDATE questionnaire_share
		   SET overdue_events_sent = 1
		 WHERE app_sid = security_pkg.GetApp
		   AND questionnaire_share_id = r.questionnaire_share_id;
	END LOOP;
END;

PROCEDURE ShareQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID,	
	in_share_with_company_sid 	IN  security_pkg.T_SID_ID
)
AS
BEGIN
	-- TODO: remove this loop - stuck in quickly for rfa
	FOR r IN (
		SELECT share_with_company_sid 
		  FROM questionnaire_share
		 WHERE app_sid = security_pkg.GetApp
		   AND qnr_owner_company_sid = in_qnr_owner_company_sid
		   AND questionnaire_id = GetQuestionnaireId(in_qnr_owner_company_sid, in_qt_class)
	) LOOP
		SetQuestionnaireStatus(in_qnr_owner_company_sid, in_qt_class, chain_pkg.READY_TO_SHARE, null);
		SetQuestionnaireShareStatus(in_qnr_owner_company_sid, r.share_with_company_sid, in_qt_class, chain_pkg.SHARING_DATA, null);
					
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
			in_to_company_sid           => in_qnr_owner_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => r.share_with_company_sid,
			in_re_user_sid           	=> SYS_CONTEXT('SECURITY', 'SID'),
			in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
		);
		
		message_pkg.TriggerMessage (
			in_primary_lookup           => chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
			in_to_company_sid           => r.share_with_company_sid,
			in_to_user_sid              => chain_pkg.FOLLOWERS,
			in_re_company_sid           => in_qnr_owner_company_sid,
			in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
		);


	END LOOP;
END;

PROCEDURE ApproveQuestionnaire (
	in_qt_class					IN  questionnaire_type.CLASS%TYPE,
	in_qnr_owner_company_sid	IN  security_pkg.T_SID_ID	
)
AS
BEGIN
	SetQuestionnaireShareStatus(in_qnr_owner_company_sid, company_pkg.GetCompany, in_qt_class, chain_pkg.SHARED_DATA_ACCEPTED, null);
	-- trigger questionnaire approved message to the supplier
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup         => chain_pkg.SUPPLIER_MSG,
		in_to_company_sid           => in_qnr_owner_company_sid,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => company_pkg.GetCompany,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);

	-- trigger questionnaire approved message to the purchaser
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid,
		in_re_questionnaire_type_id => questionnaire_pkg.GetQuestionnaireTypeId(in_qt_class)
	);
	
	-- trigger action plan started message to the purchaser (hidden by default)
	message_pkg.TriggerMessage (
		in_primary_lookup           => chain_pkg.ACTION_PLAN_STARTED,
		in_secondary_lookup         => chain_pkg.PURCHASER_MSG,
		in_to_company_sid           => company_pkg.GetCompany,
		in_to_user_sid              => chain_pkg.FOLLOWERS,
		in_re_company_sid           => in_qnr_owner_company_sid
	);
END;

PROCEDURE MessageCreated (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN	message.message_id%TYPE
)
AS
	v_msg						message%ROWTYPE DEFAULT message_pkg.GetMessage(in_message_id);
BEGIN
	
	IF v_msg.message_definition_id = message_pkg.Lookup(chain_pkg.QUESTIONNAIRE_SUBMITTED, chain_pkg.SUPPLIER_MSG) THEN
		
		message_pkg.CompleteMessage(
			in_primary_lookup			=> chain_pkg.COMPLETE_QUESTIONNAIRE,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid			=> in_to_company_sid,
			in_re_company_sid			=> v_msg.re_company_sid,
			in_re_questionnaire_type_id	=> v_msg.re_questionnaire_type_id
		);			
		
	ELSIF v_msg.message_definition_id = message_pkg.Lookup(chain_pkg.QUESTIONNAIRE_APPROVED, chain_pkg.PURCHASER_MSG) THEN
	
		message_pkg.CompleteMessage(
			in_primary_lookup			=> chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup			=> chain_pkg.PURCHASER_MSG,
			in_to_company_sid			=> in_to_company_sid,
			in_re_company_sid			=> v_msg.re_company_sid,
			in_re_questionnaire_type_id	=> v_msg.re_questionnaire_type_id
		);	
	
	END IF;
END;

END questionnaire_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
PROCEDURE FillTypeContainment
AS
BEGIN
	DELETE FROM tt_component_type_containment;
	
	INSERT INTO tt_component_type_containment
	(container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
	chain_link_pkg.FilterComponentTypeContainment;
END;

FUNCTION CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_component_id			IN  component.component_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_component_id, in_permission_set)  THEN
		
		v_company_sid := NVL(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to components for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to components for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

FUNCTION GetTypeId (
	in_component_id			IN component.component_id%TYPE
) RETURN chain_pkg.T_COMPONENT_TYPE
AS
	v_type_id 				chain_pkg.T_COMPONENT_TYPE;
BEGIN
	SELECT component_type_id
	  INTO v_type_id
	  FROM component_bind
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	RETURN v_type_id;
END;

FUNCTION GetHandlerPkg (
	in_type_id				chain_pkg.T_COMPONENT_TYPE
) RETURN all_component_type.handler_pkg%TYPE
AS
	v_hp					all_component_type.handler_pkg%TYPE;
BEGIN
	SELECT handler_pkg
	  INTO v_hp
	  FROM v$component_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_type_id = in_type_id;
	
	RETURN v_hp;
END;

/**********************************************************************************
	MANAGEMENT
**********************************************************************************/
PROCEDURE ActivateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ActivateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO component_type
		(component_type_id)
		VALUES
		(in_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE
)
AS
BEGIN
	CreateType(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, NULL); 
END;

PROCEDURE CreateType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_handler_class		IN  all_component_type.handler_class%TYPE,
	in_handler_pkg			IN  all_component_type.handler_pkg%TYPE,
	in_node_js_path			IN  all_component_type.node_js_path%TYPE,
	in_description			IN  all_component_type.description%TYPE,
	in_editor_card_group_id	IN  all_component_type.editor_card_group_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'CreateType can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		INSERT INTO all_component_type
		(component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id)
		VALUES
		(in_type_id, in_handler_class, in_handler_pkg, in_node_js_path, in_description, in_editor_card_group_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE all_component_type
			   SET handler_class = in_handler_class,
			   	   handler_pkg = in_handler_pkg,
			   	   node_js_path = in_node_js_path,
			   	   description = in_description,
			   	   editor_card_group_id = in_editor_card_group_id
			 WHERE component_type_id = in_type_id;
	END;
END;

PROCEDURE ClearSources
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearSources can only be run as BuiltIn/Administrator');
	END IF;
	
	DELETE FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE
)
AS
BEGIN
	AddSource(in_type_id, in_action, in_text, in_description, null);
END;


PROCEDURE AddSource (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_action				IN  component_source.progression_action%TYPE,
	in_text					IN  component_source.card_text%TYPE,
	in_description			IN  component_source.description_xml%TYPE,
	in_card_group_id		IN  component_source.card_group_id%TYPE
)
AS
	v_max_pos				component_source.position%TYPE;
BEGIN
	
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'AddSource can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_action <> LOWER(TRIM(in_action)) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Actions must be formatted as trimmed and lower case');
	END IF;
	
	ActivateType(in_type_id);
	
	SELECT MAX(position)
	  INTO v_max_pos
	  FROM component_source
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	INSERT INTO component_source
	(component_type_id, card_text, progression_action, description_xml, card_group_id, position)
	VALUES
	(in_type_id, in_text, in_action, in_description, in_card_group_id, NVL(v_max_pos, 0) + 1);
	
	-- I don't think there's anything wrong with adding the actions to both cards, but feel free to correct this...
	card_pkg.AddProgressionAction('Chain.Cards.ComponentSource', in_action);
	card_pkg.AddProgressionAction('Chain.Cards.ComponentBuilder.ComponentSource', in_action);
END;

PROCEDURE GetSources (
	in_card_group_id		IN  component_source.card_group_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, progression_action, card_text, description_xml
		  FROM component_source
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NVL(card_group_id, in_card_group_id) = in_card_group_id
		 ORDER BY position;
END;

PROCEDURE ClearTypeContainment
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'ClearTypeContainment can only be run as BuiltIn/Administrator');
	END IF;

	DELETE 
	  FROM component_type_containment
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

END;


PROCEDURE SetTypeContainment (
	in_container_type_id				IN chain_pkg.T_COMPONENT_TYPE,
	in_child_type_id					IN chain_pkg.T_COMPONENT_TYPE,
	in_allow_flags						IN chain_pkg.T_FLAG
)
AS
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'SetTypeContainment can only be run as BuiltIn/Administrator');
	END IF;
	
	ActivateType(in_container_type_id);
	ActivateType(in_child_type_id);
	
	BEGIN
		INSERT INTO component_type_containment
		(container_component_type_id, child_component_type_id)
		VALUES
		(in_container_type_id, in_child_type_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
		
	UPDATE component_type_containment
	   SET allow_add_existing = chain_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_EXISTING),
	       allow_add_new = chain_pkg.Flag(in_allow_flags, chain_pkg.ALLOW_ADD_NEW)
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_type_id = in_container_type_id
	   AND child_component_type_id = in_child_type_id;

END;

PROCEDURE GetTypeContainment (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	FillTypeContainment;
	
	OPEN out_cur FOR
		SELECT * FROM tt_component_type_containment;
END;

/**********************************************************************************
	UTILITY
**********************************************************************************/
FUNCTION IsType (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE
) RETURN BOOLEAN
AS
	v_type_id		chain_pkg.T_COMPONENT_TYPE;
BEGIN
	BEGIN
		SELECT component_type_id
		  INTO v_type_id
		  FROM component_bind
		 WHERE app_sid = security_pkg.GetApp
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN FALSE;
	END;
	
	IF v_type_id = in_type_id THEN
		RETURN TRUE;
	ELSE
		RETURN FALSE;
	END IF;
END;

FUNCTION GetCompanySid (
	in_component_id		   IN component.component_id%TYPE
) RETURN security_pkg.T_SID_ID
AS
	v_company_sid 			company.company_sid%TYPE;
BEGIN
	BEGIN
		SELECT company_sid 
		  INTO v_company_sid 
		  FROM component_bind
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND component_id = in_component_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN NULL;
	END;
		
	RETURN v_company_sid;
	
END;

FUNCTION IsDeleted (
	in_component_id			IN component.component_id%TYPE
) RETURN BOOLEAN
AS
	v_deleted				component.deleted%TYPE;
BEGIN
	-- don't worry about sec as there's not much we can do with a bool flag...

	SELECT deleted
	  INTO v_deleted
	  FROM component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id;
	
	RETURN v_deleted = chain_pkg.DELETED;
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_id		IN  component.component_id%TYPE
)
AS
	v_top_component_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM TT_COMPONENT_TREE
	 WHERE top_component_id = in_top_component_id;
	
	-- if we've already got entries, get out
	IF v_count > 0 THEN
		RETURN;
	END IF;
	
	SELECT T_NUMERIC_ROW(in_top_component_id, NULL)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;
	
	RecordTreeSnapshot(v_top_component_ids);
END;

PROCEDURE RecordTreeSnapshot (
	in_top_component_ids	IN  T_NUMERIC_TABLE
)
AS
	v_unrecorded_ids		T_NUMERIC_TABLE;
	v_count					NUMBER(10);
BEGIN
	SELECT T_NUMERIC_ROW(item, NULL)
	  BULK COLLECT INTO v_unrecorded_ids
	  FROM TABLE(in_top_component_ids)
	 WHERE item NOT IN (SELECT top_component_id FROM TT_COMPONENT_TREE);
	 
	SELECT COUNT(*)
	  INTO v_count
	  FROM TABLE(v_unrecorded_ids);
	
	-- if there's nothing here, then they've all been collected
	IF v_count = 0 THEN
		RETURN;
	END IF;
	
	-- insert the top components
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, position)
	SELECT item, null, item, 0
	  FROM TABLE(v_unrecorded_ids);
	
	-- insert the tree
	INSERT INTO TT_COMPONENT_TREE
	(top_component_id, container_component_id, child_component_id, position)
	SELECT top_component_id, container_component_id, child_component_id, rownum
	  FROM (
			SELECT CONNECT_BY_ROOT container_component_id top_component_id, container_component_id, child_component_id
			  FROM component_relationship
			 START WITH container_component_id IN (SELECT item FROM TABLE(v_unrecorded_ids))
			CONNECT BY NOCYCLE PRIOR child_component_id = container_component_id
			 ORDER SIBLINGS BY position
		);
END;

/**********************************************************************************
	COMPONENT TYPE CALLS
**********************************************************************************/
PROCEDURE GetTypes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetType(NULL, out_cur);	
END;

PROCEDURE GetType (
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT component_type_id, handler_class, handler_pkg, node_js_path, description, editor_card_group_id		
		  FROM v$component_type
		 WHERE app_sid = security_pkg.GetApp
		   AND component_type_id = NVL(in_type_id, component_type_id);
END;

/**********************************************************************************
	COMPONENT CALLS
**********************************************************************************/
FUNCTION SaveComponent (
	in_component_id			IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE
) RETURN component.component_id%TYPE
AS
	v_component_id			component.component_id%TYPE;
	v_user_sid				security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'SID');
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF v_user_sid = security_pkg.SID_BUILTIN_ADMINISTRATOR THEN
		v_user_sid := securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Users/UserCreatorDaemon');
	END IF;
	
	IF NVL(in_component_id, 0) < 1 THEN

		INSERT INTO component 
		(component_id,  description, component_code, created_by_sid)
		VALUES 
		(component_id_seq.nextval, in_description, in_component_code, v_user_sid) 
		RETURNING component_id INTO v_component_id;
		
		INSERT INTO component_bind
		(component_id, component_type_id)
		VALUES
		(v_component_id, in_type_id);

	ELSE

		IF NOT IsType(in_component_id, in_type_id) THEN
			RAISE_APPLICATION_ERROR(-20001, 'Cannot save component with id '||in_component_id||' because it is not of type '||in_type_id);
		END IF;
		
		v_component_id := in_component_id;
		
		UPDATE component
		   SET description = in_description, 
			   component_code = in_component_code
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	END IF;
	
	RETURN v_component_id;
END;

PROCEDURE DeleteComponent (
	in_component_id		   	IN component.component_id%TYPE
)
AS
BEGIN
	IF IsDeleted(in_component_id) THEN
	   	RETURN;
    END IF;
	
	-- TODO: shouldn't DeleteComponent be checking the delete permission?
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE component 
	   SET deleted = chain_pkg.DELETED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND component_id = in_component_id; 

	-- call the handler
	EXECUTE IMMEDIATE 'begin '||GetHandlerPkg(GetTypeId(in_component_id))||'.DeleteComponent('||in_component_id||'); end;';
	
	-- detach the component from everything
	DetachComponent(in_component_id);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_READ);
	
	OPEN out_cur FOR
		SELECT component_id, component_type_id, company_sid, created_by_sid, created_dtm, description, component_code
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id
		   AND deleted = chain_pkg.NOT_DELETED;
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT c.component_id, c.component_type_id, c.description, c.component_code, c.deleted, c.company_sid, c.created_by_sid, c.created_dtm
		  FROM v$component c, TT_COMPONENT_TREE ct
		 WHERE c.app_sid = security_pkg.GetApp
		   AND c.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND c.component_type_id = in_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	SearchComponents(in_page, in_page_size, in_container_type_id, in_search_term, NULL, out_count_cur, out_result_cur);
END;

PROCEDURE SearchComponents ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_container_type_id	IN  chain_pkg.T_COMPONENT_TYPE,
	in_search_term  		IN  varchar2,
	in_of_type				IN  chain_pkg.T_COMPONENT_TYPE,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_search				VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search_term))|| '%';
	v_results				security.T_ORDERED_SID_TABLE := security.T_ORDERED_SID_TABLE();
BEGIN
	
	IF NOT capability_pkg.CheckCapability(chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	FillTypeContainment;
	
	-- bulk collect component id's that match our search result
	SELECT security.T_ORDERED_SID_ROW(component_id, null)
	  BULK COLLECT INTO v_results
	  FROM (
	  	SELECT c.component_id
		  FROM v$component c, tt_component_type_containment ctc
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
		   AND c.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND c.component_type_id = NVL(in_of_type, component_type_id)
		   AND c.component_type_id = ctc.child_component_type_id
		   AND ctc.container_component_type_id = in_container_type_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		   AND (   LOWER(description) LIKE v_search
				OR LOWER(component_code) LIKE v_search)
	  );
	
	OPEN out_count_cur FOR
		SELECT COUNT(*) total_count,
		   CASE WHEN in_page_size = 0 THEN 1 
				ELSE CEIL(COUNT(*) / in_page_size) END total_pages 
		  FROM TABLE(v_results);
			
	-- if page_size is 0, return all results
	IF in_page_size = 0 THEN	
		 OPEN out_result_cur FOR 
			SELECT *
			  FROM v$component c, TABLE(v_results) T
			 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND c.component_id = T.SID_ID
			   AND c.deleted = chain_pkg.NOT_DELETED
			 ORDER BY LOWER(c.description), LOWER(c.component_code);

	-- if page_size is specified, return the paged results
	ELSE		
		OPEN out_result_cur FOR 
			SELECT *
			  FROM (
				SELECT A.*, ROWNUM r 
				  FROM (
						SELECT c.*
						  FROM v$component c, TABLE(v_results) T
						 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND c.component_id = T.SID_ID
						   AND c.deleted = chain_pkg.NOT_DELETED
						 ORDER BY LOWER(c.description), LOWER(c.component_code)
					   ) A 
				 WHERE ROWNUM < (in_page * in_page_size) + 1
			) WHERE r >= ((in_page - 1) * in_page_size) + 1;
	END IF;
	
END;

-- Note: These are actually components belonging to the company but conceptually they are "stuff they buy"
PROCEDURE SearchComponentsPurchased (
	in_search					IN  VARCHAR2,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids				T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_order_by					VARCHAR2(200);
	v_sort_sql					VARCHAR2(4000);
	v_total_count				NUMBER(10);
	v_record_called				BOOLEAN DEFAULT FALSE;
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	---------------------------------------------------------------------------------------
	-- VALIDATE ORDERING DATA
	
	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'componentcode', 'suppliername') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	v_order_by := in_sort_by;
	-- remap a couple of order by columns
	IF LOWER(v_order_by) = 'componentcode' THEN v_order_by := 'component_code'; END IF;
	IF LOWER(v_order_by) = 'suppliername' THEN v_order_by := 'supplier_name'; END IF;
	
	v_order_by := 'LOWER(pc.'||v_order_by||') '||in_sort_dir;
	-- always sub order by product description (unless ordering by description)
	IF LOWER(in_sort_by) <> 'description' THEN
		v_order_by	:= v_order_by || ', LOWER(pc.description) '||in_sort_dir;
	END IF;
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODCUT IDS BASED ON INPUT
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id)
	SELECT component_id
	  FROM v$purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND ((in_supplier_company_sid IS NULL) OR (supplier_company_sid = in_supplier_company_sid) OR (uninvited_supplier_sid = in_supplier_company_sid))
	   AND ((LOWER(description) LIKE v_search) OR (LOWER(component_code) LIKE v_search));
	
	---------------------------------------------------------------------------------------
	-- APPLY THE ORDERING
	
	-- if the sort by is a column in the v$product view...
	v_sort_sql := ''||
		'	SELECT pc.component_id '||
		'	  FROM v$purchased_component pc, TT_ID t '||
		'	 WHERE pc.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') '||
		'	   AND pc.component_id = t.id '||
		'	 ORDER BY '||v_order_by;
	
	EXECUTE IMMEDIATE ''||
		'UPDATE TT_ID i '||
		'   SET position = ( '||
		'		SELECT r.rn '||
		'		  FROM ('||
		'			SELECT component_id, rownum rn '||
		'			  FROM ('||v_sort_sql||') '||
		'			) r '||
		'		 WHERE i.id = r.component_id '||
		'   )';
	
	---------------------------------------------------------------------------------------
	-- APPLY PAGING
	
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
	    OR position > NVL(in_start + in_page_size, v_total_count);
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_component_ids
	  FROM TT_ID;
	
	OPEN out_component_cur FOR
		SELECT component_id, description, 
			   component_code, deleted, company_sid, 
			   created_by_sid, created_dtm, component_supplier_type_id, 
			   acceptance_status_id, supplier_company_sid, supplier_name, supplier_country_code, supplier_country_name, 
			   purchaser_company_sid, purchaser_name, uninvited_supplier_sid, 
			   uninvited_name, supplier_product_id
		  FROM v$purchased_component cp, TABLE(v_component_ids) i
		 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cp.component_id = i.item
		 ORDER BY i.pos;
	
END;

/**********************************************************************************
	COMPONENT HEIRARCHY CALLS
**********************************************************************************/

PROCEDURE AttachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
	v_position				component_relationship.position%TYPE;
	v_container_type_id		chain_pkg.T_COMPONENT_TYPE;
	v_child_type_id			chain_pkg.T_COMPONENT_TYPE;
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	v_company_sid := component_pkg.GetCompanySid(in_container_id);
	
	IF v_company_sid <> component_pkg.GetCompanySid(in_child_id) THEN
		RAISE_APPLICATION_ERROR(-20001, 'You cannont attach components which are owned by different companies');
	END IF;
	
	SELECT NVL(MAX(position), 0) + 1
	  INTO v_position
	  FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id;
	
	SELECT component_type_id
	  INTO v_container_type_id
	  FROM v$component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_container_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	SELECT component_type_id
	  INTO v_child_type_id
	  FROM v$component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_child_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	BEGIN 
		INSERT INTO component_relationship
		(container_component_id, container_component_type_id, child_component_id, child_component_type_id, company_sid, position)
		VALUES
		(in_container_id, v_container_type_id, in_child_id, v_child_type_id, v_company_sid, v_position);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;


PROCEDURE DetachComponent (
	in_component_id			IN component.component_id%TYPE
)
AS
BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
		
	-- fully delete component relationship, no matter whether this component is the parent or the child
	DELETE FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (child_component_id = in_component_id OR container_component_id = in_component_id);
END;

PROCEDURE DetachChildComponents (
	in_container_id			IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE);
	
	-- fully delete all child attachments
	DELETE FROM component_relationship
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id;
END;

PROCEDURE DetachComponent (
	in_container_id			IN component.component_id%TYPE,
	in_child_id				IN component.component_id%TYPE	
)
AS
BEGIN
	CheckCapability(in_container_id, security_pkg.PERMISSION_WRITE) ;

	-- delete component relationship
	DELETE FROM component_relationship 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_container_id
	   AND child_component_id = in_child_id;

END;

/*
FUNCTION GetComponentTreeIds (
	in_top_component_id		IN component.component_id%TYPE
) RETURN T_NUMERIC_TABLE
AS
	v_top_component_ids		T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	SELECT T_NUMERIC_ROW(in_top_component_id, 0)
	  BULK COLLECT INTO v_top_component_ids
	  FROM DUAL;	
	
	RETURN GetComponentTreeIds(v_top_component_ids);
END;

FUNCTION GetComponentTreeIds (
	in_top_component_ids	IN T_NUMERIC_TABLE
) RETURN T_NUMERIC_TABLE
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	
	-- this intentionally barfs if we get more than one company_sid
	SELECT cb.company_sid
	  INTO v_company_sid
	  FROM component_bind cb, TABLE(in_top_component_ids) c
	 WHERE cb.component_id = c.item
	 GROUP BY cb.company_sid;
	
	IF NOT capability_pkg.CheckCapability(v_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to components for company with sid '||v_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(child_component_id, rn)
	  BULK COLLECT INTO v_component_ids
	  FROM (
	  		-- add the rownum
	  		SELECT child_component_id, rownum rn 
	  		  FROM (
				-- get unique ids
				SELECT UNIQUE child_component_id
				  FROM (
				  	-- include all of the top_component_ids that we've passed in
					SELECT item child_component_id FROM TABLE(in_top_component_ids)
					 UNION ALL
					-- wrap it to accomodate the order by / union
					SELECT child_component_id
					  FROM (
					    -- walk the tree
						SELECT child_component_id
						  FROM component_relationship
						 WHERE app_sid = security_pkg.GetApp
						 START WITH container_component_id IN (SELECT item FROM TABLE(in_top_component_ids))
					   CONNECT BY NOCYCLE PRIOR child_component_id = container_component_id
						 ORDER SIBLINGS BY position
						   )
				   )
			   )
		   );
	
	RETURN v_component_ids;
END;
*/
PROCEDURE GetComponentTreeHeirarchy (
	in_top_component_id		IN component.component_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	RecordTreeSnapshot(in_top_component_id);
	
	OPEN out_cur FOR
		SELECT child_component_id, container_component_id
		  FROM TT_COMPONENT_TREE
		 WHERE top_component_id = in_top_component_id
		 ORDER BY position;
END;

/**********************************************************************************
	SPECIFIC COMPONENT TYPE CALLS
**********************************************************************************/


PROCEDURE ChangeNotSureType (
	in_component_id			IN  component.component_id%TYPE,
	in_to_type_id			IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS

BEGIN
	CheckCapability(in_component_id, security_pkg.PERMISSION_WRITE);
	
	IF NOT IsType(in_component_id, chain_pkg.NOTSURE_COMPONENT) THEN
		RAISE_APPLICATION_ERROR(-20001, 'Cannot change component type to '||in_to_type_id||'of component with id '||in_component_id||' because it is not a NOT SURE component');
	END IF;
	
	-- THIS MAY BARF - I've set the constraint to deferrable initially deferred, so I _think_ it should be ok...
	
	UPDATE component_bind
	   SET component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	
	UPDATE component_relationship
	   SET child_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND child_component_id = in_component_id;
	
	UPDATE component_relationship
	   SET container_component_type_id = in_to_type_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND container_component_id = in_component_id;
	
	GetType(in_to_type_id, out_cur); 
END;

END component_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.purchased_component_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/

PROCEDURE RefeshSupplierActions (
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_supplier_company_sid	IN  security_pkg.T_SID_ID
)
AS
	v_count					NUMBER(10);
	v_action_id				action.action_id%TYPE;
BEGIN

	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component pc, v$supplier_relationship sr
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = sr.app_sid
	   AND pc.company_sid = in_company_sid
	   AND pc.company_sid = sr.purchaser_company_sid
	   AND pc.supplier_company_sid = in_supplier_company_sid
	   AND pc.supplier_company_sid = sr.supplier_company_sid
	   AND pc.acceptance_status_id = chain_pkg.ACCEPT_PENDING;
	
	IF v_count = 0 THEN
		
		message_pkg.CompleteMessage (
			in_primary_lookup 			=> chain_pkg.PRODUCT_MAPPING_REQUIRED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> in_supplier_company_sid,
			in_re_company_sid	  	 	=> in_company_sid
		);
			
	ELSE
		
		message_pkg.TriggerMessage (
			in_primary_lookup 			=> chain_pkg.PRODUCT_MAPPING_REQUIRED,
			in_secondary_lookup			=> chain_pkg.SUPPLIER_MSG,
			in_to_company_sid	  	 	=> in_supplier_company_sid,
			in_to_user_sid		  		=> chain_pkg.FOLLOWERS,
			in_re_company_sid	  	 	=> in_company_sid
		);
		
	END IF;

END;

PROCEDURE CollectToCursor (
	in_component_ids		IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT pc.component_id, pc.description, pc.component_code, pc.company_sid, 
				pc.created_by_sid, pc.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				-- supplier data
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				pcs.supplier_name, pcs.supplier_country_code, pcs.supplier_country_name
		  FROM v$purchased_component pc, v$purchased_component_supplier pcs, TABLE(in_component_ids) i
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = pcs.app_sid
		   AND pc.component_id = i.item
		   AND pc.component_id = pcs.component_id
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY i.pos;
END;

-- note that this procedure could be called by either the supplier or purchaser 
-- (if the purcher component is being deleted)
-- i.e. - be careful about getting the company sid from sys context
PROCEDURE SetSupplier (
	in_component_id			IN  component.component_id%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID
)
AS
	v_cur_data				purchased_component%ROWTYPE;
	v_supplier_type_id		component_supplier_type.component_supplier_type_id%TYPE;
	v_current_supplier_sid	security_pkg.T_SID_ID;
	v_company_sid 			security_pkg.T_SID_ID;
	v_accpetance_status_id	chain_pkg.T_ACCEPTANCE_STATUS;
	v_key					supplier_relationship.virtually_active_key%TYPE;
BEGIN
	
	
	-- figure out which type of supplier we're attaching to...
	IF NVL(in_supplier_sid, 0) > 0 THEN
		
		v_company_sid := component_pkg.GetCompanySid(in_component_id);
		
		-- activate the virtual relationship so that we can attach to companies with pending relationships as well
		company_pkg.ActivateVirtualRelationship(v_company_sid, in_supplier_sid, v_key);
		
		IF uninvited_pkg.IsUninvitedSupplier(v_company_sid, in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.UNINVITED_SUPPLIER;
		ELSIF company_pkg.IsSupplier(v_company_sid, in_supplier_sid) THEN
			v_supplier_type_id := chain_pkg.EXISTING_SUPPLIER;
		ELSIF company_pkg.IsPurchaser(v_company_sid, in_supplier_sid) THEN 
			v_supplier_type_id := chain_pkg.EXISTING_PURCHASER;
		END IF;
		
		company_pkg.DeactivateVirtualRelationship(v_key);
		
		IF v_supplier_type_id IS NULL THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied attaching to company with sid ('||in_supplier_sid||') - they are not a current purchaser or supplier of company with sid ('||v_company_sid||')');
		END IF;
	ELSE
		v_supplier_type_id := chain_pkg.SUPPLIER_NOT_SET;
	END IF;
	
	BEGIN
		-- try to setup minimum data in case it doesn't exist already
		INSERT INTO purchased_component
		(component_id, component_supplier_type_id)
		VALUES
		(in_component_id, chain_pkg.SUPPLIER_NOT_SET);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	-- get the current data
	SELECT *
	  INTO v_cur_data
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id;
	-- this is a bit of a strange way, but I think we're best to have an update statement per 
	-- supplier_type entry as the data that we need is highly dependant on this state
	
	IF v_supplier_type_id = chain_pkg.SUPPLIER_NOT_SET THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

	
	ELSIF v_supplier_type_id = chain_pkg.UNINVITED_SUPPLIER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = in_supplier_sid,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_PURCHASER THEN

		UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = NULL,
			   supplier_company_sid = NULL,
			   purchaser_company_sid = in_supplier_sid,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;

		   
	ELSIF v_supplier_type_id = chain_pkg.EXISTING_SUPPLIER THEN
	  
	  	IF v_cur_data.component_supplier_type_id <> chain_pkg.EXISTING_SUPPLIER OR v_cur_data.supplier_company_sid <> in_supplier_sid THEN
	  		v_accpetance_status_id := chain_pkg.ACCEPT_PENDING;
	  	ELSE
	  		v_accpetance_status_id := NVL(v_cur_data.acceptance_status_id, chain_pkg.ACCEPT_PENDING);
	  	END IF;
	  	
	  	UPDATE purchased_component
		   SET component_supplier_type_id = v_supplier_type_id,
			   acceptance_status_id = v_accpetance_status_id,
			   supplier_company_sid = in_supplier_sid,
			   purchaser_company_sid = NULL,
			   uninvited_supplier_sid = NULL,
			   supplier_product_id = NULL	   
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id = in_component_id;
	  	
	  	RefeshSupplierActions(v_cur_data.company_sid, in_supplier_sid);
	END IF;
END;

/**********************************************************************************
	PUBLIC -- ICOMPONENT HANDLER PROCEDURES
**********************************************************************************/

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_supplier_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	v_component_id := component_pkg.SaveComponent(in_component_id, chain_pkg.PURCHASED_COMPONENT, in_description, in_component_code);
	
	SetSupplier(v_component_id, in_supplier_sid);
	
	GetComponent(v_component_id, out_cur);
END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;

	SELECT T_NUMERIC_ROW(in_component_id, null)
	  BULK COLLECT INTO v_component_ids
	  FROM v$purchased_component 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_id = in_component_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_component_ids			T_NUMERIC_TABLE;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	SELECT T_NUMERIC_ROW(component_id, rownum)
	  BULK COLLECT INTO v_component_ids
	  FROM (
		SELECT pc.component_id
		  FROM v$purchased_component pc, TT_COMPONENT_TREE ct
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.component_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PURCHASED_COMPONENT
		   AND pc.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position
	);
		
	CollectToCursor(v_component_ids, out_cur);
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	SetSupplier(in_component_id, NULL);	
END;

/**********************************************************************************
	PUBLIC
**********************************************************************************/

PROCEDURE ClearSupplier (
	in_component_id				IN  component.component_id%TYPE
) 
AS
	v_count						NUMBER(10);
BEGIN
	-- make sure that the company clearing the supplier is either the supplier company, or the component owner company
	SELECT COUNT(*)
	  INTO v_count
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND component_id = in_component_id
	   AND (	company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') 
	   		 OR supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   	   );

	IF v_count = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied clearing the supplier for purchased component with id '||in_component_id||' where you are niether the owner or supplier company');
	END IF;
	
	SetSupplier(in_component_id, NULL);	
END;

PROCEDURE RelationshipActivated (
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_purchaser_company_sid
		   AND (
		   			supplier_company_sid = in_supplier_company_sid
		   		 OR purchaser_company_sid = in_supplier_company_sid
		   	   )
	) LOOP
		SetSupplier(r.component_id, in_supplier_company_sid);	
	END LOOP;
END;

PROCEDURE SearchProductMappings (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_accept_status			IN  chain_pkg.T_ACCEPTANCE_STATUS,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_results_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_product_ids				T_NUMERIC_TABLE;
	v_total_count				NUMBER(10);
BEGIN

	/*
	IF NOT capability_pkg.CheckCapability(in_purchaser_company_sid, chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||in_purchaser_company_sid);
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	
	-- collect all of the PURCHASERS products
	SELECT T_NUMERIC_ROW(product_id, NULL)
	  BULK COLLECT INTO v_product_ids
	  FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = NVL(in_purchaser_company_sid, company_sid)
	   AND deleted = chain_pkg.NOT_DELETED;
	
	-- take a snap shot of these trees
	component_pkg.RecordTreeSnapshot(v_product_ids);
	
	-- fill the id table with all valid purchased components, owned by the purchaser company, and supplied by our company
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id, position)
	SELECT component_id, rownum
	  FROM (
		SELECT pc.component_id
		  FROM v$purchased_component pc, TT_COMPONENT_TREE ct, (
		  		SELECT app_sid, product_id, description, code1, code2, code3
		  		  FROM v$product 
		  		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		  		   AND deleted = chain_pkg.NOT_DELETED
		  	   ) p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.app_sid = c.app_sid
		   AND pc.component_id = ct.child_component_id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_product_id = p.product_id(+)
		   AND pc.supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND pc.deleted = chain_pkg.NOT_DELETED
		   AND pc.acceptance_status_id = NVL(in_accept_status, pc.acceptance_status_id)
		   AND (
		   			pc.description LIKE v_search
		   		 OR pc.component_code LIKE v_search
		   		 OR p.description LIKE v_search
		   		 OR p.code1 LIKE v_search
		   		 OR p.code2 LIKE v_search
		   		 OR p.code3 LIKE v_search
		       )
		 ORDER BY LOWER(c.name), LOWER(pc.description)
		);

	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
		OR position > NVL(in_start + in_page_size, v_total_count);
		
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_results_cur FOR
		SELECT c.name purchaser_company_name, pc.component_id, pc.description component_description, pc.component_code, pc.acceptance_status_id, 
				p.product_id, p.description product_description, p.code1, p.code2, p.code3
		  FROM v$purchased_component pc, TT_ID i, v$product p, v$company c
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.app_sid = p.app_sid(+)
		   AND pc.component_id = i.id
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_company_sid = p.company_sid(+)
		   AND pc.supplier_product_id = p.product_id(+)
		 ORDER BY i.position;
END;

PROCEDURE ClearMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/
	
	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;

	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	       acceptance_status_id = chain_pkg.ACCEPT_PENDING
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;

	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE RejectMapping (
	in_component_id			IN  component.component_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = NULL,
	   	   acceptance_status_id = chain_pkg.ACCEPT_REJECTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
END;

PROCEDURE SetMapping (
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
)
AS
BEGIN
	/*
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	*/

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to write products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	UPDATE purchased_component
	   SET supplier_product_id = in_product_id,
		   acceptance_status_id = chain_pkg.ACCEPT_ACCEPTED
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND component_id = in_component_id;
	
	RefeshSupplierActions(component_pkg.GetCompanySid(in_component_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
END;

PROCEDURE MigrateUninvitedComponents (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID
)
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND uninvited_supplier_sid = in_uninvited_supplier_sid
	) LOOP
		SetSupplier(r.component_id, in_created_as_company_sid);	
	END LOOP;
END;


END purchased_component_pkg;
/
CREATE OR REPLACE PACKAGE BODY chain.product_pkg
IS

/**********************************************************************************
	PRIVATE
**********************************************************************************/
FUNCTION CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN
AS
	v_company_sid			security_pkg.T_SID_ID DEFAULT NVL(component_pkg.GetCompanySid(in_product_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
BEGIN
	RETURN capability_pkg.CheckCapability(v_company_sid, chain_pkg.PRODUCTS, in_permission_set);
END;

PROCEDURE CheckCapability (
	in_product_id			IN  product.product_id%TYPE,
	in_permission_set		IN  security_pkg.T_PERMISSION
)
AS
	v_company_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT CheckCapability(in_product_id, in_permission_set)  THEN
		
		v_company_sid := NVL(component_pkg.GetCompanySid(in_product_id), SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
		
		IF in_permission_set = security_pkg.PERMISSION_WRITE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_READ THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||v_company_sid);
		
		ELSIF in_permission_set = security_pkg.PERMISSION_DELETE THEN	
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Delete access denied to products for company with sid '||v_company_sid);
		
		ELSE
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied (perm_set:'||in_permission_set||') to products for company with sid '||v_company_sid);
		
		END IF;
	END IF;
END;

PROCEDURE CollectToCursor (
	in_product_ids			IN  T_NUMERIC_TABLE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT p.product_id, p.pseudo_root_component_id, p.active, p.code1, p.code2, p.code3, 
				p.need_review, p.description, p.company_sid, p.created_by_sid, p.created_dtm,
				'Open' status
		  FROM v$product p, TABLE(in_product_ids) i
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.product_id = i.item
		 ORDER BY i.pos;
END;

/**********************************************************************************
	PRODUCT CALLS
**********************************************************************************/

FUNCTION SaveProduct (
	in_product_id			IN  product.product_id%TYPE,
    in_description			IN  component.description%TYPE,
    in_code1				IN  chain_pkg.T_COMPONENT_CODE,
    in_code2				IN  chain_pkg.T_COMPONENT_CODE,
    in_code3				IN  chain_pkg.T_COMPONENT_CODE
) RETURN NUMBER
AS
	v_product_id			product.product_id%TYPE;
	v_pct					product_code_type%ROWTYPE;
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	-- this will do in the place of a NOT NULL on the column (not all components require a code)
	IF in_code1 IS NULL THEN
		RAISE_APPLICATION_ERROR(-20001, 'A product cannot have NULL component_code (code1)');
	END IF;
	
	v_product_id := component_pkg.SaveComponent(in_product_id, chain_pkg.PRODUCT_COMPONENT, in_description, in_code1);
	
	BEGIN
		-- we select this into a variable to be sure that the entry exists, an insert based on select would fail silently
		SELECT *
		  INTO v_pct
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		
		INSERT INTO product
		(product_id, pseudo_root_component_id, code2_mandatory, code2, code3_mandatory, code3)
		VALUES
		(v_product_id, v_product_id, v_pct.code2_mandatory, in_code2, v_pct.code3_mandatory, in_code3);
		
		chain_link_pkg.AddProduct(v_product_id);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE product
			   SET code2 = in_code2,
			       code3 = in_code3
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   		   AND product_id = v_product_id;
	END;

	
	RETURN v_product_id;
END;

PROCEDURE DeleteProduct (
	in_product_id		   IN product.product_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
    component_pkg.DeleteComponent(in_product_id);    
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	FOR r IN (
		SELECT component_id
		  FROM v$purchased_component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_supplier_type_id = chain_pkg.EXISTING_SUPPLIER
		   AND supplier_product_id = in_component_id
		   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	) LOOP
		purchased_component_pkg.ClearSupplier(r.component_id);	
    END LOOP;
END;


PROCEDURE GetProduct (
	in_product_id			IN  product.product_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_READ);

	SELECT T_NUMERIC_ROW(product_id, null)
	  BULK COLLECT INTO v_product_ids
	  FROM v$product 
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id
	   AND deleted = chain_pkg.NOT_DELETED;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProducts (
	in_company_sid			IN  security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||in_company_sid);
	END IF;	
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT product_id
		  FROM v$product
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid
		   AND deleted = chain_pkg.NOT_DELETED
		 ORDER BY LOWER(description), LOWER(code1)
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

-- this is required for component implementation
PROCEDURE GetComponent (
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetProduct(in_component_id, out_cur);
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR 
)
AS
	v_product_ids			T_NUMERIC_TABLE;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
		SELECT p.product_id
		  FROM v$product p, TT_COMPONENT_TREE ct
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.product_id = ct.child_component_id
		   AND ct.top_component_id = in_top_component_id
		   AND in_type_id = chain_pkg.PRODUCT_COMPONENT
		   AND p.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position
		);
	
	CollectToCursor(v_product_ids, out_cur);
END;

PROCEDURE SearchProductsSold (
	in_search					IN  VARCHAR2,
	in_purchaser_company_sid	IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID,
	in_only_show_need_review	IN  NUMBER,
	in_show_deleted				IN  NUMBER,
	in_start					IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_sort_by					IN  VARCHAR2,
	in_sort_dir					IN  VARCHAR2,
	out_count_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_product_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_purchaser_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_supplier_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_top_component_ids			T_NUMERIC_TABLE;
	v_product_ids				T_NUMERIC_TABLE;
	v_search					VARCHAR2(1000) DEFAULT '%'|| LOWER(TRIM(in_search))|| '%';
	v_order_by					VARCHAR2(200) DEFAULT 'LOWER(p.'||in_sort_by||') '||in_sort_dir;
	v_sort_sql					VARCHAR2(4000);
	v_total_count				NUMBER(10);
	v_record_called				BOOLEAN DEFAULT FALSE;
BEGIN

	IF NOT capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;	
	
	---------------------------------------------------------------------------------------
	-- VALIDATE ORDERING DATA
	
	-- to prevent any injection
	IF LOWER(in_sort_dir) NOT IN ('asc','desc') THEN
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort direction "'||in_sort_dir||'".');
	END IF;
	IF LOWER(in_sort_by) NOT IN ('description', 'code1', 'code2', 'code3', 'status') THEN -- add as needed
		RAISE_APPLICATION_ERROR(-20001, 'Unknown sort by col "'||in_sort_by||'".');
	END IF;	
	
	IF LOWER(in_sort_by) = 'status' THEN
		-- clear the order by as the only status that we have right now is 'Open'
		v_order_by := '';
	ELSIF LOWER(in_sort_by) = 'customer' THEN
		-- remap the order by
		v_order_by := 'LOWER(t.value) '||in_sort_dir;
	END IF;
	
	-- always sub order by product description (unless ordering by description)
	IF LOWER(in_sort_by) <> 'description' THEN
		v_order_by	:= v_order_by || ', LOWER(p.description) '||in_sort_dir;
	END IF;
	
	---------------------------------------------------------------------------------------
	-- COLLECT PRODCUT IDS BASED ON INPUT
	
	-- first we'll add all product that match our search and product flags
	DELETE FROM TT_ID;
	INSERT INTO TT_ID
	(id)
	SELECT product_id
	  FROM v$product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   -- don't show deleted unless it's been asked for
	   AND (deleted = chain_pkg.NOT_DELETED OR in_show_deleted = 1)
	   -- show all products unless we want to only show needs review ones
	   AND ((need_review = chain_pkg.ACTIVE AND in_only_show_need_review = 1) OR in_only_show_need_review = 0)
	   AND (   LOWER(description) LIKE v_search
			OR LOWER(code1) LIKE v_search
			OR LOWER(code2) LIKE v_search
			OR LOWER(code3) LIKE v_search
		   );

	-- if we're looking at a specific purchaser company, remove any products that we don't supply to them
	IF in_purchaser_company_sid IS NOT NULL THEN
		
		DELETE 
		  FROM TT_ID 
		 WHERE id NOT IN (
		 	SELECT supplier_product_id
		 	  FROM v$purchased_component
		 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND company_sid = in_purchaser_company_sid
		 	   AND supplier_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		 );
		 
	END IF;
	
	-- if we're looking at a specific supplier company, then we need to drill down the component tree and find all of our purchased components
	IF in_supplier_company_sid IS NOT NULL THEN
		
		SELECT T_NUMERIC_ROW(id, rownum)
	  	  BULK COLLECT INTO v_top_component_ids
	  	  FROM TT_ID;
		
		component_pkg.RecordTreeSnapshot(v_top_component_ids);
		v_record_called := TRUE;
		
		DELETE 
		  FROM TT_ID
		 WHERE id NOT IN (
		 	SELECT ct.top_component_id
		 	  FROM TT_COMPONENT_TREE ct, TT_ID i, v$purchased_component pc
		 	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND pc.component_id = ct.child_component_id
		 	   AND (pc.supplier_company_sid = in_supplier_company_sid)
		 	   AND ct.top_component_id = i.id
		 	   AND pc.deleted = chain_pkg.NOT_DELETED
		 );
		 
	END IF;
	
	---------------------------------------------------------------------------------------
	-- APPLY THE ORDERING
	
	-- if the sort by is a column in the v$product view...
	IF LOWER(in_sort_by) IN ('description', 'code1', 'code2', 'code3', 'status') THEN
	
		v_sort_sql := ''||
			'	SELECT p.product_id '||
			'	  FROM v$product p, TT_ID t '||
			'	 WHERE p.app_sid = SYS_CONTEXT(''SECURITY'', ''APP'') '||
			'	   AND p.product_id = t.id '||
			'	 ORDER BY '||v_order_by;
	
	/* -- the page doesn't let you do this!
	ELSIF LOWER(in_sort_by) = 'customer' THEN
	
		v_sort_sql := ''||
			'	SELECT id product_id, min(rn) '||
			'	  FROM ( '||
			'		SELECT i.id, rownum rn '||
			'		  FROM ( '||
			'		  	SELECT id  '||
			'		  	  FROM TT_ORDERED_PARAM  '||
			'			 ORDER BY '||v_order_by||
			'		  	 ) i '||
			'		 ) '||
			'	GROUP BY id';
	*/			
	END IF;
	
	EXECUTE IMMEDIATE ''||
		'UPDATE TT_ID i '||
		'   SET position = ( '||
		'		SELECT r.rn '||
		'		  FROM ('||
		'			SELECT product_id, rownum rn '||
		'			  FROM ('||v_sort_sql||') '||
		'			) r '||
		'		 WHERE i.id = r.product_id '||
		'   )';
	
	---------------------------------------------------------------------------------------
	-- APPLY PAGING
	
	SELECT COUNT(*)
	  INTO v_total_count
	  FROM TT_ID;

	DELETE 
	  FROM TT_ID
	 WHERE position <= NVL(in_start, 0)
	    OR position > NVL(in_start + in_page_size, v_total_count);
	
	---------------------------------------------------------------------------------------
	-- COLLECT SEARCH RESULTS
	OPEN out_count_cur FOR
		SELECT v_total_count total_count
		  FROM DUAL;
	
	OPEN out_purchaser_cur FOR
		SELECT pc.supplier_product_id product_id, c.company_sid, c.name
		  FROM v$purchased_component pc, v$company c, TT_ID i
		 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND pc.app_sid = c.app_sid
		   AND pc.company_sid = c.company_sid
		   AND pc.supplier_product_id = i.id
		   AND pc.deleted = chain_pkg.NOT_DELETED
	 	 ORDER BY LOWER(c.name);
	
	
	IF NOT v_record_called THEN
		SELECT T_NUMERIC_ROW(id, rownum)
		  BULK COLLECT INTO v_top_component_ids
		  FROM TT_ID;

		component_pkg.RecordTreeSnapshot(v_top_component_ids);
	END IF;
	
	OPEN out_supplier_cur FOR
		SELECT i.id product_id, c.company_sid, c.name
		  FROM TT_COMPONENT_TREE ct, TT_ID i, v$purchased_component pc, v$company c
	 	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND pc.app_sid = c.app_sid
		   AND pc.component_id = ct.child_component_id
		   AND pc.supplier_company_sid = c.company_sid
	 	   AND ct.top_component_id = i.id
		   AND pc.deleted = chain_pkg.NOT_DELETED
	 	 ORDER BY LOWER(c.name);
		 
	SELECT T_NUMERIC_ROW(id, position)
	  BULK COLLECT INTO v_product_ids
	  FROM TT_ID;
	
	CollectToCursor(v_product_ids, out_product_cur);
END;

PROCEDURE GetRecentProducts (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_product_ids			T_NUMERIC_TABLE :=  T_NUMERIC_TABLE();
BEGIN
	IF NOT capability_pkg.CheckCapability(chain_pkg.PRODUCTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to products for company with sid '||SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'));
	END IF;
	
	SELECT T_NUMERIC_ROW(product_id, rownum)
	  BULK COLLECT INTO v_product_ids
	  FROM (
			SELECT product_id
			  FROM v$product
			 WHERE created_by_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND created_dtm > SYSDATE - 7 -- let's give them a week as the row limit will take care of too many
			   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
			 ORDER BY created_dtm DESC
			)
	 WHERE rownum <= 3;
	
	CollectToCursor(v_product_ids, out_cur);
END;


PROCEDURE GetProductCodes (
	in_company_sid			IN  company.company_sid%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product code types for company with sid '||in_company_sid);
	END IF;

	OPEN out_cur FOR
		SELECT code_label1, code_label2, code_label3, code2_mandatory, code3_mandatory
		  FROM product_code_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductCodes (
    in_company_sid      	IN  security_pkg.T_SID_ID,
	in_code_label1			IN  product_code_type.code_label1%TYPE,
	in_code_label2			IN  product_code_type.code_label2%TYPE,
	in_code_label3			IN  product_code_type.code_label3%TYPE,
	in_code2_mandatory		IN  product_code_type.code2_mandatory%TYPE,
	in_code3_mandatory		IN 	product_code_type.code3_mandatory%TYPE
)
AS
BEGIN

	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	-- this will blowup if we're setting to mandatory and any of the existing products have null vals...
	UPDATE product
	   SET code2_mandatory = in_code2_mandatory,
		   code3_mandatory = in_code3_mandatory
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
	
	UPDATE product_code_type
	   SET code_label1 = TRIM(in_code_label1),
		   code_label2 = TRIM(in_code_label2),
		   code_label3 = TRIM(in_code_label3),
		   code2_mandatory = in_code2_mandatory,
		   code3_mandatory = in_code3_mandatory
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductCodeDefaults (
	in_company_sid			IN  company.company_sid%TYPE
)
AS 
BEGIN
	-- we'll let this blow up if it already exists because I'm not sure what the correct response is if this is called twice
	INSERT INTO product_code_type 
	(company_sid) 
	VALUES (in_company_sid);
END;


PROCEDURE GetMappingApprovalRequired (
	in_company_sid					IN  company.company_sid%TYPE,
	out_mapping_approval_required	OUT	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to product codes for company with sid '||in_company_sid);
	END IF;

	SELECT mapping_approval_required
	  INTO out_mapping_approval_required
	  FROM product_code_type
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetMappingApprovalRequired (
    in_company_sid					IN	security_pkg.T_SID_ID,
    in_mapping_approval_required	IN	product_code_type.mapping_approval_required%TYPE
)
AS
BEGIN
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.PRODUCT_CODE_TYPES, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to product code types for company with sid '||in_company_sid);
	END IF;

	UPDATE product_code_type
	   SET mapping_approval_required = in_mapping_approval_required
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP') 
	   AND company_sid = in_company_sid;
END;


PROCEDURE SetProductActive (
	in_product_id			IN  product.product_id%TYPE,
    in_active				IN  product.active%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);

	UPDATE product 
	   SET active = in_active
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


PROCEDURE SetProductNeedsReview (
	in_product_id			IN  product.product_id%TYPE,
    in_need_review			IN  product.need_review%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
	
	UPDATE product 
	   SET need_review = in_need_review
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


PROCEDURE SetPseudoRootComponent (
	in_product_id			IN  product.product_id%TYPE,
	in_component_id			IN  product.pseudo_root_component_id%TYPE
)
AS
BEGIN
	CheckCapability(in_product_id, security_pkg.PERMISSION_WRITE);
		
	UPDATE product 
	   SET pseudo_root_component_id = in_component_id
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND product_id = in_product_id;
END;


END product_pkg;
/

CREATE OR REPLACE PACKAGE  chain.message_pkg
IS

/**********************************************************************************
	INTERNAL FUNCTIONS
	
	These methods should not be widely used and are provided publicly for setup convenience
**********************************************************************************/

FUNCTION Lookup (
	in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE;

FUNCTION Lookup (
	in_primary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE;


/**********************************************************************************
	GLOBAL MANAGEMENT
	
	These methods act on data across all applications
**********************************************************************************/

/**
 * Creates or updates a message
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_message_template	The template text to use
 * @param in_repeat_type		Defines how create the message in the event that it already exists
 * @param in_priority			The priority of the message
 * @param in_addressing_type	Defines who the message should be delivered to
 * @param in_completion_type	Defines the method that will be used to complete this message
 * @param in_completed_template	Additional information to display once the message is marked as completed
 * @param in_helper_pkg			The pkg that will be called when this message is opened or completed
 * @param in_css_class			The css class that wraps the message
 */
PROCEDURE DefineMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE,
	in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
	in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
	in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
);

/**
 * Creates or updates a message parameter
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_param_name			The message parameter name (camelCase, must conform to [a-z][A-Z][0-9])
 * @param in_css_class			The css class to wrap the parameter in (this is only applied at the top template level - i.e. nested parameters will be not be wrapped)
 * @param in_href				The href for a link. Links are not used if this is null
 * @param in_value				The innerHTML of the link (if href is not null) or span
 *
 * NOTES:
 * 	1. top level template parameters are essentially xtemplate formatted as:
 *
 *		{paramName}->{paramName:OPEN}{paramName:VALUE}{paramName:CLOSE}
 *
 *		{paramName:OPEN} -> <span class="{cssClass}">
 *								<tpl if="href">
 *									<a href="{href}">
 *								</tpl>
 *						
 *		{paramName:VALUE} ->	{value}
 *
 *		{paramName:CLOSE} -> 	<tpl if="href">
 *									</a>
 *								</tpl>
 *							</span>
 *
 * 	2. subsequent level parameters are formatted using:
 *		
 *		{paramName} -> {value}
 *
 * This allows us to keep translations in-line in the template, but still use single parameter definitions as needed.
 */
PROCEDURE DefineMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL	
);


/**********************************************************************************
	APPLICATION MANAGEMENT
	
	These methods act on data at an application level
**********************************************************************************/

/**
 * Creates or updates an application level message override
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_message_template	Overrides the template text to use
 * @param in_priority			Overrides the priority of the message
 * @param in_addressing_type	Overrides who the message should be delivered to
 * @param in_completed_template	Overrides additional information to display once the message is marked as completed
 * @param in_helper_pkg			Overrides the pkg that will be called when this message is opened or completed
 * @param in_css_class			Overrides the css class that wraps the message
 */
PROCEDURE OverrideMessageDefinition (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE	DEFAULT NULL,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT NULL,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
);

/**
 * Creates or updates an application level message parameter override
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_param_name			The message parameter name (camelCase, must conform to [a-z][A-Z][0-9])
 * @param in_css_class			Overrides the css class to wrap the parameter in (this is only applied at the top template level - i.e. nested parameters will be not be wrapped)
 * @param in_href				Overrides the href for a link. Links are not used if this is null
 * @param in_value				Overrides the innerHTML of the link (if href is not null) or span
 *
 * NOTE: See above for notes on how parameters are applied
 */
PROCEDURE OverrideMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL
);

/**********************************************************************************
	COMMON METHODS
	
	These are the core methods for sending a message
**********************************************************************************/

/**
 * Creates a recipient box for the company_sid, user_sid combination
 *
 * @param in_company_sid		The company_sid to create the box for
 * @param in_user_sid			The user_sid to create the box for
 * @return recipient_id			The new recipient id
 */
FUNCTION CreateRecipient (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE;

/**
 * Triggers a message (triggering is determined by the message definition repeate type)
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 * @param in_due_dtm			A timestamp that will be used in the notes of the message.
 *
 *	NOTE: the in_due_dtm is only used as a visual aid for the user, and DOES NOT
 *		automatically trigger additional notifications if passed without completion.
 */
PROCEDURE TriggerMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_due_dtm					IN  message.due_dtm%TYPE						DEFAULT NULL
);

/**
 * Completes a message if it is completable and is not already completed
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
PROCEDURE CompleteMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
);

/**
 * Completes a message if it is completable and is not already completed
 *
 * @param in_message_id			The id of the message to complete
 */
PROCEDURE CompleteMessageById (
	in_message_id				IN  message.message_id%TYPE
);

/**
 * Finds the most recent message which matches the parameters provided. 
 *
 * @param in_primary_lookup		The primary lookup key for the message
 * @param in_secondary_lookup	The secondary (directional) lookup key for the message (e.g. PURCHASER_MSG or SUPPLIER_MSG)
 * @param in_to_company_sid		The company that the message is addressed to
 * @param in_to_user_sid		The user that the message is addressed to
 * @param in_re_company_sid		The company that the message is about
 * @param in_re_user_sid		The user that the message is about
 * @param in_re_questionnaire_type_id The questionnaire type that the message is about
 * @param in_re_component_id	The component that the message is about
 */
FUNCTION FindMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
RETURN message%ROWTYPE;

/**
 * Gets all messages for the current user, current company
 *
 * @param in_to_company_sid				The company to get the messages for
 * @param in_to_user_sid				The user to get the messages for
 * @param in_filter_for_priority		Set to non-zero to get remove messages that are needing completion, grouped by the highest priority
 * @param in_filter_for_pure_messages	Set to non-zero to get remove messages that are not needing completion
 * @param in_page_size					The page size - 0 to get all
 * @param in_page						The page number (ignored if page_size is 0)
 * @param out_stats_cur					The stats used for paging
 * @param out_message_cur				The message details
 * @param out_message_param_cur			The message definition parameters
 * @param out_company_cur				Companies that are involved in these messages
 * @param out_user_cur					Users that are involved in these messages
 * @param out_questionnaire_type_cur	Questionnaire types that are involved in these messages
 * @param out_component_cur				Components that are involved in these messages
 */
PROCEDURE GetMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_filter_for_priority		IN  NUMBER,
	in_filter_for_pure_messages	IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_page						IN  NUMBER,	
	out_stats_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
);

/**
 * Gets a message by id
 *
 * @param in_message_id			The id of the message to retrieve
 */
FUNCTION GetMessage (
	in_message_id				IN  message.message_id%TYPE
) RETURN message%ROWTYPE;


END message_pkg;
/

CREATE OR REPLACE PACKAGE BODY chain.message_pkg
IS

DIRECT_TO_USER				CONSTANT NUMBER := 0;
TO_ENTIRE_COMPANY			CONSTANT NUMBER := 1;
TO_OTHER_COMPANY_USER		CONSTANT NUMBER := 2;

/**********************************************************************************
	PRIVATE FUNCTIONS
**********************************************************************************/
FUNCTION GetDefinition (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE
) RETURN v$message_definition%ROWTYPE
AS
	v_dfn						v$message_definition%ROWTYPE;
BEGIN
	-- Grab the definition data
	SELECT *
	  INTO v_dfn
	  FROM v$message_definition
	 WHERE message_definition_id = in_message_definition_id;

	RETURN v_dfn;
END;

PROCEDURE CreateDefaultMessageParam (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_param_name				IN  message_param.param_name%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO default_message_param
		(message_definition_id, param_name, lower_param_name)
		VALUES
		(in_message_definition_id, in_param_name, LOWER(in_param_name));
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;	
END;

PROCEDURE CreateDefinitionOverride (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO message_definition
		(message_definition_id)
		VALUES
		(in_message_definition_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

FUNCTION GetRecipientId (
	in_message_id				IN  message.message_id%TYPE,
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE
AS
	v_r_id						recipient.recipient_id%TYPE;
BEGIN
	-- try to get the recipient id
	BEGIN	
		SELECT recipient_id
		  INTO v_r_id
		  FROM recipient
		 WHERE NVL(to_company_sid, 0) = NVL(in_company_sid, 0)
		   AND NVL(to_user_sid, 0) = NVL(in_user_sid, 0);
	EXCEPTION
		-- if we don't have an id for this combination, create one
		WHEN NO_DATA_FOUND THEN
			v_r_id := CreateRecipient(in_company_sid, in_user_sid);
		-- if we find more than one match, then send it off to the link_pkg
		WHEN TOO_MANY_ROWS THEN
			v_r_id := chain_link_pkg.FindMessageRecipient(in_message_id, in_company_sid, in_user_sid);
			
			IF v_r_id IS NULL THEN
				RAISE_APPLICATION_ERROR(-20001, 'Could not resolve to a single recipient id using company_sid='||in_company_sid||' and user_sid='||in_user_sid);
			END IF;
	END;

	RETURN v_r_id;
END;

FUNCTION FindMessage_ (
	in_message_definition_id	IN  message_definition.message_definition_id%TYPE,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
RETURN message%ROWTYPE
AS
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(in_message_definition_id);
	v_msg						message%ROWTYPE;
	v_message_id				message.message_id%TYPE;
	v_to_user_sid				security_pkg.T_SID_ID;
BEGIN
	IF in_to_user_sid <> chain_pkg.FOLLOWERS THEN
		v_to_user_sid := in_to_user_sid;
	END IF;
	
	IF v_to_user_sid IS NULL AND in_to_company_sid IS NULL THEN
		RETURN v_msg;
	END IF;	
	
	SELECT MAX(message_id)
	  INTO v_message_id
	  FROM (
			SELECT message_id, rownum rn
			  FROM v$message_recipient
			 WHERE message_definition_id = in_message_definition_id
			   AND (v_to_user_sid IS NULL OR to_user_sid = v_to_user_sid)
			   AND NVL(to_company_sid, 0) 			= NVL(in_to_company_sid, 0)
			   AND NVL(re_company_sid, 0) 			= NVL(in_re_company_sid, 0)
			   AND NVL(re_user_sid, 0) 				= NVL(in_re_user_sid, 0)
			   AND NVL(re_questionnaire_type_id, 0) = NVL(in_re_questionnaire_type_id, 0)
			   AND NVL(re_component_id, 0) 			= NVL(in_re_component_id, 0)
			 ORDER BY last_refreshed_dtm DESC
		   )
	 WHERE rn = 1;
		
	RETURN GetMessage(v_message_id);
END;

FUNCTION GetUserRecipientIds (
	in_company_sid				security_pkg.T_SID_ID,
	in_user_sid					security_pkg.T_SID_ID
) RETURN T_NUMERIC_TABLE
AS
	v_vals 						T_NUMERIC_TABLE;
BEGIN
	SELECT T_NUMERIC_ROW(recipient_id, addressed_to)
	  BULK COLLECT INTO v_vals
	  FROM (
	  		SELECT recipient_id, DIRECT_TO_USER addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid = in_user_sid
			   AND (to_company_sid IS NULL OR to_company_sid = in_company_sid)
			 UNION ALL
			SELECT recipient_id, TO_ENTIRE_COMPANY addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid IS NULL
			   AND to_company_sid = in_company_sid
			 UNION ALL
			SELECT recipient_id, TO_OTHER_COMPANY_USER addressed_to
			  FROM recipient
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND to_user_sid <> in_user_sid
			   AND to_company_sid = in_company_sid
	  );

	RETURN v_vals;
END;



/**********************************************************************************
	INTERNAL FUNCTIONS
**********************************************************************************/
FUNCTION Lookup (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE
AS
BEGIN
	RETURN Lookup(in_primary_lookup, chain_pkg.NONE_IMPLIED);
END;

FUNCTION Lookup (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP
) RETURN message_definition.message_definition_id%TYPE
AS
	v_dfn_id					message_definition.message_definition_id%TYPE;
BEGIN
	SELECT message_definition_id
	  INTO v_dfn_id
	  FROM message_definition_lookup
	 WHERE primary_lookup_id = in_primary_lookup
	   AND secondary_lookup_id = in_secondary_lookup;
	
	RETURN v_dfn_id;
END;


/**********************************************************************************
	GLOBAL MANAGEMENT
**********************************************************************************/
PROCEDURE DefineMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE,
	in_repeat_type				IN  chain_pkg.T_REPEAT_TYPE 					DEFAULT chain_pkg.ALWAYS_REPEAT,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT chain_pkg.NEUTRAL,
	in_addressing_type			IN  chain_pkg.T_ADDRESS_TYPE 					DEFAULT chain_pkg.COMPANY_USER_ADDRESS,
	in_completion_type			IN  chain_pkg.T_COMPLETION_TYPE 				DEFAULT chain_pkg.NO_COMPLETION,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE;
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessage can only be run as BuiltIn/Administrator');
	END IF;

	BEGIN
		INSERT INTO message_definition_lookup
		(message_definition_id, primary_lookup_id, secondary_lookup_id)
		VALUES
		(message_definition_id_seq.nextval, in_primary_lookup, in_secondary_lookup)
		RETURNING message_definition_id INTO v_dfn_id;
	EXCEPTION 
		WHEN DUP_VAL_ON_INDEX THEN
			v_dfn_id := Lookup(in_primary_lookup, in_secondary_lookup);
	END;
	
	BEGIN
		INSERT INTO default_message_definition
		(message_definition_id, message_template, message_priority_id, repeat_type_id, addressing_type_id, completion_type_id, completed_template, helper_pkg, css_class)
		VALUES
		(v_dfn_id, in_message_template, in_priority, in_repeat_type, in_addressing_type, in_completion_type, in_completed_template, in_helper_pkg, in_css_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE default_message_definition
			   SET message_template = in_message_template, 
			       message_priority_id = in_priority, 
			       repeat_type_id = in_repeat_type, 
			       addressing_type_id = in_addressing_type, 
			       completion_type_id = in_completion_type, 
			       completed_template = in_completed_template, 
			       helper_pkg = in_helper_pkg,
			       css_class = in_css_class
			 WHERE message_definition_id = v_dfn_id;
	END;
END;

PROCEDURE DefineMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE DEFAULT NULL,
	in_href						IN  message_param.href%TYPE DEFAULT NULL,
	in_value					IN  message_param.value%TYPE DEFAULT NULL	
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'DefineMessageParam can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefaultMessageParam(v_dfn_id, in_param_name);
	
	UPDATE default_message_param
	   SET value = in_value, 
	       href = in_href, 
	       css_class = in_css_class
	 WHERE message_definition_id = v_dfn_id
	   AND param_name = in_param_name;
END;

/**********************************************************************************
	APPLICATION MANAGEMENT
**********************************************************************************/
PROCEDURE OverrideMessageDefinition (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_message_template			IN  message_definition.message_template%TYPE	DEFAULT NULL,
	in_priority					IN  chain_pkg.T_PRIORITY_TYPE 					DEFAULT NULL,
	in_completed_template		IN  message_definition.completed_template%TYPE 	DEFAULT NULL,
	in_helper_pkg				IN  message_definition.helper_pkg%TYPE 			DEFAULT NULL,
	in_css_class				IN  message_definition.css_class%TYPE 			DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideMessageDefinition can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefinitionOverride(v_dfn_id);
	
	UPDATE message_definition
	   SET message_template = in_message_template, 
	       message_priority_id = in_priority, 
	       completed_template = in_completed_template, 
	       helper_pkg = in_helper_pkg, 
	       css_class = in_css_class
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND message_definition_id = v_dfn_id;
END;

PROCEDURE OverrideMessageParam (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_param_name				IN  message_param.param_name%TYPE,
	in_css_class				IN  message_param.css_class%TYPE 				DEFAULT NULL,
	in_href						IN  message_param.href%TYPE 					DEFAULT NULL,
	in_value					IN  message_param.value%TYPE 					DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
BEGIN
	IF NOT security_pkg.IsAdmin(security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'OverrideMessageDefinition can only be run as BuiltIn/Administrator');
	END IF;
	
	CreateDefaultMessageParam(v_dfn_id, in_param_name);
	CreateDefinitionOverride(v_dfn_id);
	
	BEGIN
		INSERT INTO message_param
		(message_definition_id, param_name, value, href, css_class)
		VALUES
		(v_dfn_id, in_param_name, in_value, in_href, in_css_class);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE message_param
			   SET value = in_value, 
			       href = in_href, 
			       css_class = in_css_class
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND message_definition_id = v_dfn_id
			   AND param_name = in_param_name;    
	END;
END;

/**********************************************************************************
	PUBLIC METHODS
**********************************************************************************/
FUNCTION CreateRecipient (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
)
RETURN recipient.recipient_id%TYPE
AS
	v_r_id						recipient.recipient_id%TYPE;
BEGIN
	INSERT INTO recipient
	(recipient_id, to_company_sid, to_user_sid)
	VALUES
	(recipient_id_seq.NEXTVAL, in_company_sid, in_user_sid)
	RETURNING recipient_id INTO v_r_id;
	
	RETURN v_r_id;
END;

PROCEDURE TriggerMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL,
	in_due_dtm					IN  message.due_dtm%TYPE						DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_dfn						v$message_definition%ROWTYPE DEFAULT GetDefinition(v_dfn_id);
	v_msg						message%ROWTYPE;
	v_msg_id					message.message_id%TYPE;
	v_r_id						recipient.recipient_id%TYPE;
	v_find_by_user_sid			security_pkg.T_SID_ID;	
	v_to_users					T_NUMBER_LIST;
BEGIN
	
	---------------------------------------------------------------------------------------------------
	-- validate message addressing

	IF v_dfn.addressing_type_id = chain_pkg.USER_ADDRESS THEN
		IF in_to_company_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid cannot be set for USER_ADDRESS messages');
		ELSIF in_to_user_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid must be set for USER_ADDRESS messages');
		END IF;
	ELSIF v_dfn.addressing_type_id = chain_pkg.COMPANY_ADDRESS THEN
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for COMPANY_ADDRESS messages');
		ELSIF in_to_user_sid IS NOT NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid cannot be set for COMPANY_ADDRESS messages');
		END IF;
	ELSE
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for COMPANY_USER_ADDRESS messages');
		ELSIF in_to_user_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'User sid must be set for COMPANY_USER_ADDRESS messages');
		END IF;
	END IF;	
	
	---------------------------------------------------------------------------------------------------
	-- manage pseudo user codes
	IF in_to_user_sid = chain_pkg.FOLLOWERS THEN
		IF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company sid must be set for FOLLOWERS psuedo addressed messages');
		ELSIF in_to_company_sid IS NULL THEN
			RAISE_APPLICATION_ERROR(-20001, 'Re company sid must be set for FOLLOWERS psuedo addressed messages');
		END IF;
	
		IF in_secondary_lookup = chain_pkg.SUPPLIER_MSG THEN
			v_to_users := company_pkg.GetPurchaserFollowers(in_re_company_sid, in_to_company_sid);
		ELSIF in_secondary_lookup = chain_pkg.PURCHASER_MSG THEN
			v_to_users := company_pkg.GetSupplierFollowers(in_to_company_sid, in_re_company_sid);
		ELSE
			RAISE_APPLICATION_ERROR(-20001, 'Secondary lookup must be specified as SUPPLIER_MSG or PURCHASER_MSG for FOLLOWERS psuedo addressed messages');
		END IF;
		
		IF v_to_users IS NULL OR v_to_users.COUNT = 0 THEN
			RAISE_APPLICATION_ERROR(-20001, 'TODO: figure out how we deal with messages addressed followers when no followers exist: msg_def_id='||v_dfn_id||', in_to_company_sid='||in_to_company_sid||', in_to_user_sid='||in_to_user_sid||', in_re_company_sid='||in_re_company_sid||', in_re_user_sid='||in_re_user_sid||', in_re_questionnaire_type_id='||in_re_questionnaire_type_id||', in_re_component_id='||in_re_component_id);
		END IF;
				
	ELSIF in_to_user_sid IS NOT NULL THEN
		
		v_to_users := T_NUMBER_LIST(in_to_user_sid);
		v_find_by_user_sid := in_to_user_sid;
		
	ELSE
		
		v_to_users := T_NUMBER_LIST(NULL);
		
	END IF;
	
	---------------------------------------------------------------------------------------------------
	-- get the message if it exists already 
	v_msg := FindMessage_(
		v_dfn_id, 
		in_to_company_sid, 
		v_find_by_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
	
	---------------------------------------------------------------------------------------------------
	-- apply repeatability
	IF v_dfn.repeat_type_id = chain_pkg.NEVER_REPEAT THEN	

		IF v_msg.message_id IS NOT NULL THEN 
			RETURN;
		END IF;
	
	ELSIF v_dfn.repeat_type_id = chain_pkg.REPEAT_IF_CLOSED THEN
	
		IF v_msg.completed_dtm IS NULL THEN
			RETURN;
		END IF;
	
	ELSIF v_dfn.repeat_type_id = chain_pkg.REFRESH_OR_REPEAT THEN
	
		IF v_msg.completed_dtm IS NULL THEN
			
			INSERT INTO message_refresh_log
			(message_id, refresh_index)
			SELECT message_id, MAX(refresh_index) + 1
			  FROM message_refresh_log
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND message_id = v_msg.message_id
			 GROUP BY message_id;
			
			DELETE FROM user_message_log
			 WHERE message_id = v_msg.message_id;
		
			chain_link_pkg.MessageRefreshed(v_dfn.helper_pkg, in_to_company_sid, v_msg.message_id);
			
			RETURN;

		END IF;
	
	END IF;
	
	---------------------------------------------------------------------------------------------------
	-- create the message entry 
	INSERT INTO message
	(message_id, message_definition_id, re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, due_dtm)
	VALUES
	(message_id_seq.NEXTVAL, v_dfn_id, in_re_company_sid, in_re_user_sid, in_re_questionnaire_type_id, in_re_component_id, in_due_dtm)
	RETURNING message_id INTO v_msg_id;
	
	INSERT INTO message_refresh_log
	(message_id, refresh_index)
	VALUES
	(v_msg_id, 0);
	
	FOR i IN v_to_users.FIRST .. v_to_users.LAST
	LOOP
		v_r_id := GetRecipientId(v_msg_id, in_to_company_sid, v_to_users(i));

		INSERT INTO message_recipient
		(message_id, recipient_id)
		VALUES
		(v_msg_id, v_r_id);
		
	END LOOP;
	
	chain_link_pkg.MessageCreated(v_dfn.helper_pkg, in_to_company_sid, v_msg.message_id);
END;

PROCEDURE CompleteMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
AS
	v_dfn_id					message_definition.message_definition_id%TYPE DEFAULT Lookup(in_primary_lookup, in_secondary_lookup);
	v_msg						message%ROWTYPE;
BEGIN
	v_msg := FindMessage_(
		v_dfn_id, 
		in_to_company_sid, 
		in_to_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
	
	IF v_msg.message_id IS NULL THEN
		-- crazy long message because if it blows up, it will be tough to figure out why - this may help...
		RAISE_APPLICATION_ERROR(-20001, 'Message could not be completed because it was not found: msg_def_id='||v_dfn_id||', in_to_company_sid='||in_to_company_sid||', in_to_user_sid='||in_to_user_sid||', in_re_company_sid='||in_re_company_sid||', in_re_user_sid='||in_re_user_sid||', in_re_questionnaire_type_id='||in_re_questionnaire_type_id||', in_re_component_id='||in_re_component_id);
	END IF;
	
	CompleteMessageById(v_msg.message_id);
	
END;

PROCEDURE CompleteMessageById (
	in_message_id				IN  message.message_id%TYPE
)
AS
	v_helper_pkg				message_definition.helper_pkg%TYPE;
	v_to_company_sid			security_pkg.T_SID_ID;
BEGIN
	
	UPDATE message
	   SET completed_dtm = SYSDATE,
	       completed_by_user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND message_id = in_message_id
	   AND message_definition_id IN (
	   		SELECT message_definition_id
	   		  FROM v$message_definition
	   		 WHERE completion_type_id <> chain_pkg.NO_COMPLETION
	   		);	

	IF SQL%ROWCOUNT > 0 THEN
		SELECT md.helper_pkg
		  INTO v_helper_pkg
		  FROM message m, v$message_definition md
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.message_definition_id = md.message_definition_id
		   AND m.message_id = in_message_id;
		
		SELECT MAX(r.to_company_sid) -- there may be 0 or more entries, but all have the same company sid
		  INTO v_to_company_sid
		  FROM recipient r, message_recipient mr
		 WHERE mr.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND mr.app_sid = r.app_sid
		   AND mr.recipient_id = r.recipient_id
		   AND mr.message_id = in_message_id;		   
		
		chain_link_pkg.MessageCompleted(v_helper_pkg, v_to_company_sid, in_message_id);
	END IF;
END;

FUNCTION FindMessage (
	in_primary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP,
	in_secondary_lookup			IN  chain_pkg.T_MESSAGE_DEFINITION_LOOKUP		DEFAULT chain_pkg.NONE_IMPLIED,
	in_to_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_to_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_company_sid			IN  security_pkg.T_SID_ID						DEFAULT NULL,	
	in_re_user_sid				IN  security_pkg.T_SID_ID						DEFAULT NULL,
	in_re_questionnaire_type_id	IN  message.re_questionnaire_type_id%TYPE		DEFAULT NULL,
	in_re_component_id			IN  message.re_component_id%TYPE				DEFAULT NULL
)
RETURN message%ROWTYPE
AS
BEGIN
	RETURN FindMessage_(
		Lookup(in_primary_lookup, in_secondary_lookup), 
		in_to_company_sid, 
		in_to_user_sid, 
		in_re_company_sid, 
		in_re_user_sid, 
		in_re_questionnaire_type_id, 
		in_re_component_id
	);
END;

PROCEDURE GetMessages (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_filter_for_priority		IN  NUMBER,
	in_filter_for_pure_messages	IN  NUMBER,
	in_page_size				IN  NUMBER,
	in_page						IN  NUMBER,
	out_stats_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_message_param_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_company_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_user_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_questionnaire_type_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_component_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_recipient_ids				T_NUMERIC_TABLE DEFAULT GetUserRecipientIds(in_to_company_sid, in_to_user_sid);
	v_user_level_messaging		company.user_level_messaging%TYPE;
	v_has_show_stoppers			NUMBER(10);
	v_page						NUMBER(10) DEFAULT in_page;
	v_count						NUMBER(10);
BEGIN
	
	-- TODO: turn this and the following query back into a single query
	INSERT INTO tt_message_search
	(	message_id, message_definition_id, to_company_sid, to_user_sid, 
		re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, 
		completed_by_user_sid, last_refreshed_by_user_sid, order_by_dtm
	)
	SELECT m.message_id, m.message_definition_id, m.to_company_sid, m.to_user_sid, 
			m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			m.completed_by_user_sid, m.last_refreshed_by_user_sid, 
			CASE WHEN m.completed_dtm IS NOT NULL AND m.completed_dtm > m.last_refreshed_dtm THEN m.completed_dtm ELSE m.last_refreshed_dtm END
	  FROM v$message_recipient m, v$message_definition md, TABLE(v_recipient_ids) r
	 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND m.recipient_id = r.item
	   AND m.message_definition_id = md.message_definition_id
	   AND md.message_priority_id <> chain_pkg.HIDDEN
	   AND (
			   -- the message is privately addressed to the user
			   (md.addressing_type_id = chain_pkg.USER_ADDRESS 			AND r.pos = DIRECT_TO_USER)
			   -- the message is addressed to the entire company
			OR (md.addressing_type_id = chain_pkg.COMPANY_ADDRESS 		AND r.pos = TO_ENTIRE_COMPANY)
				-- the message is address to the comapny and user 
			OR (md.addressing_type_id = chain_pkg.COMPANY_USER_ADDRESS 	AND r.pos = DIRECT_TO_USER)
				-- we're not using user level addressing, and the messsage is addressed to the company, but another user within the company
	   	   );
	
	SELECT NVL(MIN(user_level_messaging), chain_pkg.INACTIVE)
	  INTO v_user_level_messaging
	  FROM v$company
	 WHERE company_sid = in_to_company_sid;
	 
	IF v_user_level_messaging = chain_pkg.INACTIVE THEN
		-- TODO: turn this and the previous query back into a single query
		INSERT INTO tt_message_search
		(	message_id, message_definition_id, to_company_sid, to_user_sid, 
			re_company_sid, re_user_sid, re_questionnaire_type_id, re_component_id, 
			completed_by_user_sid, last_refreshed_by_user_sid, order_by_dtm
		)
		SELECT m.message_id, m.message_definition_id, m.to_company_sid, m.to_user_sid, 
				m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
				m.completed_by_user_sid, m.last_refreshed_by_user_sid, 
			CASE WHEN m.completed_dtm IS NOT NULL AND m.completed_dtm > m.last_refreshed_dtm THEN m.completed_dtm ELSE m.last_refreshed_dtm END
		  FROM v$message_recipient m, v$message_definition md, TABLE(v_recipient_ids) r
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.recipient_id = r.item
		   AND m.message_definition_id = md.message_definition_id
		   AND md.message_priority_id <> chain_pkg.HIDDEN
		   AND md.addressing_type_id = chain_pkg.COMPANY_USER_ADDRESS 	
		   AND r.pos = TO_OTHER_COMPANY_USER
		   AND m.message_id NOT IN (SELECT message_id FROM tt_message_search);
	END IF;
	
	IF in_filter_for_priority <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE completed_by_user_sid IS NOT NULL;
		
		DELETE FROM tt_message_search
		 WHERE message_definition_id IN (
		 	SELECT message_definition_id
		 	  FROM v$message_definition
		 	 WHERE completion_type_id = chain_pkg.NO_COMPLETION
		 );
		
		SELECT COUNT(*)
		  INTO v_has_show_stoppers
		  FROM tt_message_search ms, v$message_definition md
		 WHERE ms.message_definition_id = md.message_definition_id 
		   AND md.message_priority_id = chain_pkg.SHOW_STOPPER;
		
		IF v_has_show_stoppers > 0 THEN
			DELETE FROM tt_message_search
			 WHERE message_definition_id NOT IN (
				SELECT message_definition_id
				  FROM v$message_definition
				 WHERE message_priority_id = chain_pkg.SHOW_STOPPER
		 		);		
		END IF;
	END IF;

	IF in_filter_for_pure_messages <> 0 THEN
		DELETE FROM tt_message_search
		 WHERE completed_by_user_sid IS NULL
		   AND message_definition_id NOT IN (
		   	SELECT message_definition_id
			  FROM v$message_definition
		 	 WHERE completion_type_id = chain_pkg.NO_COMPLETION
		   );
	END IF;

	SELECT COUNT(*)
	  INTO v_count
	  FROM tt_message_search;
	
	OPEN out_stats_cur FOR
		SELECT v_count total_rows FROM DUAL;

	IF in_page_size > 0 THEN
		IF in_page < 1 THEN
			v_page := 1;
		END IF;
		
		DELETE FROM tt_message_search
		 WHERE message_id NOT IN (
			SELECT message_id
			  FROM (
				SELECT message_id, rownum rn
				  FROM (
					SELECT message_id
					  FROM tt_message_search
					 ORDER BY order_by_dtm DESC
					)
			  )
			 WHERE rn > in_page_size * (v_page - 1)
			   AND rn <= in_page_size * v_page
		 );		 
	END IF;


	UPDATE tt_message_search o
	   SET viewed_dtm = (
	   		SELECT viewed_dtm
	   		  FROM user_message_log i
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
			   AND i.message_id = o.message_id
  		);
	
	INSERT INTO user_message_log
	(message_id, user_sid, viewed_dtm)
	SELECT message_id, in_to_user_sid, SYSDATE
	  FROM tt_message_search
	 WHERE (SYS_CONTEXT('SECURITY', 'APP'), message_id, in_to_user_sid) NOT IN (
	 	SELECT app_sid, message_id, user_sid
	 	  FROM user_message_log
	 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	 	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
	 );	 

	OPEN out_message_cur FOR
		SELECT m.message_id, m.message_definition_id, md.message_template, md.completion_type_id, m.completed_by_user_sid, 
			   md.completed_template, md.css_class, ms.to_company_sid, ms.to_user_sid, 
			   m.re_company_sid, m.re_user_sid, m.re_questionnaire_type_id, m.re_component_id, 
			   m.completed_dtm, m.created_dtm, m.last_refreshed_dtm, m.last_refreshed_by_user_sid, m.due_dtm, SYSDATE now_dtm,
			   CASE WHEN m.completed_dtm IS NULL AND md.completion_type_id = chain_pkg.ACKNOWLEDGE THEN 1 ELSE 0 END requires_acknowledge
		  FROM v$message m, v$message_definition md, tt_message_search ms
		 WHERE m.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND m.message_definition_id = md.message_definition_id
		   AND m.message_id = ms.message_id
		 ORDER BY ms.order_by_dtm DESC;
		   
	OPEN out_message_param_cur FOR
		SELECT message_definition_id, param_name, value, href, css_class
		  FROM v$message_param 
		 WHERE message_definition_id IN (
		 		SELECT message_definition_id FROM tt_message_search
		 	   );
		 
	OPEN out_company_cur FOR
		SELECT company_sid, name 
		  FROM company
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND company_sid IN (
		   		SELECT to_company_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT re_company_sid FROM tt_message_search
		   	   );

	OPEN out_user_cur FOR
		SELECT csr_user_sid user_sid, full_name
		  FROM csr.csr_user
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND csr_user_sid  IN (
		   		SELECT to_user_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT re_user_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT completed_by_user_sid FROM tt_message_search
		   		 UNION ALL
		   		SELECT last_refreshed_by_user_sid FROM tt_message_search
		   	   );
		
	OPEN out_questionnaire_type_cur FOR
		SELECT questionnaire_type_id, name, edit_url, view_url
		  FROM questionnaire_type
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND questionnaire_type_id IN (
		 		SELECT re_questionnaire_type_id FROM tt_message_search
		 	   );

	OPEN out_component_cur FOR
		SELECT component_id, description
		  FROM v$component
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND component_id IN (
		 		SELECT re_component_id FROM tt_message_search
		 	   );
END;

FUNCTION GetMessage (
	in_message_id				IN  message.message_id%TYPE
) RETURN message%ROWTYPE
AS
	v_msg						message%ROWTYPE;
BEGIN
	BEGIN
		SELECT *
		  INTO v_msg
		  FROM message
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND message_id = in_message_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL;
	END;
	
	RETURN v_msg;
END;



END message_pkg;
/

commit;
PROMPT >> Inserting basedata

BEGIN
	-- setup message repeat types
	INSERT INTO chain.repeat_type (repeat_type_id, description)
	VALUES (chain.chain_pkg.NEVER_REPEAT, 'Never repeat');

	INSERT INTO chain.repeat_type (repeat_type_id, description)
	VALUES (chain.chain_pkg.REPEAT_IF_CLOSED, 'Repeat it if closed');

	INSERT INTO chain.repeat_type (repeat_type_id, description)
	VALUES (chain.chain_pkg.REFRESH_OR_REPEAT, 'Refreshes the timestamp on an existing open message, or creates a new one');
	
	INSERT INTO chain.repeat_type (repeat_type_id, description)
	VALUES (chain.chain_pkg.ALWAYS_REPEAT, 'Always repeat');

	-- setup addressing types
	INSERT INTO chain.addressing_type (addressing_type_id, description)
	VALUES (chain.chain_pkg.USER_ADDRESS, 'Private address - send it to this user regardless of company');
	
	INSERT INTO chain.addressing_type (addressing_type_id, description)
	VALUES (chain.chain_pkg.COMPANY_USER_ADDRESS, 'User address - send it to this user at the specified company');
	
	INSERT INTO chain.addressing_type (addressing_type_id, description)
	VALUES (chain.chain_pkg.COMPANY_ADDRESS, 'Company address - send it to all users of this company');

	-- setup message priority
	INSERT INTO chain.message_priority (message_priority_id, description)
	VALUES (chain.chain_pkg.HIDDEN, 'Never show the message');
	
	INSERT INTO chain.message_priority (message_priority_id, description)
	VALUES (chain.chain_pkg.NEUTRAL, 'The message is neutral (informational)');
	
	INSERT INTO chain.message_priority (message_priority_id, description)
	VALUES (chain.chain_pkg.SHOW_STOPPER, 'This must be attended to before other show stopper or highlighted messages are shown');

	-- setup completion types
	INSERT INTO chain.completion_type (completion_type_id, description)
	VALUES (chain.chain_pkg.NO_COMPLETION, 'No completion is required - this is a pure message');
	
	INSERT INTO chain.completion_type (completion_type_id, description)
	VALUES (chain.chain_pkg.ACKNOWLEDGE, 'The user must only acknowledge that this message has been read');
	
	INSERT INTO chain.completion_type (completion_type_id, description)
	VALUES (chain.chain_pkg.CODE_ACTION, 'The user must follow a course of action, and this will be completed through code');
END;
/

commit;
PROMPT >> Setting up default messages



BEGIN

	user_pkg.LogonAdmin;
	
	/****************************************************************************
			ADMINISTRATIVE MESSAGING
	*****************************************************************************/
	
	----------------------------------------------------------------------------
	--	CONFIRM_COMPANY_DETAILS
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.CONFIRM_COMPANY_DETAILS,
		in_message_template 		=> 'Please check and confirm the company details for {toCompany}.',
		in_repeat_type 				=> chain.chain_pkg.NEVER_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.COMPANY_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Confirmed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon info-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.CONFIRM_COMPANY_DETAILS, 
				in_param_name 				=> 'toCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_href 					=> '/csr/site/chain/myCompany.acds?confirm=true', 
				in_value 					=> '{toCompanyName}'
			);
			
	----------------------------------------------------------------------------
	--		CONFIRM_YOUR_DETAILS
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.CONFIRM_YOUR_DETAILS,
		in_message_template 		=> 'Welcome, as a first step please check and confirm your {toUser:OPEN}personal details{toUser:CLOSE}.',
		in_repeat_type 				=> chain.chain_pkg.NEVER_REPEAT,
		in_addressing_type 			=> chain.chain_pkg.USER_ADDRESS,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Confirmed {relCompletedDtm}',
		in_css_class 				=> 'background-icon info-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.CONFIRM_YOUR_DETAILS, 
				in_param_name 				=> 'toUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_href 					=> '/csr/site/chain/myDetails.acds?confirm=true'
			);
	
	/****************************************************************************
			INVITATION MESSAGING
	*****************************************************************************/

	----------------------------------------------------------------------------
	--		INVITATION_SENT
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation sent to {reUser} of {reCompany} by {triggerUser}.',
		in_css_class 				=> 'background-icon invitation-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_SENT, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);
	
	----------------------------------------------------------------------------
	--		INVITATION_ACCEPTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation accepted by {reUser} from {reCompany}.',
		in_css_class 				=> 'background-icon invitation-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_ACCEPTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
	
	
	----------------------------------------------------------------------------
	--		INVITATION_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation rejected by {reUser} from {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon invitation-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_REJECTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_value 					=> '{reCompanyName}'
			);

	----------------------------------------------------------------------------
	--		INVITATION_EXPIRED
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Invitation to {reUser} of {reCompany} has expired.',
		in_css_class 				=> 'background-icon invitation-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.INVITATION_EXPIRED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
		
	
	/****************************************************************************
			QUESTIONNAIRE MESSAGING
	*****************************************************************************/

	----------------------------------------------------------------------------
	--		COMPLETE_QUESTIONNAIRE
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please enter {reQuestionnaire} data for {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} data submitted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_SUBMITTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} submitted by {triggerUser} to {reCompany}.',
		in_helper_pkg				=> 'chain.questionnaire_pkg',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Your {reQuestionnaire} has been received and accepted by {reCompany}.',
		in_completion_type 			=> chain.chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowleded by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} has been approved.',
		in_helper_pkg				=> 'chain.questionnaire_pkg',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_OVERDUE -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} is overdue.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_OVERDUE -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} is overdue.',
		in_repeat_type 				=> chain.chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
	
	/****************************************************************************
			COMPONENT MESSAGING
	*****************************************************************************/

	----------------------------------------------------------------------------
	--		PRODUCT_MAPPING_REQUIRED
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.chain_pkg.PRODUCT_MAPPING_REQUIRED,
		in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'One or more products that {reCompany} buys from you {productMapping:OPEN}needs to be mapped{productMapping:CLOSE} to the actual products you sell.',
		in_repeat_type 				=> chain.chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Last mapping completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon product-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.PRODUCT_MAPPING_REQUIRED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.chain_pkg.PRODUCT_MAPPING_REQUIRED, 
				in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'productMapping', 
				in_css_class 				=> 'background-icon faded-product-icon',
				in_href 					=> '/csr/site/chain/products/mapmyproductstopurchasers.acds?companySid={reCompanySid}'
			);

	/****************************************************************************
			MAERSK/CHAINDEMO SPECIFIC
	****************************************************************************/	
	----------------------------------------------------------------------------
	--		CHANGED_SUPPLIER_REG_DETAILS
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 				=> chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS,
		in_secondary_lookup				=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template				=> 'Supplier registration details for {reCompany} have changed. Please review your {rap:OPEN}Readiness Assessment Priority{rap:CLOSE}.',
		in_completion_type 				=> chain.chain_pkg.CODE_ACTION,
		in_completed_template 			=> 'Reviewed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 					=> 'background-icon questionnaire-icon'
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, 
				in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 			=> 'reCompany', 
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 				=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup =>		chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, 
				in_secondary_lookup	=> 		chain.chain_pkg.PURCHASER_MSG,
				in_param_name =>			'rap'
		);


	----------------------------------------------------------------------------
	--		ACTION_PLAN_STARTED
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 				=> chain.chain_pkg.ACTION_PLAN_STARTED,
		in_secondary_lookup				=> chain.chain_pkg.PURCHASER_MSG,
		in_message_template				=> 'An {actionPlan:OPEN}action plan{actionPlan:CLOSE} has been started (or restarted) for {reCompany}.',
		in_css_class 					=> 'background-icon faded-questionnaire-icon',
		in_priority						=> chain.chain_pkg.HIDDEN -- turn off by default
	);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.ACTION_PLAN_STARTED, 
				in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name			=> 'reCompany', 
				in_css_class 			=> 'background-icon faded-company-icon',
				in_href 				=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 				=> '{reCompanyName}'
			);

			chain.message_pkg.DefineMessageParam(
				in_primary_lookup 		=> chain.chain_pkg.ACTION_PLAN_STARTED, 
				in_secondary_lookup		=> chain.chain_pkg.PURCHASER_MSG,
				in_param_name 			=> 'actionPlan'
		);

END;
/

commit;
PROMPT >> Setting up override messages


BEGIN

	user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT host 
		  FROM chain.v$chain_host WHERE chain_implementation IN (
			'CSR.HAMMERSON',
			'CSR.SCAA',
			'CSR.WHISTLER',
			'deutschebank',
			'eicc.credit360.com'
		  )
	) LOOP
		user_pkg.LogonAdmin(r.host);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.CONFIRM_COMPANY_DETAILS,
			in_message_template 		=> 'An admin must check your registered company details for {toCompany}.'
			-- as opposed to			   'Please check and confirm the company details for {toCompany}.'
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.CONFIRM_YOUR_DETAILS,
			in_message_template 		=> 'You must check your {toUser:OPEN}personal details{toUser:CLOSE}.'
			-- as opposed to 			   'Welcome, as a first step please check and confirm your {toUser:OPEN}personal details{toUser:CLOSE}.',
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
			in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
			in_message_template 		=> 'Your {reQuestionnaire} has been approved.'
			-- as opposed to			   'Your {reQuestionnaire} has been received and accepted by {reCompany}.'
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} has been approved. Click to view results.'
			-- as opposed to 			   'Questionnaire {reQuestionnaire} for {reCompany} has been approved.'
		);
		
	END LOOP;
	
	FOR r2 IN (
		SELECT host, chain_implementation 
		  FROM chain.v$chain_host WHERE chain_implementation = 'MAERSK'
	) LOOP
		user_pkg.LogonAdmin(r2.host);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_message_template 		=> 'Please review the {reQuestionnaire} data submitted by {reCompany} and resulting Readiness Assessment Priority.'
			-- as opposed to			   'Please review the {reQuestionnaire} data submitted by {reCompany}.'
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
			in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
			in_message_template 		=> 'Your {reQuestionnaire} has been received and accepted by {reCompany}. Click to review your Readiness Assessment Priority.'
			-- as opposed to 			   'Your {reQuestionnaire} has been received and accepted by {reCompany}.'
		);
		
		chain.message_pkg.OverrideMessageParam(
			in_primary_lookup 			=> chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, 
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_param_name 				=> 'rap', 
			in_href 					=> '/maersk/site/results/registrationResultsOverview.acds?companySid={reCompanySid}'
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 				=> chain.chain_pkg.ACTION_PLAN_STARTED,
			in_secondary_lookup				=> chain.chain_pkg.PURCHASER_MSG,
			in_priority						=> chain.chain_pkg.NEUTRAL
		);
		
		chain.message_pkg.OverrideMessageParam(
			in_primary_lookup 			=> chain.chain_pkg.ACTION_PLAN_STARTED, 
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_param_name 				=> 'actionPlan', 
			in_href 					=> '/maersk/site/results/registrationResultsOverview.acds?companySid={reCompanySid}'
		);
		
		

		
	END LOOP;
	
	FOR r2 IN (
		SELECT host, chain_implementation 
		  FROM v$chain_host WHERE chain_implementation = 'CHAINDEMO'
	) LOOP
		user_pkg.LogonAdmin(r2.host);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_SUBMITTED,
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_message_template 		=> 'Please review the {reQuestionnaire} data submitted by {reCompany} and resulting Readiness Assessment Priority.'
			-- as opposed to			   'Please review the {reQuestionnaire} data submitted by {reCompany}.'
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
			in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
			in_message_template 		=> 'Your {reQuestionnaire} has been received and accepted by {reCompany}. Click to review your Readiness Assessment Priority.'
			-- as opposed to 			   'Your {reQuestionnaire} has been received and accepted by {reCompany}.'
		);
		
		chain.message_pkg.OverrideMessageParam(
			in_primary_lookup 			=> chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, 
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_param_name 				=> 'rap', 
			in_href 					=> '/chaindemo/site/results/registrationResultsOverview.acds?companySid={reCompanySid}'
		);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 				=> chain.chain_pkg.ACTION_PLAN_STARTED,
			in_secondary_lookup				=> chain.chain_pkg.PURCHASER_MSG,
			in_priority						=> chain.chain_pkg.NEUTRAL
		);
		
		chain.message_pkg.OverrideMessageParam(
			in_primary_lookup 			=> chain.chain_pkg.ACTION_PLAN_STARTED, 
			in_secondary_lookup			=> chain.chain_pkg.PURCHASER_MSG,
			in_param_name 				=> 'actionPlan', 
			in_href 					=> '/chaindemo/site/results/registrationResultsOverview.acds?companySid={reCompanySid}'
		);
		
	END LOOP;
	
	FOR r3 IN (
		SELECT host 
		  FROM v$chain_host WHERE chain_implementation IN (
			'OTTO'
		  )
	) LOOP
		user_pkg.LogonAdmin(r3.host);
		
		chain.message_pkg.OverrideMessageDefinition(
			in_primary_lookup 			=> chain.chain_pkg.QUESTIONNAIRE_APPROVED,
			in_secondary_lookup			=> chain.chain_pkg.SUPPLIER_MSG,
			in_message_template 		=> 'Your {reQuestionnaire} submission has been accepted.'
			-- as opposed to			   'Your {reQuestionnaire} has been received and accepted by {reCompany}.'
		);
		
		
	END LOOP;
		
END;
/

commit;
PROMPT >> Setting up mappings


BEGIN
	/********************************************************************************
		Setup Action Mappings
	********************************************************************************/
	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.CONFIRM_COMPANY_DETAILS), 1, 'Please check and confirm the company details for {forCompanyUrl}');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.COMPLETE_QUESTIONNAIRE, chain.chain_pkg.SUPPLIER_MSG), 2, 'Please enter {relatedQuestionnaireUrl} data for {forCompanyName}');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, chain.chain_pkg.PURCHASER_MSG), 3, 'Please review the {relatedQuestionnaireUrl} data entered by {relatedCompanyUrl}.');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_APPROVED, chain.chain_pkg.SUPPLIER_MSG), 4, 'Your {relatedQuestionnaireUrl} has been received and accepted by {relatedCompanyName}');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.CONFIRM_YOUR_DETAILS), 5, 'Welcome, as a first step please check and confirm your {forUserUrl}personal details{otherUrl1}.');

	INSERT INTO chain.TEMP_MESSAGE_MAP -- this is used for maersk, and chain demo (but we don't need it on cd)
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.CHANGED_SUPPLIER_REG_DETAILS, chain.chain_pkg.PURCHASER_MSG), 6, 'Supplier registration details for {relatedCompanyUrl} have changed. Click to review your Readiness Assessment Priority.');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, action_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.PRODUCT_MAPPING_REQUIRED, chain.chain_pkg.SUPPLIER_MSG), 100, 'One or more products {relatedCompanyName} buy from you need {otherUrl1} to the actual products you sell.');


	/********************************************************************************
		Setup Event Mappings
	********************************************************************************/
	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.INVITATION_SENT, chain.chain_pkg.PURCHASER_MSG), 1, 'Invitation sent to {relatedUserFullName} of {relatedCompanyName} by {forCompanyName}');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.INVITATION_ACCEPTED, chain.chain_pkg.PURCHASER_MSG), 2, 'Invitation from {forCompanyName} accepted by {relatedUserFullName} from {relatedCompanyUrl}');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.INVITATION_REJECTED, chain.chain_pkg.PURCHASER_MSG), 3, 'Invitation from {forCompanyName} rejected by {relatedUserFullName} from {relatedCompanyUrl}');

	/* -- this event has been made redundant
	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, chain.chain_pkg.PURCHASER_MSG), 4, 'Questionnaire {relatedQuestionnaireUrl} submitted by {relatedCompanyUrl}');
	*/

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_APPROVED, chain.chain_pkg.PURCHASER_MSG), 5, 'Questionnaire {relatedQuestionnaireUrl} for {relatedCompanyUrl} has been approved.');

	INSERT INTO chain.TEMP_MESSAGE_MAP --  this is used for maersk, and chain demo (but we don't need it on cd)
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.ACTION_PLAN_STARTED, chain.chain_pkg.PURCHASER_MSG), 6, 'Action plan started / restarted for {relatedCompanyUrl}. Click {otherUrl1}here{otherUrl2} to view.');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_SUBMITTED, chain.chain_pkg.SUPPLIER_MSG), 7, 'Questionnaire {relatedQuestionnaireUrl} submitted to {relatedCompanyName}');

	/*  -- this event has been made redundant
	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_APPROVED, chain.chain_pkg.SUPPLIER_MSG), 8, 'Questionnaire {relatedQuestionnaireUrl} for has been approved by {relatedCompanyName}.');
	*/

	/* -- this event has been made redundant
	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(XXXXXXXXXXXX), 9, 'Supplier registration details for {relatedCompanyUrl} have changed.');
	*/

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.INVITATION_EXPIRED, chain.chain_pkg.PURCHASER_MSG), 10, 'Invitation from {forCompanyName} to {relatedUserFullName} of {relatedCompanyUrl} has expired');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_OVERDUE, chain.chain_pkg.PURCHASER_MSG), 11, 'Questionnaire {relatedQuestionnaireUrl} for {relatedCompanyUrl} is overdue');

	INSERT INTO chain.TEMP_MESSAGE_MAP
	(message_definition_id, event_type_id, message_template)
	VALUES
	(chain.message_pkg.Lookup(chain.chain_pkg.QUESTIONNAIRE_OVERDUE, chain.chain_pkg.SUPPLIER_MSG), 12, 'Questionnaire {relatedQuestionnaireUrl} for {relatedCompanyName} is overdue');
END;
/

commit;
PROMPT >> creating recipients


BEGIN
	INSERT INTO chain.recipient
	(app_sid, recipient_id, to_company_sid, to_user_sid)
	SELECT app_sid, recipient_id_seq.NEXTVAL, company_sid, user_sid
	  FROM (
		SELECT UNIQUE app_sid, company_sid, user_sid
		  FROM (
			SELECT app_sid, company_sid, user_sid
			  FROM ( 
				SELECT app_sid, company_sid, null user_sid
				  FROM chain.company
				 UNION ALL
				SELECT app_sid, purchaser_company_sid company_sid, user_sid 
				  FROM chain.supplier_follower
				 UNION ALL
				SELECT app_sid, supplier_company_sid company_sid, user_sid 
				  FROM chain.purchaser_follower
				 UNION ALL
				SELECT app_sid, null company_sid, user_sid
				  FROM chain.chain_user
				 UNION ALL
				SELECT app_sid, default_company_sid company_sid, user_sid
				  FROM chain.chain_user
				 UNION ALL
				SELECT app_sid, company_sid, user_sid
				  FROM chain.v$company_member
					)
			 MINUS
			SELECT app_sid, to_company_sid, to_user_sid
			  FROM chain.recipient
				)
		);
END;
/
commit;
PROMPT >> creating temp views


CREATE OR REPLACE VIEW chain.event_type_message_definition
as
select tmm.event_type_id, md.message_definition_id, md.message_template, mdl.secondary_lookup_id
  from chain.temp_message_map tmm, chain.default_message_definition md, chain.message_definition_lookup mdl
 where tmm.message_definition_id = md.message_definition_id
   and tmm.event_type_id is not null
   and mdl.message_definition_id = md.message_definition_id
  order by event_type_id
;

CREATE OR REPLACE VIEW chain.ucd_sid
as
	SELECT app_sid, csr_user_sid
	  FROM csr.csr_user
	 WHERE user_name = 'UserCreatorDaemon'
;

commit;
PROMPT >> copying events


INSERT INTO chain.message
(event_id, app_sid, message_id, message_definition_id, re_company_sid, re_user_sid, re_questionnaire_type_id)
SELECT e.event_id, e.app_sid, message_id_seq.nextval, tmm.message_definition_id, e.related_company_sid, e.related_user_sid, q.questionnaire_type_id
  FROM chain.event e, chain.temp_message_map tmm, chain.questionnaire q
 WHERE e.event_type_id = tmm.event_type_id
   AND e.app_sid = q.app_sid(+)
   AND e.related_questionnaire_id = q.questionnaire_id(+)
   AND e.event_id NOT IN (SELECT event_id FROM chain.message WHERE event_id IS NOT NULL);

commit;
PROMPT >> setting events to refresh log

   
INSERT INTO chain.message_refresh_log
(app_sid, message_id, refresh_index, refresh_dtm, refresh_user_sid)
SELECT m.app_sid, m.message_id, 0, e.created_dtm, u.csr_user_sid
  FROM chain.message m, chain.event e, chain.ucd_sid u
 WHERE m.app_sid = e.app_sid
   AND m.app_sid = u.app_sid
   AND m.event_id = e.event_id;

commit;
PROMPT >> setting message_recipients for events

INSERT INTO chain.message_recipient
(app_sid, message_id, recipient_id)
SELECT app_sid, message_id, recipient_id
  FROM (
	SELECT m.app_sid, m.message_id, r.recipient_id
	  FROM chain.message m, chain.event_type_message_definition etmd, chain.event e, chain.recipient r, chain.supplier_follower sf
	 WHERE m.app_sid = e.app_sid
	   AND m.app_sid = r.app_sid
	   AND m.app_sid = sf.app_sid
	   AND m.event_id = e.event_id
	   AND m.message_definition_id = etmd.message_definition_id
	   AND etmd.secondary_lookup_id = 1 -- PURCHASER_MSG
	   AND e.for_company_sid = sf.purchaser_company_sid
	   AND e.related_company_sid = sf.supplier_company_sid
	   AND r.to_company_sid = e.for_company_sid
	   AND r.to_user_sid = sf.user_sid
	 UNION 
	SELECT m.app_sid, m.message_id, r.recipient_id
	  FROM chain.message m, chain.event_type_message_definition etmd, chain.event e, chain.recipient r, chain.purchaser_follower pf
	 WHERE m.app_sid = e.app_sid
	   AND m.app_sid = r.app_sid
	   AND m.app_sid = pf.app_sid
	   AND m.event_id = e.event_id
	   AND m.message_definition_id = etmd.message_definition_id
	   AND etmd.secondary_lookup_id = 2 -- SUPPLIER_MSG
	   AND e.for_company_sid = pf.supplier_company_sid
	   AND e.related_company_sid = pf.purchaser_company_sid
	   AND r.to_company_sid = e.for_company_sid
	   AND r.to_user_sid = pf.user_sid
	 )
 MINUS
SELECT app_sid, message_id, recipient_id
  FROM chain.message_recipient;


DROP view event_type_message_definition;
DROP view chain.ucd_sid;

commit;
PROMPT >> creating temp views for actoins


CREATE OR REPLACE VIEW chain.action_type_message_definition
as
select tmm.action_type_id, md.message_definition_id, md.message_template, mdl.secondary_lookup_id, md.addressing_type_id
  from temp_message_map tmm, default_message_definition md, message_definition_lookup mdl
 where tmm.message_definition_id = md.message_definition_id
   and tmm.action_type_id is not null
   and mdl.message_definition_id = md.message_definition_id
  order by action_type_id
;

CREATE OR REPLACE VIEW chain.ucd_sid
as
	SELECT app_sid, csr_user_sid
	  FROM csr.csr_user
	 WHERE user_name = 'UserCreatorDaemon'
;

commit;
PROMPT >> copying messages for actions


INSERT INTO chain.message
(action_id, app_sid, message_id, message_definition_id, re_company_sid, re_user_sid, re_questionnaire_type_id, due_dtm, completed_dtm, completed_by_user_sid)
SELECT a.action_id, a.app_sid, message_id_seq.NEXTVAL message_id, tmm.message_definition_id, a.related_company_sid, a.related_user_sid, q.questionnaire_type_id, a.due_date, a.completion_dtm, 
  		CASE WHEN a.completion_dtm IS NULL THEN NULL ELSE u.csr_user_sid END
  FROM chain.action a, chain.reason_for_action rfa, chain.temp_message_map tmm, chain.questionnaire q, chain.ucd_sid u
 WHERE a.app_sid = rfa.app_sid
   AND a.app_sid = q.app_sid(+)   
   AND a.app_sid = u.app_sid
   AND a.related_questionnaire_id = q.questionnaire_id(+)
   AND a.reason_for_action_id = rfa.reason_for_action_id
   AND rfa.action_type_id = tmm.action_type_id
   AND a.action_id NOT IN (SELECT action_id FROM chain.message WHERE action_id IS NOT NULL);

commit;
PROMPT >> setting up refresh log for actions


INSERT INTO chain.message_refresh_log
(app_sid, message_id, refresh_index, refresh_dtm, refresh_user_sid)
SELECT m.app_sid, m.message_id, 0, a.created_dtm, u.csr_user_sid
  FROM chain.message m, chain.action a, chain.ucd_sid u
 WHERE m.app_sid = a.app_sid
   AND m.app_sid = u.app_sid
   AND m.action_id = a.action_id;

commit;
PROMPT >> creating message_recipients for actions


INSERT INTO chain.message_recipient
(app_sid, message_id, recipient_id)
SELECT app_sid, message_id, recipient_id
  FROM (
	SELECT m.app_sid, m.message_id, r.recipient_id
	  FROM chain.message m, chain.action_type_message_definition atmd, chain.action a, chain.recipient r, chain.supplier_follower sf
	 WHERE m.app_sid = a.app_sid
	   AND m.app_sid = r.app_sid
	   AND m.app_sid = sf.app_sid
	   AND m.action_id = a.action_id
	   AND m.message_definition_id = atmd.message_definition_id
	   AND atmd.secondary_lookup_id = 1 -- PURCHASER_MSG
	   AND a.for_company_sid = sf.purchaser_company_sid
	   AND a.related_company_sid = sf.supplier_company_sid
	   AND r.to_company_sid = a.for_company_sid
	   AND r.to_user_sid = sf.user_sid
     UNION ALL	   
	SELECT m.app_sid, m.message_id, r.recipient_id
	  FROM chain.message m, chain.action_type_message_definition atmd, chain.action a, chain.recipient r, chain.purchaser_follower pf
	 WHERE m.app_sid = a.app_sid
	   AND m.app_sid = r.app_sid
	   AND m.app_sid = pf.app_sid
	   AND m.action_id = a.action_id
	   AND m.message_definition_id = atmd.message_definition_id
	   AND atmd.secondary_lookup_id = 2 -- SUPPLIER_MSG
	   AND a.for_company_sid = pf.supplier_company_sid
	   AND a.related_company_sid = pf.purchaser_company_sid
	   AND r.to_company_sid = a.for_company_sid
	   AND r.to_user_sid = pf.user_sid
	 UNION ALL
	SELECT ma.app_sid, ma.message_id, r.recipient_id
	  FROM chain.recipient r,  (
		SELECT m.app_sid, m.message_id, CASE WHEN atmd.addressing_type_id = 0 THEN NULL ELSE a.for_company_sid END for_company_sid, a.for_user_sid
		  FROM chain.message m, chain.action_type_message_definition atmd, chain.action a
		 WHERE m.app_sid = a.app_sid
		   AND m.action_id = a.action_id 
		   AND m.message_definition_id = atmd.message_definition_id
		   AND atmd.secondary_lookup_id = 0 -- NONE_IMPLIED
		) ma -- message/action
	 WHERE ma.app_sid = r.app_sid
	   AND NVL(ma.for_company_sid, 0) = NVL(r.to_company_sid, 0)
	   AND NVL(ma.for_user_sid, 0) = NVL(r.to_user_sid, 0)
	 )
 MINUS
SELECT app_sid, message_id, recipient_id
  FROM chain.message_recipient;

drop view action_type_message_definition;
DROP view chain.ucd_sid;

commit;
PROMPT >> finishing up


grant execute on chain.message_pkg to web_user;

ALTER TABLE chain.alert_entry_type add (DISABLED NUMBER(1) DEFAULT 0 NOT NULL);

@..\scheduled_alert_body

UPDATE chain.alert_entry_type 
   SET disabled = 1
 WHERE generator_pkg in ('chain.event_pkg', 'chain.action_pkg');
 
 commit;

@..\message_pkg
@..\message_body

@..\rls

@update_tail