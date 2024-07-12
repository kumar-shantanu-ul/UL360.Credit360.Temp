-- Please update version.sql too -- this keeps clean builds in sync
define version=292
@update_header


INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) values (portlet_id_seq.nextval, 'Issues', 'Credit360.Portlets.Issue', '/csr/site/portal/Credit360.Portlets.Issue.js');

@..\issue_pkg
@..\issue_body

@update_tail
