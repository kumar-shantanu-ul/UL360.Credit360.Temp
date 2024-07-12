-- Please update version.sql too -- this keeps clean builds in sync
define version=0
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
DROP TABLE CSRIMP.SHEET_VALUE_FILE_HIDDEN_CACHE;
CREATE TABLE CSRIMP.SHEET_VALUE_FILE_HIDDEN_CACHE(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    SHEET_VALUE_ID                 NUMBER(10, 0)     NOT NULL,
	FILE_UPLOAD_SID                NUMBER(10,0)      NOT NULL,
    CONSTRAINT PK_SVFHC PRIMARY KEY (CSRIMP_SESSION_ID, SHEET_VALUE_ID, FILE_UPLOAD_SID),
    CONSTRAINT FK_SVFHC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

-- Alter tables

-- *** Grants ***
grant insert,select,update,delete on csrimp.sheet_value_file_hidden_cache to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_body
@../schema_body

@update_tail
