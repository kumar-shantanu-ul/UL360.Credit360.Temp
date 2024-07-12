-- Please update version.sql too -- this keeps clean builds in sync
define version=214
@update_header

-- portlet tweaks
update portlet set default_state = '{"portletHeight":400}' where type='Credit360.Portlets.MyDelegations';
INSERT INTO PORTLET (PORTLET_ID, NAME, TYPE, SCRIPT_PATH) VALUES (portlet_id_seq.nextval, 'Target Dashboard', 'Credit360.Portlets.TargetDashboard', '/csr/site/portal/Credit360.Portlets.TargetDashboard.js');

@update_tail