CREATE OR REPLACE PACKAGE BODY CSR.activity_pkg IS

-- for calls from C#
PROCEDURE IsReadAccessAllowed(
	in_activity_id			IN	activity.activity_id%TYPE,
	out_result				OUT NUMBER
)
AS
BEGIN
	IF IsReadAccessAllowed(in_activity_id) THEN
		out_result := 1;
	ELSE
		out_result := 0;
	END IF;
END;

-- Don't call this from a piece of SQL or it'll perform hopelessly badly!
FUNCTION IsReadAccessAllowed(
	in_activity_id			IN	activity.activity_id%TYPE
) RETURN BOOLEAN
AS
	v_is_members_only	activity.is_members_only%TYPE;
	v_is_editable		NUMBER(10);
	v_cnt				NUMBER(10);
BEGIN
	SELECT is_members_only
	  INTO v_is_members_only
	  FROM activity
	 WHERE activity_id = in_activity_id;

	IF v_is_members_only = 0 THEN
		-- accessible to non-members so check role
		SELECT MAX(is_editable)
		  INTO v_is_editable
		  FROM v$flow_item_role_member firm
		  JOIN activity a ON firm.flow_item_id = a.flow_item_id AND firm.app_sid = a.app_sid
		 WHERE a.activity_id = in_activity_id;

		IF v_is_editable IS NOT NULL THEN
			RETURN TRUE;
		END IF;
	END IF;

	-- it's members only... is the user a member?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM activity_member
	 WHERE activity_id = in_activity_id
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');

	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- check capability
	IF csr_data_pkg.CheckCapability('Activity management') THEN
		RETURN TRUE;
	END IF;

	RETURN FALSE;
END;


-- Don't call this from a piece of SQL or it'll perform hopelessly badly!
FUNCTION IsMember(
	in_activity_id			IN	activity.activity_id%TYPE
) RETURN BOOLEAN
AS
	v_cnt				NUMBER(10);
BEGIN
	-- is the user an owner?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM activity_member
	 WHERE activity_id = in_activity_id
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID');

	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- check capability (always consider as a member)
	IF csr_data_pkg.CheckCapability('Activity management') THEN
		RETURN TRUE;
	END IF;

	RETURN FALSE;
END;


-- Don't call this from a piece of SQL or it'll perform hopelessly badly!
FUNCTION IsWriteAccessAllowed(
	in_activity_id			IN	activity.activity_id%TYPE
) RETURN BOOLEAN
AS
	v_cnt				NUMBER(10);
	v_is_editable		NUMBER(10);
BEGIN
	-- is the user an owner?
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM activity_member
	 WHERE activity_id = in_activity_id
	   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND is_owner = 1;

	IF v_cnt > 0 THEN
		RETURN TRUE;
	END IF;

	-- check capability
	IF csr_data_pkg.CheckCapability('Activity management') THEN
		RETURN TRUE;
	END IF;

	-- check role
	SELECT NVL(MAX(is_editable),0) 
	  INTO v_is_editable
	  FROM v$flow_item_role_member firm
	  JOIN activity a ON firm.flow_item_id = a.flow_item_id AND firm.app_sid = a.app_sid
	 WHERE a.activity_id = 1;

	IF v_is_editable = 0 THEN
		RETURN FALSE;
	ELSE
		RETURN TRUE;
	END IF;
END;

