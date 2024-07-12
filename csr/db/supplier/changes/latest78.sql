-- Please update version.sql too -- this keeps clean builds in sync
define version=78
@update_header

/**
 *	SECTION 1: CLEAN EXISTING
 **/
PROMPT > Clean existing (you may need to run this line by line as the tables may not exist)

begin
	for r in (select table_name from all_tables where owner='SUPPLIER' and table_name in (
'MESSAGE_CONTACT',
'MESSAGE_QUESTIONNAIRE',
'MESSAGE_USER',
'MESSAGE_PROCURER_SUPPLIER',
'MESSAGE',
'MESSAGE_TEMPLATE',
'MESSAGE_TEMPLATE_FORMAT',
'QUESTIONNAIRE_REQUEST',
'COMPANY_QUESTIONNAIRE_RESPONSE',
'QUESTIONNAIRE_RESPONSE_STATUS',
'INVITE_QUESTIONNAIRE',
'INVITE_COMPANY_USER',
'INVITE_CONTACT',
'INVITE',
'INVITE_STATUS',
'CONTACT',
'CONTACT_STATE',
'REQUEST_STATUS',
'CHAIN_QUESTIONNAIRE',

'REQUEST_TO_USER',
'REQUEST_BY_USER',

'USER_PROFILE_VISIBILITY',
'CONTACT_SHORTLIST',
'CONTACT_STATUS',
'DOMAIN_BLACKLIST',
'DOMAIN_LOOKUP',
'SUPPLIER_QUESTIONNAIRE_GROUP',
'SUPPLIER_QUESTIONNAIRE_REQUEST',
'QUESTIONNAIRE_GROUP_SUPPLIER',
'CURRENCY',
'ALL_PROCURER_SUPPLIER'
)) loop
		execute immediate 'drop table supplier.'||r.table_name;
	end loop;
end;
/
	


/*
-- if you're having problems, you may need to run this -- 
-- depends on whether you've had the chain data setup before or not --

BEGIN
	DELETE FROM ALL_PROCURER_SUPPLIER;
	
	user_pkg.LogonAdmin('chain.credit360.com');
	FOR r IN (
		SELECT * FROM all_company WHERE app_sid = security_pkg.GetApp
	)
	LOOP
		security.securableobject_pkg.DELETESO(security_pkg.GetAct, r.company_sid);
	END LOOP;
END;
/
*/


ALTER TABLE supplier.COMPANY_USER DROP CONSTRAINT REFUSER_PROFILE_VISIBILITY569;



/**
 *	SECTION 2: ALTER EXISTING
 **/

PROMPT > Alter existing tables

-- COMPANY_USER
ALTER TABLE supplier.COMPANY_USER ADD (
    APP_SID                          NUMBER(10, 0),
    PENDING_COMPANY_AUTHORIZATION    NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    USER_PROFILE_VISIBILITY_ID       NUMBER(10, 0)    DEFAULT 1 NOT NULL
)
;

-- update the app_sid
UPDATE supplier.company_user cu
   SET cu.app_sid = (
    SELECT so.application_sid_id 
      FROM security.securable_object so
     WHERE so.sid_id = cu.company_sid
);

UPDATE supplier.company_user
   SET USER_PROFILE_VISIBILITY_ID = 0;


ALTER TABLE supplier.COMPANY_USER MODIFY (APP_SID NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL);

ALTER TABLE supplier.COMPANY_USER DROP CONSTRAINT COMPANY_USER_PK;
ALTER TABLE supplier.COMPANY_USER ADD CONSTRAINT COMPANY_USER_PK PRIMARY KEY (COMPANY_SID, CSR_USER_SID, APP_SID) USING INDEX;


/**
 *	SECTION 3: CREATE SEQUENCES
 **/
PROMPT > Create sequences

DROP SEQUENCE SUPPLIER.MESSAGE_ID_SEQ;

CREATE SEQUENCE SUPPLIER.MESSAGE_ID_SEQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;

DROP SEQUENCE SUPPLIER.CHAIN_QUESTIONNAIRE_ID_SEQ;

CREATE SEQUENCE SUPPLIER.CHAIN_QUESTIONNAIRE_ID_SEQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;


/**
 *	SECTION 4: CREATE TABLES
 **/
PROMPT > Create tables 
-- 
-- TABLE: ALL_PROCURER_SUPPLIER 
--

CREATE TABLE supplier.ALL_PROCURER_SUPPLIER(
    PROCURER_COMPANY_SID      NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID      NUMBER(10, 0)    NOT NULL,
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ESTIMATED_ANNUAL_SPEND    NUMBER(10, 0),
    CURRENCY_CODE             VARCHAR2(4),
    CONSTRAINT PK155 PRIMARY KEY (PROCURER_COMPANY_SID, SUPPLIER_COMPANY_SID, APP_SID)
)
;



-- 
-- TABLE: CHAIN_QUESTIONNAIRE 
--

CREATE TABLE supplier.CHAIN_QUESTIONNAIRE(
    CHAIN_QUESTIONNAIRE_ID    NUMBER(10, 0)     NOT NULL,
    APP_SID                   NUMBER(10, 0)     NOT NULL,
    ACTIVE            		  NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    FRIENDLY_NAME             VARCHAR2(256)     NOT NULL,
    DESCRIPTION               VARCHAR2(1024)    NOT NULL,
    EDIT_URL                  VARCHAR2(256)     NOT NULL,
    CONSTRAINT PK273 PRIMARY KEY (CHAIN_QUESTIONNAIRE_ID)
)
;



-- 
-- TABLE: COMPANY_QUESTIONNAIRE_RESPONSE 
--

CREATE TABLE supplier.COMPANY_QUESTIONNAIRE_RESPONSE(
    COMPANY_SID               NUMBER(10, 0)    NOT NULL,
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    RESPONSE_STATUS_ID        NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    CHAIN_QUESTIONNAIRE_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK242 PRIMARY KEY (COMPANY_SID, CHAIN_QUESTIONNAIRE_ID)
)
;



-- 
-- TABLE: CONTACT 
--

