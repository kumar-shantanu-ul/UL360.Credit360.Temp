CREATE OR REPLACE PACKAGE CHEM.SUBSTANCE_PKG AS

/* NOTE THAT RECOMPILING THIS AGAINST LIVE MAY RESULT IN SESSIONS HANGING AS CSR.SHEET_PKG HAS
   A DEPENDENCY ON THIS CODE, SO RECOMPILE CAREFULLY!
*/

WAIVER_REQUIRED		CONSTANT	NUMBER(1) := 1;
WAIVER_NOTREQUIRED	CONSTANT	NUMBER(1) := 0;


PROCEDURE AddCas(
	in_cas_code			IN cas.cas_code%TYPE,
	in_name				IN cas.name%TYPE,
	in_category			IN cas.category%TYPE,
	in_is_voc			IN cas.is_voc%TYPE,
	in_unconfirmed		IN cas.unconfirmed%TYPE
);


PROCEDURE AddCas(
	in_cas_code		IN cas.cas_code%TYPE,
	in_name			IN cas.name%TYPE,
	in_unconfirmed	IN cas.unconfirmed%TYPE
);


-- creates a substance for a site and will update it only if a substance_id is provided
PROCEDURE CreateOrUpdateLocalSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_local_ref			IN	substance_region.local_ref%TYPE,
	in_description			IN	substance.description%TYPE,
	in_classification_id	IN	classification.classification_id%TYPE,
	in_manufacturer_name	IN	manufacturer.name%TYPE,
	in_region_sid			IN	substance.region_sid%TYPE,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pct_comps			IN	security_pkg.T_DECIMAL_ARRAY,
	out_substance_id		OUT	security_pkg.T_SID_ID
);

-- creates a global substance (12NC) and will update it if a substance_id is provided OR there is a unique key violation without a substance_id
PROCEDURE CreateOrUpdateGlobalSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_ref					IN	substance.ref%TYPE,
	in_description			IN	substance.description%TYPE,
	in_classification_id	IN	classification.classification_id%TYPE,
	in_manufacturer_name	IN	manufacturer.name%TYPE,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY,
	in_pct_comps			IN	security_pkg.T_DECIMAL_ARRAY,
	out_substance_id		OUT	security_pkg.T_SID_ID
);


PROCEDURE UpdateSubLocalRef(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid			IN	substance_region.region_sid%TYPE,
	in_local_ref			IN	substance_region.local_ref%TYPE
);

PROCEDURE AddSubstanceCAS(
	in_substance_id			IN	security_pkg.T_SID_ID,
	in_cas_code				IN	cas.cas_code%TYPE,
	in_pct_comp				IN	substance_cas.pct_composition%TYPE
);

PROCEDURE DeleteSubstanceCAS(
	in_substance_id			IN	security_pkg.T_SID_ID,
	in_cas_code				IN	cas.cas_code%TYPE
);

