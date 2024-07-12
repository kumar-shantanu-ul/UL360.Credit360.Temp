CREATE OR REPLACE PACKAGE CSR.user_cover_pkg
IS

PROCEDURE AddUserCover (
	in_user_being_covered_sid	IN security_pkg.T_SID_ID, 
	in_user_giving_cover_sid	IN security_pkg.T_SID_ID, 
	in_start_date				IN user_cover.start_dtm%TYPE,
	in_end_date					IN user_cover.end_dtm%TYPE, 
	out_user_cover_id			OUT user_cover.user_cover_id%TYPE
);

PROCEDURE UpdateUserCover (
	in_user_cover_id			IN user_cover.user_cover_id%TYPE, 
	in_start_date				IN user_cover.start_dtm%TYPE,
	in_end_date					IN user_cover.end_dtm%TYPE
);

PROCEDURE DeleteUserCover (
	in_user_cover_id			IN user_cover.user_cover_id%TYPE
);

PROCEDURE DeleteMissingUserCover (
	in_user_being_covered_sid	IN	security_pkg.T_SID_ID,
	in_current_user_cover_ids	IN  security_pkg.T_SID_IDS
);

PROCEDURE GetCoverForUser (
	in_user_being_covered_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCurrentCoveringUsers (
	in_user_being_covered_sid	IN	security_pkg.T_SID_ID,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAppsWithCover(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetUserCoverForApp(
	out_current_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_stop_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_fully_end_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE StartOrRefreshCover (
	in_user_cover_id				IN 		user_cover.user_cover_id%TYPE,
	out_cur							OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE StopCover (
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
);

PROCEDURE ClearUserCoverIfLastOne(
	in_delegation_sid			IN security_pkg.T_SID_ID,
	in_user_being_covered_sid	IN security_pkg.T_SID_ID, 
	in_user_giving_cover_sid	IN security_pkg.T_SID_ID 
);

PROCEDURE FullyEndCover(
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
);

PROCEDURE MarkAlertSent(
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
);

PROCEDURE MarkAlertUnSent(
	in_user_cover_id	IN user_cover.user_cover_id%TYPE
);

END;
/