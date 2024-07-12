-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSRIMP.INCIDENT_TYPE(
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	TAB_SID                 NUMBER(10, 0)     NOT NULL,
	GROUP_KEY               VARCHAR2(255)     NOT NULL,
	LABEL                   VARCHAR2(500)     NOT NULL,
	PLURAL                  VARCHAR2(255)     NOT NULL,
	BASE_CSS_CLASS          VARCHAR2(255)     NOT NULL,
	POS                     NUMBER(10, 0)     NOT NULL,
	LIST_URL                VARCHAR2(2000)    NOT NULL,
	EDIT_URL                VARCHAR2(2000)    NOT NULL,
	NEW_CASE_URL            VARCHAR2(2000),
	MOBILE_FORM_PATH        VARCHAR2(2000),
	MOBILE_FORM_SID		    NUMBER(10, 0),
	DESCRIPTION             CLOB,
	CONSTRAINT PK_INCIDENT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, TAB_SID),
	CONSTRAINT CK_INCIDENT_MOBILE_FORM CHECK ( MOBILE_FORM_PATH IS NULL OR MOBILE_FORM_SID IS NULL ),
	CONSTRAINT FK_INCIDENT_TYPE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;
-- Alter tables

-- *** Grants ***
grant insert on csr.incident_type to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../csrimp/imp_pkg

@../schema_body
@../csrimp/imp_body

@update_tail
