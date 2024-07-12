-- Please update version.sql too -- this keeps clean builds in sync
define version=2953
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.CLIENT_UTIL_SCRIPT (
    APP_SID                         NUMBER(10)     DEFAULT SYS_CONTEXT('security', 'app') NOT NULL,
    CLIENT_UTIL_SCRIPT_ID           NUMBER(10)     NOT NULL,
    UTIL_SCRIPT_NAME                VARCHAR2(255),
    DESCRIPTION                     VARCHAR2(2047),
    UTIL_SCRIPT_SP                  VARCHAR2(255),
    WIKI_ARTICLE                    VARCHAR2(10),
    CONSTRAINT PK_CLIENT_UTIL_SCRIPT PRIMARY KEY (APP_SID, CLIENT_UTIL_SCRIPT_ID)
);

CREATE TABLE CSR.CLIENT_UTIL_SCRIPT_PARAM (
    APP_SID                         NUMBER(10)      DEFAULT SYS_CONTEXT('security', 'app') NOT NULL,
    CLIENT_UTIL_SCRIPT_ID           NUMBER(10)      NOT NULL,
    PARAM_NAME                      VARCHAR2(1023)  NOT NULL,
    PARAM_HINT                      VARCHAR2(1023),
    POS                             NUMBER(2)       NOT NULL,
    PARAM_HIDDEN                    NUMBER(1)       DEFAULT 0,
    PARAM_VALUE                     VARCHAR(1024),
    CONSTRAINT PK_CLIENT_UTIL_SCRIPT_PARAM PRIMARY KEY (APP_SID, CLIENT_UTIL_SCRIPT_ID, POS),
    CONSTRAINT FK_CLIENT_UTIL_PARAM_SCRIPT FOREIGN KEY (APP_SID, CLIENT_UTIL_SCRIPT_ID) REFERENCES CSR.CLIENT_UTIL_SCRIPT(APP_SID, CLIENT_UTIL_SCRIPT_ID)
);

CREATE SEQUENCE CSR.CLIENT_UTIL_SCRIPT_ID_SEQ;

-- Alter tables
ALTER TABLE CSR.UTIL_SCRIPT_RUN_LOG
    MODIFY UTIL_SCRIPT_ID NULL;

ALTER TABLE CSR.UTIL_SCRIPT_RUN_LOG
    ADD CLIENT_UTIL_SCRIPT_ID NUMBER(10, 0);

ALTER TABLE CSR.UTIL_SCRIPT_RUN_LOG
    ADD CONSTRAINT FK_UTIL_SCRIPT_RUN_LOG_CLIENT FOREIGN KEY (APP_SID, CLIENT_UTIL_SCRIPT_ID)
    REFERENCES CSR.CLIENT_UTIL_SCRIPT(APP_SID, CLIENT_UTIL_SCRIPT_ID);

ALTER TABLE CSR.UTIL_SCRIPT_RUN_LOG
    ADD CONSTRAINT CHK_UTIL_SCRIPT_RUN_ID_NOT_NUL CHECK (
        (CLIENT_UTIL_SCRIPT_ID IS NOT NULL AND UTIL_SCRIPT_ID IS NULL) OR
        (CLIENT_UTIL_SCRIPT_ID IS NULL AND UTIL_SCRIPT_ID IS NOT NULL)
    );

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
@../util_script_pkg
@../util_script_body

@update_tail
