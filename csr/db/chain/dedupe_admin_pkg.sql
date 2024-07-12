CREATE OR REPLACE PACKAGE CHAIN.dedupe_admin_pkg
IS

PROCEDURE GetImportSources(
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SaveImportSource(
	in_import_source_id				IN import_source.import_source_id%TYPE,
	in_name							IN import_source.name%TYPE,
	in_position						IN import_source.position%TYPE,
	in_no_match_action_id			IN import_source.dedupe_no_match_action_id%TYPE,
	in_lookup_key					IN import_source.lookup_key%TYPE,
	in_override_company_active		IN import_source.override_company_active%TYPE DEFAULT 0,
	out_import_source_id			OUT import_source.import_source_id%TYPE
);

PROCEDURE DeleteImportSource(
	in_import_source_id				IN import_source.import_source_id%TYPE
);

PROCEDURE GetMappings(
	in_dedupe_staging_link_id		IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_mapping_cur					OUT SYS_REFCURSOR
);

PROCEDURE SetRuleSetsPositions(
	in_dedupe_rule_set_ids				IN	security_pkg.T_SID_IDS
);

PROCEDURE SetRulesPositions(
	in_dedupe_rule_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SetImportSourcesPositions(
	in_import_source_ids			IN	security_pkg.T_SID_IDS
);

PROCEDURE SetStagingLinksPositions(
	in_staging_link_ids				IN	security_pkg.T_SID_IDS
);

-- in_mapping_ids, in_rule_type_ids, in_match_thresholds are expected to be in sync
PROCEDURE SaveRuleSet(
	in_dedupe_rule_set_id			IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_description					IN dedupe_rule_set.description%TYPE,
	in_dedupe_staging_link_id		IN dedupe_rule_set.dedupe_staging_link_id%TYPE,
	in_dedupe_match_type_id			IN dedupe_rule_set.dedupe_match_type_id%TYPE,
	in_rule_set_position			IN dedupe_rule_set.position%TYPE,
	in_rule_ids						IN security_pkg.T_SID_IDS, 
	in_mapping_ids					IN security_pkg.T_SID_IDS, 
	in_rule_type_ids				IN security_pkg.T_SID_IDS,
	in_match_thresholds				IN helper_pkg.T_NUMBER_ARRAY,
	out_dedupe_rule_set_id			OUT dedupe_rule_set.dedupe_rule_set_id%TYPE
);

/* used for unit tests */
PROCEDURE TestSaveRuleSetForExactMatches(
	in_dedupe_rule_set_id			IN dedupe_rule_set.dedupe_rule_set_id%TYPE,
	in_description					IN dedupe_rule_set.description%TYPE,
	in_dedupe_staging_link_id		IN dedupe_rule_set.dedupe_staging_link_id%TYPE,
	in_rule_set_position			IN dedupe_rule_set.position%TYPE,
	in_rule_ids						IN security_pkg.T_SID_IDS, 
	in_mapping_ids					IN security_pkg.T_SID_IDS, 
	out_dedupe_rule_set_id			OUT dedupe_rule_set.dedupe_rule_set_id%TYPE
);

PROCEDURE GetRuleSets(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_rule_sets_cur 			OUT SYS_REFCURSOR,
	out_rules_cur				OUT SYS_REFCURSOR
);

PROCEDURE DeleteRuleSet(
	in_dedupe_rule_set_id		IN dedupe_rule_set.dedupe_rule_set_id%TYPE
);

PROCEDURE GetDedupeRuleTypes(
	out_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetDedupeMatchTypes(
	out_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetFields(
	out_cur	OUT SYS_REFCURSOR
);

PROCEDURE GetPreProcFields(
	out_cur	OUT SYS_REFCURSOR
);

PROCEDURE SaveMapping(
	in_dedupe_mapping_id			IN dedupe_mapping.dedupe_mapping_id%TYPE,
	in_dedupe_staging_link_id		IN dedupe_mapping.dedupe_staging_link_id%TYPE,
	in_tab_sid 						IN dedupe_mapping.tab_sid%TYPE,
	in_col_sid 						IN dedupe_mapping.col_sid%TYPE,
	in_dedupe_field_id 				IN dedupe_mapping.dedupe_field_id%TYPE DEFAULT NULL,
	in_reference_id		 			IN dedupe_mapping.reference_id%TYPE DEFAULT NULL,
	in_tag_group_id		 			IN dedupe_mapping.tag_group_id%TYPE DEFAULT NULL,
	in_role_sid			 			IN security_pkg.T_SID_ID DEFAULT NULL,
	in_destination_tab_sid			IN dedupe_mapping.destination_tab_sid%TYPE DEFAULT NULL,
	in_destination_col_sid			IN dedupe_mapping.destination_col_sid%TYPE DEFAULT NULL,
	in_allow_create_alt_comp_name	IN dedupe_mapping.allow_create_alt_company_name%TYPE DEFAULT NULL,
	in_fill_nulls_under_ui_source	IN dedupe_mapping.fill_nulls_under_ui_source%TYPE DEFAULT 0,
	out_dedupe_mapping_id			OUT dedupe_mapping.dedupe_mapping_id%TYPE
);

PROCEDURE DeleteMapping(
	in_dedupe_mapping_id			IN dedupe_mapping.dedupe_mapping_id%TYPE
);

PROCEDURE GetStagingLink(
	in_dedupe_staging_link_id	IN dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_staging_link_cur 		OUT SYS_REFCURSOR
);

PROCEDURE GetStagingLinks(
	in_import_source_id		IN import_source.import_source_id%TYPE,
	out_staging_link_cur 	OUT SYS_REFCURSOR
);

PROCEDURE GetPotentialParentStagings(
	in_import_source_id 			IN  dedupe_staging_link.import_source_id%TYPE,
	in_dedupe_staging_link_id 		IN  dedupe_staging_link.dedupe_staging_link_id%TYPE,
	out_dedupe_staging_link_cur 	OUT SYS_REFCURSOR
);

PROCEDURE SaveStagingLink(
	in_dedupe_staging_link_id 		IN  dedupe_staging_link.dedupe_staging_link_id%TYPE,
	in_import_source_id 			IN  dedupe_staging_link.import_source_id%TYPE,
	in_description 					IN  dedupe_staging_link.description%TYPE,
	in_staging_tab_sid 				IN  dedupe_staging_link.staging_tab_sid%TYPE,
	in_position 					IN  dedupe_staging_link.position%TYPE,
	in_staging_id_col_sid 			IN  dedupe_staging_link.staging_id_col_sid%TYPE,
	in_staging_batch_num_col_sid 	IN  dedupe_staging_link.staging_batch_num_col_sid%TYPE DEFAULT NULL,
	in_staging_src_lookup_col_sid 	IN  dedupe_staging_link.staging_source_lookup_col_sid%TYPE DEFAULT NULL,
	in_parent_staging_link_id 		IN  dedupe_staging_link.parent_staging_link_id%TYPE DEFAULT NULL,
	in_destination_tab_sid 			IN  dedupe_staging_link.destination_tab_sid%TYPE DEFAULT NULL,
	out_dedupe_staging_link_id 		OUT dedupe_staging_link.dedupe_staging_link_id%TYPE
);

PROCEDURE DeleteStagingLink(
	in_dedupe_staging_link_id 		IN dedupe_staging_link.dedupe_staging_link_id%TYPE
);

PROCEDURE GetProcessedRecords(
	in_import_source_id			IN import_source.import_source_id%TYPE,
	in_start					IN NUMBER,
	in_page_size				IN NUMBER,
	out_cur 					OUT SYS_REFCURSOR,
	out_matches_cur				OUT SYS_REFCURSOR,
	out_staging_links_cur		OUT SYS_REFCURSOR
);

PROCEDURE GetMergedDataDetails(
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	in_get_errors					IN NUMBER,
	out_cur 						OUT SYS_REFCURSOR
);

PROCEDURE GetRecordMatches(
	in_dedupe_processed_record_id	IN dedupe_processed_record.dedupe_processed_record_id%TYPE,
	out_matches_cur					OUT SYS_REFCURSOR,
	out_tags_cur					OUT SYS_REFCURSOR,
	out_refs_cur					OUT SYS_REFCURSOR,
	out_alt_comp_names				OUT SYS_REFCURSOR
);

PROCEDURE GetLockedCompanyTabs(
	in_company_sid					IN security.security_pkg.T_SID_ID,
	in_company_tab_ids				IN security.security_pkg.T_SID_IDS,
	out_cur							OUT security.security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetPreProcRulesPositions(
	in_dedupe_preproc_rule_ids		IN	security_pkg.T_SID_IDS
);

PROCEDURE SavePreProcRule(
	in_dedupe_preproc_rule_id	    IN dedupe_preproc_rule.dedupe_preproc_rule_id%TYPE, 
	in_pattern               	    IN dedupe_preproc_rule.pattern%TYPE, 
	in_replacement                  IN dedupe_preproc_rule.replacement%TYPE, 
	in_run_order            	    IN dedupe_preproc_rule.run_order%TYPE, 
	in_dedupe_field_ids				IN security_pkg.T_SID_IDS,
	in_countries					IN security_pkg.T_VARCHAR2_ARRAY,
	out_dedupe_preproc_rule_id	    OUT dedupe_preproc_rule.dedupe_preproc_rule_id%TYPE
);

PROCEDURE DeletePreProcRule(
	in_dedupe_preproc_rule_id	    IN dedupe_preproc_rule.dedupe_preproc_rule_id%TYPE
);

PROCEDURE GetPreProcRules (
	out_rules	 					OUT security_pkg.T_OUTPUT_CUR, 
	out_fields	 					OUT security_pkg.T_OUTPUT_CUR, 
	out_countries	 				OUT security_pkg.T_OUTPUT_CUR
);

FUNCTION HasProcessedRecordAccess
RETURN BOOLEAN;

PROCEDURE SetSystemDefaultMapAndRules(
	in_try_reset	IN NUMBER DEFAULT 0
);

END dedupe_admin_pkg;
/

