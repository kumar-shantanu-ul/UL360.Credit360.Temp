-- Please update version.sql too -- this keeps clean builds in sync
define version=1493
@update_header

ALTER TABLE CSR.CUSTOMER ADD ISSUE_ESCALATION_ENABLED NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUST_ISSUE_ESC_ENABLED CHECK (ISSUE_ESCALATION_ENABLED IN (0,1));

ALTER TABLE CSR.CSR_USER ADD PARENT_SID NUMBER(10, 0) DEFAULT NULL;

-- account for existing session data not being null by making nullable, updating, then setting to not null
ALTER TABLE CSRIMP.CUSTOMER ADD ISSUE_ESCALATION_ENABLED NUMBER(1); 
UPDATE CSRIMP.CUSTOMER SET ISSUE_ESCALATION_ENABLED = 0; 
ALTER TABLE CSRIMP.CUSTOMER MODIFY ISSUE_ESCALATION_ENABLED NOT NULL;

ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUST_ISSUE_ESC_ENABLED CHECK (ISSUE_ESCALATION_ENABLED IN (0,1));
ALTER TABLE CSRIMP.CSR_USER ADD PARENT_SID NUMBER(10, 0);

INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Edit user parent', 0);

@..\csr_user_pkg

@..\csr_user_body
@..\csr_app_body
@..\delegation_body
@..\schema_body
@..\chain\company_user_body

@..\csrimp\imp_body

@update_tail