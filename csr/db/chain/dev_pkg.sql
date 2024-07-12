CREATE OR REPLACE PACKAGE  CHAIN.dev_pkg
IS

PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE
);

PROCEDURE SetCompany(
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE
);


PROCEDURE GetOpenInvitations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOpenActiveActivations (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCompanies (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteCompany (
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE GenerateSuppliers (
	in_company							VARCHAR2,
	in_questionnaire_class				VARCHAR2,
	in_from_user						VARCHAR2,
	in_country							VARCHAR2,
	in_base_supplier_name				VARCHAR2,
	in_start_index						NUMBER,
	in_count							NUMBER,
	in_before_invite_sent_callback		VARCHAR2 DEFAULT NULL, -- procedure that takes paremeters of (from_company_sid, from_user_sid, to_company_sid, to_user_sid)
	in_invite_sent_callback				VARCHAR2 DEFAULT NULL, -- procedure that takes paremeters of (from_company_sid, from_user_sid, to_company_sid, to_user_sid)
	in_invite_accepted_callback			VARCHAR2 DEFAULT NULL,  -- procedure that takes paremeters of (purchaser_company_sid, supplier_company_sid, supplier_user_sid)
	in_on_behalf_of						NUMBER DEFAULT NULL
);

END dev_pkg;
/

