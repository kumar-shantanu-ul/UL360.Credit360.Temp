CREATE OR REPLACE PACKAGE CSR.sqlreport_pkg
IS

/* TODO: ADD TABLE TO */

/*
	Add a SqlReport SO into the SqlReports folder so 
	we can set permissions on it for user groups
	
	PARAM: in_report_procedure	the sql procedure name including user e.g.
	csr.delegation_pkg.GetReportDelegationBlockers
*/
PROCEDURE EnableReport(
	in_report_procedure	IN	security_pkg.T_SO_NAME
);

/* Functions to check if a report can be accessed */
FUNCTION CheckAccess(
	in_report_procedure	IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN;

FUNCTION SQL_CheckAccess(
	in_report_procedure	IN	security_pkg.T_SO_NAME
) RETURN BINARY_INTEGER;

FUNCTION CheckAccess(
	in_act_Id		IN	security_pkg.T_ACT_ID,
	in_report_procedure	IN	security_pkg.T_SO_NAME
) RETURN BOOLEAN;

END;
/
