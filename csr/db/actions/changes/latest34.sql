-- Please update version.sql too -- this keeps clean builds in sync
define version=34
@update_header

CREATE GLOBAL TEMPORARY TABLE INITIATIVE_PROPERTIES
(
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	REGION_DESC			VARCHAR2(1024)	NOT NULL,
	COUNTRY_SID			NUMBER(10, 0)	NOT NULL,
	COUNTRY_DESC		VARCHAR2(1024)	NOT NULL,
	PROPERTY_SID		NUMBER(10, 0)	NOT NULL,
	PROPERTY_DESC		VARCHAR2(1024)	NOT NULL
)
ON COMMIT DELETE ROWS;

-- run as csr (could grant execute on 
-- portlet_id_seq but this is easier)
PROMPT Enter connection (e.g. ASPEN)
connect csr/csr@&&1

insert into csr.portlet (portlet_id, name, type, default_state, script_path)
values (csr.portlet_id_seq.nextval, 'Action Tasks', 'Credit360.Portlets.ActionsMyTasks', null, '/csr/site/portal/Credit360.Portlets.ActionsMyTasks.js');

insert into csr.customer_portlet (portlet_id, default_state, app_sid)
	select csr.portlet_id_seq.currval, empty_clob(), app_sid
	  from csr.customer
	 where host='rbsenv.credit360.com';

COMMIT;

grant execute on csr.stragg to actions;

-- re-connect to actions to run @update_tail
connect actions/actions@&&1

@update_tail
