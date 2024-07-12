-- Please update version.sql too -- this keeps clean builds in sync
define version=1001
@update_header

BEGIN
	INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT Breakdown picker', 'Credit360.Portlets.CarbonTrust.BreakdownPicker', '/csr/site/portal/portlets/ct/breakdownPicker.js');
	INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'Fusion chart', 'Credit360.Portlets.FusionChart', '/csr/site/portal/portlets/FusionChart.js');
	INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT Advice', 'Credit360.Portlets.CarbonTrust.Advice', '/csr/site/portal/portlets/ct/advice.js');
END;
/

@update_tail
