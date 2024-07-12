-- Please update version.sql too -- this keeps clean builds in sync
define version=955
@update_header

BEGIN
	UPDATE CSR.USER_SETTING 
	   SET DATA_TYPE = 'STRING' 
	 WHERE CATEGORY = 'CREDIT360.PORTLETS.MYSHEETS' 
	   AND SETTING IN ('toEnterStatus', 'toApproveStatus');

	UPDATE CSR.USER_SETTING_ENTRY 
	   SET VALUE = 'Red'
	 WHERE CATEGORY = 'CREDIT360.PORTLETS.MYSHEETS' 
	   AND SETTING IN ('toEnterStatus', 'toApproveStatus')
	   AND VALUE = '1';
	
	UPDATE CSR.USER_SETTING_ENTRY 
	   SET VALUE = 'Amber'
	 WHERE CATEGORY = 'CREDIT360.PORTLETS.MYSHEETS' 
	   AND SETTING IN ('toEnterStatus', 'toApproveStatus')
	   AND VALUE = '2';
	
	UPDATE CSR.USER_SETTING_ENTRY 
	   SET VALUE = 'Green'
	 WHERE CATEGORY = 'CREDIT360.PORTLETS.MYSHEETS' 
	   AND SETTING IN ('toEnterStatus', 'toApproveStatus')
	   AND VALUE = '3';

END;
/

@update_tail
