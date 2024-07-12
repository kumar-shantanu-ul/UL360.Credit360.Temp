CREATE OR REPLACE PACKAGE CSR.activity_pkg IS

PROCEDURE IsReadAccessAllowed(
	in_activity_id			IN	activity.activity_id%TYPE,
	out_result				OUT NUMBER
);

-- Don't call this from a piece of SQL or it'll perform hopelessly badly!
FUNCTION IsReadAccessAllowed(
	in_activity_id			IN	activity.activity_id%TYPE
) RETURN BOOLEAN;

-- Don't call this from a piece of SQL or it'll perform hopelessly badly!
FUNCTION IsMember(
	in_activity_id			IN	activity.activity_id%TYPE
) RETURN BOOLEAN;

-- Don't call this from a piece of SQL or it'll perform hopelessly badly!
FUNCTION IsWriteAccessAllowed(
	in_activity_id			IN	activity.activity_id%TYPE
) RETURN BOOLEAN;

PROCEDURE GetActivityRegions(
	in_activity_type_id 	IN  activity_type.activity_type_id%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetActivityTypes(
	out_activity_type_cur		OUT SYS_REFCURSOR,
	out_activity_sub_type_cur	OUT SYS_REFCURSOR
);

PROCEDURE ClearImg(
	in_activity_id 				IN  activity.activity_id%TYPE
);

PROCEDURE SetImg(
	in_activity_id 				IN  activity.activity_id%TYPE,
	in_cache_key 				IN  VARCHAR2
);

PROCEDURE AmendActivity(
	in_activity_id 				IN  activity.activity_id%TYPE,
	in_region_sid				IN  security_pkg.T_SID_ID,
	in_activity_type_id			IN  activity.activity_type_id%TYPE,
	in_activity_sub_type_id		IN  activity.activity_sub_type_id%TYPE DEFAULT NULL,
	in_label					IN  activity.label%TYPE,
	in_description				IN  activity.description%TYPE,
	in_start_dtm				IN  activity.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm					IN  activity.end_dtm%TYPE DEFAULT NULL
);

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
);

PROCEDURE InviteMembers(
	in_activity_id			IN  activity.activity_id%TYPE,
	in_user_sids			IN 	security_pkg.T_SID_IDS,
	in_msg					IN  VARCHAR2
);

PROCEDURE GetActivities(
	out_cur 		OUT SYS_REFCURSOR
);

PROCEDURE GetMyActivities(
	out_cur 		OUT SYS_REFCURSOR
);

PROCEDURE GetSimpleActivity(
	in_activity_id 		IN  activity.activity_id%TYPE, 
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE GetActivity(
	in_activity_id 				IN  activity.activity_id%TYPE, 
	out_activity_cur 			OUT SYS_REFCURSOR,
	out_flow_states_cur			OUT SYS_REFCURSOR,
	out_members_cur  			OUT SYS_REFCURSOR,
	out_time_cur				OUT SYS_REFCURSOR,
	out_money_cur 				OUT SYS_REFCURSOR,
	out_followers_cur			OUT SYS_REFCURSOR
);

PROCEDURE GetActivityPosts(
	in_activity_id 				IN  activity.activity_id%TYPE, 
	out_posts_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
);

PROCEDURE AddMoney(
	in_activity_id 				IN  activity_money.activity_id%TYPE,
	in_description				IN 	activity_money.description%TYPE,
	in_amount					IN  activity_money.amount%TYPE,
	in_currency_code			IN  activity_money.currency_code%TYPE DEFAULT NULL,
	in_is_anonymous				IN  activity_money.is_anonymous%TYPE,
	out_cur 					OUT SYS_REFCURSOR
);

PROCEDURE AddMemberTime(
	in_activity_id 				IN  activity_member_time.activity_id%TYPE,
	in_description				IN 	activity_member_time.description%TYPE,
	in_hours					IN  activity_member_time.hours%TYPE,
	in_dtm 						IN  activity_member_time.dtm%TYPE,
	out_cur 					OUT SYS_REFCURSOR
);

PROCEDURE Post(
	in_activity_id 			IN  activity_post.activity_id%TYPE,
	in_post_text			IN  activity_post.post_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_post_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
);

PROCEDURE LikeActivity(
	in_activity_id 				IN  activity_member_time.activity_id%TYPE
);

PROCEDURE FollowActivity(
	in_activity_id 				IN  activity_member_time.activity_id%TYPE
);

PROCEDURE GetActivityImage(
	in_activity_id	IN 	activity.activity_id%TYPE,
	out_cur			OUT  SYS_REFCURSOR
);

FUNCTION CanViewActivityPostImage(
	in_activity_post_file_Id	IN 	activity_post_file.activity_post_file_id%TYPE,
	in_sha1						IN	activity_post_file.sha1%TYPE
) RETURN NUMBER;

PROCEDURE GetActivityPostImage(
	in_activity_post_file_Id	IN 	activity_post_file.activity_post_file_id%TYPE,
	in_sha1						IN	activity_post_file.sha1%TYPE,
	out_cur						OUT  SYS_REFCURSOR
);

END;
/
