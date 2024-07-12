-- Please update version.sql too -- this keeps clean builds in sync
define version=3363
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DROP TABLE CSR.MANANGED_CONTENT_UNPACKAGE_LOG_RUN CASCADE CONSTRAINTS;

CREATE TABLE CSR.MANAGED_CONTENT_UNPACKAGE_LOG_RUN (
	APP_SID		            NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	MESSAGE_ID 	            NUMBER(10, 0) NOT NULL,
	RUN_ID 		            NUMBER(10, 0) NOT NULL,
	SEVERITY            	VARCHAR2(1) NOT NULL,
	MSG_DTM		            DATE NOT NULL,
	MESSAGE		            CLOB NOT NULL,
    CONSTRAINT PK_MANAGED_CONTENT_UNPKG_LOG_RUN PRIMARY KEY (APP_SID, RUN_ID, MESSAGE_ID),
    CONSTRAINT CK_MANAGED_CONTENT_MSG_SEV CHECK (SEVERITY IN ('E','C','I','D'))
)
;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../managed_content_pkg
@../managed_content_body

@update_tail
