-- Please update version.sql too -- this keeps clean builds in sync
define version=722
@update_header

insert into csr.portlet (portlet_id, name, type, default_state, script_path) values (csr.portlet_id_seq.nextval, 'Legislation Dashboard', 'Clients.Jlp.Portlets.LegislationDashboard', null, '/jlp/site/portlets/LegislationDashboard.js');

@update_tail
