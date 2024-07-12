-- Please update version.sql too -- this keeps clean builds in sync
define version=1002
@update_header

BEGIN
	INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'Hotspot chart', 'Credit360.Portlets.CarbonTrust.HotspotChart', '/csr/site/portal/portlets/ct/hotspotChart.js');
END;
/

@update_tail
