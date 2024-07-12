-- Please update version.sql too -- this keeps clean builds in sync
define version=627
@update_header


-- Replace old style Actions and Events with the new style Messaging stuff
INSERT INTO csr.portlet (portlet_id, name, type, script_path) VALUES (portlet_id_seq.nextval, 'Supply Chain Required Actions', 'Credit360.Portlets.Chain.RequiredActions', '/csr/site/portal/Portlets/Chain/RequiredActions.js');
INSERT INTO csr.portlet (portlet_id, name, type, script_path) VALUES (portlet_id_seq.nextval, 'Supply Chain Recent Activity', 'Credit360.Portlets.Chain.RecentActivity', '/csr/site/portal/Portlets/Chain/RecentActivity.js');

UPDATE csr.customer_portlet
   SET portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.RequiredActions')
 WHERE portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.Actions');

UPDATE csr.customer_portlet
   SET portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.RecentActivity')
 WHERE portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.Events');

UPDATE csr.tab_portlet
   SET portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.RequiredActions')
 WHERE portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.Actions');

UPDATE csr.tab_portlet
   SET portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.RecentActivity')
 WHERE portlet_id = (SELECT portlet_id FROM portlet WHERE type='Credit360.Portlets.Chain.Events');


commit;

@update_tail
