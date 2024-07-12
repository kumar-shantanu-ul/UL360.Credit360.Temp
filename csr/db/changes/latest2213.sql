-- Please update version.sql too -- this keeps clean builds in sync
define version=2213
@update_header

BEGIN
	INSERT INTO csr.user_setting (category, setting, description, data_type)
	VALUES ('CREDIT360.PROPERTY', 'activeTab', 'stores the last active plugin tab', 'STRING');
END;
/

@update_tail
