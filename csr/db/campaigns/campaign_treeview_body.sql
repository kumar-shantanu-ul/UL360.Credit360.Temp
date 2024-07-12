CREATE OR REPLACE PACKAGE BODY campaigns.campaign_treeview_pkg AS

PROCEDURE GetCampaignTreeWithDepth(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_fetch_depth		IN  NUMBER,
	in_show_inactive 	IN 	NUMBER,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions
	IF in_parent_sid <> -1 AND NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the campaign with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT so.sid_id, so.name, c.campaign_sid, c.name label,
			   CONNECT_BY_ISLEAF is_leaf, so.parent_sid_id, so.link_sid_id, level lvl
		  FROM security.securable_object so
	 LEFT JOIN campaign c ON c.campaign_sid = so.sid_id
	     WHERE level <= in_fetch_depth
	START WITH ((in_include_root = 0 AND so.parent_sid_id = in_parent_sid) OR
			 	   (in_include_root = 1 AND so.sid_id = in_parent_sid))
    CONNECT BY PRIOR so.sid_id = so.parent_sid_id
	ORDER SIBLINGS BY LOWER(so.name);
END;

PROCEDURE GetCampaignTreeTextFiltered(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_search_phrase	IN	VARCHAR2,
	in_show_inactive 	IN 	NUMBER,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions
	IF in_parent_sid <> -1 AND NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the campaign with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT so.sid_id, so.name, so.parent_sid_id, so.link_sid_id,
			   c.campaign_sid, c.name label,
			   CONNECT_BY_ISLEAF is_leaf, LEVEL lvl
		  FROM (
				    SELECT DISTINCT sid_id
					  FROM security.securable_object so
				 LEFT JOIN campaign c ON c.campaign_sid = so.sid_id
				START WITH sid_id IN (
							  SELECT campaign_sid
							    FROM campaign
							   WHERE (LOWER(name) LIKE '%'||LOWER(in_search_phrase)||'%')
								  OR (REGEXP_LIKE(in_search_phrase, '^[0-9]+$') AND survey_sid = TO_NUMBER(in_search_phrase))
								  OR (REGEXP_LIKE(in_search_phrase, '^[0-9]+$') AND campaign_sid = TO_NUMBER(in_search_phrase))
				)
				CONNECT BY PRIOR parent_sid_id = sid_id
			 ) t
		  JOIN security.securable_object so ON t.sid_id = so.sid_id
	 LEFT JOIN campaign c ON c.campaign_sid = so.sid_id
	START WITH ((in_include_root = 0 AND so.parent_sid_id = in_parent_sid)
			OR (in_include_root = 1 AND so.sid_id = in_parent_sid))
	CONNECT BY PRIOR so.sid_id = so.parent_sid_id;
END;

PROCEDURE GetCampaignTreeWithSelect(
	in_act_id			IN  security.security_pkg.T_ACT_ID,
	in_parent_sid		IN  NUMBER,
	in_include_root 	IN  NUMBER,
	in_select_sid		IN	security.security_pkg.T_SID_ID,
	in_show_inactive 	IN 	NUMBER,
	out_cur				OUT security.security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check permissions
	IF in_parent_sid <> -1 AND NOT security.security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'Access denied to the campaign with sid '||in_parent_sid);
	END IF;

	OPEN out_cur FOR
		SELECT so.sid_id, so.name, c.campaign_sid, c.name label, 
			   CONNECT_BY_ISLEAF is_leaf, so.parent_sid_id, so.link_sid_id, level lvl
		  FROM security.securable_object so
	 LEFT JOIN campaign c ON c.campaign_sid = so.sid_id
	START WITH ((in_include_root = 0 AND parent_sid_id = in_parent_sid) OR
				(in_include_root = 1 AND so.sid_id = in_parent_sid))
	CONNECT BY PRIOR so.sid_id = so.parent_sid_id
		 ORDER SIBLINGS BY LOWER(name);
END;

END campaign_treeview_pkg;
/