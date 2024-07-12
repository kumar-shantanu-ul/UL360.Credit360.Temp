-- Please update version.sql too -- this keeps clean builds in sync
define version=671
@update_header

insert into csr.portlet (portlet_id, name, type, default_state, script_path) values (csr.portlet_id_seq.nextval, 'Issue Dashboard', 'Clients.Jlp.Portlets.IssueDashboard', null, '/jlp/site/portlets/IssueDashboard.js');

@update_tail
