CREATE OR REPLACE PACKAGE CSR.system_status_pkg AS

PROCEDURE GetCalcJobs(
	out_cur							OUT	SYS_REFCURSOR
);

END system_status_pkg;
/
