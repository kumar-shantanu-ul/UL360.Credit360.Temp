-- Please update version.sql too -- this keeps clean builds in sync
define version=2005
@update_header

INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.TEAMROOM', 'activeTab', 'STRING', 'stores the last active plugin tab');
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.INITIATIVE', 'activeTab', 'STRING', 'stores the last active plugin tab');

@update_tail