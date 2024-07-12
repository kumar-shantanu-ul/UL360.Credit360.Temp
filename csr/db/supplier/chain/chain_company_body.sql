CREATE OR REPLACE PACKAGE BODY SUPPLIER.chain_company_pkg
IS

PROCEDURE CreateCompany (
	in_name					IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE,
	out_company_sid			OUT security_pkg.T_SID_ID
)
AS
BEGIN
	CreateCompany(in_name, null, null, null, null, null, null, null, in_country_code, out_company_sid);
END;

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
)
AS
BEGIN
	company_pkg.CreateCompany(
		security_pkg.GetAct,
		security_pkg.GetApp,
		in_name,	
		in_addr1,
		in_addr2,
		in_addr3,
		in_addr4,
		in_town,
		in_state,
		in_postcode,
		null, -- company phone 
		null, -- company phone 
		null, -- company fax  
		1, -- internal_supplier
		in_country_code,
		out_company_sid
	);
	
	company_group_pkg.CreateGroups(out_company_sid);
END;

PROCEDURE SearchCompanyUsersAndContacts (
	in_company_sid		IN  security_pkg.T_SID_ID,
	in_search_term		IN  varchar2,
	out_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_search			VARCHAR2(1024) DEFAULT '%' || LOWER(in_search_term) || '%';
BEGIN
	
	-- check read permission on companies folder in security - only read permission as the point is every normal supplier user should be able to do this
	IF NOT security_pkg.IsAccessAllowedSID(
		security_pkg.GetAct(), 
		securableobject_pkg.GetSIDFromPath(security_pkg.GetAct(), security_pkg.GetApp(), 'Supplier/Companies'), 
		security_pkg.PERMISSION_READ
	) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading companies container');
	END IF;

	
	OPEN out_cur FOR
		SELECT * FROM (
			SELECT null csr_user_sid, contact_id, full_name, email, job_title, phone_number
			  FROM v$contact
			 WHERE existing_company_sid = in_company_sid
			   AND existing_user_sid is null
			   AND owner_company_sid = company_pkg.GetCompany
			   AND app_sid = security_pkg.GetApp
		     UNION 
			SELECT csr_user_sid, null contact_id, full_name, email, job_title, phone_number
			  FROM v$chain_user
			 WHERE app_sid = security_pkg.GetApp
			   AND company_sid = in_company_sid
		) 
		 WHERE (	LOWER(full_name) LIKE v_search
				 OR LOWER(job_title) LIKE v_search
				 OR LOWER(email) LIKE v_search
			   )
		 ORDER BY LOWER(full_name);
END;

END chain_company_pkg;
/

