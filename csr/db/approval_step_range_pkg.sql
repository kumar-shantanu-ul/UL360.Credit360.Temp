CREATE OR REPLACE PACKAGE CSR.approval_step_range_pkg AS

/*
e.g.

DECLARE
	v_rows	NUMBER(10);
BEGIN 
	approval_step_range_pkg.Init('', 728);
    approval_step_range_pkg.AddRegion(259);
    approval_step_range_pkg.AddAllIndicators();
    approval_step_range_pkg.AddPeriodId(44);
    approval_step_range_pkg.SelectPendingVals();
    SELECT COUNT(*) 
      INTO v_rows
	  FROM TABLE(approval_step_range_pkg.GetPendingVals);
END;

*/


m_ind_ids					security.T_SID_TABLE;
m_region_ids				security.T_SID_TABLE;
m_period_ids				security.T_SID_TABLE;
m_pending_vals				T_PENDING_VAL_TABLE;
m_leaf_points               T_PENDING_LEAF_TABLE;
m_is_initialised			BOOLEAN := FALSE;
m_leaf_points_selected		BOOLEAN := FALSE;
m_pending_vals_selected		BOOLEAN := FALSE;
m_pending_vals_count		NUMBER(10);

m_act_id			security_pkg.T_ACT_ID;
m_approval_step_id	approval_step.approval_step_id%TYPE;
m_sheet_key			approval_step_sheet.sheet_key%TYPE;

FUNCTION GetInds RETURN security.T_SID_TABLE;
FUNCTION GetRegions RETURN security.T_SID_TABLE;
FUNCTION GetPeriods RETURN security.T_SID_TABLE;
FUNCTION GetPendingVals RETURN T_PENDING_VAL_TABLE;
FUNCTION GetLeafPoints RETURN T_PENDING_LEAF_TABLE;

-- actions
PROCEDURE SelectPendingVals;

PROCEDURE Approve(
	in_note		IN	approval_step_sheet_log.note%TYPE	
);

PROCEDURE Merge;

PROCEDURE Submit(
	in_note		IN	approval_step_sheet_log.note%TYPE	
);

PROCEDURE RejectFromParentStep(
	in_parent_approval_step_id	IN	approval_step.approval_step_id%TYPE,
	in_note						IN	approval_step_sheet_log.note%TYPE,
	in_just_selected            IN  NUMBER,
	out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE CascadeRejectFromParentStep(
	in_parent_approval_step_id	IN	approval_step.approval_step_id%TYPE,
	in_note						IN	approval_step_sheet_log.note%TYPE,
	in_just_selected            IN  NUMBER,
	out_cur                     OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPendingValFiles(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetPendingValAccuracy(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetPendingValComments(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetPendingValCommentCounts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetPendingVals(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCheckboxAndRadioSummary(
	out_checkbox_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_radio_cur		OUT	security_pkg.T_OUTPUT_CUR
);


-- periods
PROCEDURE AddPeriodId(
	in_period_id IN PENDING_PERIOD.PENDING_PERIOD_ID%TYPE
);

PROCEDURE AddAllPeriods;

-- indicators
PROCEDURE AddAllIndicators;

PROCEDURE AddIndicator(
	in_ind_id IN	PENDING_IND.PENDING_IND_ID%TYPE
);

PROCEDURE RemoveIndicator(
	in_ind_id IN	PENDING_IND.PENDING_IND_ID%TYPE	
);

PROCEDURE AddIndicatorAndChildren(
	in_ind_root_id	IN	PENDING_IND.PENDING_IND_ID%TYPE
);

-- regions
PROCEDURE AddAllRegions;

PROCEDURE AddRegion(
	in_region_id 	IN	PENDING_REGION.PENDING_REGION_ID%TYPE
);

PROCEDURE RemoveRegion(
	in_region_id 	IN	PENDING_REGION.PENDING_REGION_ID%TYPE
);

PROCEDURE AddRegionAndChildren(
	in_region_root_id	IN	PENDING_REGION.PENDING_REGION_ID%TYPE
);

-- dispose and init
PROCEDURE Dispose;

PROCEDURE InitDataSource(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_start_dtm			IN	pending_period.start_dtm%TYPE,
	in_end_dtm				IN	pending_period.end_dtm%TYPE,
	in_interval_months		IN	NUMBER, -- number of months in the interval (3 = quarterly)
	in_include_stored_calcs	IN	NUMBER,
	out_inds_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_aggr_children_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_ind_depends_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_values_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_dates_cur			OUT	security_pkg.T_OUTPUT_CUR, -- we use a cursor as it's easier to call from C#
	out_pending_inds_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_pending_val_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_variance_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE InitWithKey(
	in_act_id			 	IN	security_pkg.T_ACT_ID,
	in_approval_step_id	 	IN	approval_step.approval_step_id%TYPE,
	in_sheet_key			IN	approval_step_sheet.sheet_key%TYPE,
	in_specific_ind_root_id	IN	pending_region.pending_region_id%TYPE DEFAULT NULL,
	in_specific_region_id	IN	pending_region.pending_region_id%TYPE DEFAULT NULL
);

PROCEDURE Init(
	in_act_id			 IN	security_pkg.T_ACT_ID,
	in_approval_step_id	 IN	approval_step.approval_step_id%TYPE
);

-- Supposed to be internal but called by pending_pkg
PROCEDURE FillSheetFromParent;

END approval_step_range_pkg;
/
