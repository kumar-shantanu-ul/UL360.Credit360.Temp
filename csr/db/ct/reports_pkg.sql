CREATE OR REPLACE PACKAGE ct.reports_pkg AS

PROCEDURE PSItemReport(
	out_result_cur					OUT	security_pkg.T_OUTPUT_CUR
);

END reports_pkg;
/
