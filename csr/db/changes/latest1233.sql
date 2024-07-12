-- Please update version.sql too -- this keeps clean builds in sync
define version=1233
@update_header

INSERT INTO CSR.portlet (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (csr.portlet_id_seq.nextval, 'CT Whats Next', 'Credit360.Portlets.CarbonTrust.WhatsNext', '/csr/site/portal/portlets/ct/WhatsNext.js');

@update_tail