CREATE TABLE supplier.CONTACT(
	CONTACT_ID                       NUMBER(10, 0)    NOT NULL,
	OWNER_COMPANY_SID                NUMBER(10, 0)    NOT NULL,
	APP_SID                          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONTACT_GUID                     CHAR(36)         NOT NULL,
	FULL_NAME                        VARCHAR2(255),
	EMAIL                            VARCHAR2(255),
	JOB_TITLE                        VARCHAR2(255),
	PHONE_NUMBER                     VARCHAR2(255),
	COMPANY_NAME                     VARCHAR2(255),
	ADDRESS_1                        VARCHAR2(256),
	ADDRESS_2                        VARCHAR2(256),
	ADDRESS_3                        VARCHAR2(256),
	ADDRESS_4                        VARCHAR2(256),
	TOWN                             VARCHAR2(256),
	STATE                            VARCHAR2(256),
	POSTCODE                         VARCHAR2(256),
	COUNTRY_CODE                     VARCHAR2(8),
	ESTIMATED_ANNUAL_SPEND           NUMBER(10, 0),
	CURRENCY_CODE                    VARCHAR2(4),
	EXISTING_COMPANY_SID             NUMBER(10, 0),
	EXISTING_USER_SID                NUMBER(10, 0),
	CONTACT_STATE_ID                 NUMBER(10, 0)    DEFAULT 0 NOT NULL,
	LAST_CONTACT_STATE_UPDATE_DTM    DATE,
	REGISTERED_TO_COMPANY_SID        NUMBER(10, 0),
    REGISTERED_AS_USER_SID           NUMBER(10, 0),
    CONSTRAINT EXISTING_COMPANY_USER CHECK (EXISTING_USER_SID IS NULL OR (EXISTING_USER_SID IS NOT NULL AND EXISTING_COMPANY_SID IS NOT NULL)),
    CONSTRAINT PK_CONTACT_SHORTLIST PRIMARY KEY (CONTACT_ID, OWNER_COMPANY_SID, APP_SID)
)
;



-- 
-- TABLE: CONTACT_STATE 
--

CREATE TABLE supplier.CONTACT_STATE(
    CONTACT_STATE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION         VARCHAR2(200)    NOT NULL,
    CONSTRAINT PK268 PRIMARY KEY (CONTACT_STATE_ID)
)
;



-- 
-- TABLE: INVITE 
--

CREATE TABLE supplier.INVITE(
    APP_SID                   NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SENT_BY_COMPANY_SID       NUMBER(10, 0)    NOT NULL,
    INVITE_ID                 NUMBER(10, 0)    NOT NULL,
    SENT_BY_USER_SID          NUMBER(10, 0)    NOT NULL,
    SENT_TO_CONTACT_ID        NUMBER(10, 0)    NOT NULL,
    CREATION_DTM              DATE             NOT NULL,
    INVITE_STATUS_ID          NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    LAST_STATUS_CHANGE_DTM    DATE,
    CONSTRAINT PK8 PRIMARY KEY (INVITE_ID)
)
;



-- 
-- TABLE: INVITE_QUESTIONNAIRE 
--

CREATE TABLE supplier.INVITE_QUESTIONNAIRE(
    INVITE_ID                    NUMBER(10, 0)    NOT NULL,
    CHAIN_QUESTIONNAIRE_ID       NUMBER(10, 0)    NOT NULL,
    APP_SID                      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DUE_DTM                      DATE,
    REMINDER_COUNT               NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    LAST_MSG_DTM                 DATE             NOT NULL,
    LAST_MSG_FROM_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    LAST_MSG_FROM_USER_SID       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK13 PRIMARY KEY (INVITE_ID, CHAIN_QUESTIONNAIRE_ID)
)
;



-- 
-- TABLE: MESSAGE 
--

CREATE TABLE supplier.MESSAGE(
    MESSAGE_ID             NUMBER(10, 0)    NOT NULL,
    MESSAGE_TEMPLATE_ID    NUMBER(10, 0)    NOT NULL,
    COMPANY_SID            NUMBER(10, 0)    NOT NULL,
    USER_SID               NUMBER(10, 0),
    GROUP_SID              NUMBER(10, 0),
    MSG_DTM                DATE             NOT NULL,
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP'),
    CONSTRAINT PK2 PRIMARY KEY (MESSAGE_ID)
)
;



-- 
-- TABLE: MESSAGE_CONTACT 
--

CREATE TABLE supplier.MESSAGE_CONTACT(
    MESSAGE_ID           NUMBER(10, 0)    NOT NULL,
    APP_SID              NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP'),
    CONTACT_ID           NUMBER(10, 0),
    OWNER_COMPANY_SID    NUMBER(10, 0),
    CONSTRAINT PK261 PRIMARY KEY (MESSAGE_ID)
)
;



-- 
-- TABLE: MESSAGE_QUESTIONNAIRE 
--

CREATE TABLE supplier.MESSAGE_QUESTIONNAIRE(
    MESSAGE_ID          	NUMBER(10, 0)    NOT NULL,
    CHAIN_QUESTIONNAIRE_ID  NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK6_1 PRIMARY KEY (MESSAGE_ID)
)
;



-- 
-- TABLE: MESSAGE_PROCURER_SUPPLIER 
--

CREATE TABLE supplier.MESSAGE_PROCURER_SUPPLIER(
    MESSAGE_ID              NUMBER(10, 0)    NOT NULL,
    PROCURER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CONSTRAINT PK275 PRIMARY KEY (MESSAGE_ID)
)
;



-- 
-- TABLE: MESSAGE_TEMPLATE 
--

CREATE TABLE supplier.MESSAGE_TEMPLATE(
    MESSAGE_TEMPLATE_ID           NUMBER(10, 0)    NOT NULL,
    MESSAGE_TEMPLATE_FORMAT_ID    NUMBER(10, 0)    NOT NULL,
    LABEL                         VARCHAR2(255)    NOT NULL,
    TPL                           VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK8_2 PRIMARY KEY (MESSAGE_TEMPLATE_ID)
)
;



-- 
-- TABLE: MESSAGE_TEMPLATE_FORMAT 
--

CREATE TABLE supplier.MESSAGE_TEMPLATE_FORMAT(
    MESSAGE_TEMPLATE_FORMAT_ID    NUMBER(10, 0)    NOT NULL,
    TPL_FORMAT                    VARCHAR2(200)    NOT NULL,
    CONSTRAINT PK254 PRIMARY KEY (MESSAGE_TEMPLATE_FORMAT_ID)
)
;



-- 
-- TABLE: MESSAGE_USER 
--

