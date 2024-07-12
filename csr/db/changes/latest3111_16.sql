-- Please update version.sql too -- this keeps clean builds in sync
define version=3111
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.INTAPI_COMPANY_USER_GROUP(
	APP_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	GROUP_SID_ID	NUMBER(10, 0)	NOT NULL,
	CONSTRAINT FK_GROUP_SID_ID FOREIGN KEY (GROUP_SID_ID) REFERENCES SECURITY.GROUP_TABLE (SID_ID),
	CONSTRAINT PK_INTAPI_COMPANY_USER_GROUP PRIMARY KEY (APP_SID, GROUP_SID_ID)
)
;

CREATE TABLE CSRIMP.INTAPI_COMPANY_USER_GROUP(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GROUP_SID_ID				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_INTAPI_COMPANY_USER_GROUP PRIMARY KEY(CSRIMP_SESSION_ID, GROUP_SID_ID)
);

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.intapi_company_user_group TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.intapi_company_user_group TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (36,'Change Integration Api Company User Default Groups','Add or remove default groups for users created via the Integration Api Company Users','ChangeIntApiCompanyUserGroup',null);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (36, 'Group Sid Id', 'The Group Sid of the group to add/remove', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (36, 'Remove', 'Add = 0, Remove = 1', 2, 0);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg

@../schema_body
@../csr_app_body

@../csrimp/imp_pkg
@../csrimp/imp_body

@../util_script_pkg
@../util_script_body

@../integration_api_body

@update_tail
