-- Please update version.sql too -- this keeps clean builds in sync
define version=2034
@update_header

/* CHAIN SCHEDULED ALERTS */

/* SCHEMA CHANGES */
/* DROPPING OLD STUFF */
DROP TABLE chain.action_type CASCADE CONSTRAINTS;
DROP TABLE chain.reason_for_action CASCADE CONSTRAINTS;
DROP TABLE chain.action CASCADE CONSTRAINTS;
DROP TABLE chain.action_user_status CASCADE CONSTRAINTS;
DROP TABLE chain.action_repeat_type CASCADE CONSTRAINTS;
DROP TABLE chain.event_user_status CASCADE CONSTRAINTS;
DROP TABLE chain.event CASCADE CONSTRAINTS;
DROP TABLE chain.event_type CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry_action CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry_event CASCADE CONSTRAINTS;

DROP TABLE chain.alert_entry_type CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry_named_param CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry_ordered_param CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry_param_type CASCADE CONSTRAINTS;
DROP TABLE chain.alert_entry_template CASCADE CONSTRAINTS;
DROP TABLE chain.scheduled_alert CASCADE CONSTRAINTS;

DROP SEQUENCE CHAIN.ALERT_ENTRY_ID_SEQ;
DROP SEQUENCE CHAIN.SCHEDULED_ALERT_ID_SEQ;

/* ADDING NEW STUFF */

CREATE TABLE CHAIN.ALERT_ENTRY_TYPE(
    ALERT_ENTRY_TYPE_ID           NUMBER(10, 0)     NOT NULL,
    STD_ALERT_TYPE_ID             NUMBER(10, 0)     NOT NULL,
    DESCRIPTION                   VARCHAR2(255)     NOT NULL,
    COMPANY_SECTION_TEMPLATE      VARCHAR2(1000)    NOT NULL,
    USER_SECTION_TEMPLATE         VARCHAR2(1000)    NOT NULL,
    IMPORTANT_SECTION_TEMPLATE    VARCHAR2(1000)    NOT NULL,
    GENERATOR_SP                  VARCHAR2(255)     NOT NULL,
    SCHEDULE_XML                  CLOB              NOT NULL,
    ENABLED                       NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    FORCE_DISABLE                 NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT PK146 PRIMARY KEY (ALERT_ENTRY_TYPE_ID)
)
;

CREATE TABLE CHAIN.CUSTOMER_ALERT_ENTRY_TYPE(
    ALERT_ENTRY_TYPE_ID           NUMBER(10, 0)     NOT NULL,
    APP_SID                       NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPANY_SECTION_TEMPLATE      VARCHAR2(1000)    DEFAULT NULL,
    USER_SECTION_TEMPLATE         VARCHAR2(1000)    DEFAULT NULL,
    IMPORTANT_SECTION_TEMPLATE    VARCHAR2(1000)    DEFAULT NULL,
    GENERATOR_SP                  VARCHAR2(255)     DEFAULT NULL,
    SCHEDULE_XML                  CLOB              DEFAULT NULL,
    ENABLED                       NUMBER(1, 0)      DEFAULT NULL,
    FORCE_DISABLE                 NUMBER(1, 0)      DEFAULT NULL,
    CONSTRAINT PK531 PRIMARY KEY (ALERT_ENTRY_TYPE_ID, APP_SID)
)
;

CREATE TABLE CHAIN.USER_ALERT_ENTRY_TYPE(
    ALERT_ENTRY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    USER_SID               NUMBER(10, 0)    NOT NULL,
    SCHEDULE_XML           CLOB             DEFAULT NULL,
    ENABLED                NUMBER(1, 0)     DEFAULT NULL,
    CONSTRAINT PK540 PRIMARY KEY (ALERT_ENTRY_TYPE_ID, APP_SID, USER_SID)
)
;

