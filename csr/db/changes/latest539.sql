-- Please update version.sql too -- this keeps clean builds in sync
define version=539
@update_header

INSERT INTO CSR.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Supply Chain News Flash', 'Credit360.Portlets.Chain.NewsFlash', '/csr/site/portal/Portlets/Chain/NewsFlash.js');
INSERT INTO CSR.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Supply Chain Summary', 'Credit360.Portlets.Chain.InvitationSummary', '/csr/site/portal/Portlets/Chain/InvitationSummary.js');
INSERT INTO CSR.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Supply Chain Required Actions', 'Credit360.Portlets.Chain.Actions', '/csr/site/portal/Portlets/Chain/Actions.js');
INSERT INTO CSR.PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Supply Chain Events', 'Credit360.Portlets.Chain.Events', '/csr/site/portal/Portlets/Chain/Events.js');

@update_tail