CREATE TABLE supplier.MESSAGE_USER(
    MESSAGE_ID    NUMBER(10, 0)    NOT NULL,
    ENTRY_INDEX   NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    APP_SID       NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    USER_SID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK3 PRIMARY KEY (MESSAGE_ID, ENTRY_INDEX)
)
;



-- 
-- TABLE: QUESTIONNAIRE_REQUEST 
--

CREATE TABLE supplier.QUESTIONNAIRE_REQUEST(
    PROCURER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    SUPPLIER_COMPANY_SID    NUMBER(10, 0)    NOT NULL,
    CHAIN_QUESTIONNAIRE_ID  NUMBER(10, 0)    NOT NULL,
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROCURER_USER_SID       NUMBER(10, 0)    NOT NULL,
    SUPPLIER_USER_SID       NUMBER(10, 0)    NOT NULL,
    REQUEST_STATUS_ID       NUMBER(10, 0)    NOT NULL,
    DUE_DTM                 DATE             NOT NULL,
    ACCEPTED_DTM            DATE,
    REMINDER_COUNT          NUMBER(10, 0)    DEFAULT 0 NOT NULL,
    LAST_REMINDER_DTM       DATE,
    CONSTRAINT PK157 PRIMARY KEY (CHAIN_QUESTIONNAIRE_ID, APP_SID, SUPPLIER_COMPANY_SID, PROCURER_COMPANY_SID)
)
;



-- 
-- TABLE: QUESTIONNAIRE_RESPONSE_STATUS 
--

CREATE TABLE supplier.QUESTIONNAIRE_RESPONSE_STATUS(
    RESPONSE_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK243 PRIMARY KEY (RESPONSE_STATUS_ID)
)
;



-- 
-- TABLE: REQUEST_STATUS 
--

CREATE TABLE supplier.REQUEST_STATUS(
    REQUEST_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION          VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK_REQUEST_STATUS PRIMARY KEY (REQUEST_STATUS_ID)
)
;



-- 
-- TABLE: USER_PROFILE_VISIBILITY 
--

CREATE TABLE supplier.USER_PROFILE_VISIBILITY(
    USER_PROFILE_VISIBILITY_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                   VARCHAR2(200)    NOT NULL,
    CONSTRAINT PK187 PRIMARY KEY (USER_PROFILE_VISIBILITY_ID)
)
;



-- 
-- TABLE: INVITE_STATUS 
--

CREATE TABLE supplier.INVITE_STATUS(
    INVITE_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION         VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK267 PRIMARY KEY (INVITE_STATUS_ID)
)
;



-- 
-- TABLE: CURRENCY 
--

CREATE TABLE supplier.CURRENCY(
    CURRENCY_CODE    VARCHAR2(4)     NOT NULL,
    LABEL            VARCHAR2(64)    NOT NULL,
    CONSTRAINT PK172 PRIMARY KEY (CURRENCY_CODE)
)
;



/**
 *	SECTION 5: CREATE CONSTRAINTS
 **/
PROMPT > Create constraints
-- 
-- TABLE: ALL_PROCURER_SUPPLIER 
--

ALTER TABLE supplier.ALL_PROCURER_SUPPLIER ADD CONSTRAINT RefALL_COMPANY506 
    FOREIGN KEY (SUPPLIER_COMPANY_SID)
    REFERENCES supplier.ALL_COMPANY(COMPANY_SID)
;

ALTER TABLE supplier.ALL_PROCURER_SUPPLIER ADD CONSTRAINT RefALL_COMPANY507 
    FOREIGN KEY (PROCURER_COMPANY_SID)
    REFERENCES supplier.ALL_COMPANY(COMPANY_SID)
;

ALTER TABLE supplier.ALL_PROCURER_SUPPLIER ADD CONSTRAINT RefCURRENCY641 
    FOREIGN KEY (CURRENCY_CODE)
    REFERENCES supplier.CURRENCY(CURRENCY_CODE)
;

ALTER TABLE supplier.ALL_PROCURER_SUPPLIER ADD CONSTRAINT RefCUSTOMER751 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;


-- 
-- TABLE: CHAIN_QUESTIONNAIRE 
--

ALTER TABLE supplier.CHAIN_QUESTIONNAIRE ADD CONSTRAINT RefCUSTOMER766 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;


-- 
-- TABLE: COMPANY_QUESTIONNAIRE_RESPONSE 
--

ALTER TABLE supplier.COMPANY_QUESTIONNAIRE_RESPONSE ADD CONSTRAINT RefCHAIN_QUESTIONNAIRE767 
    FOREIGN KEY (CHAIN_QUESTIONNAIRE_ID)
    REFERENCES supplier.CHAIN_QUESTIONNAIRE(CHAIN_QUESTIONNAIRE_ID)
;

ALTER TABLE supplier.COMPANY_QUESTIONNAIRE_RESPONSE ADD CONSTRAINT RefQUESTIONNAIRE_RESPONSE_S673 
    FOREIGN KEY (RESPONSE_STATUS_ID)
    REFERENCES supplier.QUESTIONNAIRE_RESPONSE_STATUS(RESPONSE_STATUS_ID)
;

ALTER TABLE supplier.COMPANY_QUESTIONNAIRE_RESPONSE ADD CONSTRAINT RefALL_COMPANY674 
    FOREIGN KEY (COMPANY_SID)
    REFERENCES supplier.ALL_COMPANY(COMPANY_SID)
;

ALTER TABLE supplier.COMPANY_QUESTIONNAIRE_RESPONSE ADD CONSTRAINT RefCUSTOMER752 
    FOREIGN KEY (APP_SID)
    REFERENCES csr.CUSTOMER(APP_SID)
;


-- 
-- TABLE: CONTACT 
--

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefCUSTOMER_OPTIONS642 
    FOREIGN KEY (APP_SID)
    REFERENCES supplier.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefALL_COMPANY643 
    FOREIGN KEY (OWNER_COMPANY_SID)
    REFERENCES supplier.ALL_COMPANY(COMPANY_SID)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefCURRENCY645 
    FOREIGN KEY (CURRENCY_CODE)
    REFERENCES supplier.CURRENCY(CURRENCY_CODE)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefCOUNTRY715 
    FOREIGN KEY (COUNTRY_CODE)
    REFERENCES supplier.COUNTRY(COUNTRY_CODE)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefALL_COMPANY726 
    FOREIGN KEY (EXISTING_COMPANY_SID)
    REFERENCES supplier.ALL_COMPANY(COMPANY_SID)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefCOMPANY_USER727 
    FOREIGN KEY (EXISTING_COMPANY_SID, EXISTING_USER_SID, APP_SID)
    REFERENCES supplier.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefCONTACT_STATE753 
    FOREIGN KEY (CONTACT_STATE_ID)
    REFERENCES supplier.CONTACT_STATE(CONTACT_STATE_ID)
