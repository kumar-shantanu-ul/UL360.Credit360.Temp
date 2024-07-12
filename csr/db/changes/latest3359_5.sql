-- Please update version.sql too -- this keeps clean builds in sync
define version=3359
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.MANANGED_CONTENT_UNPACKAGE_LOG_RUN (
	APP_SID		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	MESSAGE_ID 	NUMBER(10, 0) NOT NULL,
	RUN_ID 		NUMBER(10, 0) NOT NULL,
	SEVERITY	VARCHAR2(1) NOT NULL,
	MSG_DTM		DATE NOT NULL,
	MESSAGE		CLOB NOT NULL,
    CONSTRAINT PK_MANGED_CONTENT_UNPKG_LOG_RUN PRIMARY KEY (APP_SID, RUN_ID, MESSAGE_ID),
    CONSTRAINT CK_MANAGED_CONTENT_MSG_SEV CHECK (SEVERITY IN ('E','C','I','D'))
);

CREATE SEQUENCE CSR.MANAGED_CONTENT_UNPACKAGE_MSG_SEQ;
CREATE SEQUENCE CSR.MANAGED_CONTENT_UNPACKAGE_RUN_SEQ;
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../managed_content_pkg
@../managed_content_body

@update_tail
