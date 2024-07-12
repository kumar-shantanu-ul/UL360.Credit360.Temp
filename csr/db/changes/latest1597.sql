-- Please update version.sql too -- this keeps clean builds in sync
define version=1597
@update_header

CREATE TABLE CSR.INCIDENT_TYPE(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TAB_SID             NUMBER(10, 0)    NOT NULL,
    GROUP_KEY           VARCHAR(255)     DEFAULT 'main' NOT NULL,
    LABEL               VARCHAR2(500)    NOT NULL,
    BASE_CSS_CLASS      VARCHAR2(255)    NOT NULL,
    POS                 NUMBER(10)       DEFAULT 0 NOT NULL,
    LIST_URL            VARCHAR2(2000)    NOT NULL,
    EDIT_URL            VARCHAR2(2000)    NOT NULL,
    NEW_CASE_URL        VARCHAR2(2000),
    CONSTRAINT PK_INCIDENT_TYPE PRIMARY KEY (APP_SID, TAB_SID)
);


-- add to cross_schema_constraints
ALTER TABLE CSR.INCIDENT_TYPE ADD CONSTRAINT FK_INC_TYPE_CMS_TAB
    FOREIGN KEY (APP_SID, TAB_SID)
    REFERENCES CMS.TAB(APP_SID, TAB_SID) ON DELETE CASCADE;

-- TODO: add to RLS

CREATE OR REPLACE PACKAGE CSR.incident_pkg
AS
END;
/


grant select on csr.role to cms;
GRANT EXECUTE ON csr.incident_pkg TO WEB_USER;

@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body
@..\incident_pkg
@..\incident_body



@update_tail