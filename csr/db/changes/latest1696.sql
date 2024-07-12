-- Please update version.sql too -- this keeps clean builds in sync
define version=1696
@update_header
	
INSERT INTO csr.user_setting VALUES 
('CREDIT360.PORTLETS.DELEGATIONPERIODPICKER', 'periods', 'Stores delegation periods', 'STRING'); 

Insert into csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (884,'Delegation period picker','Credit360.Portlets.DelegationPeriodPicker',EMPTY_CLOB(),'/csr/site/portal/portlets/DelegationPeriodPicker.js');

@update_tail
