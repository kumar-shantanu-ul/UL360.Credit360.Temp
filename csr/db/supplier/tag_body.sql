CREATE OR REPLACE PACKAGE BODY SUPPLIER.tag_pkg
IS

-- Securable object callbacks for tag group
PROCEDURE CreateObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_class_id					IN security_pkg.T_CLASS_ID,
	in_name						IN security_pkg.T_SO_NAME,
	in_parent_sid_id			IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_name					IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE tag_group 
	 SET name = in_new_name
	 WHERE tag_group_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID
) AS
BEGIN
	-- TODO: this might orphan tags, i.e. tags which no longer belong to a group
	DELETE FROM tag_group_member
	 WHERE tag_group_sid = in_sid_id;
	 
	DELETE FROM tag_group
	 WHERE tag_group_sid = in_sid_id;
END;

PROCEDURE MoveObject(
	in_act_id					IN security_pkg.T_ACT_ID,
	in_sid_id					IN security_pkg.T_SID_ID,
	in_new_parent_sid_id		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id		IN security_pkg.T_SID_ID
) AS	
BEGIN	 
	NULL;
END;


-- create a tag_group
PROCEDURE CreateTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_name						IN  tag_group.name%TYPE,
	in_multi_select				IN	tag_group.multi_select%TYPE,
	in_mandatory				IN	tag_group.mandatory%TYPE,
	in_render_as				IN	tag_group.render_as%TYPE,
	in_render_in				IN	tag_group.render_in%TYPE,
	out_tag_group_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Supplier/TagGroups
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Supplier/TagGroups');
	
	SecurableObject_Pkg.CreateSO(in_act_id, v_parent_sid, class_pkg.getClassID('SupplierTagGroup'), in_name, out_tag_group_sid);
	
	INSERT INTO TAG_GROUP
				(tag_group_sid, app_sid, name, description, multi_select, mandatory, render_as, render_in
				)
		 VALUES (out_tag_group_sid, in_app_sid, in_name, in_name, in_multi_select, in_mandatory, in_render_as, in_render_in
				);
END;	


-- 
-- AmendTagGroup
--
PROCEDURE AmendTagGroup (
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_name		  				IN	tag_group.name%TYPE,
	in_multi_select				IN	tag_group.multi_select%TYPE,
	in_mandatory				IN	tag_group.mandatory%TYPE,
	in_render_as				IN	tag_group.render_as%TYPE,
	in_render_in				IN	tag_group.render_in%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	UPDATE tag_group
	 SET multi_select = in_multi_select,
		 mandatory = in_mandatory,
		 render_as = in_render_as,
		 render_in = in_render_in
	 WHERE tag_group_sid = in_tag_group_sid;
	 
	 -- we update the name here 
	 securableobject_pkg.RenameSO(in_act_id, in_tag_group_sid, in_name);
END;

-- update tag 
PROCEDURE UpdateTag(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_tag_id					IN	tag.tag_id%TYPE,
	in_tag						IN	tag.tag%TYPE,
	in_explanation				IN	tag.explanation%TYPE,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_is_visible				IN	tag_group_member.is_visible%TYPE
)
AS
BEGIN
	-- check write permissions on tag_group	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied on tag group');
	END IF;

	UPDATE TAG
		SET tag = in_tag, explanation = in_explanation
	WHERE tag_id = in_tag_id;
	
	UPDATE TAG_GROUP_MEMBER
		SET pos = in_pos, is_visible = in_is_visible
	WHERE tag_id = in_tag_id 
	  AND tag_group_sid = in_tag_Group_sid;
END;


-- add a new tag to a group
PROCEDURE AddNewTagToGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_tag						IN	tag.tag%TYPE,
	in_explanation				IN	tag.explanation%TYPE,
	in_pos						IN	tag_group_member.pos%TYPE,
	in_is_visible				IN	tag_group_member.is_visible%TYPE,
	out_tag_id					OUT	tag.tag_id%TYPE
)
AS
BEGIN
	-- check write permissions on tag_group	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	INSERT INTO TAG
		(TAG_ID, TAG, EXPLANATION)
	VALUES
		(tag_id_seq.nextval, in_tag, in_explanation)
	RETURNING TAG_ID into out_tag_id;

	INSERT INTO TAG_GROUP_MEMBER
		(tag_group_sid, tag_id, pos, is_visible)
	SELECT in_tag_group_sid, out_tag_id, NVL(in_pos, NVL(MAX(POS),0)+1), in_is_visible FROM TAG_GROUP_MEMBER;
END;



PROCEDURE RemoveTagFromGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_tag_id					IN	tag.tag_id%TYPE
)
AS
	v_in_use	NUMBER(10);
BEGIN
	-- check write permissions on tag_group	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	-- check to see if tag is in use on a product for this tag_group_sid
	SELECT COUNT(*) INTO v_in_use
      FROM PRODUCT p, PRODUCT_TAG pt, TAG_GROUP_MEMBER tgm
     WHERE p.product_id = pt.product_id
       AND pt.tag_id = tgm.tag_id
       AND pt.tag_id = in_tag_id
       AND tgm.tag_group_sid = in_tag_group_sid;
	
	IF v_in_use > 0 THEN 
		RAISE_APPLICATION_ERROR(tag_pkg.ERR_TAG_IN_USE, 'Tag in use');
	END IF;

	DELETE FROM TAG_GROUP_MEMBER
	 WHERE tag_group_sid = in_Tag_Group_sid
	   AND tag_id = in_tag_id;
	   
	-- TODO could leave floating tags

END;


