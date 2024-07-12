CREATE OR REPLACE PACKAGE  DONATIONS.funding_commitment_Pkg
IS
FC_ACTIVE				CONSTANT NUMBER(10) := 1;
FC_EXPIRED				CONSTANT NUMBER(10) := 2;
FC_EXPIRED_PENDING_REV	CONSTANT NUMBER(10) := 3;
FC_NO_BUDGETS			CONSTANT NUMBER(10) := 10;
FC_INVALID				CONSTANT NUMBER(10) := 11;

-- Securable object callbacks
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
);

PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);


PROCEDURE CreateFundingCommitment(
	in_name						IN funding_commitment.name%TYPE,
	in_description				IN funding_commitment.description%TYPE,
	in_scheme_sid				IN funding_commitment.scheme_sid%TYPE,
	in_recipient_sid			IN funding_commitment.recipient_sid%TYPE,
	in_region_group_sid			IN funding_commitment.region_group_sid%TYPE,
	in_region_sid				IN funding_commitment.region_sid%TYPE,
	in_donation_status_sid		IN funding_commitment.donation_status_sid%TYPE,
	in_reminder_dtm				IN funding_commitment.reminder_dtm%TYPE,
	in_payment_dtm				IN funding_commitment.payment_dtm%TYPE,
	in_review_on_expiry			IN funding_commitment.review_on_expiry%TYPE,
	in_tag_ids					IN security_pkg.T_SID_IDS,
	out_funding_commitment_sid	OUT security_PKG.T_SID_ID
);

PROCEDURE AmendFundingCommitment(
	in_funding_commitment_sid	IN funding_commitment.funding_commitment_sid%TYPE,
	in_name						IN funding_commitment.name%TYPE,
	in_description				IN funding_commitment.description%TYPE,
	in_scheme_sid				IN funding_commitment.scheme_sid%TYPE,
	in_recipient_sid			IN funding_commitment.recipient_sid%TYPE,
	in_region_group_sid			IN funding_commitment.region_group_sid%TYPE,
	in_region_sid				IN funding_commitment.region_sid%TYPE,
	in_donation_status_sid		IN funding_commitment.donation_status_sid%TYPE,
	in_reminder_dtm				IN funding_commitment.reminder_dtm%TYPE,
	in_payment_dtm				IN funding_commitment.payment_dtm%TYPE,
	in_review_on_expiry			IN funding_commitment.review_on_expiry%TYPE,
	in_tag_ids					IN security_pkg.T_SID_IDS
);

PROCEDURE GetFundingCommitments(
	in_start_row					IN	INTEGER,
	in_row_count					IN	INTEGER,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetFundingCommitments(
	in_start_row					IN	INTEGER,
	in_row_count					IN	INTEGER,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_filter_ids					IN  security_Pkg.T_SID_IDS,	-- not sids but will do
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllFundingCommitments(
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetFundingCommitment(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetFcSchemes(
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetFcFromDonationId(
	in_donation_id					IN  donation.donation_id%TYPE,
	out_cur							OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetBudgets(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_budgets_cur					OUT security_Pkg.T_OUTPUT_CUR,
	out_sel_budgets_cur				OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE SetBudgets(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_budget_ids					IN security_pkg.T_SID_IDS,
	in_budget_amounts				IN donation_pkg.T_DECIMAL_ARRAY
);

FUNCTION GetStatus(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE GetReview(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	out_review_cur					OUT security_Pkg.T_OUTPUT_CUR,
	out_docs_cur					OUT security_Pkg.T_OUTPUT_CUR
);

PROCEDURE SetReview(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_notes						IN funding_commitment.notes%TYPE,
	in_last_review_dtm				IN funding_commitment.last_review_dtm%TYPE
);

PROCEDURE SetReviewDocs(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_fc_upload_sids				IN security_pkg.T_SID_IDS
);

PROCEDURE internal_setTags(
	in_funding_commitment_sid		security_pkg.T_SID_ID,
	in_tag_ids						security_pkg.T_SID_IDS
);

PROCEDURE SetFcDonation(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_donation_id					IN donation.donation_id%TYPE,
	in_aligned_dtm					IN donation.entered_dtm%TYPE
);

PROCEDURE DeleteFcDonation(
	in_donation_id					IN	donation.donation_id%TYPE,
	in_funding_commitment_sid		IN	funding_commitment.funding_commitment_sid%TYPE
);

PROCEDURE GetFcForAlert(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE RecordUserBatchRun(	
	in_app_sid						security_pkg.T_SID_ID,
	in_csr_user_sid					security_pkg.T_SID_ID,
	in_funding_commitment_sid 		security_pkg.T_SID_ID
);

FUNCTION GetFcDonationId(
	in_funding_commitment_sid		IN security_pkg.T_SID_ID,
	in_budget_id					IN budget.budget_id%TYPE
) RETURN NUMBER;


FUNCTION GetFundingCommitmentRowNum(
	in_funding_commitment_sid		IN	security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_filter_ids					IN  security_Pkg.T_SID_IDS
) RETURN NUMBER;

PROCEDURE internal_PrepareFcFilters(
	in_act_id 						IN security_pkg.T_ACT_ID,
	in_parent_sid					IN security_pkg.T_SID_ID,
	in_order_by						IN	VARCHAR2,
	in_order_dir					IN	VARCHAR2,
	in_filter_ids					IN  security_Pkg.T_SID_IDS,
	out_has_filter					OUT NUMBER,
	out_can_see_all					OUT NUMBER,
	out_order_by					OUT VARCHAR2,
	out_filter_ids					OUT security.T_SID_TABLE
);

FUNCTION internal_GetFcTagId RETURN NUMBER;

FUNCTION HasFundingCommitments RETURN NUMBER;

FUNCTION internal_ConcatTagIds(
	in_funding_commitment_sid	IN security_pkg.T_SID_ID
) RETURN VARCHAR2;

FUNCTION internal_ConcatTags(
	in_funding_commitment_sid	IN security_pkg.T_SID_ID,
	in_max_length				IN 	INTEGER DEFAULT 100
) RETURN VARCHAR2;

FUNCTION internal_GetThisYearDate(
	in_dtm		IN	DATE
) RETURN DATE;

END funding_commitment_Pkg;
/
