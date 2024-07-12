-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CHAIN.REFERENCE_COMPANY_TYPE(
	APP_SID                          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    REFERENCE_ID            		 NUMBER(10, 0)    NOT NULL,
    COMPANY_TYPE_ID					 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REFERENCE_COMPANY_TYPE PRIMARY KEY (APP_SID, REFERENCE_ID, COMPANY_TYPE_ID),
    CONSTRAINT FK_REF_CMP_TYP_CMP_TYP FOREIGN KEY (APP_SID, COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID),
    CONSTRAINT FK_REF_CMP_TYP_REF FOREIGN KEY (APP_SID, REFERENCE_ID) REFERENCES CHAIN.REFERENCE(APP_SID, REFERENCE_ID)
);

CREATE INDEX CHAIN.IX_REF_CMP_TYP_CMP_TYP ON CHAIN.REFERENCE_COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID);

CREATE TABLE CSRIMP.CHAIN_REFERENCE_COMPANY_TYPE(
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    REFERENCE_ID            		 NUMBER(10, 0)    NOT NULL,
    COMPANY_TYPE_ID					 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_REFERENCE_COMPANY_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, REFERENCE_ID, COMPANY_TYPE_ID),
    CONSTRAINT PK_REFERENCE_COMPANY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

ALTER TABLE CHAIN.REFERENCE RENAME COLUMN FOR_COMPANY_TYPE_ID TO XXX_FOR_COMPANY_TYPE_ID;

INSERT INTO CHAIN.REFERENCE_COMPANY_TYPE (APP_SID, REFERENCE_ID, COMPANY_TYPE_ID)
SELECT APP_SID, REFERENCE_ID, XXX_FOR_COMPANY_TYPE_ID
  FROM CHAIN.REFERENCE R
 WHERE XXX_FOR_COMPANY_TYPE_ID IS NOT NULL
   AND NOT EXISTS(
	SELECT *
	  FROM CHAIN.REFERENCE_COMPANY_TYPE E
	 WHERE R.APP_SID = E.APP_SID
	   AND R.REFERENCE_ID = E.REFERENCE_ID
	   AND R.XXX_FOR_COMPANY_TYPE_ID = E.COMPANY_TYPE_ID
);

ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP COLUMN FOR_COMPANY_TYPE_ID;


-- *** Grants ***
grant select on chain.reference_company_type to CSR;
grant select, insert, update, delete on csrimp.chain_reference_company_type to tool_user;
grant insert on chain.reference_company_type to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\helper_pkg
@..\schema_pkg

@..\chain\helper_body
@..\chain\report_body
@..\chain\chain_body
@..\chain\company_body
@..\chain\company_type_body
@..\chain\higg_setup_body
@..\csrimp\imp_body
@..\schema_body


@update_tail
