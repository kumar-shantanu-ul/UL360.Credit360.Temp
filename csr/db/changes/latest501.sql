-- Please update version.sql too -- this keeps clean builds in sync
define version=501
@update_header

PROMPT > Granting Chain permissions...
PROMPT ===============================
connect chain/chain@&_CONNECT_IDENTIFIER
grant select, references on chain.company to csr;
grant select, references on chain.action_repeat_type to csr;
grant select, references on chain.customer_options to csr;
grant select, references on chain.invitation to csr;
grant select on chain.v$chain_user to csr;
grant select, references on chain.chain_user to csr;
grant select, references on chain.questionnaire to csr;
grant select, references on chain.questionnaire_type to csr;
grant execute on chain.questionnaire_pkg to csr;
grant select, references on chain.company_metric to csr;
grant execute on CheckCompanyPermission to csr;
grant select on chain.task to csr;
grant execute on chain.task_pkg to csr;
grant select on task_type to csr;
grant execute on newsflash_pkg to csr;
grant references on chain.newsflash to csr;

connect csr/csr@&_CONNECT_IDENTIFIER

-- TABLE: CHAIN_TPL_DELEGATION 
--

CREATE TABLE CHAIN_TPL_DELEGATION(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TPL_DELEGATION_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CHAIN_TPL_DELEGATION PRIMARY KEY (APP_SID, TPL_DELEGATION_SID)
)
;



-- TABLE: SUPPLIER 
--

CREATE TABLE SUPPLIER(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUPPLIER_SID    NUMBER(10, 0)    NOT NULL,
    REGION_SID      NUMBER(10, 0),
    CONSTRAINT PK_SUPPLIER PRIMARY KEY (APP_SID, SUPPLIER_SID)
)
;



-- 
-- TABLE: SUPPLIER_DELEGATION 
--

CREATE TABLE SUPPLIER_DELEGATION(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SUPPLIER_SID          NUMBER(10, 0)    NOT NULL,
    TPL_DELEGATION_SID    NUMBER(10, 0)    NOT NULL,
    DELEGATION_SID        NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SUPPLIER_DELEGATION PRIMARY KEY (APP_SID, SUPPLIER_SID, TPL_DELEGATION_SID)
)
;



-- 
-- TABLE: CHAIN_TPL_DELEGATION 
--

ALTER TABLE CHAIN_TPL_DELEGATION ADD CONSTRAINT REFCH_TPL_DELEG_DELEG 
    FOREIGN KEY (APP_SID, TPL_DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
;

ALTER TABLE CHAIN_TPL_DELEGATION ADD CONSTRAINT REFCH_TPL_DELEG_QUE_TYPE 
    FOREIGN KEY (APP_SID, TPL_DELEGATION_SID)
    REFERENCES CHAIN.QUESTIONNAIRE_TYPE(APP_SID, QUESTIONNAIRE_TYPE_ID)  DEFERRABLE INITIALLY DEFERRED
;


-- TABLE: SUPPLIER 
--

ALTER TABLE SUPPLIER ADD CONSTRAINT REFSUP_CHAIN_COMPANY 
    FOREIGN KEY (APP_SID, SUPPLIER_SID)
    REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)
;

ALTER TABLE SUPPLIER ADD CONSTRAINT REFSUP_REGION 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES REGION(APP_SID, REGION_SID)  DEFERRABLE INITIALLY DEFERRED
;


-- 
-- TABLE: SUPPLIER_DELEGATION 
--

ALTER TABLE SUPPLIER_DELEGATION ADD CONSTRAINT REFSUP_DELEG_DELEG 
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES DELEGATION(APP_SID, DELEGATION_SID)
;

ALTER TABLE SUPPLIER_DELEGATION ADD CONSTRAINT REFSUP_DELEG_SUPPLIER 
    FOREIGN KEY (APP_SID, SUPPLIER_SID)
    REFERENCES SUPPLIER(APP_SID, SUPPLIER_SID)
;

ALTER TABLE SUPPLIER_DELEGATION ADD CONSTRAINT REFSUP_DELEG_TPL_DELEG 
    FOREIGN KEY (APP_SID, TPL_DELEGATION_SID)
    REFERENCES CHAIN_TPL_DELEGATION(APP_SID, TPL_DELEGATION_SID)
;



-- to be dropped later
create table LINK_AUDIT (
	ACTION_DTM 			TIMESTAMP,
	FUNCTION_NAME		varchar2(200),
	MESSAGE				varchar2(4000)
);


set define off;

@..\region_pkg
@..\supplier_pkg
@..\region_pkg
@..\supplier_body

set define on;

PROMPT > Granting execute on csr packages to chain...
PROMPT ==============================================
grant execute on supplier_pkg to chain;

@..\rls

@update_tail