;

ALTER TABLE supplier.CONTACT ADD CONSTRAINT RefCOMPANY_USER768 
    FOREIGN KEY (REGISTERED_TO_COMPANY_SID, REGISTERED_AS_USER_SID, APP_SID)
    REFERENCES supplier.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;


-- 
-- TABLE: INVITE 
--

ALTER TABLE supplier.INVITE ADD CONSTRAINT RefCOMPANY_USER646 
    FOREIGN KEY (SENT_BY_COMPANY_SID, SENT_BY_USER_SID, APP_SID)
    REFERENCES supplier.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;

ALTER TABLE supplier.INVITE ADD CONSTRAINT RefCONTACT754 
    FOREIGN KEY (SENT_TO_CONTACT_ID, SENT_BY_COMPANY_SID, APP_SID)
    REFERENCES supplier.CONTACT(CONTACT_ID, OWNER_COMPANY_SID, APP_SID)
;

ALTER TABLE supplier.INVITE ADD CONSTRAINT RefINVITE_STATUS755 
    FOREIGN KEY (INVITE_STATUS_ID)
    REFERENCES supplier.INVITE_STATUS(INVITE_STATUS_ID)
;


-- 
-- TABLE: INVITE_QUESTIONNAIRE 
--

ALTER TABLE supplier.INVITE_QUESTIONNAIRE ADD CONSTRAINT RefCHAIN_QUESTIONNAIRE769 
    FOREIGN KEY (CHAIN_QUESTIONNAIRE_ID)
    REFERENCES supplier.CHAIN_QUESTIONNAIRE(CHAIN_QUESTIONNAIRE_ID)
;

ALTER TABLE supplier.INVITE_QUESTIONNAIRE ADD CONSTRAINT RefINVITE677 
    FOREIGN KEY (INVITE_ID)
    REFERENCES supplier.INVITE(INVITE_ID)
;

ALTER TABLE supplier.INVITE_QUESTIONNAIRE ADD CONSTRAINT RefCOMPANY_USER717 
    FOREIGN KEY (LAST_MSG_FROM_COMPANY_SID, LAST_MSG_FROM_USER_SID, APP_SID)
    REFERENCES supplier.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;


-- 
-- TABLE: MESSAGE 
--

ALTER TABLE supplier.MESSAGE ADD CONSTRAINT RefALL_COMPANY648 
    FOREIGN KEY (COMPANY_SID)
    REFERENCES supplier.ALL_COMPANY(COMPANY_SID)
;

ALTER TABLE supplier.MESSAGE ADD CONSTRAINT RefCSR_USER660 
    FOREIGN KEY (USER_SID, APP_SID)
    REFERENCES csr.CSR_USER(CSR_USER_SID, APP_SID)
;

ALTER TABLE supplier.MESSAGE ADD CONSTRAINT RefGROUP_TABLE684 
    FOREIGN KEY (GROUP_SID)
    REFERENCES supplier.SECURITY.GROUP_TABLE(SID_ID)
;

ALTER TABLE supplier.MESSAGE ADD CONSTRAINT RefMESSAGE_TEMPLATE689 
    FOREIGN KEY (MESSAGE_TEMPLATE_ID)
    REFERENCES supplier.MESSAGE_TEMPLATE(MESSAGE_TEMPLATE_ID)
;


-- 
-- TABLE: MESSAGE_CONTACT 
--

ALTER TABLE supplier.MESSAGE_CONTACT ADD CONSTRAINT RefCONTACT710 
    FOREIGN KEY (CONTACT_ID, OWNER_COMPANY_SID, APP_SID)
    REFERENCES supplier.CONTACT(CONTACT_ID, OWNER_COMPANY_SID, APP_SID)
;

ALTER TABLE supplier.MESSAGE_CONTACT ADD CONSTRAINT RefMESSAGE711 
    FOREIGN KEY (MESSAGE_ID)
    REFERENCES supplier.MESSAGE(MESSAGE_ID)
;


-- 
-- TABLE: MESSAGE_QUESTIONNAIRE 
--

ALTER TABLE supplier.MESSAGE_QUESTIONNAIRE ADD CONSTRAINT RefCHAIN_QUESTIONNAIRE770 
    FOREIGN KEY (CHAIN_QUESTIONNAIRE_ID)
    REFERENCES supplier.CHAIN_QUESTIONNAIRE(CHAIN_QUESTIONNAIRE_ID)
;

ALTER TABLE supplier.MESSAGE_QUESTIONNAIRE ADD CONSTRAINT RefMESSAGE697 
    FOREIGN KEY (MESSAGE_ID)
    REFERENCES supplier.MESSAGE(MESSAGE_ID)
;


-- 
-- TABLE: MESSAGE_PROCURER_SUPPLIER 
--

ALTER TABLE supplier.MESSAGE_PROCURER_SUPPLIER ADD CONSTRAINT RefALL_PROCURER_SUPPLIER776 
    FOREIGN KEY (PROCURER_COMPANY_SID, SUPPLIER_COMPANY_SID, APP_SID)
    REFERENCES supplier.ALL_PROCURER_SUPPLIER(PROCURER_COMPANY_SID, SUPPLIER_COMPANY_SID, APP_SID)
;

ALTER TABLE supplier.MESSAGE_PROCURER_SUPPLIER ADD CONSTRAINT RefMESSAGE777 
    FOREIGN KEY (MESSAGE_ID)
    REFERENCES supplier.MESSAGE(MESSAGE_ID)
;


-- 
-- TABLE: MESSAGE_TEMPLATE 
--

ALTER TABLE supplier.MESSAGE_TEMPLATE ADD CONSTRAINT RefMESSAGE_TEMPLATE_FORMAT694 
    FOREIGN KEY (MESSAGE_TEMPLATE_FORMAT_ID)
    REFERENCES supplier.MESSAGE_TEMPLATE_FORMAT(MESSAGE_TEMPLATE_FORMAT_ID)
;


-- 
-- TABLE: MESSAGE_USER 
--

