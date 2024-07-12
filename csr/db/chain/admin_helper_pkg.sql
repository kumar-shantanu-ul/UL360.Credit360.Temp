CREATE OR REPLACE PACKAGE CHAIN.admin_helper_pkg
IS

/* ***************************************
	ALL FUNCTIONS IN THIS PACKAGE SHOULD ENFORCE THE FOLLOWING CHECK - AS THEY EXPOSE THINGS ONLY SUPERADMINS SHOULD BE ALLOWED TO SEE

	IF NOT (security.user_pkg.IsSuperAdmin() = 1) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'XXX can only be run as CSR Super Admin');
	END IF;	
	
**************************************** */

PROCEDURE GetInviteFromGUID (
	in_guid							IN	invitation.guid%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCustomerOptions (
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveCustomerOption(
	in_col_name						IN	VARCHAR2,
	in_val							IN	VARCHAR2,
	in_data_type					IN	VARCHAR2
);

END admin_helper_pkg;
/