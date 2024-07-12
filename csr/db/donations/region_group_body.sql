CREATE OR REPLACE PACKAGE BODY DONATIONS.region_group_pkg
IS


-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_class_id			IN security_pkg.T_CLASS_ID,
	in_name				IN security_pkg.T_SO_NAME,
	in_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_sid_id			IN security_pkg.T_SID_ID,
	in_new_name		IN security_pkg.T_SO_NAME
) AS
BEGIN
	UPDATE REGION_GROUP
	   SET DESCRIPTION = in_new_name
	 WHERE region_group_sid = in_sid_id;
END;

PROCEDURE DeleteObject(
	in_act_id		IN security_pkg.T_ACT_ID,
	in_sid_id		IN security_pkg.T_SID_ID
) AS
	 t_letter_body_text_ids			 security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN

  -- we need to collect the ids of letter_body_text, so we can delete only these, 
  -- which were associated with current region_group
  FOR r IN ( 
    SELECT letter_body_text_id
            FROM letter_body_region_group
           WHERE region_group_sid = in_sid_id
  )
  LOOP
    t_letter_body_text_ids.extend;
    t_letter_body_text_ids(t_letter_body_text_ids.count) := r.letter_body_text_id;    
  END LOOP;
 
	DELETE FROM letter_body_region_group
		  WHERE region_group_sid = in_sid_id;
	
  -- finally delete unused letters
	DELETE FROM letter_body_text 
     WHERE letter_body_text_id IN (
        SELECT column_value FROM TABLE(t_letter_body_text_ids) 
     );
	
	DELETE FROM region_group_recipient
		  WHERE region_group_sid = in_sid_id;
	
	DELETE FROM REGION_GROUP_MEMBER
		  WHERE region_group_sid = in_sid_id;	

	DELETE FROM DONATION_TAG
		  WHERE donation_Id IN (
			SELECT donation_Id 
			  FROM donation d, budget b 
			 WHERE d.budget_id = b.budget_Id
			   AND b.region_group_sid = in_sid_id
	);	

	DELETE FROM DONATION_DOC
		  WHERE donation_Id IN (
			SELECT donation_Id 
			  FROM donation d, budget b 
			 WHERE d.budget_id = b.budget_Id
			   AND b.region_group_sid = in_sid_id
	);	

	DELETE FROM DONATION 
		  WHERE donation_Id IN (
			SELECT donation_Id 
			  FROM donation d, budget b 
			 WHERE d.budget_id = b.budget_Id
			   AND b.region_group_sid = in_sid_id
	);	

	DELETE FROM DONATION 
		  WHERE budget_Id IN (SELECT budget_id FROM budget WHERE region_group_sid = in_sid_id);	

	DELETE FROM BUDGET_CONSTANT
	      WHERE budget_Id IN (
			SELECT budget_id 
			  FROM budget
			 WHERE region_group_sid = in_sid_id
	);
	
	DELETE FROM BUDGET
		  WHERE region_group_sid = in_sid_id;	
	
	DELETE FROM REGION_GROUP
		  WHERE region_group_sid = in_sid_id;	
END;

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
) AS	
BEGIN	 
	NULL;
END;

