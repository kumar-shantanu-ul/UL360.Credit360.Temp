CREATE OR REPLACE PACKAGE SUPPLIER.supplier_user_pkg
IS

ERR_USER_IS_PROVIDER		CONSTANT NUMBER := -20225;
USER_IS_PROVIDER		EXCEPTION;
PRAGMA EXCEPTION_INIT(USER_IS_PROVIDER, -20225);

ERR_USER_IS_APPROVER		CONSTANT NUMBER := -20226;
USER_IS_APPROVER			EXCEPTION;
PRAGMA EXCEPTION_INIT(USER_IS_APPROVER, -20226);

ERR_USER_HAS_NO_COMPANY		CONSTANT NUMBER := -20227;
USER_HAS_NO_COMPANY			EXCEPTION;
PRAGMA EXCEPTION_INIT(USER_HAS_NO_COMPANY, -20227);

-- security interface procs
PROCEDURE CreateObject(
	in_act 				IN	security_pkg.T_ACT_ID,
	in_sid_id			IN	security_pkg.T_SID_ID,
	in_class_id			IN	security_pkg.T_CLASS_ID,
	in_name				IN	security_pkg.T_SO_NAME,
	in_parent_sid_id	IN  security_pkg.T_SID_ID);

PROCEDURE RenameObject(
	in_act 		IN	security_pkg.T_ACT_ID,
	in_sid_id 	IN	security_pkg.T_SID_ID,
	in_new_name IN	security_pkg.T_SO_NAME);

PROCEDURE DeleteObject(
	in_act 		IN	security_pkg.T_ACT_ID,
	in_sid_id 	IN	security_pkg.T_SID_ID);

PROCEDURE MoveObject(
	in_act 					IN	security_pkg.T_ACT_ID,
	in_sid_id 				IN	security_pkg.T_SID_ID,
	in_new_parent_sid_id 	IN	security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN	security_pkg.T_SID_ID
);

PROCEDURE Logoff(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_sid_id				IN 	security_pkg.T_SID_ID
);

PROCEDURE Logon(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_sid_id				IN	security_pkg.T_SID_ID,
	in_act_timeout			IN	security_pkg.T_ACT_TIMEOUT,
	in_logon_type			IN	security_pkg.T_LOGON_TYPE
);


PROCEDURE LogonFailed(
	in_sid_id				IN security_pkg.T_SID_ID,
	in_error_code			IN NUMBER,
	in_message			    IN VARCHAR2
);

PROCEDURE GetAccountPolicy(
	in_sid_id				IN	security_pkg.T_SID_ID,
	out_policy_sid			OUT security_pkg.T_SID_ID
);


-- main code
PROCEDURE UpdateUserCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_new_company_sid		IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE ClearUserCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE DeleteMultipleSupplierUsers(
	in_act_id				IN security_pkg.T_ACT_ID,	
	in_user_sids			IN security_pkg.T_SID_IDS,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteSupplierUser(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_user_sid				IN security_pkg.T_SID_ID
);

PROCEDURE SearchSupplierUser(
    in_act_id       	IN  security_pkg.T_ACT_ID,
	in_app_sid 	IN  security_pkg.T_SID_ID,	 
	in_group_sid		IN 	security_pkg.T_SID_ID, 
	in_filter_name		IN	csr.csr_user.full_name%TYPE,
	in_company_sid		IN 	security_pkg.T_SID_ID,	
	in_excluded_users	IN 	security_pkg.T_SID_IDS,
	in_work_to_do		IN	NUMBER, 
	in_internal_comp_only IN NUMBER,
	in_order_by 		IN	VARCHAR2, 
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchSupplierUserForExport(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,	 
	in_group_sid	IN 	security_pkg.T_SID_ID, 
	in_filter_name	IN	csr.csr_user.full_name%TYPE,
	in_work_to_do	IN	NUMBER,
	in_order_by 	IN	VARCHAR2, 
	out_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCompany(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

-- Check if the user passed in has approver permission 
-- (all admins are approvers too)
FUNCTION IsUserApproverRetNum(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_app_sid			IN	security_pkg.T_SID_ID
) RETURN NUMBER;

-- Check if the user passed in has approver permission 
-- (all admins are approvers too)
FUNCTION IsUserApprover(
    in_act_id				IN	security_Pkg.T_ACT_ID,
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_app_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN;

END supplier_user_pkg;
/