PROCEDURE GetActivityTypes(
	out_activity_type_cur		OUT SYS_REFCURSOR,
	out_activity_sub_type_cur	OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_activity_type_cur FOR
		SELECT activity_type_id, label, lookup_key, track_time, track_money, hidden, base_css_class,
			t.matched_giving_policy_id,
			mgp.description matched_giving_policy
		  FROM activity_type t
		  LEFT JOIN matched_giving_policy mgp ON t.matched_giving_policy_id = mgp.matched_giving_policy_id AND t.app_sid = mgp.app_sid
		 WHERE t.app_sid = security_pkg.getApp;		   
		 
	OPEN out_activity_sub_type_cur FOR
		SELECT activity_sub_type_id, activity_type_id, label, hidden, base_css_class
		  FROM activity_sub_type
		 WHERE app_sid = security_pkg.getApp;
END;


PROCEDURE GetActivityRegions(
	in_activity_type_id 	IN  activity_type.activity_type_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security check required as filters based on sys context user sid
	OPEN out_cur FOR		
	  SELECT rrm.region_sid, r.description
	    FROM activity_type t 
	    JOIN flow f ON t.use_flow_sid = f.flow_sid AND t.app_sid = f.app_sid
	    JOIN flow_state fs ON f.default_state_id = fs.flow_state_id AND f.app_sid = fs.app_sid
	    JOIN flow_state_role fsr ON fs.flow_state_id = fsr.flow_state_id AND fs.app_sid = fsr.app_sid
	    JOIN region_role_member rrm ON fsr.role_sid = rrm.role_sid AND fsr.app_sid = rrm.app_sid
	        AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	    JOIN v$region r ON rrm.region_sid = r.region_sid AND rrm.app_sid = r.app_sid AND r.region_type = csr_data_pkg.REGION_TYPE_PROPERTY
	    WHERE t.activity_type_id = in_activity_type_Id
	    ORDER BY r.description;
END;

PROCEDURE ClearImg(
	in_activity_id 				IN  activity.activity_id%TYPE
)
AS
BEGIN
	 IF NOT IsWriteAccessAllowed(in_activity_id) THEN
	 	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Activity id '||in_activity_id||' not editable by user sid '||SYS_CONTEXT('SECURITY','SID'));
	 END IF;

	 UPDATE activity
	    SET img_data = null, img_sha1 = null, img_mime_type = null, img_last_modified_dtm = null
	  WHERE activity_id = in_activity_id;
END;


PROCEDURE SetImg(
	in_activity_id 				IN  activity.activity_id%TYPE,
	in_cache_key 				IN  VARCHAR2
)
AS
BEGIN
	 IF NOT IsWriteAccessAllowed(in_activity_id) THEN
	 	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Activity id '||in_activity_id||' not editable by user sid '||SYS_CONTEXT('SECURITY','SID'));
	 END IF;

	 UPDATE activity
	    SET (img_data, img_sha1, img_mime_type, img_last_modified_dtm) = (
			SELECT object, dbms_crypto.hash(object, dbms_crypto.hash_sh1), mime_type, SYSDATE 				   
			  FROM aspen2.filecache 
			 WHERE cache_key = in_cache_key
		)
	   WHERE activity_id = in_activity_id;
END;

PROCEDURE AmendActivity(
	in_activity_id 				IN  activity.activity_id%TYPE,
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_activity_type_id			IN  activity.activity_type_id%TYPE,
	in_activity_sub_type_id		IN  activity.activity_sub_type_id%TYPE DEFAULT NULL,
	in_label					IN  activity.label%TYPE,
	in_description				IN  activity.description%TYPE,
	in_start_dtm				IN  activity.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm					IN  activity.end_dtm%TYPE DEFAULT NULL
)
AS
BEGIN
	IF NOT IsWriteAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Activity id '||in_activity_id||' not editable by user sid '||SYS_CONTEXT('SECURITY','SID'));
	END IF;

	UPDATE activity 
	   SET region_sid = in_region_sid,
	   	activity_type_id = in_activity_type_id,
	   	activity_sub_type_id = in_activity_sub_type_id,
		label = in_label,
		short_label = in_label, -- for now
		description = in_description,
		start_dtm = in_start_dtm,
		end_dtm = in_end_dtm
	 WHERE activity_id = in_activity_id;
END;


PROCEDURE CreateActivity(
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_activity_type_id			IN  activity.activity_type_id%TYPE,
	in_activity_sub_type_id		IN  activity.activity_sub_type_id%TYPE DEFAULT NULL,
	in_label					IN  activity.label%TYPE,
	in_short_label				IN  activity.short_label%TYPE,
	in_description				IN  activity.description%TYPE,
	in_start_dtm				IN  activity.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm					IN  activity.end_dtm%TYPE DEFAULT NULL,
	in_is_members_only			IN  activity.is_members_only%TYPE,
	out_activity_id				OUT activity.activity_id%TYPE
)
AS
	v_flow_sid 				security_pkg.T_SID_ID;
	v_flow_item_id			csr_data_pkg.T_FLOW_ITEM_ID;
	v_default_state_id		csr_data_pkg.T_FLOW_STATE_ID;
	v_flow_state_log_id		flow_state_log.flow_state_log_id%TYPE;
BEGIN	
	-- which workflow is used by this activity type?
	SELECT t.use_flow_sid, f.default_state_id
	  INTO v_flow_sid, v_default_state_id
	  FROM activity_type t
	  JOIN flow f ON t.use_flow_sid = f.flow_sid AND t.app_sid = f.app_sid
	 WHERE activity_type_id = in_activity_type_id;

	-- is this user going to be able to do stuff to activities for this region?
	IF flow_pkg.CanSeeDefaultState(v_flow_sid, in_region_sid) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'User '||security_pkg.getsid||' not in appropriate role for region '||in_region_sid||' in workflow '||v_flow_sid);
	END IF;
	 
	INSERT INTO flow_item (flow_item_id, flow_sid, current_state_id)
		VALUES (flow_item_id_seq.NEXTVAL, v_flow_sid, v_default_state_id)
		RETURNING flow_item_id INTO v_flow_item_id;

	v_flow_state_log_id := flow_pkg.AddToLog(in_flow_item_id => v_flow_item_id);
	
	INSERT INTO activity (activity_id, region_sid, flow_item_id, activity_type_id, activity_sub_type_id, 
		label, short_label, description, start_dtm, end_dtm, open_dtm, close_dtm, 
		active, is_members_only)
	VALUES (activity_id_seq.nextval, in_region_sid, v_flow_item_id, in_activity_type_id, in_activity_sub_type_id, 
		in_label, in_short_label, in_description, in_start_dtm, in_end_dtm, null, NVL(in_end_dtm, in_start_dtm+1),
		1, in_is_members_only)
	RETURNING activity_id INTO out_activity_id; 

	-- make this user a member (and owner) of the activity
	INSERT INTO activity_member (activity_id, user_sid, joined_dtm, is_owner, active, completed)
		VALUES (out_activity_id, SYS_CONTEXT('SECURITY','SID'), SYSDATE, 1, 1, 0);

	-- auto follow activity
	INSERT INTO activity_follower (activity_id, follower_sid)
		VALUES (out_activity_id, SYS_CONTEXT('SECURITY','SID'));
END;

PROCEDURE InviteMembers(
	in_activity_id			IN  activity.activity_id%TYPE,
	in_user_sids			IN 	security_pkg.T_SID_IDS,
	in_msg					IN  VARCHAR2
)
AS
	t_user_sids	security.T_SID_TABLE;
BEGIN
	t_user_sids := security_pkg.SidArrayToTable(in_user_sids);

	FOR r IN (
		SELECT column_value FROM TABLE(t_user_sids)
	)
	LOOP
		BEGIN
			INSERT INTO activity_member (activity_id, user_sid)
			 VALUES (in_activity_id, r.column_value);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	-- we update joined_dtm to SYSDATE when they click the link in the invite
END;


PROCEDURE GetActivities(
	out_cur 		OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT a.activity_id, a.region_sid, a.region_description, a.label, a.short_label, a.description, a.activity_type_Id, a.activity_type_label,
		    a.activity_sub_type_Id, a.activity_sub_type_label, a.created_by_sid, a.created_by_name, a.created_dtm, a.flow_item_id,
		    a.flow_state_Id, a.flow_state_label, a.state_colour, a.country_name, a.country_currency, 
		    a.track_time, a.track_money, a.base_css_class, a.is_running, a.open_dtm, a.close_dtm, a.start_dtm, a.end_dtm,
		    a.is_members_only, a.active,    
		    CASE WHEN am.activity_id IS NOT NULL THEN 1 ELSE 0 END is_member,
		    CASE WHEN af.activity_id IS NOT NULL THEN 1 ELSE 0 END is_following,
		    CASE WHEN al.activity_id IS NOT NULL THEN 1 ELSE 0 END is_liked
		  FROM v$activity a
		  LEFT JOIN activity_member am ON a.activity_id = am.activity_Id AND am.user_sid = SYS_CONTEXT('SECURITY','SID') AND a.app_sid = am.app_sid 
		  LEFT JOIN activity_follower af ON a.activity_id = af.activity_Id AND af.follower_sid = SYS_CONTEXT('SECURITY','SID') AND a.app_sid = af.app_sid 
		  LEFT JOIN activity_like al ON a.activity_id = al.activity_Id AND al.liked_by_user_sid = SYS_CONTEXT('SECURITY','SID') AND a.app_sid = al.app_sid 
		 WHERE a.is_members_only = 0
		    OR a.activity_id IN (
		        SELECT activity_id FROM activity_member WHERE user_sid = SYS_CONTEXT('SECURITY','SID')
		    );

END;

-- active activities linked to your profile
PROCEDURE GetMyActivities(
	out_cur 		OUT SYS_REFCURSOR
)
AS
BEGIN
	-- security is provided by restriction on sys_context('security','sid')
	OPEN out_cur FOR
		SELECT a.activity_id, a.region_sid, a.region_description, a.label, a.short_label, a.description, a.activity_type_Id, a.activity_type_label,
			a.activity_sub_type_Id, a.activity_sub_type_label, a.created_by_sid, a.created_by_name, a.created_dtm, a.flow_item_id,
			a.flow_state_Id, a.flow_state_label, a.state_colour, a.country_name, a.country_currency, 
			a.track_time, a.track_money, a.base_css_class, a.is_running, a.open_dtm, a.close_dtm, 
			a.is_members_only, a.active, fc.follower_cnt, fc.member_cnt
		  FROM v$my_activity a
          LEFT JOIN (
            SELECT a.activity_Id, COUNT(am.activity_id) member_cnt, COUNT(af.activity_id) follower_cnt
            	--SUM(CASE WHEN af.follower_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END) you_are_following
              FROM v$my_activity a
              JOIN activity_member am ON a.activity_id = am.activity_id AND a.app_sid = am.app_sid
              LEFT JOIN activity_follower af ON a.activity_id = af.activity_id AND a.app_sid = af.app_sid             
             GROUP BY a.activity_id
          )fc ON a.activity_id = fc.activity_Id
		 ORDER BY created_dtm DESC;
END;

-- get the basics for editing
PROCEDURE GetSimpleActivity(
	in_activity_id 		IN  activity.activity_id%TYPE, 
	out_cur 			OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT IsReadAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading activity id '||in_activity_id);
	END IF;

	OPEN out_cur FOR
		SELECT activity_id, region_sid, region_description, label, short_label, description, activity_type_Id,
			activity_sub_type_Id, created_by_sid, created_by_name, created_dtm, flow_item_id,
			flow_state_Id, flow_state_label, state_colour,
			start_dtm, end_dtm, open_dtm, close_dtm, img_mime_type
		  FROM v$activity
		 WHERE activity_id = in_activity_id;
END;

PROCEDURE GetActivity(
	in_activity_id 				IN  activity.activity_id%TYPE, 
	out_activity_cur 			OUT SYS_REFCURSOR,
	out_flow_states_cur			OUT SYS_REFCURSOR,
	out_members_cur  			OUT SYS_REFCURSOR,
	out_time_cur				OUT SYS_REFCURSOR,
	out_money_cur 				OUT SYS_REFCURSOR,
	out_followers_cur			OUT SYS_REFCURSOR
)
AS
	v_can_edit	NUMBER(10);
BEGIN
	IF NOT IsReadAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading activity id '||in_activity_id);
	END IF;

	IF IsWriteAccessAllowed(in_activity_Id) THEN
		v_can_edit := 1;
	ELSE
		v_can_edit := 0;
	END IF;

	OPEN out_activity_cur FOR
		SELECT a.activity_id, a.region_sid, a.region_description, a.label, a.short_label, a.description, a.activity_type_Id, a.activity_type_label,
			a.activity_sub_type_Id, a.activity_sub_type_label, a.created_by_sid, a.created_by_name, a.created_dtm, a.flow_item_id,
			a.flow_state_Id, a.flow_state_label, a.state_colour, a.country_name, a.country_currency,
			a.track_time, a.track_money, a.base_css_class, a.is_running, a.start_dtm, a.end_dtm, a.open_dtm, a.close_dtm,
			a.is_members_only, a.active, CASE WHEN am.activity_id IS NOT NULL THEN 1 ELSE 0 END is_member,
			mgp.description matched_giving_description, CASE WHEN img_mime_type IS NOT NULL THEN 1 ELSE 0 END has_img,
			v_can_edit can_edit
		  FROM v$activity a
		  LEFT JOIN matched_giving_policy mgp ON a.matched_giving_policy_id = mgp.matched_giving_policy_id AND a.app_sid = mgp.app_sid
		  LEFT JOIN activity_member am ON a.activity_id = am.activity_id AND am.user_sid = SYS_CONTEXT('SECURITY','SID') AND a.app_sid = am.app_sid
		 WHERE a.activity_id = in_activity_id;

	OPEN out_flow_states_cur FOR
		SELECT fs.flow_state_id, fs.label, fs.state_colour,
			CASE WHEN fi.current_state_id = fs.flow_state_id THEN 1 ELSE 0 END is_current
		  FROM activity a
		  JOIN flow_item fi ON a.flow_item_id = fi.flow_item_id AND a.app_sid = fi.app_sid
		  JOIN flow f ON fi.flow_sid = f.flow_sid AND fi.app_sid = f.app_sid
		  JOIN flow_state fs ON f.flow_sid = fs.flow_sid AND f.app_sid = fs.app_sid AND fs.is_deleted = 0
		 WHERE a.activity_id = in_activity_id
		 ORDER BY fs.pos;

	OPEN out_members_cur FOR
		SELECT am.user_sid, cu.full_name, cu.email, am.is_owner, am.joined_dtm, am.completed, am.active
		  FROM activity_member am
		  JOIN csr_user cu ON am.user_sid = cu.csr_user_sid AND am.app_sid = cu.app_sid
		 WHERE am.activity_id = in_activity_id;

	OPEN out_time_cur FOR
		SELECT amt.activity_member_time_id, amt.user_sid, amt.description, amt.hours, amt.dtm,
			cu.full_name, cu.email
		  FROM activity_member_time amt
		  JOIN csr_user cu ON amt.user_sid = cu.csr_user_sid AND amt.app_sid = cu.app_sid
		 WHERE activity_id = in_activity_id
		 ORDER BY amt.dtm DESC, amt.activity_member_time_id DESC;

	-- money isn't always from members, so include full user details
	OPEN out_money_cur FOR
		SELECT am.activity_money_id, am.description, am.amount, am.currency_code, am.dtm, am.is_anonymous,
			CASE WHEN is_anonymous = 1 AND SYS_CONTEXT('SECURITY','SID') != am.user_sid THEN 0 ELSE am.user_sid END user_sid,
			CASE WHEN is_anonymous = 1 AND SYS_CONTEXT('SECURITY','SID') != am.user_sid THEN 'Anonymous' ELSE cu.full_name END full_name,
			CASE WHEN is_anonymous = 1 AND SYS_CONTEXT('SECURITY','SID') != am.user_sid THEN 'anonymous@credit360.com' ELSE cu.email END email
		  FROM activity_money am
		  JOIN csr_user cu ON am.user_sid = cu.csr_user_sid AND am.app_sid = cu.app_sid
		 WHERE activity_id = in_activity_id
		 ORDER BY am.dtm DESC, am.activity_money_id DESC;

	OPEN out_followers_cur FOR
		SELECT cu.csr_user_sid user_sid, cu.full_name, cu.email, af.followed_dtm
		  FROM activity_follower af
		  JOIN csr_user cu ON af.follower_sid = cu.csr_user_sid AND af.app_sid = cu.app_sid
		 WHERE activity_id = in_activity_id;		 
END;

PROCEDURE GetActivityPosts(
	in_activity_id 				IN  activity.activity_id%TYPE, 
	out_posts_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT IsReadAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading activity id '||in_activity_id);
	END IF;

	OPEN out_posts_cur FOR
		SELECT p.activity_post_id, p.user_sid, cu.full_name, cu.email, p.post_dtm, p.post_text
		  FROM activity_post p
		  JOIN csr_user cu ON p.user_sid = cu.csr_user_sid AND p.app_sid = cu.app_sid
		 WHERE activity_id = in_activity_id
		 ORDER BY post_dtm DESC;

	OPEN out_files_cur FOR
		SELECT apf.activity_post_file_id, apf.activity_post_id, cast(apf.sha1 as varchar2(40)) sha1, apf.mime_type
		  FROM activity_post_file apf
		  JOIN activity_post ap ON apf.activity_post_id = ap.activity_post_id
		 WHERE ap.activity_id = in_activity_id;

	OPEN out_likes_cur FOR
		SELECT apl.activity_post_id, apl.liked_by_user_sid, apl.liked_dtm, cu.full_name, cu.email
		  FROM activity_post_like apl
		  JOIN csr_user cu ON apl.liked_by_user_sid = cu.csr_user_sid AND apl.app_sid = cu.app_sid
		  JOIN activity_post ap ON apl.activity_post_id = ap.activity_post_id
		 WHERE ap.activity_id = in_activity_id;
END;

PROCEDURE AddMoney(
	in_activity_id 				IN  activity_money.activity_id%TYPE,
	in_description				IN 	activity_money.description%TYPE,
	in_amount					IN  activity_money.amount%TYPE,
	in_currency_code			IN  activity_money.currency_code%TYPE DEFAULT NULL,
	in_is_anonymous				IN  activity_money.is_anonymous%TYPE,
	out_cur 					OUT SYS_REFCURSOR
)
AS
	v_id 				activity_money.activity_money_Id%TYPE;
	v_currency_code  	activity_money.currency_code%TYPE;
BEGIN
	IF NOT IsWriteAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing activity id '||in_activity_id);
	END IF;

	v_currency_code := in_currency_code;
	IF v_currency_code IS NULL THEN
		-- default
		SELECT NVL(country_currency,'USD') -- hmm - default?
		  INTO v_currency_code
		  FROM v$activity
		 WHERE activity_id = in_activity_id;
	END IF;

	INSERT INTO activity_money (activity_money_id, activity_id, user_sid, description, amount, currency_code, dtm, is_anonymous)
		VALUES (activity_money_id_seq.nextval, in_activity_id, SYS_CONTEXT('SECURITY','SID'), in_description, in_amount, v_currency_code, SYSDATE, in_is_anonymous)
		RETURNING activity_money_id INTO v_id;

	-- money isn't always from members, so include full user details
	OPEN out_cur FOR
		SELECT am.activity_money_id, am.description, am.amount, am.currency_code, am.dtm, am.is_anonymous,
			CASE WHEN is_anonymous = 1 AND SYS_CONTEXT('SECURITY','SID') != am.user_sid THEN 0 ELSE am.user_sid END user_sid,
			CASE WHEN is_anonymous = 1 AND SYS_CONTEXT('SECURITY','SID') != am.user_sid THEN 'Anonymous' ELSE cu.full_name END full_name,
			CASE WHEN is_anonymous = 1 AND SYS_CONTEXT('SECURITY','SID') != am.user_sid THEN 'anonymous@credit360.com' ELSE cu.email END email
		  FROM activity_money am
		  JOIN csr_user cu ON am.user_sid = cu.csr_user_sid AND am.app_sid = cu.app_sid
		 WHERE activity_money_id = v_id;
END;

PROCEDURE AddMemberTime(
	in_activity_id 				IN  activity_member_time.activity_id%TYPE,
	in_description				IN 	activity_member_time.description%TYPE,
	in_hours					IN  activity_member_time.hours%TYPE,
	in_dtm 						IN  activity_member_time.dtm%TYPE,
	out_cur 					OUT SYS_REFCURSOR
)
AS
	v_id 		activity_member_time.activity_member_time_Id%TYPE;
BEGIN
	IF NOT IsWriteAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing activity id '||in_activity_id);
	END IF;

	INSERT INTO activity_member_time (activity_member_time_id, activity_id, user_sid, description, hours, dtm)
		VALUES (activity_member_time_id_seq.nextval, in_activity_id, SYS_CONTEXT('SECURITY','SID'), in_description, in_hours, in_dtm)
		RETURNING activity_member_time_id INTO v_id;

	OPEN out_cur FOR
		SELECT amt.activity_member_time_id, amt.user_sid, amt.description, amt.hours, amt.dtm,
			cu.full_name, cu.email
		  FROM activity_member_time amt
		  JOIN csr_user cu ON amt.user_sid = cu.csr_user_sid AND amt.app_sid = cu.app_sid
		 WHERE amt.activity_member_time_id = v_id;
END;


PROCEDURE LikeActivity(
	in_activity_id 				IN  activity_member_time.activity_id%TYPE
)
AS
	v_ok	BOOLEAN := FALSE;
BEGIN
	-- you can't like something you can't see?
	IF NOT IsReadAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading activity id '||in_activity_id);
	END IF;

	BEGIN
		INSERT INTO activity_like (activity_id, liked_by_user_sid)
		VALUES (in_activity_id, SYS_CONTEXT('SECURITY', 'SID'));
		v_ok := TRUE;
		-- log in feed?
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	IF v_ok THEN
		user_profile_pkg.WriteToUserFeed(
			in_user_feed_action_id	=> csr_data_pkg.USER_FEED_ACTIVITY_LIKE, 
			in_target_activity_id	=> in_activity_id
		);
	END IF;
END;

PROCEDURE FollowActivity(
	in_activity_id 				IN  activity_member_time.activity_id%TYPE
)
AS
	v_ok	BOOLEAN := FALSE;
BEGIN
	-- you can't like something you can't see?
	IF NOT IsReadAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading activity id '||in_activity_id);
	END IF;

	BEGIN
		INSERT INTO activity_follower (activity_id, follower_sid)
		VALUES (in_activity_id, SYS_CONTEXT('SECURITY', 'SID'));
		v_ok := TRUE;
		-- log in feed?
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	IF v_ok THEN
		user_profile_pkg.WriteToUserFeed(
			in_user_feed_action_id	=> csr_data_pkg.USER_FEED_ACTIVITY_FOLLOW, 
			in_target_activity_id	=> in_activity_id
		);
	END IF;
END;




PROCEDURE Post(
	in_activity_id 			IN  activity_post.activity_id%TYPE,
	in_post_text			IN  activity_post.post_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_post_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
)
AS
	v_cache_key_tbl		security.T_VARCHAR2_TABLE;
	v_activity_post_id  activity_post.activity_post_id%TYPE;
	v_label 			activity.label%TYPE;
	v_cnt				NUMBER(10);
BEGIN
	-- you can only post if you're a member
	IF NOT IsMember(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only members can post to activity id '||in_activity_id);
	END IF;
	
	INSERT INTO activity_post (activity_post_Id, activity_id, user_sid, post_text, post_dtm)
		VALUES (activity_post_id_seq.nextval, in_activity_id, SYS_CONTEXT('SECURITY','SID'), in_post_text, SYSDATE)
		RETURNING activity_post_id INTO v_activity_post_id;

	SELECT label  
	  INTO v_label
	  FROM activity
	 WHERE activity_id = in_activity_id;

	user_profile_pkg.WriteToUserFeed(
		in_user_feed_action_id	=> csr_data_pkg.USER_FEED_ACTIVITY_POST, 
		in_target_activity_id	=> in_activity_id,
		in_target_param_1		=> v_activity_post_id
	);

	-- crap hack for ODP.NET
    IF in_cache_keys IS NULL OR (in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		-- do nothing
        NULL;
    ELSE
		v_cache_key_tbl := security_pkg.Varchar2ArrayToTable(in_cache_keys);
		INSERT INTO activity_post_file (activity_post_file_id, activity_post_id, filename, mime_type, data, sha1) 
			SELECT activity_post_file_id_seq.nextval, v_activity_post_id, filename, mime_type, object, 
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache 
			 WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)     
			 );
	END IF;	

	OPEN out_post_cur FOR
		SELECT p.activity_post_id, p.user_sid, cu.full_name, cu.email, p.post_dtm, p.post_text
		  FROM activity_post p
		  JOIN csr_user cu ON p.user_sid = cu.csr_user_sid AND p.app_sid = cu.app_sid
		 WHERE p.activity_post_id = v_activity_post_id;

	OPEN out_files_cur FOR		
		SELECT apf.activity_post_file_id, apf.activity_post_id, cast(apf.sha1 as varchar2(40)) sha1, apf.mime_type
		  FROM activity_post_file apf
		 WHERE apf.activity_post_id = v_activity_post_id;
END;

FUNCTION CanViewActivityPostImage(
	in_activity_post_file_Id	IN 	activity_post_file.activity_post_file_id%TYPE,
	in_sha1						IN	activity_post_file.sha1%TYPE
) RETURN NUMBER
AS
	v_activity_id  activity.activity_id%TYPE;
BEGIN
	SELECT MIN(ap.activity_id)
	  INTO v_activity_id
	  FROM activity_post_file apf
	  JOIN activity_post ap ON apf.activity_post_id = ap.activity_post_id AND apf.app_sid = ap.app_sid	  
	 WHERE sha1 = in_sha1 AND activity_post_file_id = in_activity_post_file_id;

	IF v_activity_id IS NULL THEN 
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot view this image - mismatched SHA1 or incorrect activity_post_file_id');
	END IF;

	IF NOT IsReadAccessAllowed(v_activity_id) THEN
		RETURN 0;
	END IF;	

	RETURN 1;
END;


PROCEDURE GetActivityImage(
	in_activity_id	IN 	activity.activity_id%TYPE,
	out_cur			OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF NOT IsReadAccessAllowed(in_activity_id) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot view this activity');
	END IF;

	OPEN out_cur FOR
		SELECT img_data, img_sha1, img_mime_type, img_last_modified_dtm
		  FROM activity
		 WHERE activity_id = in_activity_id;
END;



PROCEDURE GetActivityPostImage(
	in_activity_post_file_Id	IN 	activity_post_file.activity_post_file_id%TYPE,
	in_sha1						IN	activity_post_file.sha1%TYPE,
	out_cur						OUT  SYS_REFCURSOR
)
AS
BEGIN
	IF CanViewActivityPostImage(in_activity_post_file_id, in_sha1) = 0 THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'You cannot view this image');
	END IF;

	OPEN out_cur FOR
		SELECT apf.filename, apf.data, apf.sha1, apf.mime_type, ap.post_dtm last_modified_dtm
		  FROM activity_post_file apf
		  JOIN activity_post ap ON apf.activity_post_id = ap.activity_post_id AND apf.app_sid = ap.app_sid	  
		 WHERE apf.sha1 = in_sha1 AND apf.activity_post_file_id = in_activity_post_file_id;
END;


END;
/
