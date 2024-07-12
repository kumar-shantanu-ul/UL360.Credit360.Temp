CREATE OR REPLACE PACKAGE SUPPLIER.registration_pkg
IS

-- Possible status codes:
--   0 -> This company name is not in use
--   1 -> This company name is in use, but not for this country
--   2 -> This company name is in use for this country
PROCEDURE ValidateCompanyName (
	in_company_name			IN  security_pkg.T_SO_NAME,
	in_country_code			IN  company.country_code%TYPE,
	out_result				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ValidateEmailAsUserName (
	in_email				IN  security_pkg.T_SO_NAME,
	out_used				OUT NUMBER
);

PROCEDURE RegisterUser (
	in_contact_guid			IN  contact.contact_guid%TYPE,
	in_full_name			IN  csr.csr_user.full_name%TYPE,
	in_email				IN  csr.csr_user.email%TYPE,
	in_job_title			IN  csr.csr_user.job_title%TYPE,
	in_phone_number			IN  csr.csr_user.phone_number%TYPE,
	in_password				IN  security_Pkg.T_USER_PASSWORD,
	in_company_name			IN  all_company.name%TYPE,
	in_country_code			IN  all_company.country_code%TYPE,
	in_existing_company_sid	IN  security_pkg.T_SID_ID,
	in_info_xml				IN  csr.csr_user.info_xml%TYPE,
	out_user_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE AcceptAsRegisteredUser (
	in_contact_guid			IN  contact.contact_guid%TYPE
);

PROCEDURE RejectInvitesForGuid (
	in_contact_guid			IN  contact.contact_guid%TYPE
);

END registration_pkg;
/
