CREATE OR REPLACE PACKAGE BODY CSR.Tree_Pkg IS

PROCEDURE GetRouteUpTree(
    in_act_id       IN  security_pkg.T_ACT_ID,
    in_start_sid 	IN  security_pkg.T_SID_ID,
    in_top_sid 		IN  security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	OPEN out_cur FOR
		  SELECT c.sid_id, c.parent_sid_id, c.NAME, class_id, Class_Pkg.GetClassName(class_id) class_name, GetAttributeList(c.sid_id, Class_Pkg.GetClassName(class_id)) attribute_list, lvl,
		  	(SELECT COUNT(*) FROM security.securable_object WHERE parent_sid_id = c.sid_id) children
		    FROM
			(SELECT sid_id, LEVEL lvl FROM SECURITY.SECURABLE_OBJECT so
				START WITH sid_id =in_start_sid CONNECT BY PRIOR parent_sid_id = sid_id
				AND PRIOR sid_id!=in_top_sid)p,
		  	TABLE (Securableobject_Pkg.GetChildrenAsTable(in_act_id, p.sid_id))c
		  ORDER BY lvl DESC;
END;


FUNCTION GetAttributeList(
    in_sid_id		IN security_pkg.T_SID_ID,
	in_class_name	IN security_pkg.T_SO_NAME
) RETURN VARCHAR2
AS
	CURSOR c_ind IS
		SELECT NVL(i.description, i.NAME) description, m.NAME measure_name, i.measure_sid, i.active, i.pos, i.ind_type,
			   i.format_mask, i.scale, i.target_direction, TO_CHAR(i.last_modified_dtm,'yyyy-mm-dd hh24:mi:ss') last_modified
		  FROM v$ind i, measure m
		 WHERE ind_sid = in_sid_id
		   AND i.measure_sid = m.measure_sid(+);
	CURSOR c_reg IS
		SELECT description, pos, active, link_to_region_sid
		  FROM v$region 
		 WHERE region_sid = in_sid_id;
	r_ind c_ind%ROWTYPE;
	r_reg c_reg%ROWTYPE;
	v_optional VARCHAR2(2000);
BEGIN
	CASE in_class_name
		WHEN 'CSRIndicator' THEN
			OPEN c_ind;
			FETCH c_ind INTO r_ind;
			IF NOT c_ind%NOTFOUND THEN
				IF r_ind.measure_sid IS NULL THEN
					-- category
					RETURN 'description="'||REPLACE(r_ind.description,'"',CHR(38)||'quot;')||'" '||
							'active="'||r_ind.active||'" '||
							'last-modified="'||r_ind.last_modified||'" '||
							'ind-type="'||r_ind.ind_type||'" '||
							'pos="'||r_ind.pos||'"';
				ELSE
					-- indicator
					v_optional:='';
					IF r_ind.format_mask IS NOT NULL THEN
						v_optional := v_optional || ' format-mask="'||r_ind.format_mask||'" ';
					END IF;
					IF r_ind.scale IS NOT NULL THEN
						v_optional := v_optional || ' scale="'||r_ind.scale||'" ';
					END IF;
					RETURN v_optional||'description="'||REPLACE(r_ind.description,'"',CHR(38)||'quot;')||'" '||
							'measure="'||REPLACE(r_ind.measure_name,'"',CHR(38)||'quot;')||'" '||
							'measure-sid="'||r_ind.measure_sid||'" '||
							'active="'||r_ind.active||'" '||
							'ind-type="'||r_ind.ind_type||'" '||
							'target-direction="'||r_ind.target_direction||'" '||
							'last-modified="'||r_ind.last_modified||'" '||
							'pos="'||r_ind.pos||'"';
				END IF;
			END IF;
		WHEN 'CSRRegion' THEN
			OPEN c_reg;
			FETCH c_reg INTO r_reg;
			IF NOT c_reg%NOTFOUND THEN
				RETURN 'description="'||REPLACE(r_reg.description,'"',CHR(38)||'quot;')||'" '||
						'pos="'||r_reg.pos||'" '||
						'link-to-sid="'||r_reg.link_to_region_sid||'" '||
						'active="'||r_reg.active||'"';
			END IF;
		ELSE
			RETURN '';
	END CASE;
	RETURN '';
END;


PROCEDURE GetTree(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_sid_id 		IN  security_pkg.T_SID_ID,
	in_depth 		IN  NUMBER,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	OPEN out_cur FOR
		    SELECT NVL(link_sid_id, sid_id) sid_id, NAME, class_id, class_pkg.GetClassName(class_id) class_name, GetAttributeList(sid_id, Class_Pkg.GetClassName(class_id)) attribute_list, LEVEL,
				LEVEL so_level
			  FROM SECURITY.securable_object so
	    START WITH sid_id = in_sid_id CONNECT BY PRIOR NVL(link_sid_id, sid_id) = parent_sid_id AND
			  	   security_pkg.SQL_IsAccessAllowedSID(in_act_id, sid_id, security_pkg.PERMISSION_READ) = 1 AND LEVEL<=in_depth;
END;


PROCEDURE GetTreePath(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_menu_path	IN  security_pkg.T_SO_NAME,
	in_depth 		IN  NUMBER,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	GetTree(in_act_id, securableobject_pkg.GetSIDFromPath(in_act_id, security_pkg.SID_ROOT, in_menu_path), in_depth, out_cur);
END;


/* LIST STUFF  */
PROCEDURE GetList(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_sid_id 		IN  security_pkg.T_SID_ID,
	out_cur			OUT security_pkg.T_OUTPUT_CUR
)
IS
BEGIN
	OPEN out_cur FOR
		    SELECT NVL(link_sid_id, sid_id) sid_id, NAME, class_id, class_pkg.GetClassName(class_id) class_name, tree_pkg.GetAttributeList(sid_id, Class_Pkg.GetClassName(class_id)) attribute_list
			  FROM SECURITY.securable_object so
			 WHERE PARENT_SID_ID = in_sid_id;
END;

END;
/
