-- Please update version.sql too -- this keeps clean builds in sync
define version=622
@update_header

insert into csr.portlet (portlet_id, name, type, default_state, script_path)
values (portlet_id_seq.nextval, 'Logging Form', 'Credit360.Portlets.LoggingForm', null, '/csr/site/portal/Portlets/LoggingForm.js');

@update_tail
