-- Please update version.sql too -- this keeps clean builds in sync
define version=3411
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.TRANSLATION_SET_INCLUDE_PATH(
    APPLICATION_SID_ID    NUMBER(10, 0)    NOT NULL,
    APP_PATH_SID_ID       NUMBER(10, 0)    NOT NULL,
    APP_PATH              VARCHAR2(1000)   NOT NULL,
    CONSTRAINT PK_TRANSLATION_SET_INCLUDE_PATH PRIMARY KEY (APPLICATION_SID_ID, APP_PATH_SID_ID)
)
;


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

@../../../security/db/oracle/securableobject_pkg
@../../../security/db/oracle/securableobject_body

@../schema_body
@../csrimp/imp_body

@update_tail
