-- Please update version.sql too -- this keeps clean builds in sync
define version=2982
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSRIMP.CMS_DATA_HELPER (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOOKUP_KEY 						VARCHAR2(255) NOT NULL,
    HELPER_PROCEDURE 				VARCHAR2(255) NOT NULL,
    CONSTRAINT PK_DATA_HELPER PRIMARY KEY (CSRIMP_SESSION_ID, LOOKUP_KEY),
	CONSTRAINT FK_CMS_DATA_HELPER_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

-- *** Grants ***
GRANT SELECT, UPDATE ON cms.form_version TO csrimp;
GRANT INSERT ON cms.data_helper TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.cms_data_helper TO tool_user;
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/tab_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
