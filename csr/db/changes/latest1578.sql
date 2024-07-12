-- Please update version.sql too -- this keeps clean builds in sync
define version=1578
@update_header

INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.ISSUE2', 'myStaff', 'BOOLEAN', 'stores the last "myStaff" checkbox selection that was used in a search');

CREATE INDEX CSR.IX_USER_LINE_MANAGER ON CSR.CSR_USER(APP_SID, LINE_MANAGER_SID)
;

ALTER TABLE CSR.CSR_USER ADD CONSTRAINT FK_USER_LINE_MANAGER 
    FOREIGN KEY (APP_SID, LINE_MANAGER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1033,'Rich-text Notes','Credit360.Portlets.RichTextNote', EMPTY_CLOB(),'/csr/site/portal/portlets/RichTextNote.js');

@..\issue_pkg
@..\portlet_pkg

@..\issue_body
@..\portlet_body
@..\audit_body

@update_tail
