-- Please update version.sql too -- this keeps clean builds in sync
define version=3195
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.DELETED_DELEGATION_DESCRIPTION(
    APP_SID           NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    DELEGATION_SID    NUMBER(10, 0)     NOT NULL,
    LANG              VARCHAR2(10)      NOT NULL,
    DESCRIPTION       VARCHAR2(1023)    NOT NULL,
    CONSTRAINT PK_DEL_DELEGATION_DESCRIPTION PRIMARY KEY (APP_SID, DELEGATION_SID, LANG)
)
;

ALTER TABLE CSR.DELETED_DELEGATION_DESCRIPTION ADD CONSTRAINT FK_DEL_DELEGATION_DESCRIPTION
    FOREIGN KEY (APP_SID, DELEGATION_SID)
    REFERENCES CSR.DELETED_DELEGATION(APP_SID, DELEGATION_SID) ON DELETE CASCADE
;

CREATE INDEX CSR.IX_DELETED_DELEG_DESC_DD ON CSR.DELETED_DELEGATION_DESCRIPTION(APP_SID, DELEGATION_SID)
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

@../delegation_body

@update_tail