ALTER TABLE supplier.MESSAGE_USER ADD CONSTRAINT RefMESSAGE598 
    FOREIGN KEY (MESSAGE_ID)
    REFERENCES supplier.MESSAGE(MESSAGE_ID)
;

ALTER TABLE supplier.MESSAGE_USER ADD CONSTRAINT RefCSR_USER662 
    FOREIGN KEY (USER_SID, APP_SID)
    REFERENCES csr.CSR_USER(CSR_USER_SID, APP_SID)
;


-- 
-- TABLE: COMPANY_USER 
--

/**** This has been moved to the end of the script to 
      allow data to be filled into USER_PROFILE_VISIBILITY
ALTER TABLE supplier.COMPANY_USER ADD CONSTRAINT RefUSER_PROFILE_VISIBILITY569 
    FOREIGN KEY (USER_PROFILE_VISIBILITY_ID)
    REFERENCES supplier.USER_PROFILE_VISIBILITY(USER_PROFILE_VISIBILITY_ID)
;
*/

ALTER TABLE supplier.COMPANY_USER ADD CONSTRAINT RefCSR_USER675 
    FOREIGN KEY (CSR_USER_SID, APP_SID)
    REFERENCES csr.CSR_USER(CSR_USER_SID, APP_SID)
;


-- 
-- TABLE: QUESTIONNAIRE_REQUEST 
--

ALTER TABLE supplier.QUESTIONNAIRE_REQUEST ADD CONSTRAINT RefREQUEST_STATUS756 
    FOREIGN KEY (REQUEST_STATUS_ID)
    REFERENCES supplier.REQUEST_STATUS(REQUEST_STATUS_ID)
;

ALTER TABLE supplier.QUESTIONNAIRE_REQUEST ADD CONSTRAINT RefCOMPANY_QUESTIONNAIRE_RE757 
    FOREIGN KEY (SUPPLIER_COMPANY_SID, CHAIN_QUESTIONNAIRE_ID)
    REFERENCES supplier.COMPANY_QUESTIONNAIRE_RESPONSE(COMPANY_SID, CHAIN_QUESTIONNAIRE_ID)
;

ALTER TABLE supplier.QUESTIONNAIRE_REQUEST ADD CONSTRAINT RefCOMPANY_USER758 
    FOREIGN KEY (SUPPLIER_COMPANY_SID, SUPPLIER_USER_SID, APP_SID)
    REFERENCES supplier.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;

ALTER TABLE supplier.QUESTIONNAIRE_REQUEST ADD CONSTRAINT RefCOMPANY_USER759 
    FOREIGN KEY (PROCURER_COMPANY_SID, PROCURER_USER_SID, APP_SID)
    REFERENCES supplier.COMPANY_USER(COMPANY_SID, CSR_USER_SID, APP_SID)
;

ALTER TABLE supplier.QUESTIONNAIRE_REQUEST ADD CONSTRAINT RefALL_PROCURER_SUPPLIER760 
    FOREIGN KEY (PROCURER_COMPANY_SID, SUPPLIER_COMPANY_SID, APP_SID)
    REFERENCES supplier.ALL_PROCURER_SUPPLIER(PROCURER_COMPANY_SID, SUPPLIER_COMPANY_SID, APP_SID)
;

/**
 *	SECTION 6: CREATE VIEWS AND PACKAGES
 **/ 

DROP TYPE supplier.T_ID_DATE_TABLE;

CREATE OR REPLACE TYPE supplier.T_ID_DATE_ROW AS 
  OBJECT ( 
	ITEM_ID		NUMBER(10),
	DTM			DATE
  );
/

CREATE OR REPLACE TYPE supplier.T_ID_DATE_TABLE AS 
  TABLE OF supplier.T_ID_DATE_ROW;
/


/* A couple of core views (COMPANY, PRODUCT, PRODUCT_QUESTIONNAIRE) are held in the ER/Studio schema
   and get created in create_schema.sql. The reason for this is that they're really just exact copies
   of the core tables with simple checks in the WHERE clause for USED = 1, DELETED = 0 etc so it kind
   of makes sense to keep these alongside the underlying tables.
   
   Other stuff should go in here.
 */

/*********************************************  V$CHAIN_USER  ********************************************/

DEFINE user_fully_hidden = 0
DEFINE user_hidden = 1
DEFINE user_show_job_title = 2
DEFINE user_show_name_and_job_title = 3
DEFINE user_show_all = 4

CREATE OR REPLACE VIEW supplier.v$all_chain_user AS 
  SELECT cu.company_sid, csru.app_sid, csru.csr_user_sid, cu.pending_company_authorization, cu.user_profile_visibility_id,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id >= &user_show_name_and_job_title THEN full_name
    END full_name,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id = &user_show_all THEN email
    END email,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id >= &user_show_job_title THEN job_title
    END job_title,
    CASE 
        WHEN SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = cu.company_sid OR cu.user_profile_visibility_id = &user_show_all THEN phone_number
    END phone_number
  FROM csr.csr_user csru, company_user cu
 WHERE csru.app_sid = SYS_CONTEXT('SECURITY','APP')
   AND csru.app_sid = cu.app_sid
   AND csru.csr_user_sid = cu.csr_user_sid
;
   
CREATE OR REPLACE VIEW supplier.v$chain_user AS 
  SELECT * 
    FROM v$all_chain_user
   WHERE (user_profile_visibility_id > &user_fully_hidden 
   			OR (SYS_CONTEXT('SECURITY','SUPPLY_CHAIN_COMPANY') = company_sid AND SYS_CONTEXT('SECURITY','SID') = csr_user_sid)
   	   )
;

/*********************************************************************************************************/