CREATE TABLE CHAIN.ALERT_ENTRY(
    APP_SID                     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ALERT_ENTRY_ID              NUMBER(10, 0)    NOT NULL,
    ALERT_ENTRY_TYPE_ID         NUMBER(10, 0)    NOT NULL,
    USER_SID                    NUMBER(10, 0)    NOT NULL,
    TEMPLATE_NAME               VARCHAR2(100)    NOT NULL,
    COMPANY_SID                 NUMBER(10, 0),
    MESSAGE_ID                  NUMBER(10, 0),
    OWNER_SCHEDULED_ALERT_ID    NUMBER(10, 0),
    PRIORITY                    NUMBER(10, 0)    DEFAULT 0,
    OCCURRED_DTM                TIMESTAMP(6)     NOT NULL,
    CONSTRAINT PK144 PRIMARY KEY (APP_SID, ALERT_ENTRY_ID)
)
;

CREATE TABLE CHAIN.ALERT_ENTRY_TEMPLATE(
    ALERT_ENTRY_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    TEMPLATE_NAME          VARCHAR2(100)     NOT NULL,
    TEMPLATE               VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK160 PRIMARY KEY (ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
)
;

CREATE TABLE CHAIN.CUSTOMER_ALERT_ENTRY_TEMPLATE(
    APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ALERT_ENTRY_TYPE_ID    NUMBER(10, 0)     NOT NULL,
    TEMPLATE_NAME          VARCHAR2(100)     NOT NULL,
    TEMPLATE               VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK537 PRIMARY KEY (APP_SID, ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
)
;

CREATE TABLE CHAIN.ALERT_ENTRY_PARAM(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    ALERT_ENTRY_ID    NUMBER(10, 0)     NOT NULL,
    NAME              VARCHAR2(100)     NOT NULL,
    VALUE             VARCHAR2(1000)    NOT NULL,
    CONSTRAINT PK163 PRIMARY KEY (APP_SID, ALERT_ENTRY_ID, NAME)
)
;

CREATE TABLE CHAIN.SCHEDULED_ALERT(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    SCHEDULED_ALERT_ID     NUMBER(10, 0)    NOT NULL,
    USER_SID               NUMBER(10, 0)    NOT NULL,
    ALERT_ENTRY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    SENT_DTM               TIMESTAMP(6)     DEFAULT NULL,
    CONSTRAINT PK147 PRIMARY KEY (APP_SID, SCHEDULED_ALERT_ID, USER_SID, ALERT_ENTRY_TYPE_ID)
)
;

/* CONSTRAINTS */
ALTER TABLE CHAIN.CUSTOMER_ALERT_ENTRY_TYPE ADD CONSTRAINT RefCUSTOMER_OPTIONS1285 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.CUSTOMER_ALERT_ENTRY_TYPE ADD CONSTRAINT RefALERT_ENTRY_TYPE1286 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;

ALTER TABLE CHAIN.USER_ALERT_ENTRY_TYPE ADD CONSTRAINT RefCHAIN_USER1300 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE CHAIN.USER_ALERT_ENTRY_TYPE ADD CONSTRAINT RefALERT_ENTRY_TYPE1301 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefSCHEDULED_ALERT327 
    FOREIGN KEY (APP_SID, OWNER_SCHEDULED_ALERT_ID, USER_SID, ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.SCHEDULED_ALERT(APP_SID, SCHEDULED_ALERT_ID, USER_SID, ALERT_ENTRY_TYPE_ID)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefCUSTOMER_OPTIONS328 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefALERT_ENTRY_TYPE329 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefCOMPANY342 
    FOREIGN KEY (APP_SID, COMPANY_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefCHAIN_USER343 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefALERT_ENTRY_TEMPLATE366 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
    REFERENCES CHAIN.ALERT_ENTRY_TEMPLATE(ALERT_ENTRY_TYPE_ID, TEMPLATE_NAME)
;

ALTER TABLE CHAIN.ALERT_ENTRY ADD CONSTRAINT RefMESSAGE1283 
    FOREIGN KEY (APP_SID, MESSAGE_ID)
    REFERENCES CHAIN.MESSAGE(APP_SID, MESSAGE_ID)
;

ALTER TABLE CHAIN.ALERT_ENTRY_PARAM ADD CONSTRAINT RefALERT_ENTRY1284 
    FOREIGN KEY (APP_SID, ALERT_ENTRY_ID)
    REFERENCES CHAIN.ALERT_ENTRY(APP_SID, ALERT_ENTRY_ID)
;

ALTER TABLE CHAIN.ALERT_ENTRY_TEMPLATE ADD CONSTRAINT RefALERT_ENTRY_TYPE368 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;

ALTER TABLE CHAIN.CUSTOMER_ALERT_ENTRY_TEMPLATE ADD CONSTRAINT RefALERT_ENTRY_TYPE1296 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;

ALTER TABLE CHAIN.CUSTOMER_ALERT_ENTRY_TEMPLATE ADD CONSTRAINT RefCUSTOMER_OPTIONS1297 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.SCHEDULED_ALERT ADD CONSTRAINT RefCHAIN_USER336 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
;

ALTER TABLE CHAIN.SCHEDULED_ALERT ADD CONSTRAINT RefCUSTOMER_OPTIONS337 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE CHAIN.SCHEDULED_ALERT ADD CONSTRAINT RefALERT_ENTRY_TYPE1303 
    FOREIGN KEY (ALERT_ENTRY_TYPE_ID)
    REFERENCES CHAIN.ALERT_ENTRY_TYPE(ALERT_ENTRY_TYPE_ID)
;


CREATE SEQUENCE CHAIN.ALERT_ENTRY_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE CHAIN.SCHEDULED_ALERT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

/* GRANTS */

CREATE OR REPLACE PACKAGE  CSR.RECURRENCE_PATTERN_pkg
IS

FUNCTION GetNextOccurrence(
	in_recurrence_pattern_xml 			IN XMLType,
	in_dtm								IN DATE
) RETURN DATE;

END;
/

GRANT EXECUTE ON csr.recurrence_pattern_pkg TO chain;
GRANT SELECT ON security.securable_object TO CSR WITH GRANT OPTION;
GRANT SELECT ON security.user_table TO CSR WITH GRANT OPTION;
GRANT SELECT ON csr.v$csr_user TO CHAIN;

@latest2034_packages

/* VIEWS */

DROP VIEW chain.v$action;
DROP VIEW chain.v$event;

CREATE OR REPLACE VIEW CHAIN.v$chain_user AS
	SELECT csru.app_sid, csru.csr_user_sid user_sid, csru.email, csru.user_name,   -- CSR_USER data
		   csru.full_name, csru.friendly_name, csru.phone_number, csru.job_title,   -- CSR_USER data
		   cu.visibility_id, cu.registration_status_id,								-- CHAIN_USER data
		   cu.receive_scheduled_alerts, cu.details_confirmed, ut.account_enabled
	  FROM csr.csr_user csru, chain_user cu, security.user_table ut
	 WHERE csru.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND csru.app_sid = cu.app_sid
	   AND csru.csr_user_sid = cu.user_sid
	   AND cu.user_sid = ut.sid_id
	   AND cu.registration_status_id <> 2 -- not rejected 
	   AND cu.registration_status_id <> 3 -- not merged 
	   AND cu.deleted = 0
;

CREATE OR REPLACE VIEW chain.v$chain_user_invitation_status AS
	SELECT usr.app_sid, usr.user_sid, usr.email, usr.user_name, usr.full_name, usr.friendly_name, usr.phone_number, usr.job_title, usr.visibility_id, usr.registration_status_id, usr.receive_scheduled_alerts, usr.details_confirmed, usr.company_sid, usr.invitation_id, usr.invitation_sent_dtm, usr.invitation_status_id, usr.from_user_sid, usr.from_company_sid
	  FROM (
		SELECT vcu.app_sid, vcu.user_sid, vcu.email, vcu.user_name, vcu.full_name, vcu.friendly_name, vcu.phone_number, vcu.job_title, vcu.visibility_id, vcu.registration_status_id, 
			vcu.receive_scheduled_alerts, vcu.details_confirmed, i.to_company_sid company_sid, i.invitation_id, i.sent_dtm invitation_sent_dtm, i.from_user_sid, i.from_company_sid,
			NVL(DECODE(invitation_status_id,
				4, 5),--temp_chain_pkg.PROVISIONALLY_ACCEPTED, temp_chain_pkg.ACCEPTED
				invitation_status_id) invitation_status_id,
			ROW_NUMBER() OVER (PARTITION BY i.to_company_sid, vcu.user_sid ORDER BY DECODE(i.invitation_status_id, 
				5, 1, --temp_chain_pkg.ACCEPTED, 1,
				4, 1, --temp_chain_pkg.PROVISIONALLY_ACCEPTED, 1,
				1, 2, --temp_chain_pkg.ACTIVE, 2,
				2, 3, --temp_chain_pkg.EXPIRED, 3,
				3, 3, --temp_chain_pkg.CANCELLED, 3,
				   4  --default
				), 
				sent_dtm DESC  --let sent_dtm determine the precedence of EXPIRED, CANCELLED AS in v$company_invitation_status
			) rn
		  FROM v$chain_user vcu
		  JOIN chain.invitation i ON (i.to_user_sid = vcu.user_sid)
		) usr
	 WHERE usr.rn = 1;

CREATE OR REPLACE VIEW CHAIN.v$alert_entry_type AS
	SELECT co.app_sid, 
		   aet.alert_entry_type_id, 
		   aet.std_alert_type_id,
		   aet.description, 
       NVL(caet.important_section_template, aet.important_section_template) important_section_template,
       NVL(caet.company_section_template, aet.company_section_template) company_section_template,
       NVL(caet.user_section_template, aet.user_section_template) user_section_template,
	   NVL(caet.generator_sp, aet.generator_sp) generator_sp,
       NVL(caet.schedule_xml, aet.schedule_xml) schedule_xml,
	DECODE(DECODE(caet.force_disable, NULL, aet.force_disable, 1, 1, 0, aet.force_disable), 0, NVL(caet.enabled, aet.enabled), 1, 0) enabled,
	DECODE(caet.force_disable, NULL, aet.force_disable, 1, 1, 0, aet.force_disable) force_disable	
	  FROM chain.alert_entry_type aet
	  JOIN chain.customer_options co
		ON SYS_CONTEXT('SECURITY','APP') = co.app_sid OR SYS_CONTEXT('SECURITY','APP') IS NULL
	  LEFT JOIN chain.customer_alert_entry_type caet
		ON aet.alert_entry_type_id = caet.alert_entry_type_id
	   AND caet.app_sid = co.app_sid;   
   
  CREATE OR REPLACE VIEW CHAIN.v$user_alert_entry_type AS
	SELECT vaet.app_sid, 
		   users.csr_user_sid user_sid,
		   users.email,
		   users.friendly_name,
		   vaet.alert_entry_type_id, 
		   vaet.std_alert_type_id,
		   vaet.description, 
		   vaet.generator_sp,
		   NVL(uaet.schedule_xml, vaet.schedule_xml) schedule_xml,
		   DECODE(vaet.force_disable, 0, NVL(uaet.enabled, vaet.enabled), 1, 0) enabled,
		   last_sa.last_sent_alert_dtm,
		   DECODE(last_sa.last_sent_alert_dtm, NULL, NULL, csr.RECURRENCE_PATTERN_pkg.GetNextOccurrence(XmlType(NVL(uaet.schedule_xml, vaet.schedule_xml)), last_sa.last_sent_alert_dtm)) next_alert_dtm
		FROM chain.v$alert_entry_type vaet
	    JOIN csr.v$csr_user users
		  ON users.app_sid = SYS_CONTEXT('SECURITY','APP')
		 AND users.csr_user_sid NOT IN ( SELECT csr_user_sid FROM csr.superadmin )
	  LEFT JOIN chain.user_alert_entry_type uaet
		ON vaet.alert_entry_type_id = uaet.alert_entry_type_id
	   AND users.csr_user_sid = uaet.user_sid
	   AND vaet.app_sid = SYS_CONTEXT('SECURITY','APP')
	  LEFT JOIN ( 
          SELECT sa.user_sid, sa.alert_entry_type_id, sa.sent_dtm last_sent_alert_dtm
            FROM chain.scheduled_alert sa
           WHERE sent_dtm = ( SELECT MAX(sent_dtm) FROM chain.scheduled_alert WHERE app_sid = SYS_CONTEXT('SECURITY','APP') AND user_sid = sa.user_sid AND alert_entry_type_id = sa.alert_entry_type_id)
             AND sa.app_sid = SYS_CONTEXT('SECURITY','APP') ) last_sa
		ON last_sa.user_sid = users.csr_user_sid
	   AND last_sa.alert_entry_type_id = vaet.alert_entry_type_id;
     
CREATE OR REPLACE VIEW CHAIN.v$alert_entry_template AS
SELECT * FROM (
    SELECT co.app_sid, 
           aet.alert_entry_type_id,
           NVL(caet.template_name, aet.template_name) template_name,
           NVL(caet.template, aet.template) template
      FROM chain.alert_entry_template aet
      JOIN chain.customer_options co
        ON SYS_CONTEXT('SECURITY','APP') = co.app_sid OR SYS_CONTEXT('SECURITY','APP') IS NULL  
      LEFT JOIN chain.customer_alert_entry_template caet
        ON aet.alert_entry_type_id = caet.alert_entry_type_id
       AND aet.template_name = caet.template_name
       AND caet.app_sid = co.app_sid
    UNION
    SELECT * FROM chain.customer_alert_entry_template
    );

/* ADD RLS TO NEW TABLES */	
BEGIN
dbms_rls.add_policy(
			object_schema   => 'chain',
			object_name     => 'customer_alert_entry_type',
			policy_name     => 'customer_alert_entry_type_pol', 
			function_schema => 'chain',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );

dbms_rls.add_policy(
			object_schema   => 'chain',
			object_name     => 'user_alert_entry_type',
			policy_name     => 'user_alert_entry_type_pol', 
			function_schema => 'chain',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );      

dbms_rls.add_policy(
			object_schema   => 'chain',
			object_name     => 'customer_alert_entry_template',
			policy_name     => 'cust_alert_entry_template_pol', 
			function_schema => 'chain',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );
dbms_rls.add_policy(
			object_schema   => 'chain',
			object_name     => 'alert_entry',
			policy_name     => 'alert_entry_pol', 
			function_schema => 'chain',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );
dbms_rls.add_policy(
			object_schema   => 'chain',
			object_name     => 'scheduled_alert',
			policy_name     => 'scheduled_alert_pol', 
			function_schema => 'chain',
			policy_function => 'appSidCheck',
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static );
END;
/

/* ADD ACTION MESSAGE ALERT_TYPE AND DEFAULT TEMPLATES */
BEGIN
	 INSERT INTO chain.alert_entry_type(alert_entry_type_id, description, generator_sp, enabled, force_disable, schedule_xml, std_alert_type_id, important_section_template, company_section_template, user_section_template)
	 VALUES (1, -- alert_entry_type_id
			'Actions required',  -- description (can be used as mergefield in StdAlert Template
			'chain.message_pkg.GenerateActionMessageAlerts',   -- SP to call when generating entries for this type. The job is run under web_user so make sure to have the proper grants.
			 0, -- enabled, this can be overridden by client apps or  individual users
			 0, -- force disable, if this is 1 the alert will be disabled for every app/user regardless of their enabled settings
			'<recurrences><daily every-n="weekday"></daily></recurrences>', --the recurrence pattern used, see csr.recurrence_pattern_pkg and recurrence_pattern.sql for info
			 5003, -- the StdAlertType
			'<div><b>Important messages:</b><br/><ul>{content}</ul></div>', --the important section template
			'<br/><div><b>{companyName} messages:</b><br/><ul>{content}</ul></div>', --the company section template
			'<br/><div><b>Personal messages:</b><br/><ul>{content}</ul></div>'); --the user section template

	/* some default templates to be used when adding entries for this type */
	chain.temp_scheduled_alert_pkg.SetTemplate(1, 'DEFAULT', '<div style="padding-left: 5px">{text}</div>');
	chain.temp_scheduled_alert_pkg.SetTemplate(1, 'DEFAULT_MESSAGE', '<div style="padding-left: 5px">{msg}</div>');
	chain.temp_scheduled_alert_pkg.SetTemplate(1, 'DEFAULT_LIST', '<li>{text}</li>');
	chain.temp_scheduled_alert_pkg.SetTemplate(1, 'DEFAULT_MESSAGE_LIST', '<li>{msg}</li>');
	chain.temp_scheduled_alert_pkg.SetTemplate(1, 'DEFAULT_LIST_IMPORTANT', '<li><span style="color: red">{text}</span></li>');
	chain.temp_scheduled_alert_pkg.SetTemplate(1, 'DEFAULT_MESSAGE_LIST_IMPORTANT', '<li><span style="color: red">{msg}</span></li>');

END;
/

	
 
 /* UPDATE COMPONENT MESSAGES */
 BEGIN

  security.user_pkg.logonadmin;
 
  DELETE FROM chain.default_message_param WHERE param_name = 'reComponentDescription';
  
	/****************************************************************************
			COMPONENT QUESTIONNAIRE MESSAGING
	*****************************************************************************/
	
	----------------------------------------------------------------------------
	--		COMPLETE_COMP_QUESTIONNAIRE
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Please enter {reQuestionnaire} ({componentDescription}) data for {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Submitted to {reCompanyName} by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);
	
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon',
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_COMPLETE_QUESTIONNAIRE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);					
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Please review the {reQuestionnaire} ({componentDescription}) data submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'Completed by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);					
	
	----------------------------------------------------------------------------
	--		COMP_QNR_SUBMITTED_NO_REVIEW -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) submitted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QNR_SUBMITTED_NO_REVIEW, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);						

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_SUBMITTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) submitted by {triggerUser} to {reCompany}.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'triggerUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{triggerUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'fromCompanySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_SUBMITTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);									
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_REJECTED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({componentDescription}) for {reCompany} was rejected by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);	

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);						

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_REJECTED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) was rejected by {reCompany}.',
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);	

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_REJECTED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RETURNED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'The {reQuestionnaire} ({componentDescription}) was returned to {reCompany}  by {reUser}.',
		in_css_class 				=> 'background-icon questionnaire-icon'		
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon', 
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);		
				
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_RETURNED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_completion_type 			=> chain.temp_chain_pkg.CODE_ACTION,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} ({componentDescription}) was returned from {reCompany}. Please correct and re-submit.',
		in_completed_template 		=> 'Submitted by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon', 
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reUser', 
				in_css_class 				=> 'background-icon faded-user-icon', 
				in_value 					=> '{reUserFullName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_RETURNED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);					
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_APPROVED -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Your {reQuestionnaire} ({componentDescription}) has been received and accepted by {reCompany}.',
		in_completion_type 			=> chain.temp_chain_pkg.ACKNOWLEDGE,
		in_completed_template 		=> 'Acknowledged by {completedByUserFullName} {relCompletedDtm}',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);			
	
	----------------------------------------------------------------------------
	--		QUESTIONNAIRE_APPROVED -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) has been approved.',
		in_css_class 				=> 'background-icon questionnaire-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireViewUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{reCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);			
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_APPROVED, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				
	
	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_OVERDUE -> PURCHASER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) is overdue.',
		in_repeat_type 				=> chain.temp_chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-supplier-icon',
				in_href 					=> '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}',
				in_value 					=> '{reCompanyName}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.PURCHASER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				

	----------------------------------------------------------------------------
	--		COMP_QUESTIONNAIRE_OVERDUE -> SUPPLIER_MSG
	----------------------------------------------------------------------------
	chain.temp_message_pkg.DefineMessage(
		in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE,
		in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
		in_message_template 		=> 'Questionnaire {reQuestionnaire} for {reCompany} ({componentDescription}) is overdue.',
		in_repeat_type 				=> chain.temp_chain_pkg.REFRESH_OR_REPEAT,
		in_css_class 				=> 'background-icon warning-icon'
	);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reQuestionnaire', 
				in_css_class 				=> 'background-icon faded-questionnaire-icon', 
				in_href 					=> '{reQuestionnaireEditUrl}', -- <- it is expected that this will take a {companySid} param and a {componentId} param
				in_value 					=> '{reQuestionnaireName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'reCompany', 
				in_css_class 				=> 'background-icon faded-company-icon',
				in_value 					=> '{reCompanyName}'
			);

			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'companySid', 
				in_value 					=> '{toCompanySid}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentId', 
				in_value 					=> '{reComponentId}'
			);
			
			chain.temp_message_pkg.DefineMessageParam(
				in_primary_lookup 			=> chain.temp_chain_pkg.COMP_QUESTIONNAIRE_OVERDUE, 
				in_secondary_lookup			=> chain.temp_chain_pkg.SUPPLIER_MSG,
				in_param_name 				=> 'componentDescription', 
				in_value 					=> '{reComponentDescription}'
			);				
	
