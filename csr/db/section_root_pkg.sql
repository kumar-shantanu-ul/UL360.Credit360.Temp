CREATE OR REPLACE PACKAGE CSR.section_root_pkg
IS

/* The section is not checked out by anyone and an 
   opration requiring a check out was requested */
ERR_FLOW_MISMATCH			CONSTANT NUMBER := -20501;
FLOW_MISMATCH				EXCEPTION;
PRAGMA EXCEPTION_INIT(FLOW_MISMATCH, -20501);

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
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_section_sid		IN security_pkg.T_SID_ID
);

PROCEDURE CreateRoot(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid_id		IN	security_pkg.T_SID_ID,
	in_name				IN	security_pkg.T_SO_NAME,
	in_flow_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_region_sid	IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_parent_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_default_start	IN	DATE DEFAULT NULL,
	in_default_end		IN	DATE DEFAULT NULL,
	out_sid_id			OUT security_pkg.T_SID_ID
); 

PROCEDURE CloneRoot(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid_id			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_new_name				IN	security_pkg.T_SO_NAME,
	in_flow_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_include_responses	IN	NUMBER DEFAULT 1,
	in_incr_due_dates		IN	NUMBER DEFAULT 0,
	in_include_routes		IN	NUMBER DEFAULT 0,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	out_sid_id				OUT security_pkg.T_SID_ID
);

PROCEDURE CloneRoot(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid_id			IN	security_pkg.T_SID_ID,
	in_module_root_sid		IN	security_pkg.T_SID_ID,
	in_new_name				IN	security_pkg.T_SO_NAME,
	in_flow_sid				IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_flow_region_sid		IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_include_responses	IN	NUMBER DEFAULT 1,
	in_incr_due_dates		IN	NUMBER DEFAULT 0,
	in_include_routes		IN	NUMBER DEFAULT 0,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_default_start		IN	DATE,
	in_default_end			IN	DATE,
	out_sid_id				OUT security_pkg.T_SID_ID
);

PROCEDURE GetModuleByName(
	in_name				IN section_module.label%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetModuleBySid(
	in_module_sid		IN security_pkg.T_SID_ID, 
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetModuleBySidWithPerm(
	in_module_sid			IN security.security_pkg.T_SID_ID,
	in_permission_set		IN security.security_pkg.T_PERMISSION,
	out_cur					OUT SYS_REFCURSOR
);

FUNCTION GetRootSidFromName(
	in_label			IN	security_pkg.T_SO_NAME
) RETURN NUMBER;

PROCEDURE GetModules(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid  		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetModules2(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid  		IN	security_pkg.T_SID_ID,
	in_folder_sid		IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetModuleActivity(
	in_module_sid		IN security_pkg.T_SID_ID,
	in_active			IN NUMBER
);

PROCEDURE SetModuleAttribs(
	in_module_sid		IN security_pkg.T_SID_ID,
	in_label			IN section_module.label%TYPE,
	in_reminder_offset	IN section_module.reminder_offset%TYPE,
	in_show_fact_icon	IN NUMBER DEFAULT 0
);

FUNCTION GetModulesRoot(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid  		IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE SetPreviousModuleByName(
	in_module_root_sid		IN	section_module.module_root_sid%TYPE,
	in_previous_label		IN	section_module.label%TYPE
);

PROCEDURE GetModuleBySectionSid(
	in_section_sid			IN security_pkg.T_SID_ID, 
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetTreeWithDepth(
	in_act_id						IN  security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithSelect(
	in_act_id						IN  security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTextFiltered(
	in_act_id						IN  security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTextFiltered(
	in_act_id						IN  security.security_pkg.T_ACT_ID,
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

END section_root_pkg;
/
