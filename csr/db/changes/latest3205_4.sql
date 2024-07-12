-- Please update version.sql too -- this keeps clean builds in sync
define version=3205
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSR.AUTOMATED_IMPORT_BUS_FILE (
	APP_SID							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	FILE_BLOB						BLOB NOT NULL,
	AUTOMATED_IMPORT_INSTANCE_ID	NUMBER(10) NOT NULL,
	MESSAGE_RECEIVED_DTM			DATE DEFAULT SYSDATE NOT NULL,
	SOURCE_DESCRIPTION				VARCHAR(1024),
	CONSTRAINT PK_AUTO_IMP_BUS_FILE PRIMARY KEY (APP_SID, AUTOMATED_IMPORT_INSTANCE_ID)
)
;

-- Alter tables
ALTER TABLE CSR.AUTOMATED_IMPORT_INSTANCE
ADD IS_FROM_BUS NUMBER(1) DEFAULT 0 NOT NULL;



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
@../automated_import_pkg
@../automated_import_body

@update_tail
