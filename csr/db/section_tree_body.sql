CREATE OR REPLACE PACKAGE BODY CSR.section_tree_Pkg
IS

PROCEDURE GetTreeWithDepth(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_fetch_depth			IN	NUMBER,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT section_sid sid_id, parent_sid parent_sid_id, title name, LEVEL so_level,
		   CONNECT_BY_ISLEAF is_leaf, 1 is_match, title_only is_folder
		  FROM v$visible_version
		 WHERE LEVEL <= in_fetch_depth
		 START WITH module_root_sid = in_parent_sid	and parent_sid is null
		CONNECT BY PRIOR section_sid = parent_sid
		 ORDER SIBLINGS BY section_position;
END;

PROCEDURE GetTreeTextFiltered(
	in_act_id				IN  security_pkg.T_ACT_ID,
	in_parent_sid			IN	security_pkg.T_SID_ID,
	in_search_phrase		IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT vv.section_sid sid_id, vv.parent_sid parent_sid_id, vv.title name, LEVEL so_level, 
			   CONNECT_BY_ISLEAF is_leaf, NVL(tm.is_match,0) is_match
		  FROM v$visible_version vv, (
				  SELECT DISTINCT s.section_sid
					FROM v$visible_version s
					     START WITH s.section_sid IN (
							SELECT DISTINCT s2.section_sid 
							  FROM v$visible_version s2
							 WHERE LOWER(s2.title) LIKE '%'||LOWER(in_search_phrase)||'%'
					 			   START WITH s2.module_root_sid = in_parent_sid and s2.parent_sid is null
						   		   CONNECT BY PRIOR s2.section_sid = s2.parent_sid)
				 		 CONNECT BY s.section_sid = PRIOR s.parent_sid
			   ) t,(
				  SELECT DISTINCT s_tm.section_sid, 1 is_match 
				    FROM v$visible_version s_tm
				   WHERE LOWER(s_tm.title) LIKE '%'||LOWER(in_search_phrase)||'%'
		 			     START WITH s_tm.module_root_sid = in_parent_sid and s_tm.parent_sid is null
			     		 CONNECT BY PRIOR s_tm.section_sid = s_tm.parent_sid
			   ) tm
		 WHERE vv.section_sid = t.section_sid
		   AND vv.section_sid = tm.section_sid(+)
		 START WITH vv.module_root_sid = in_parent_sid
		CONNECT BY PRIOR vv.section_sid = vv.parent_sid
		 ORDER SIBLINGS BY vv.section_position;
	
END;


PROCEDURE GetList(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_limit			IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

	OPEN out_cur FOR
		SELECT vv.section_sid sid_id, vv.parent_sid parent_sid_id, vv.title name, LEVEL so_level, 
			   CONNECT_BY_ISLEAF is_leaf, 1 is_match,
			   LTRIM(SYS_CONNECT_BY_PATH(vv.title, ' > '),' > ') path
		  FROM v$visible_version vv
		 WHERE rownum <= in_limit
		       START WITH vv.module_root_sid = in_root_sid  and vv.parent_sid is null
	   		   CONNECT BY PRIOR vv.section_sid = vv.parent_sid
		 ORDER SIBLINGS BY vv.section_position;
END;


PROCEDURE GetListTextFiltered(
	in_act_id   		IN  security_pkg.T_ACT_ID,
	in_root_sid			IN	security_pkg.T_SID_ID,
	in_search_phrase	IN	VARCHAR2,
	in_limit			IN	NUMBER,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR	   
	   	SELECT vv.section_sid sid_id, vv.parent_sid parent_sid_id, vv.title name, LEVEL so_level, 
			   CONNECT_BY_ISLEAF is_leaf, 1 is_match,
			   LTRIM(SYS_CONNECT_BY_PATH(vv.title, ' > '),' > ') path
		  FROM v$visible_version vv
		 WHERE rownum <= in_limit
		   AND LOWER(vv.title) LIKE '%'||LOWER(in_search_phrase)||'%'
		       START WITH vv.module_root_sid = in_root_sid and vv.parent_sid is null
	   		   CONNECT BY PRIOR vv.section_sid = vv.parent_sid
		 ORDER SIBLINGS BY vv.section_position;
END;

END section_tree_pkg;
/