/***************************************  V$ALL_CONTACT / V$CONTACT ****************************************/
-- holds the merged contact data for the context application
CREATE OR REPLACE VIEW supplier.v$all_contact AS
    SELECT c.contact_id, c.contact_state_id, c.owner_company_sid, c.app_sid, c.contact_guid, 
    	   c.existing_company_sid, c.existing_user_sid, c.last_contact_state_update_dtm, c.registered_to_company_sid, registered_as_user_sid,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.full_name ELSE vcu.full_name END full_name,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.email ELSE vcu.email END email,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.job_title ELSE vcu.job_title END job_title,
		   CASE WHEN c.existing_user_sid IS NULL THEN c.phone_number ELSE vcu.email END phone_number,	   
		   CASE WHEN c.existing_company_sid IS NULL THEN c.company_name ELSE cm.name END company_name,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_1 ELSE cm.address_1 END address_1,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_2 ELSE cm.address_2 END address_2,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_3 ELSE cm.address_3 END address_3,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.address_4 ELSE cm.address_4 END address_4,		   
		   CASE WHEN c.existing_company_sid IS NULL THEN c.town ELSE cm.town END town,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.state ELSE cm.state END state,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.postcode ELSE cm.postcode END postcode,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.country_code ELSE cm.country_code END country_code,		   
		   CASE WHEN c.existing_company_sid IS NULL THEN c.estimated_annual_spend ELSE aps.estimated_annual_spend END estimated_annual_spend,
		   CASE WHEN c.existing_company_sid IS NULL THEN c.currency_code ELSE aps.currency_code END currency_code
	  FROM contact c, company cm, v$chain_user vcu, all_procurer_supplier aps   
	 WHERE c.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND c.existing_company_sid = cm.company_sid(+)
	   AND c.existing_user_sid = vcu.csr_user_sid(+)
	   AND c.owner_company_sid = aps.procurer_company_sid(+)
       AND c.existing_company_sid = aps.supplier_company_sid(+)
;

-- reduced view to filter only active contacts
CREATE OR REPLACE VIEW supplier.v$contact AS
	SELECT *
	  FROM v$all_contact
	 WHERE contact_state_id = 0 -- active
;

/*********************************************************************************************************/


/**********************************************  V$MESSAGE  **********************************************/
SET DEFINE OFF
SET DEFINE &

DEFINE user_profile_path = '/csr/site/supplier/chain/UserProfile.acds?userSid='
DEFINE company_profile_path = '/csr/site/supplier/chain/CompanyProfile.acds?companySid='
DEFINE contact_profile_path = '/csr/site/supplier/chain/ContactProfile.acds?contactId='
DEFINE view_questionnaire_path = '/csr/site/supplier/chain/ViewQuestionnaire.acds?questionnaireId='


-- holds the prepared message data for the context application
CREATE OR REPLACE VIEW supplier.v$message AS
	-- Text only message --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl, 
		   null param_0, null param_0_action,
		   null param_1, null param_1_action,
		   null param_2, null param_2_action
	  FROM message m, message_template mt, message_template_format mtf, company_user cu
	 WHERE mtf.message_template_format_id = 0 -- message_pkg.MTF_TEXT_ONLY --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.company_sid = cu.company_sid
	   AND m.user_sid = cu.csr_user_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND m.app_sid = cu.app_sid