END;
/

/* Update the 5003 std alert type */
BEGIN
	DELETE FROM csr.std_alert_type_param WHERE std_alert_type_id = 5003;

	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from) VALUES (5003,
		'Chain scheduled alerts',
		'A scheduled alert run takes place.',
		'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE csr.std_alert_type SET
				description = 'Chain scheduled alerts',
				send_trigger = 'A scheduled alert run takes place.',
				sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
			WHERE std_alert_type_id = 5003;
	END;
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'SITE_NAME', 'Site name', 'The site name', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'ALERT_ENTRY_TYPE_DESCRIPTION', 'Alert Type Description', 'A description of the type of alert this is.', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (5003, 0, 'CONTENT', 'Content', 'The scheduled alert configured content.', 5);
END;
/

/* Update existing customer alert type with new default template for all chain apps */
DECLARE
	v_sat_id 	NUMERIC(10) := 5003;
	v_cat_id	NUMERIC(10) := NULL;
	v_af_id		csr.alert_frame.alert_frame_id%TYPE;
BEGIN
	security.user_pkg.logonadmin;
	FOR r IN (
		SELECT DISTINCT host FROM chain.v$chain_host ) LOOP
		
		security.user_pkg.logonadmin(r.host);
		
		BEGIN
			-- delete anything we might have already
			DELETE FROM csr.alert_template_body 
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			   AND customer_alert_type_id IN (
					SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_id
				);

			DELETE FROM csr.alert_template 
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			   AND customer_alert_type_id IN (
					SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_id
				);
				
			DELETE FROM csr.alert_batch_run
			 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			   AND customer_alert_type_id IN (
					SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_id
				);			

			 DELETE FROM csr.customer_alert_type 
			  WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
			    AND customer_alert_type_id IN (
					SELECT customer_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = v_sat_id
				);
		   
			-- shove in a new row
			INSERT INTO csr.customer_alert_type 
				(app_sid, customer_alert_type_id, std_alert_type_id) 
			VALUES 
				(SYS_CONTEXT('SECURITY','APP'), csr.customer_alert_type_id_seq.nextval, v_sat_id)
			RETURNING customer_alert_type_id INTO v_cat_id;

			BEGIN
				SELECT MIN(alert_frame_id)
				  INTO v_af_id
				  FROM csr.alert_frame 
				 WHERE app_sid = SYS_CONTEXT('SECURITY','APP') 
				 GROUP BY app_sid;
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					INSERT INTO csr.alert_frame
						(alert_frame_id, name)
					VALUES
						(csr.alert_frame_id_seq.NEXTVAL, 'Default')
					RETURNING alert_frame_id INTO v_af_id;
			END;

			INSERT INTO csr.alert_template 
				(app_sid, customer_alert_type_id, alert_frame_id, send_type)
			VALUES
				(SYS_CONTEXT('SECURITY','APP'), v_cat_id, v_af_id, 'automatic');
				
				-- set the same template values for all langs in the app
			FOR r IN (
				SELECT lang 
				  FROM aspen2.translation_set 
				 WHERE application_sid = SYS_CONTEXT('SECURITY', 'APP') 
				   AND hidden = 0
			) LOOP
				INSERT INTO csr.alert_template_body
					(app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
				VALUES
					(SYS_CONTEXT('SECURITY','APP'), v_cat_id, r.lang, 
					'<template><mergefield name="ALERT_ENTRY_TYPE_DESCRIPTION"/> - <mergefield name="SITE_NAME"/></template>', 
					'<template><div>Dear <mergefield name="TO_FRIENDLY_NAME"/>,<br/><br/>Below is a list of recent activity involving you on <mergefield name="SITE_NAME"/>.<br/><br/><mergefield name="CONTENT"/></div></template>', 
					'<template />');
			END LOOP;
		END;
		
	END LOOP;
END;
/

DROP PACKAGE chain.temp_message_pkg;
DROP PACKAGE chain.temp_chain_pkg;
DROP PACKAGE chain.temp_scheduled_alert_pkg;

--TODO: add package recompiles
@../recurrence_pattern_pkg
@../recurrence_pattern_body
@../chain/chain_pkg
@../chain/chain_body
@../chain/company_body
@../chain/company_user_body
@../chain/invitation_body
@../chain/message_pkg
@../chain/message_body
@../chain/purchased_component_body
@../chain/scheduled_alert_pkg
@../chain/scheduled_alert_body

@update_tail
