CREATE OR REPLACE PACKAGE CSR.section_tree_pkg
IS

PROCEDURE GetTreeWithDepth(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_fetch_depth			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTreeTextFiltered(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_search_phrase		IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END section_tree_pkg;
/
