-- Please update version.sql too -- this keeps clean builds in sync
define version=344
@update_header

INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Supply Chain Charts', 'Credit360.Portlets.Chain.Charts', '/csr/site/portal/Credit360.Portlets.Chain.Charts.js');

@update_tail
