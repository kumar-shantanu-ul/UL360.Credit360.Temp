CREATE OR REPLACE PACKAGE CSR.division_pkg AS

FUNCTION GetRootDivisionSid
RETURN security_pkg.T_SID_ID;

PROCEDURE GetRegion(
	in_division_id		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDivisions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearDivisions(
	in_division_ids		IN security_pkg.T_SID_IDS
);

PROCEDURE GetNewDivisionId(
	out_division_id		OUT security_pkg.T_SID_ID
);

PROCEDURE AddDivision(
	in_division_id		IN security_pkg.T_SID_ID,
	in_name				IN VARCHAR2,
	in_active			IN NUMBER
);

PROCEDURE SetDivision(
	in_division_id		IN security_pkg.T_SID_ID,
	in_name				IN VARCHAR2,
	in_active			IN NUMBER
);

PROCEDURE AllowDeleteDivision(
	in_division_id		IN security_pkg.T_SID_ID,
	out_count			OUT NUMBER
);

PROCEDURE SetVisibleDivisions(
	in_division_ids		IN security_pkg.T_SID_IDS
);

-- -----------------------------------------------------------
-- Properties
-- -----------------------------------------------------------

PROCEDURE GetProperties(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetProperty(
	in_region_sid		IN security_pkg.T_SID_ID,
	property_cur		OUT	SYS_REFCURSOR,
	division_cur		OUT	SYS_REFCURSOR
);

PROCEDURE ExistProperty(
	in_region_sid		IN security_pkg.T_SID_ID,
	out_number			OUT NUMBER
);

PROCEDURE DeleteProperty(
	in_region_sid		IN security_pkg.T_SID_ID
);

PROCEDURE SetProperty(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_street_addr_1	IN	property.street_addr_2%TYPE	DEFAULT NULL, 
	in_street_addr_2	IN	property.street_addr_2%TYPE DEFAULT NULL, 
	in_city				IN	property.city%TYPE DEFAULT NULL, 
	in_state			IN	property.state%TYPE DEFAULT NULL,	 
	in_postcode			IN	property.postcode%TYPE DEFAULT NULL
);

-- -----------------------------------------------------------
-- Properties Divisions
-- -----------------------------------------------------------

PROCEDURE ClearPropertyDivisions(
	in_region_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllPropertyDivisions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllPropDivisionsInPeriod(
	in_start_dtm		IN property_division.end_dtm%TYPE,
	in_end_dtm			IN property_division.start_dtm%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPropertyDivisions(
	in_region_sid		IN security_pkg.T_SID_ID,
	in_start_dtm		IN property_division.end_dtm%TYPE,
	in_end_dtm			IN property_division.start_dtm%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION AddPropertyDivision(
	in_region_sid		IN security_pkg.T_SID_ID,
	in_division_id		IN security_pkg.T_SID_ID,
	in_ownership		IN NUMBER,
	in_area				IN NUMBER,
	in_start_dtm		IN property_division.start_dtm%TYPE,
	in_end_dtm			IN property_division.end_dtm%TYPE
) RETURN security_Pkg.T_SID_ID;

PROCEDURE RemovePropertyFromDivision(
	in_region_sid		IN security_pkg.T_SID_ID,
	in_division_id		IN security_pkg.T_SID_ID
);

END;
/