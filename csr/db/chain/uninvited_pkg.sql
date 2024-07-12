CREATE OR REPLACE PACKAGE  CHAIN.uninvited_pkg
IS
-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);
-- END Securable object callbacks

FUNCTION IsUninvitedSupplier (
	in_company_sid					IN  security_pkg.T_SID_ID,
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsUninvitedSupplier (
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

FUNCTION IsUninvitedSupplierRetNum (
	in_uninvited_supplier_sid		IN  security_pkg.T_SID_ID
) RETURN NUMBER;

FUNCTION SupplierExists (
	in_company_name			IN  company.name%TYPE,
	in_country_code			IN  company.country_code%TYPE, 
	in_supp_rel_code		IN 	supplier_relationship.supp_rel_code%TYPE
) RETURN NUMBER;


PROCEDURE SearchUninvited (
	in_search					IN	VARCHAR2,
	in_start					IN	NUMBER,
	in_page_size				IN	NUMBER,
	out_row_count				OUT	INTEGER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE MigrateUninvitedToCompany (
	in_uninvited_supplier_sid	IN	security_pkg.T_SID_ID,
	in_created_as_company_sid	IN	security_pkg.T_SID_ID, 
	in_supp_rel_code			IN  supplier_relationship.supp_rel_code%TYPE
);

PROCEDURE CreateUninvited (
	in_name						IN	uninvited_supplier.name%TYPE,
	in_country_code				IN	uninvited_supplier.country_code%TYPE,
	in_supp_rel_code		IN  uninvited_supplier.supp_rel_code%TYPE,
	out_uninvited_supplier_sid	OUT security_pkg.T_SID_ID
);

PROCEDURE SearchSuppliers ( 
	in_page   				IN  number,
	in_page_size    		IN  number,
	in_search_term  		IN  varchar2,
	in_only_active			IN  number,
	out_count_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur			OUT	security_pkg.T_OUTPUT_CUR	
);

FUNCTION HasUninvitedSupsWithComponents (
	in_company_sid					IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;


END uninvited_pkg;
/