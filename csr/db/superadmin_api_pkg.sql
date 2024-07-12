CREATE OR REPLACE PACKAGE csr.superadmin_api_pkg AS

PROCEDURE CreateSuperAdmin(
	in_user_name			csr_user.user_name%TYPE,
	in_full_name			csr_user.full_name%TYPE,
	in_friendly_name		csr_user.friendly_name%TYPE,
	in_email				csr_user.email%TYPE
);

PROCEDURE GetPasswordResetACT(
	in_user_name			IN	csr_user.user_name%TYPE,
	in_host					IN  security.website.website_name%TYPE,
	out_user_act			OUT	security.security_pkg.T_ACT_ID
);

PROCEDURE DisableSuperAdmin(
	in_user_name			csr_user.user_name%TYPE
);

END;
/