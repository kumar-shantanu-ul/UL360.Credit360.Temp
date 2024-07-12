-- Please update version.sql too -- this keeps clean builds in sync
define version=1010
@update_header

BEGIn
	INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT Chart Picker', 'Credit360.Portlets.CarbonTrust.ChartPicker', '/csr/site/portal/portlets/ct/chartPicker.js');
END;
/

@update_tail
