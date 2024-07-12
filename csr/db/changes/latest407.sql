-- Please update version.sql too -- this keeps clean builds in sync
define version=407
@update_header

UPDATE portlet SET script_path = '/csr/site/portal/Portlets/TargetDashboard.js' WHERE name = 'Target Dashboard';

@update_tail
