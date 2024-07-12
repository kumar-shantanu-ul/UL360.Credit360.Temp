CREATE OR REPLACE PACKAGE CSR.var_expl_pkg AS

PROCEDURE GetGroups(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetGroupMembers(
	in_var_expl_group_id			IN	var_expl.var_expl_group_id%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE CreateGroup(
	in_label						IN	var_expl_group.var_expl_group_id%TYPE,
	out_var_expl_group_id			OUT	var_expl_group.var_expl_group_id%TYPE
);

PROCEDURE SetGroupLabel(
	in_var_expl_group_id			IN	var_expl_group.var_expl_group_id%TYPE,
	in_label						IN	var_expl_group.var_expl_group_id%TYPE
);

PROCEDURE SetGroupMembers(
	in_var_expl_group_id			IN	var_expl.var_expl_group_id%TYPE,
	in_var_expl_ids					IN	security_pkg.T_SID_IDS,
	in_labels						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_requires_note				IN	security_pkg.T_SID_IDS,
	out_cur							OUT SYS_REFCURSOR
);

END var_expl_pkg;
/
