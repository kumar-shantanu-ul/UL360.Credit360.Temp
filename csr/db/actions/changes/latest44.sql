-- Please update version.sql too -- this keeps clean builds in sync
define version=44
@update_header

-- run as csr
PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

insert into csr.portlet (portlet_id, name, type, default_state, script_path)
values (csr.portlet_id_seq.nextval, 'Gantt Chart', 'Credit360.Portlets.GanttChart', null, '/csr/site/portal/Credit360.Portlets.GanttChart.js');

insert into csr.customer_portlet (portlet_id, default_state, app_sid)
	select csr.portlet_id_seq.currval, empty_clob(), app_sid
	  from csr.customer
	 where host='rbsinitiatives.credit360.com';

COMMIT;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail
