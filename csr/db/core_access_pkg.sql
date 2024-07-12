CREATE OR REPLACE PACKAGE csr.core_access_pkg AS

PROCEDURE GetUserRecordBySid(
	in_csr_user_sid			IN	csr.csr_user.csr_user_sid%TYPE,
	out_user				OUT	CSR.T_USER
);

PROCEDURE GetUserRecordByRef(
	in_user_ref				IN	csr.csr_user.user_ref%TYPE,
	out_user				OUT	CSR.T_USER
);

PROCEDURE GetUserRecordByUserName(
	in_user_name			IN  csr.csr_user.user_name%TYPE,
	out_user				OUT CSR.T_USER
);

FUNCTION GetFlowSidFromTable(
	in_oracle_schema		IN	cms.tab.oracle_schema%TYPE,
	in_oracle_table			IN	cms.tab.oracle_table%TYPE
) 
RETURN security_pkg.T_SID_ID;

PROCEDURE RegionHasTag(
	in_region_sid			IN	region.region_sid%TYPE,
	in_tag_id				IN	tag.tag_id%type,
	out_has_tag				OUT NUMBER
);

PROCEDURE GetTagFromLookup(
	in_lookup_key			IN	csr.tag.lookup_key%TYPE,
	out_tag_id				OUT	csr.tag.tag_id%TYPE
);

PROCEDURE GetTagFromName(
	in_tag_name			IN	csr.tag_description.tag%TYPE,
	in_lang				IN	csr.tag_description.lang%TYPE := 'en',
	out_tag_id			OUT	csr.tag.tag_id%TYPE
);

PROCEDURE GetUserProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user_profile	OUT	csr.T_USER_PROFILE
);

PROCEDURE GetUserRecordAndProfile(
	in_csr_user_sid		IN	csr.user_profile.csr_user_sid%TYPE,
	out_user			OUT	csr.T_USER,
	out_user_profile	OUT	csr.T_USER_PROFILE
);

PROCEDURE GetRegionRecord(
	in_region_sid		IN	region.region_sid%TYPE,
	out_region			OUT	csr.T_REGION
);

PROCEDURE GetChildRegionRecords(
	in_region_sid			IN	region.region_sid%TYPE,
	in_include_inactive 	IN	NUMBER DEFAULT 0,
	out_regions				OUT	csr.T_REGIONS
);

PROCEDURE FilterIssuesBy(
	in_issue_ids			IN	security.security_pkg.T_SID_IDS,
	in_filter_deleted		IN	NUMBER DEFAULT 0,
	in_filter_closed		IN	NUMBER DEFAULT 0,
	in_filter_resolved		IN	NUMBER DEFAULT 0,
	out_filtered_ids		OUT	security.security_pkg.T_SID_IDS
);

PROCEDURE GetFormSidFromLookup(
	in_lookup_key		IN	cms.form.lookup_key%TYPE,
	out_form_sid		OUT	cms.form.form_sid%TYPE
);

PROCEDURE GetDelegationGridIndSidFromPath(
	in_path				IN	csr.delegation_grid.path%TYPE,
	out_ind_sid			OUT	csr.delegation_grid.ind_sid%TYPE
);

PROCEDURE SetOracleSchema(
	in_oracle_schema			IN	csr.customer.oracle_schema%TYPE,
	in_overwrite				IN	NUMBER DEFAULT 0
);

PROCEDURE UpdateAuditRegion(
	in_audit_sid			IN csr.internal_audit.internal_audit_sid%TYPE,
	in_new_region_sid		IN csr.region.region_sid%TYPE
);

PROCEDURE SetCmsTableHelperPackage(
  in_schema				cms.tab.oracle_schema%TYPE,
  in_oracle_table		cms.tab.oracle_table%TYPE,
  in_helper_pkg			cms.tab.helper_pkg%TYPE
);

PROCEDURE SetCmsTableFlowSid(
	in_workflow_label	csr.flow.label%TYPE,
	in_oracle_table		cms.tab.oracle_table%TYPE
);
PROCEDURE SetCmsTableFlowSid(
	in_workflow_sid		security.security_pkg.T_SID_ID,
	in_oracle_table		cms.tab.oracle_table%TYPE
);

PROCEDURE SetCmsTableColumnNullable(
	in_oracle_schema	cms.tab.oracle_schema%TYPE,
	in_oracle_table		cms.tab.oracle_table%TYPE,
	in_oracle_column	cms.tab_column.oracle_column%TYPE,
	in_nullable			cms.tab_column.nullable%TYPE -- (0 or 1)
);

END;
/
