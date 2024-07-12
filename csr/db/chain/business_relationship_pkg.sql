CREATE OR REPLACE PACKAGE CHAIN.business_relationship_pkg
IS

PROCEDURE GetBusinessRelationshipTypes (
	out_bus_rel_type_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_tier_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_tier_comp_type_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveBusinessRelationshipType(
	in_bus_rel_type_id			IN	business_relationship_type.business_relationship_type_id%TYPE,
	in_label					IN	business_relationship_type.label%TYPE,
	in_form_path				IN	business_relationship_type.form_path%TYPE,
	in_tab_sid					IN	business_relationship_type.tab_sid%TYPE,
	in_column_sid				IN	business_relationship_type.column_sid%TYPE,
	in_use_specific_dates		IN	business_relationship_type.use_specific_dates%TYPE, 
	in_period_set_id			IN	business_relationship_type.period_set_id%TYPE, 
	in_period_interval_id		IN	business_relationship_type.period_interval_id%TYPE,
	out_bus_rel_type_id			OUT	business_relationship_type.business_relationship_type_id%TYPE
);

PROCEDURE SaveBusinessRelationshipTier(
	in_bus_rel_type_id			IN	business_relationship_tier.business_relationship_type_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_tier.business_relationship_tier_id%TYPE,
	in_tier						IN	business_relationship_tier.tier%TYPE,
	in_label					IN	business_relationship_tier.label%TYPE,
	in_direct					IN	business_relationship_tier.direct_from_previous_tier%TYPE,
	in_create_supplier_rel		IN  business_relationship_tier.create_supplier_relationship%TYPE,
	in_create_new_company		IN  business_relationship_tier.create_new_company%TYPE,
	in_allow_multiple_companies	IN	business_relationship_tier.allow_multiple_companies%TYPE,
	in_crt_sup_rels_w_lower_tiers	IN business_relationship_tier.create_sup_rels_w_lower_tiers%TYPE,
	in_company_type_ids			IN	security_pkg.T_SID_IDS,
	out_bus_rel_tier_id			OUT	business_relationship_tier.business_relationship_tier_id%TYPE
);

PROCEDURE DeleteBusRelTiers(
	in_bus_rel_type_id			IN	business_relationship_tier.business_relationship_type_id%TYPE,
	in_from_tier				IN	business_relationship_tier.tier%TYPE
);

PROCEDURE DeleteBusinessRelationshipType(
	in_bus_rel_type_id			IN	business_relationship_type.business_relationship_type_id%TYPE
);

PROCEDURE CreateBusinessRelationship(
	in_bus_rel_type_id			IN	business_relationship.business_relationship_type_id%TYPE,
	out_bus_rel_id				OUT	business_relationship.business_relationship_id%TYPE
);

PROCEDURE DeleteBusinessRelationship(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE
);

PROCEDURE AddBusinessRelationshipCompany(
	in_bus_rel_id				IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_pos						IN	business_relationship_company.pos%TYPE,
	in_company_sid				IN	business_relationship_company.company_sid%TYPE,
	in_allow_inactive			IN	NUMBER DEFAULT 0,
	in_allow_admin				IN	NUMBER DEFAULT 0
);

PROCEDURE DidCreateBusinessRelationship(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE,
	in_merge_if_duplicate		IN	NUMBER DEFAULT 0,
	out_bus_rel_id				OUT	business_relationship.business_relationship_id%TYPE
);

PROCEDURE SetBusinessRelationshipPeriods(
	in_bus_rel_id				IN	business_relationship_period.business_relationship_id%TYPE,
	in_keep_bus_rel_perd_ids	IN	security_pkg.T_SID_IDS
);

PROCEDURE SaveBusinessRelationshipPeriod(
	in_bus_rel_id				IN	business_relationship_period.business_relationship_id%TYPE,
	in_bus_rel_period_id		IN	business_relationship_period.business_rel_period_id%TYPE,
	in_start_dtm				IN	business_relationship_period.start_dtm%TYPE,
	in_end_dtm					IN	business_relationship_period.end_dtm%TYPE,
	out_bus_rel_period_id		OUT	business_relationship_period.business_rel_period_id%TYPE
);

PROCEDURE DidUpdateBusinessRelationship(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE	
);

PROCEDURE MergeOverlappingPeriods(
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE	
);

PROCEDURE GetBusinessRelationship (
	in_bus_rel_id				IN	business_relationship.business_relationship_id%TYPE,
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBusinessRelationships(
	in_bus_rel_ids				security.T_ORDERED_SID_TABLE,
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterBusinessRelationships(
	in_company_sid				IN	business_relationship_company.company_sid%TYPE,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	in_compound_filter_id		IN	compound_filter.compound_filter_id%TYPE DEFAULT NULL,
	in_include_inactive			IN	NUMBER,
	in_bus_rel_type_id			IN	business_relationship.business_relationship_type_id%TYPE DEFAULT NULL,
	out_bus_rel_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_period_cur		OUT	security_pkg.T_OUTPUT_CUR,
	out_bus_rel_comp_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindAncestorsForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindSiblingsForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FindDescendantsForTier(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_bus_rel_tier_id			IN	business_relationship_company.business_relationship_tier_id%TYPE,
	in_company_sids				IN	security_pkg.T_SID_IDS,
	in_search_term  			IN  VARCHAR2 DEFAULT NULL,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetGraphCompanies(
	in_bus_rel_type_id			IN	business_relationship_company.business_relationship_id%TYPE,
	in_company_sids				IN	T_FILTERED_OBJECT_TABLE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SearchCompaniesByBusRelType(
	in_bus_rel_type_id			IN	business_relationship.business_relationship_type_id%TYPE,
	in_search_term 				IN  VARCHAR2,
	in_page   					IN  NUMBER,
	in_page_size    			IN  NUMBER,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR
);

END;
/
