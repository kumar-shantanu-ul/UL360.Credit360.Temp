PROMPT please enter: host

whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

BEGIN
	security.user_pkg.logonadmin('&&1');
	csr.enable_pkg.EnablePropertyDashboards;

	COMMIT;
END;
/

PROMPT ------------------------------------------------------------------------
PROMPT Now go to /csr/site/dashboard/metricDashboard/admin/dashboards.acds and
PROMPT configure the new dashboards (add at least one indicator).
PROMPT ------------------------------------------------------------------------