UNION  
	-- Message in the format of {UserSid (Full name), CompanySid (Company name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,  
		   NVL(vcu.full_name, vcu.job_title) param_0, '&user_profile_path'||mu.user_sid param_0_action,
		   c.name param_1, '&company_profile_path'||c.company_sid param_1_action,
		   null param_2, null param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, company c, v$all_chain_user vcu
	 WHERE mtf.message_template_format_id = 1 -- message_pkg.MTF_USER_COMPANY --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
	   AND c.company_sid = m.company_sid
	   AND vcu.csr_user_sid = mu.user_sid
	   AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	-- Message in the format of {UserSid (Full name), UserSid (Full name), CompanySid (Company name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl, 
		   fmu.label param_0, '&user_profile_path'||fmu.user_sid param_0_action,
		   smu.label param_1, '&user_profile_path'||smu.user_sid param_1_action,
		   c.name param_2, '&company_profile_path'||c.company_sid param_2_action
	  FROM message m, message_template mt, message_template_format mtf, company c, 
		   (SELECT message_id, NVL(vcu.full_name, vcu.job_title) label, mu.user_sid, mu.app_sid 
			  FROM message_user mu, v$all_chain_user vcu
			 WHERE mu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mu.user_sid = vcu.csr_user_sid(+)
			   AND mu.entry_index = 0) fmu, -- first message user --
		   (SELECT message_id, NVL(vcu.full_name, vcu.job_title) label, mu.user_sid, mu.app_sid 
			  FROM message_user mu, v$all_chain_user vcu
			 WHERE mu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND mu.user_sid = vcu.csr_user_sid(+)
			   AND mu.entry_index = 1) smu -- second message user --
	 WHERE mtf.message_template_format_id = 2 -- message_pkg.MTF_USER_USER_COMPANY --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = fmu.message_id
	   AND m.message_id = smu.message_id
	   AND m.company_sid = c.company_sid
	   AND m.app_sid = fmu.app_sid
	   AND m.app_sid = smu.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
UNION
	-- Message in the format of {UserSid (Full name), ContactId (Company name), QuestionnaireId (Friendly name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,  
		   NVL(vcu.full_name, vcu.job_title) param_0, '&user_profile_path'||mu.user_sid param_0_action,
           c.company_name param_1, '&contact_profile_path'||c.contact_id param_1_action,
		   q.friendly_name param_2, '&view_questionnaire_path'||q.chain_questionnaire_id param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, message_contact mc, message_questionnaire mq, 
           v$all_chain_user vcu, v$all_contact c, chain_questionnaire q
	 WHERE mtf.message_template_format_id = 3 -- message_pkg.MTF_USER_CONTACT_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
       AND m.message_id = mc.message_id
       AND m.message_id = mq.message_id
	   AND vcu.csr_user_sid = mu.user_sid
	   AND vcu.company_sid = m.company_sid
	   AND mc.contact_id = c.contact_id(+)
       AND mq.chain_questionnaire_id = q.chain_questionnaire_id
       AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	-- Message in the format of {UserSid (Full name), SupplierSid (Company name), QuestionnaireId (Friendly name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,
		   NVL(vcu.full_name, vcu.job_title) param_0, '&user_profile_path'||mu.user_sid param_0_action,
		   c.name param_1, '&company_profile_path'||c.company_sid param_1_action,
		   q.friendly_name param_2, '&view_questionnaire_path'||q.chain_questionnaire_id param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, message_procurer_supplier mps, 
		   message_questionnaire mq, v$all_chain_user vcu, chain_questionnaire q, all_company c
	 WHERE mtf.message_template_format_id = 4 -- message_pkg.MTF_USER_SUPPLIER_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
	   AND m.message_id = mps.message_id
	   AND m.message_id = mq.message_id
	   AND vcu.csr_user_sid = mu.user_sid
	   AND vcu.company_sid = mps.procurer_company_sid
	   AND mps.procurer_company_sid = m.company_sid
	   AND mps.supplier_company_sid = c.company_sid
	   AND mq.chain_questionnaire_id = q.chain_questionnaire_id
	   AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = c.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	-- Message in the format of {UserSid (Full name), ProcurerSid (Company name), QuestionnaireId (Friendly name)} --
	SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,
		   NVL(vcu.full_name, vcu.job_title) param_0, '&user_profile_path'||mu.user_sid param_0_action,
		   c.name param_1, '&company_profile_path'||c.company_sid param_1_action,
		   q.friendly_name param_2, '&view_questionnaire_path'||q.chain_questionnaire_id param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_user mu, message_procurer_supplier mps, 
		   message_questionnaire mq, v$all_chain_user vcu, chain_questionnaire q, all_company c
	 WHERE mtf.message_template_format_id = 5 -- message_pkg.MTF_USER_PROCURER_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mu.message_id
	   AND m.message_id = mps.message_id
	   AND m.message_id = mq.message_id
	   AND vcu.csr_user_sid = mu.user_sid
	   AND vcu.company_sid = mps.supplier_company_sid
	   AND mps.procurer_company_sid = c.company_sid
	   AND mps.supplier_company_sid = m.company_sid
	   AND mq.chain_questionnaire_id = q.chain_questionnaire_id
	   AND m.app_sid = vcu.app_sid        
	   AND m.app_sid = mu.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = c.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND mu.entry_index = 0
UNION
	 -- Message in the format of {SupplierSid (Company name), QuestionnaireId (Friendly name)} --
	 SELECT m.message_id, m.app_sid, m.msg_dtm, m.user_sid, m.company_sid, m.group_sid, mt.tpl,
		   c.name param_0, 'company_profile_path'||c.company_sid param_0_action,
		   q.friendly_name param_1, 'view_questionnaire_path'||q.chain_questionnaire_id param_1_action,
		   null param_2, null param_2_action
	  FROM message m, message_template mt, message_template_format mtf, message_procurer_supplier mps, 
		   message_questionnaire mq, chain_questionnaire q, all_company c
	 WHERE mtf.message_template_format_id = 6 -- message_pkg.MTF_SUPPLIER_QNAIRE --
	   AND mtf.message_template_format_id = mt.message_template_format_id
	   AND m.message_template_id = mt.message_template_id
	   AND m.message_id = mps.message_id
	   AND m.message_id = mq.message_id
	   AND mps.supplier_company_sid = c.company_sid
	   AND mps.procurer_company_sid = m.company_sid
	   AND mq.chain_questionnaire_id = q.chain_questionnaire_id 
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = c.app_sid
	   AND m.app_sid = mps.app_sid
	   AND m.app_sid = SYS_CONTEXT('SECURITY','APP')
;
/*********************************************************************************************************/

/***************************************  V$COMPANY_QUESTIONNAIRE  ***************************************/

CREATE OR REPLACE VIEW supplier.v$company_questionnaire AS 
	SELECT 0 request_status_id, -1 response_status_id, i.app_sid, 
		   i.invite_id, c.owner_company_sid procurer_company_sid, 
		   i.sent_by_user_sid procurer_user_sid, pc.name procurer_company_name,
		   c.existing_company_sid supplier_company_sid, c.contact_id, 
		   null supplier_user_sid, c.company_name supplier_company_name,
		   iq.last_msg_dtm, iq.reminder_count, 
		   q.chain_questionnaire_id, q.friendly_name questionnaire_name, 
		   iq.due_dtm, i.creation_dtm, null accepted_dtm, 
		   q.edit_url, q.view_url, q.result_url, q.all_results_url, q.quick_survey_sid
	  FROM v$contact c, invite i, chain_questionnaire q, invite_questionnaire iq, 
			(SELECT * FROM company WHERE app_sid = SYS_CONTEXT('SECURITY','APP')) pc
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND i.app_sid = c.app_sid
	   AND i.app_sid = q.app_sid 
	   AND i.app_sid = iq.app_sid
	   AND i.sent_to_contact_id = c.contact_id
	   AND i.sent_by_company_sid = c.owner_company_sid
	   AND iq.last_msg_from_company_sid = c.owner_company_sid
	   AND i.sent_by_company_sid = pc.company_sid
	   AND i.invite_id = iq.invite_id
	   AND q.chain_questionnaire_id = iq.chain_questionnaire_id  
	   AND i.invite_status_id = 0
UNION ALL
	SELECT qr.request_status_id, cqr.response_status_id, qr.app_sid, 
			null invite_id, qr.procurer_company_sid, 
			qr.procurer_user_sid, pc.name procurer_company_name,
			qr.supplier_company_sid, null contact_id, 
			qr.supplier_user_sid, ac.name supplier_company_name,
			last_reminder_dtm last_msg_dtm, reminder_count, 
			qr.chain_questionnaire_id, q.friendly_name questionnaire_name, 
			qr.due_dtm, null creation_dtm, qr.accepted_dtm, 
			q.edit_url, q.view_url, q.result_url, q.all_results_url, q.quick_survey_sid
	  FROM questionnaire_request qr, chain_questionnaire q, all_company ac, company_questionnaire_response cqr,
			(SELECT * FROM company WHERE app_sid = SYS_CONTEXT('SECURITY','APP')) pc
	 WHERE qr.app_sid = SYS_CONTEXT('SECURITY','APP')
	   AND qr.app_sid = q.app_sid 
	   AND qr.app_sid = ac.app_sid
	   AND qr.app_sid = cqr.app_sid
	   AND qr.procurer_company_sid = pc.company_sid
	   AND qr.supplier_company_sid = ac.company_sid   
	   AND qr.supplier_company_sid = cqr.company_sid   
   	   AND qr.chain_questionnaire_id = q.chain_questionnaire_id
   	   AND qr.chain_questionnaire_id = cqr.chain_questionnaire_id
;

/*********************************************************************************************************/

@..\company_pkg;
@..\company_body;

@..\chain\chain_company_pkg;
@..\chain\chain_questionnaire_pkg;
@..\chain\company_group_pkg;
@..\chain\company_user_pkg;
@..\chain\contact_pkg;
@..\chain\currency_pkg;
@..\chain\invite_pkg;    
@..\chain\message_pkg;               
@..\chain\registration_pkg;

@..\chain\chain_company_body;         
@..\chain\chain_questionnaire_body;   
@..\chain\company_group_body;         
@..\chain\company_user_body;          
@..\chain\contact_body;               
@..\chain\currency_body;
@..\chain\invite_body;
@..\chain\message_body;
@..\chain\registration_body;          

/**
 *	SECTION 7: BASE DATA
 **/ 
PROMPT > Inserting base data

begin
	insert into supplier.user_profile_visibility (user_profile_visibility_id, description) values (0, 'Fully hidden (i.e. superusers)');
	insert into supplier.user_profile_visibility (user_profile_visibility_id, description) values (1, 'Hidden');
	insert into supplier.user_profile_visibility (user_profile_visibility_id, description) values (2, 'Show my job title'); 
	insert into supplier.user_profile_visibility (user_profile_visibility_id, description) values (3, 'Show only my name and job title'); 
	insert into supplier.user_profile_visibility (user_profile_visibility_id, description) values (4, 'Show all');
end;
/

begin
	insert into supplier.invite_status (invite_status_id, description) values (0, 'Invitation sent');
	insert into supplier.invite_status (invite_status_id, description) values (1, 'Cancelled');
	insert into supplier.invite_status (invite_status_id, description) values (2, 'Accepted');
	insert into supplier.invite_status (invite_status_id, description) values (3, 'Rejected - not supplier');
end;
/

begin
	insert into supplier.contact_state (contact_state_id, description) values (0, 'Active');
	insert into supplier.contact_state (contact_state_id, description) values (1, 'Removed by owner procurer');
	insert into supplier.contact_state (contact_state_id, description) values (2, 'Removed by contact invitation rejection');
	insert into supplier.contact_state (contact_state_id, description) values (3, 'Registered as user');
end;
/

begin
	insert into supplier.questionnaire_response_status (response_status_id, description) values (0, 'Not completed');
	insert into supplier.questionnaire_response_status (response_status_id, description) values (1, 'Submitted for approval');
	insert into supplier.questionnaire_response_status (response_status_id, description) values (2, 'Approved for release');
end;
/

begin
	insert into supplier.request_status (request_status_id, description) values (0, 'Pending supplier acceptance');
	insert into supplier.request_status (request_status_id, description) values (1, 'Accepted by supplier');
	insert into supplier.request_status (request_status_id, description) values (2, 'Shared by supplier');
end;
/

begin
	insert into supplier.currency (currency_code, label) values ('USD', 'US Dollars');
	insert into supplier.currency (currency_code, label) values ('EUR', 'Euros');
	insert into supplier.currency (currency_code, label) values ('GBP', 'British Sterling');
end;
/

begin
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (message_pkg.MTF_TEXT_ONLY, 'Text only');
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (message_pkg.MTF_USER_COMPANY, 'UserSid (Full name), CompanySid (Company name)');
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (message_pkg.MTF_USER_USER_COMPANY, 'UserSid (Full name), UserSid (Full name), CompanySid (Company name)');
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (message_pkg.MTF_USER_CONTACT_QNAIRE, 'UserSid (Full name), ContactId (Company name), QuestionnaireId (Friendly name)');
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (message_pkg.MTF_USER_SUPPLIER_QNAIRE, 'UserSid (Full name), SupplierSid (Company name), QuestionnaireId (Friendly name)');
	insert into supplier.message_template_format (message_template_format_id, tpl_format) values (message_pkg.MTF_USER_PROCURER_QNAIRE, 'UserSid (Full name), ProcurerSid (Company name), QuestionnaireId (Friendly name)');
	
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_WELCOME_MESSAGE, 
		message_pkg.MTF_TEXT_ONLY, 
		'Standard welcome message', 
		'Welcome to the CHAIN!');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_JOIN_COMPANY_REQUEST, 
		message_pkg.MTF_USER_COMPANY, 
		'Join company request', 
		'{0} would like to be added as a user to {1}');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_JOIN_COMPANY_GRANTED, 
		message_pkg.MTF_USER_USER_COMPANY, 
		'Join company granted', 
		'{0} has added {1} as a user to {2}');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_JOIN_COMPANY_DENIED, 
		message_pkg.MTF_USER_COMPANY, 
		'Join company denied', 
		'{0} has denied your request to be added as a user to {1}');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_CONTACT_QI, 
		message_pkg.MTF_USER_CONTACT_QNAIRE, 
		'Contact invited to fill in questionnaire', 
		'{0} has invited {1} to complete the {2} questionnaire');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_CONTACT_QI_REMINDER, 
		message_pkg.MTF_USER_CONTACT_QNAIRE, 
		'Contact reminded to fill in questionnaire', 
		'{0} has reminded {1} to complete the {2} questionnaire');
		
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_CONTACT_QI_CANCELLED, 
		message_pkg.MTF_USER_CONTACT_QNAIRE, 
		'Contact questionnaire invitation cancelled', 
		'{0} has cancelled the request for {1} to complete the {2} questionnaire');
		
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_QUESTIONNAIRE_REMINDER, 
		message_pkg.MTF_USER_SUPPLIER_QNAIRE, 
		'Message from procurer user to supplier company to complete a questionnaire', 
		'{0} has reminded {1} to complete the {2} questionnaire');
		
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_ACCEPT_QUESTIONNAIRE, 
		message_pkg.MTF_USER_PROCURER_QNAIRE, 
		'Message that a user has accepted an inviation from a procurer, to complete a questionnare', 
		'{0} has accepted the invitation from {1} to complete the {2} questionnaire');
	
	insert into supplier.message_template (message_template_id, message_template_format_id, label, tpl) values (
		message_pkg.MT_QUESTIONNAIRE_ACCEPTED, 
		message_pkg.MTF_USER_SUPPLIER_QNAIRE, 
		'Message from procurer user to supplier company to complete a questionnaire', 
		'{1} has accepted the invitation from {0} to complete the {2} questionnaire');
end;
/

commit;


/**
 *	SECTION 8: FINAL CONSTRAINTS
 **/ 
PROMPT > Final constraints
-- 
-- TABLE: COMPANY_USER 
--

/**** This has been moved to the end of the script to 
      allow data to be filled into USER_PROFILE_VISIBILITY */
ALTER TABLE supplier.COMPANY_USER ADD CONSTRAINT RefUSER_PROFILE_VISIBILITY569 
    FOREIGN KEY (USER_PROFILE_VISIBILITY_ID)
    REFERENCES supplier.USER_PROFILE_VISIBILITY(USER_PROFILE_VISIBILITY_ID)
;


@update_tail