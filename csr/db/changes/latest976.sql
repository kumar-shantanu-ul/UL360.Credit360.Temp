-- Please update version.sql too -- this keeps clean builds in sync
define version=976
@update_header

BEGIN
	
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.REGIONDROPDOWN', 'lastRegionComboValue', 'STRING', 'stores the last region selected');

END;
/

@update_tail
