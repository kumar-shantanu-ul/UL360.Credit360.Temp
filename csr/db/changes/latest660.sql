-- Please update version.sql too -- this keeps clean builds in sync
define version=660
@update_header

INSERT INTO csr.portlet (portlet_id, name, type, script_path) VALUES (csr.portlet_id_seq.nextval, 'Task Summary', 'Credit360.Portlets.Chain.TaskSummary', '/csr/site/portal/Portlets/Chain/TaskSummary.js');

@../portlet_pkg
@../portlet_body

@update_tail