PROCEDURE DeleteSubstanceCasCodes(
	in_substance_id			IN	security_pkg.T_SID_ID,
	in_cas_codes			IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetSubstanceCAS(
	in_substance_id			IN	security_pkg.T_SID_ID,
    in_codes            	IN	VARCHAR2,
	in_region_sid			IN	security_pkg.T_SID_ID DEFAULT NULL  -- if we know the region where the substance is being used
);

FUNCTION SetManufacturer(
	in_manufacturer_name	IN	manufacturer.name%TYPE
) RETURN manufacturer.manufacturer_id%TYPE;

PROCEDURE AddCasRestriction(
	in_cas_code			IN	cas.cas_code%TYPE,
	in_root_region_sid	IN	security_pkg.T_SID_ID,
	in_start_dtm		IN	cas_restricted.start_dtm%TYPE,
	in_end_dtm			IN	cas_restricted.end_dtm%TYPE DEFAULT NULL,
	in_category			IN	cas.category%TYPE DEFAULT NULL,
	in_remarks			IN	cas_restricted.remarks%TYPE DEFAULT NULL,
	in_source			IN	cas_restricted.source%TYPE DEFAULT NULL,
	in_clp_table_3_1	IN	cas_restricted.clp_table_3_1%TYPE DEFAULT NULL,
	in_clp_table_3_2	IN	cas_restricted.clp_table_3_2%TYPE DEFAULT NULL
);

PROCEDURE ExportSheet(
	in_sheet_Id			IN	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetSubstanceCasCodes(
	in_substance_id			IN	substance.substance_id%TYPE,
	out_cas_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstance(
	in_ref					IN	substance.ref%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_sub_cur				OUT	Security_Pkg.T_OUTPUT_CUR,
	out_cas_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_substance_file_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_transition_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstance(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_sub_cur				OUT	Security_Pkg.T_OUTPUT_CUR,
	out_cas_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_substance_file_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_transition_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceList(
	in_search_phrase	IN	varchar2,
	in_fetch_limit		IN	number,
	in_region_sid		IN	security.security_pkg.T_SID_ID DEFAULT NULL, -- exclude substances registered for this region
	out_sub_cur			OUT Security_Pkg.T_OUTPUT_CUR
);

FUNCTION IsApprovedState(
	in_state_lookup		IN	VARCHAR2
) RETURN NUMBER;

FUNCTION IsSubstanceAccessAllowed(
	in_user_sid			IN	security.security_pkg.T_SID_ID,
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_is_editing		IN	NUMBER DEFAULT 0,
	in_is_approved		IN NUMBER DEFAULT 0
) RETURN BOOLEAN;

PROCEDURE GetRegisteredSubstanceList(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_approved		IN	NUMBER,
	in_start_dtm	IN	substance_process_use.start_dtm%TYPE DEFAULT NULL,
	in_end_dtm		IN	substance_process_use.end_dtm%TYPE DEFAULT NULL,
	out_sub_cur		OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION CanRegisterSubstance(
	in_region_sid	IN	security_pkg.T_SID_ID
) RETURN NUMBER;

PROCEDURE RegisterSubstanceForRegion(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_require_approval	IN	NUMBER
);

PROCEDURE GetTransitions(
	in_substance_id	IN	substance.substance_id%TYPE,
	in_region_sid		IN  security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetConsumptionPeriods(
	in_region_sid		IN  security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE AddToFlow(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	out_flow_item_id	OUT	substance_region.flow_item_id%TYPE
);

PROCEDURE SetFlowState(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	csr.flow_state.flow_state_id%TYPE,
	in_comment_text		IN	csr.flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security.security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetFlowState(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security.security_pkg.T_SID_ID,
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	csr.flow_state.flow_state_id%TYPE,
	in_comment_text		IN	csr.flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security.security_pkg.T_VARCHAR2_ARRAY,
	out_state 			OUT SYS_REFCURSOR, 
	out_transitions		OUT SYS_REFCURSOR
);

PROCEDURE GetUsagesList(
	out_usages_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE LookupCas(
	in_region_sid  	IN 	security_pkg.T_SID_ID,
	in_cas_code		IN	cas.cas_code%TYPE,
	out_cas_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLookups(
	out_class_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_manu_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveSubstanceRegionProcess(
	in_ref				IN	substance.ref%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_label			IN	substance_region_process.label%TYPE,
	in_usage_id			IN	usage.usage_id%TYPE,
	out_process_id		OUT	substance_region_process.process_id%TYPE
);

PROCEDURE SaveSubstanceRegionProcess(
	in_substance_id		IN	substance.substance_id%TYPE,
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_label			IN	substance_region_process.label%TYPE,
	in_usage_id			IN	usage.usage_id%TYPE,
	out_process_id		OUT	substance_region_process.process_id%TYPE
);

PROCEDURE UNSEC_DeleteSubstance(
	in_substance_id	IN	substance.substance_id%TYPE	
);

PROCEDURE DeleteSubstanceRegionProcess(
	in_process_id		IN	substance_region_process.process_id%TYPE
);

PROCEDURE AddSubstanceFile(
	in_substance_id	IN	substance.substance_id%TYPE,
	in_cache_key	IN	aspen2.filecache.cache_key%TYPE
);

PROCEDURE DeleteSubstanceProcessUse(
	in_substance_process_use_id		IN substance_process_use.substance_process_use_id%TYPE
);

PROCEDURE SetCASGroupMember(
	in_group_name		IN	cas_group.label%TYPE,
	in_cas_code			IN	cas.cas_code%TYPE
);


PROCEDURE SetSubstProcessCasDest(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	in_cas_code						IN	cas.cas_code%TYPE,
	in_to_air_pct					IN	substance_process_cas_dest.to_air_pct%TYPE,
	in_to_product_pct				IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_to_waste_pct					IN	substance_process_cas_dest.to_waste_pct%TYPE,
	in_to_water_pct					IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_remaining_dest				IN	substance_process_cas_dest.remaining_dest%TYPE
);

PROCEDURE ImportSubstanceProcessUse(
	in_substance_ref				IN	substance.ref%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_process_label				IN	substance_region_process.label%TYPE,
	in_usage_id						IN	usage.usage_id%TYPE,
	in_root_deleg_sid				IN	security_pkg.T_SID_ID,
	in_mass_value					IN	substance_process_use.mass_value%TYPE,
	in_note							IN	substance_process_use.note%TYPE,
	in_start_dtm					IN	substance_process_use.start_dtm%TYPE,
	in_end_dtm						IN	substance_process_use.end_dtm%TYPE,
	in_entry_mass_value 			IN	substance_process_use.entry_mass_value%TYPE,
	in_entry_std_measure_conv_id 	IN	substance_process_use.entry_std_measure_conv_id%TYPE,
	out_substance_process_use_id 	OUT	substance_process_use.substance_process_use_id%TYPE
);

PROCEDURE ImportSubstProcessCasDest(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	in_to_air_pct					IN	substance_process_cas_dest.to_air_pct%TYPE,
	in_to_product_pct				IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_to_waste_pct					IN	substance_process_cas_dest.to_waste_pct%TYPE,
	in_to_water_pct					IN	substance_process_cas_dest.to_product_pct%TYPE,
	in_remaining_dest				IN	substance_process_cas_dest.remaining_dest%TYPE
);

PROCEDURE SetSubstanceProcessUse(
	in_substance_process_use_id		IN	substance_process_use.substance_process_use_id%TYPE,
	in_substance_id					IN	substance.substance_id%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_process_id					IN	substance_region_process.process_id%TYPE,
	in_root_deleg_sid				IN	security_pkg.T_SID_ID,
	in_mass_value					IN	substance_process_use.mass_value%TYPE,
	in_note							IN	substance_process_use.note%TYPE,
	in_start_dtm					IN	substance_process_use.start_dtm%TYPE,
	in_end_dtm						IN	substance_process_use.end_dtm%TYPE,
	in_entry_mass_value 			IN	substance_process_use.entry_mass_value%TYPE,
	in_entry_std_measure_conv_id 	IN	substance_process_use.entry_std_measure_conv_id%TYPE,
	in_local_ref					IN	substance_region.local_ref%TYPE,
	in_persist_files				IN	security_pkg.T_SID_IDS,
	out_substance_process_use_id 	OUT	substance_process_use.substance_process_use_id%TYPE
);

PROCEDURE AddSubstanceProcessUseFile(
	in_substance_process_use_id 		IN	substance_process_use.substance_process_use_id%TYPE,
	in_cache_key						IN	aspen2.filecache.cache_key%TYPE,
	out_subst_process_use_file_id		OUT	security_pkg.T_SID_ID
);

PROCEDURE DownloadProcessUseFile(
	in_subst_process_use_file_id		IN	substance_process_use_file.substance_process_use_file_id%TYPE,
	out_sub_cur							OUT	Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceProcessUse(
	in_substance_process_use_id				IN	substance_process_use.substance_process_use_id%TYPE,
	out_proc_use_cur						OUT	security_pkg.T_OUTPUT_CUR,
	out_proc_use_file_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_proc_cas_dest_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceProcessUseList(
	in_root_deleg_sid			IN	substance_process_use.root_delegation_sid%TYPE,
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	substance_process_use.start_dtm%TYPE,
	in_end_dtm					IN	substance_process_use.end_dtm%TYPE,
	in_incomplete_rows			IN	NUMBER,
	out_subst_proc_use_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceRegionProcesses(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid 			IN	security_pkg.T_SID_ID,
	out_subst_rgn_proc_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDefaultProcessDests(
	in_substance_id			IN	substance.substance_id%TYPE,
	in_region_sid 			IN	security_pkg.T_SID_ID,
	in_process_id			IN	substance_region_process.process_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceProcessCasDest(
	in_process_id					IN substance_region_process.process_id%TYPE,
	out_subst_proc_cas_dest_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE LocateSubstanceProcessCasDest(
	in_ref							IN	substance.ref%TYPE,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_label						IN	substance_region_process.label%TYPE,
	out_subst_proc_cas_dest_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceProcessUses(
	in_process_id							IN	substance_region_process.process_id%TYPE,
	out_proc_use_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceProcessUseFile(
	in_substance_process_use_id				IN	substance_process_use.substance_process_use_id%TYPE,
	out_proc_use_file_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSubstanceProcessUseCasDest(
	in_substance_process_use_id				IN	substance_process_use.substance_process_use_id%TYPE,
	out_proc_cas_dest_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCasGroupAggr(
	in_aggregate_ind_group_id	IN	NUMBER,
	in_start_dtm				IN	DATE,
	in_end_dtm					IN	DATE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

END SUBSTANCE_PKG;
/
