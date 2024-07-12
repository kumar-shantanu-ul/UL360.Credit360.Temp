-- Please update version.sql too -- this keeps clean builds in sync
define version=1006
@update_header

BEGIN
	INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT Welcome', 'Credit360.Portlets.CarbonTrust.Welcome', '/csr/site/portal/portlets/ct/welcome.js');
END;
/

@update_tail
