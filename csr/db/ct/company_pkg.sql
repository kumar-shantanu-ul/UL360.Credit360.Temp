CREATE OR REPLACE PACKAGE ct.company_pkg AS

FUNCTION GetCompanyCurrency RETURN company.currency_id%TYPE;

PROCEDURE GetCompany(
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompany(
	in_company_sid				IN  security_pkg.T_SID_ID,
	out_cur 					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetCompany (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_fte						IN  company.fte%TYPE,
	in_turnover					IN  company.turnover%TYPE,
	in_currency_id				IN  company.currency_id%TYPE,
	in_period_id				IN  company.period_id%TYPE,
	in_business_type_id			IN  company.business_type_id%TYPE,
	in_eio_id					IN  company.eio_id%TYPE,
	in_scope_input_type_id		IN  company.scope_input_type_id%TYPE,
	in_scope_1					IN  company.scope_1%TYPE,
	in_scope_2					IN  company.scope_2%TYPE
);


PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

END company_pkg;
/
