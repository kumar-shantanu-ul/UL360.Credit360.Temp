CREATE OR REPLACE PACKAGE SUPPLIER.chain_company_pkg
IS

PROCEDURE SearchCompanyUsersAndContacts (
	in_company_sid		IN  security_pkg.T_SID_ID,
	in_search_term		IN  varchar2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateCompany (
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE CreateCompany (
	in_name					IN  company.name%TYPE,	
	in_addr1				IN  company.address_1%TYPE,
	in_addr2				IN  company.address_2%TYPE,
	in_addr3				IN  company.address_3%TYPE,
	in_addr4				IN  company.address_4%TYPE,	 
	in_town					IN  company.town%TYPE,
	in_state				IN  company.state%TYPE,
	in_postcode				IN  company.postcode%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
);

END chain_company_pkg;
/

