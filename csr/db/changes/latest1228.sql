-- Please update version.sql too -- this keeps clean builds in sync
define version=1228
@update_header

INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT Flash Map', 'Credit360.Portlets.CarbonTrust.FlashMap', '/csr/site/portal/portlets/ct/FlashMap.js');

@update_tail