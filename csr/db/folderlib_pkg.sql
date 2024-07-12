CREATE OR REPLACE PACKAGE CSR.FolderLib_Pkg AS

PROCEDURE GetFolderTreeWithDepth(
	in_act_id   	IN  security.security_pkg.T_ACT_ID,
	in_parent_sid	IN	security.security_pkg.T_SID_ID,
	in_fetch_depth	IN	NUMBER,
	in_hide_root	IN  NUMBER DEFAULT 1,
	out_cur			OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderTreeTextFiltered(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_additional_class IN  VARCHAR2 DEFAULT null,
	in_hide_root	IN  NUMBER DEFAULT 1,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderTreeWithSelect(
	in_act_id   	IN  security.security_pkg.T_ACT_ID,
	in_parent_sid	IN	security.security_pkg.T_SID_ID,
	in_select_sid	IN	security.security_pkg.T_SID_ID,
	in_fetch_depth	IN	NUMBER,
	in_hide_root	IN  NUMBER DEFAULT 1,
	out_cur			OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderList(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFolderListTextFiltered(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN	security.security_pkg.T_SID_ID,
	in_search_term		IN	VARCHAR2,
	in_limit			IN	NUMBER,
	in_additional_class IN  VARCHAR2 DEFAULT null,
	out_cur				OUT	security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE CreateFolder(
	in_parent_sid			IN	security.security_pkg.T_SID_ID,
	in_name					IN	security.security_pkg.T_SO_NAME,
	out_sid_id				OUT	security.security_pkg.T_SID_ID
);

PROCEDURE TrashObject(
	in_act_id   		IN  security.security_pkg.T_ACT_ID,
	in_sid_id			IN	security.security_pkg.T_SID_ID
);

END FolderLib_Pkg;
/
