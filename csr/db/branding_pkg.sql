CREATE OR REPLACE PACKAGE csr.branding_pkg AS

PROCEDURE GetAllBrandings(
	out_all_brandings		OUT	SYS_REFCURSOR
);

PROCEDURE GetAvailableBrandings(
	out_branding_availability		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_ChangeBranding(
	in_client_name					IN	csr.branding.client_folder_name%TYPE
);

PROCEDURE ChangeBranding(
	in_client_name					IN	csr.branding.client_folder_name%TYPE
);

FUNCTION CanLockBrandings
	RETURN BOOLEAN;

FUNCTION CanLockBrandingsReturnLong
	RETURN NUMBER;

FUNCTION CanChangeBrandings
	RETURN BOOLEAN;

FUNCTION CanChangeBrandingsReturnLong
	RETURN NUMBER;

FUNCTION IsBrandingLocked
	RETURN BOOLEAN;

FUNCTION GetCurrentClientFolderName
  RETURN VARCHAR2;

PROCEDURE GetLockInfo(
	out_lock_info					OUT	SYS_REFCURSOR
);

PROCEDURE ToggleBrandingLock(
	in_lock_duration_hrs			IN 	NUMBER	DEFAULT 1
);

FUNCTION GetBrandingNameFromWebPath(
	in_web_path						IN	security.security_pkg.T_SO_ATTRIBUTE_STRING
) RETURN VARCHAR2;

FUNCTION IsBrandingAvailable(
	in_branding						IN	csr.branding.client_folder_name%TYPE
) RETURN BOOLEAN;

FUNCTION GetBrandingAttribute(
	in_attribute_name				IN	VARCHAR2
) RETURN VARCHAR2;

PROCEDURE SetBrandingAttribute(
	in_attribute_name				IN	VARCHAR2,
	in_attribute_value				IN	VARCHAR2
);

PROCEDURE AddBranding(
	in_client_folder_name			IN	csr.branding.client_folder_name%TYPE,
	in_branding_title				IN	csr.branding.branding_title%TYPE,
	in_author						IN	csr.branding.author%TYPE DEFAULT NULL
);

PROCEDURE AllowBranding(
	in_client_folder_name			IN	csr.branding.client_folder_name%TYPE
);

PROCEDURE AllowBranding(
	in_app_sid						IN	security.security_pkg.T_SID_ID,
	in_client_folder_name			IN	csr.branding.client_folder_name%TYPE
);

FUNCTION IsBrandingServiceEnabled
	RETURN BOOLEAN;
	
FUNCTION Sql_IsBrandingServiceEnabled
	RETURN NUMBER;

PROCEDURE SetMegaMenu(
	in_value						IN  NUMBER
);

FUNCTION IsMegaMenuEnabled
	RETURN NUMBER;

FUNCTION IsMobileBrandingEnabled RETURN NUMBER;

PROCEDURE EnableMobileBranding(
	in_value						IN  NUMBER
);

FUNCTION IsUlDesignSystemEnabled RETURN NUMBER;

PROCEDURE EnableUlDesignSystem(
	in_value						IN  NUMBER
);

FUNCTION IsBrandingServiceEnabled_NEW RETURN NUMBER;

PROCEDURE SetBrandingServiceEnabled(
	in_value						IN  NUMBER
);

END Branding_Pkg;
/