PROCEDURE CreateRegionGroup (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_app_sid				IN	security_pkg.T_SID_ID,
	in_description			IN	region_group.description%TYPE,
	/*in_currency_code		IN	region_group.currency_code%TYPE,*/
	out_region_group_sid	OUT security_pkg.T_SID_ID
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	-- get securable object Donations/RegionGroup
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Donations/RegionGroups');
	SecurableObject_Pkg.CreateSO(in_act_id, v_parent_sid, class_pkg.getClassID('DonationsRegionGroup'), in_description, out_region_group_sid);
	
	INSERT INTO REGION_GROUP
		(region_group_sid, app_sid, description/*, currency_code*/)
	  VALUES (out_region_group_sid, in_app_sid, in_description/*, in_currency_code*/);
END;


PROCEDURE AmendRegionGroup (
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_region_group_sid		IN	security_pkg.T_SID_ID,
	in_description			IN	region_group.description%TYPE/*,
	in_currency_code		IN	region_group.currency_code%TYPE*/
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_group_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering region group');
	END IF;
	
	securableobject_pkg.renameSO(in_act_id, in_region_group_sid, in_description);
	
	UPDATE region_group
	   SET description = in_description/*,
	       currency_code = in_currency_code*/
	 WHERE region_group_sid = in_region_group_sid;
END;

PROCEDURE GetRegionGroups(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Donations/RegionGroups');
	
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_parent_sid, security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region groups');
	END IF;

	OPEN out_cur FOR
		SELECT region_group_sid, description, /*currency_code, */letter_template_id
		  FROM region_group
		 WHERE app_sid = in_app_sid
		 ORDER BY description;
END;


PROCEDURE GetRegionGroup(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid				IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_group_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region group');
	END IF;

	OPEN out_cur FOR
		SELECT region_group_sid, description, /*currency_code, */letter_template_id
		  FROM region_group
		 WHERE region_group_sid = in_region_group_sid;
END;


PROCEDURE GetRegionGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_group_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region group');
	END IF;

	OPEN out_cur FOR
		SELECT r.region_sid, r.description
		  FROM region_group_member rgm, csr.v$region r
		 WHERE rgm.region_group_sid = in_region_group_sid
		   AND r.region_sid = rgm.region_sid
		 ORDER BY description;
END;


PROCEDURE GetMyRegions(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR	
)
AS
    v_user_sid  security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_group_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region group');
	END IF;
    
    user_pkg.GetSid(in_act_id, v_user_sid);
	OPEN out_cur FOR
		SELECT r.region_sid, r.description
		  FROM region_group_member rgm, csr.v$region r, csr.region_owner ro
		 WHERE rgm.region_group_sid = in_region_group_sid
		   AND r.region_sid = rgm.region_sid
		   AND ro.user_sid = v_user_sid
		   AND ro.region_sid = r.region_sid
		 ORDER BY description;
END;

PROCEDURE GetRegionFromGroup(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_region_group_sid			IN	security_pkg.T_SID_ID,
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR	
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_sid, security_Pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region');
	END IF;

	OPEN out_cur FOR
		SELECT r.region_sid, r.description 
		  FROM region_group_member rgm, csr.v$region r
		 WHERE r.region_sid = in_region_sid
		   AND rgm.region_group_sid = in_region_group_sid
		   AND r.region_sid = rgm.region_sid;
END;

PROCEDURE SetRegionGroupMembers(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	in_members					IN	VARCHAR2
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, in_region_group_sid, security_Pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to region group');
	END IF;

	DELETE FROM REGION_GROUP_MEMBER 
	 WHERE REGION_GROUP_SID = in_region_group_sid;
	
	INSERT INTO REGION_GROUP_MEMBER
		(REGION_GROUP_SID, REGION_SID)
		SELECT in_region_group_sid, item
	    FROM TABLE(Utils_Pkg.SplitString(in_members,','));
END;

FUNCTION ConcatRegionGroupMembers(
	in_region_group_sid	IN	security_pkg.T_SID_ID,
	in_max_length				IN 	INTEGER
) RETURN VARCHAR2
AS
	v_s	VARCHAR2(512);
	v_sep VARCHAR2(10);
BEGIN
	v_s := '';
	v_sep := '';
	FOR r IN (
		SELECT description 
		  FROM region_group_member rgm, csr.v$region r
		 WHERE rgm.region_sid = r.region_sid
		   AND rgm.region_group_sid = in_region_group_sid)
	LOOP
		IF LENGTH(v_s) + LENGTH(r.description) + 3 >= in_max_length THEN
			v_s := v_s || '...';
			EXIT;
		END IF;
		v_s := v_s || v_sep || r.description;		
		v_sep := ', ';
	END LOOP;
	RETURN v_s;
END;


PROCEDURE GetRegionGroupsSummary(
	in_act_id		IN	security_pkg.T_ACT_ID,
	in_app_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		 SELECT rg.region_group_sid, rg.description, 
		 	(SELECT count(*) 
		 	   FROM region_group_member rgm 
		 	  WHERE region_group_sid = rg.region_group_sid) member_count,
		    region_group_pkg.ConcatRegionGroupMembers(rg.region_group_sid, 20) MEMBERS 
		   FROM region_group rg
		  WHERE app_sid = in_app_sid
		  	AND security_pkg.SQL_IsAccessAllowedSID(in_act_id, rg.region_group_sid, security_pkg.PERMISSION_READ) = 1;
END;


PROCEDURE GetRegionGroupsForRecipient(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_app_sid			IN	security_pkg.T_SID_ID,
	in_recipient_sid	IN	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_parent_sid	security_pkg.T_SID_ID;
BEGIN
	v_parent_sid := securableobject_pkg.GetSIDFromPath(in_act_id, in_app_sid, 'Donations/RegionGroups');
	IF NOT security_pkg.IsAccessAllowedSID(in_act_id, v_parent_sid, security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region groups');
	END IF;

	OPEN out_cur FOR
		SELECT rg.region_group_sid, rg.description, /*rg.currency_code, */rg.letter_template_id
		  FROM region_group rg, region_group_recipient rgr
		 WHERE rg.region_group_sid = rgr.region_group_sid
		   AND rgr.recipient_sid = in_recipient_sid
		 ORDER BY description;
END;

PROCEDURE GetAllRegionGroupsAndRegions(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_act_id			security_pkg.T_ACT_ID DEFAULT SYS_CONTEXT('SECURITY','ACT');
	v_parent_sid		security_pkg.T_SID_ID;
	v_is_super_admin	NUMBER(1) DEFAULT 0;
BEGIN
	v_parent_sid := securableobject_pkg.GetSIDFromPath(v_act_id, SYS_CONTEXT('SECURITY','APP'), 'Donations/RegionGroups');
	
	IF NOT security_pkg.IsAccessAllowedSID(v_act_id, v_parent_sid, security_Pkg.PERMISSION_LIST_CONTENTS) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading region groups');
	END IF;

	IF user_pkg.IsUserInGroup(v_act_id, securableobject_pkg.GetSIDFromPath(v_act_id, 0, 'csr/SuperAdmins')) = 1 THEN
		v_is_super_admin := 1;
	END IF;

	OPEN out_cur FOR
		SELECT rg.region_group_sid, rg.description region_group_description, rgm.region_sid, r.description region_description 
		  FROM region_group rg, region_group_member rgm, csr.v$region r
		 WHERE rgm.region_sid = r.region_sid
		   AND rg.region_group_sid = rgm.region_group_sid
		   AND rg.app_sid = SYS_CONTEXT('SECURITY','APP')
		   AND (v_is_super_admin = 1 OR rgm.region_sid IN (
				  SELECT region_sid FROM csr.region_owner WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
				))
		 ORDER BY region_description, region_group_description;
END;
	
END region_group_pkg;
/