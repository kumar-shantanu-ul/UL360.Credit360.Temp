CREATE OR REPLACE PACKAGE CSR.permission_pkg AS

PROCEDURE GetSections(
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithDepth(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTextFiltered(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithSelect(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_select_sid					IN	security.security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetList(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTextFiltered(
	in_parent_sid					IN	security.security_pkg.T_SID_ID,
	in_search_term					IN	VARCHAR2,
	in_limit						IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

END;
/
