CREATE OR REPLACE PACKAGE CSR.snapshot_Pkg AS

PROCEDURE RegisterSnapshot(
	in_name							IN	snapshot.name%TYPE,
	in_title						IN	snapshot.title%TYPE,
	in_description					IN	snapshot.description%TYPE,
	in_tag_group_Ids				IN	security_pkg.T_SID_IDS,
	in_start_dtm					IN	snapshot.start_dtm%TYPE,
	in_end_dtm						IN	snapshot.end_dtm%TYPE,
	in_period_set_id				IN	snapshot.period_set_id%TYPE,
	in_period_interval_id			IN	snapshot.period_interval_id%TYPE,
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_region_sids					IN	security_pkg.T_SID_IDS,
	in_refresh_xml					IN	snapshot.refresh_xml%TYPE,
	in_use_unmerged					IN	snapshot.use_unmerged%TYPE,
	in_is_supplier					IN	snapshot.is_supplier%TYPE
);

PROCEDURE DropAllSnapshots;

PROCEDURE DropSnapshot(
	in_name							IN	snapshot.name%TYPE,
	out_name_in_use					OUT	NUMBER
);

PROCEDURE GetData(
	in_name							IN	snapshot.name%TYPE,
	in_tag_ids						IN	security_pkg.T_SID_IDS,
	in_period_id					IN	NUMBER,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_max_row						IN	NUMBER,
	in_asc							IN	NUMBER,
	in_root_region_sid				IN	security_pkg.T_SID_ID,
	in_include_nulls    			IN  NUMBER,
	in_include_inactive_regions		IN  NUMBER,
	out_cur							OUT SYS_REFCURSOR,
	out_sum_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetSnapshotForRefresh(
	in_name				IN	snapshot.name%TYPE,
	out_cur_snapshot	OUT SYS_REFCURSOR,
	out_cur_inds		OUT SYS_REFCURSOR,
	out_cur_regions		OUT SYS_REFCURSOR
);


PROCEDURE GetRegions(
	in_name		IN	snapshot.name%TYPE,
	out_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetSnapshot(
	in_name				IN	snapshot.name%TYPE,
	out_cur_snapshot	OUT SYS_REFCURSOR,
	out_cur_tags		OUT SYS_REFCURSOR,
	out_cur_inds		OUT SYS_REFCURSOR,
	out_cur_periods		OUT SYS_REFCURSOR
);

PROCEDURE GetSnapshotInfo(
	in_name				IN	snapshot.name%TYPE,
	out_cur_snapshot	OUT SYS_REFCURSOR,
	out_cur_tags		OUT SYS_REFCURSOR,
	out_cur_inds		OUT SYS_REFCURSOR,
	out_cur_regions		OUT SYS_REFCURSOR
);

PROCEDURE GetSnapshotList(
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllSnapshotsForUpdate(
	out_cur				OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE SetNextUpdateDate(
	in_name				IN snapshot.name%TYPE,
	in_update_dtm		IN snapshot.next_update_after_dtm%type
);

END;
/