-- returns the schemes and tag groups this user can see 
PROCEDURE GetTagGroups(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tg.tag_group_sid, tg.name, tg.mandatory, tg.multi_select, tg.render_as, tg.render_in
		  FROM tag_group tg
		 WHERE tg.app_sid = in_app_sid
		   AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, tg.tag_group_sid, security_pkg.PERMISSION_READ)=1;
END;


-- returns basic details of specified tag_group 
PROCEDURE GetTagGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tag_group_sid, name, multi_select, mandatory, render_as, render_in
		  FROM tag_group
		 WHERE tag_group_sid = in_tag_group_sid;
END;
	
-- return all tag groups and the products they are associated with for given app_sid
PROCEDURE GetAllTagGroups(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	-- TODO: what SO do we check permission on?
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_app_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_sid, NAME, multi_select, mandatory, render_as, tgm.tag_Id, tgm.pos, tgm.is_visible, t.tag, t.explanation
		  FROM tag_group tg, tag_group_member tgm, tag t
		 WHERE tg.tag_group_sid = tgm.tag_group_sid(+)
		   AND tgm.tag_id = t.tag_id(+)
		   AND tg.app_sid = in_app_sid
		 ORDER BY tg.tag_group_sid, tgm.pos;
END;




PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permission on tag_group
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_tag_group_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied');
	END IF;
	
	OPEN out_cur FOR
--		SELECT t.tag_id, tag, explanation, is_visible, pos
--		  FROM tag_group_member tgm, tag t
--		 WHERE tgm.tag_id = t.tag_id
--		   AND tgm.tag_group_sid = in_tag_group_sid
--		 ORDER BY pos;
	  SELECT tags.tag_id, tags.tag, tags.explanation, tags.is_visible, tags.pos, REPLACE(NVL(tblLbls.label, 'Other'),'lbl_','') label, tblGroups.val_group, tblParents.is_parent is_parent 
              FROM 
                 (
                 SELECT t.tag_id, tag, explanation, is_visible, pos
                   FROM tag_group_member tgm, tag t 
                  WHERE tgm.tag_id = t.tag_id
                    AND tgm.tag_group_sid = in_tag_group_sid
                 ) tags,
                 (
                  SELECT t.tag_id,t.tag, MAX(ta.name) label
                    FROM tag t, tag_tag_attribute tta, tag_attribute ta
                   WHERE t.tag_id = tta.tag_id 
                     AND ta.tag_attribute_id = tta.tag_attribute_id
                     AND ta.name like 'lbl_%'
                   GROUP BY t.tag_id, t.tag
                  ) tblLbls,
                  (
                  SELECT t.tag_id,t.tag, MAX(ta.name) val_group
                    FROM tag t, tag_tag_attribute tta, tag_attribute ta
                   WHERE t.tag_id = tta.tag_id 
                     AND ta.tag_attribute_id = tta.tag_attribute_id
                     AND ta.name like 'group%'
                   GROUP BY t.tag_id, t.tag
                  ) tblGroups,
				  (
                  SELECT tta.tag_id, REPLACE( ta.name,'child_','') is_parent
					FROM tag_tag_attribute tta, tag_attribute ta
				   WHERE ta.name like 'child_%'
					 AND ta.tag_attribute_id = tta.tag_attribute_id
                  ) tblParents
             WHERE tags.tag_id = tblLbls.tag_id (+)
               AND tags.tag_id = tblGroups.tag_id (+)
               AND tags.tag_id = tblParents.tag_id (+)
             ORDER BY label,pos;


END;

PROCEDURE GetTagGroupMembers(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_tag_group_name			IN	tag_group.name%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_tag_group_sid				security_pkg.T_SID_ID;
BEGIN

	BEGIN
		SELECT tag_group_sid
		  INTO v_tag_group_sid
		  FROM tag_group
		 WHERE name = in_tag_group_name
		   AND app_sid = in_app_sid;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
            -- return a blank dataset
            OPEN out_cur FOR
                SELECT null tag_id, null tag, null explanation, null is_visible, null pos
                  FROM DUAL
                 WHERE 1 = 0;
            RETURN;
	END;

	GetTagGroupMembers(in_act_id, v_tag_group_sid, out_cur);
END;

FUNCTION ConcatTagGroupMembers(
	in_tag_group_sid			IN	security_pkg.T_SID_ID,
	in_max_length				IN 	INTEGER
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT tag
		  FROM tag_group_member tgm, tag t
		 WHERE tgm.tag_id = t.tag_id
		   AND tgm.tag_group_sid = in_tag_group_sid)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.tag) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.tag;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;


PROCEDURE GetTagGroupsSummary(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT tag_group_sid, name,
			(SELECT count(*) FROM tag_group_member tgm WHERE tag_group_sid = tg.tag_group_sid) member_count,
		    tag_pkg.ConcatTagGroupMembers(tg.tag_group_sid, 30) MEMBERS
		  FROM tag_group tg
		 WHERE app_sid = in_app_sid;
END;


PROCEDURE GetTag(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_id					IN	tag.tag_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Securty check?
	OPEN out_cur FOR
		SELECT tag_id, tag, explanation
		  FROM tag
		 WHERE tag_id = in_tag_id;
END;

PROCEDURE GetTagAttributes(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_tag_id					IN	tag.tag_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Securty check?
	OPEN out_cur FOR
		SELECT tta.tag_attribute_id, ta.name
		  FROM tag_attribute ta, tag_tag_attribute tta
		 WHERE ta.tag_attribute_id = tta.tag_attribute_id
		   AND tta.tag_id = in_tag_id;
END;

END tag_pkg;
/