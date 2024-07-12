CREATE OR REPLACE PACKAGE CSR.initiative_export_pkg
IS

PROCEDURE PrepExportViewFilter(
	in_text_filter			IN  VARCHAR2, 
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN 	security_pkg.T_SID_ID,
	in_project_sid			IN 	security_pkg.T_SID_ID,
	in_rag_status_id		IN 	security_pkg.T_SID_ID,
	in_tag_id				IN 	security_pkg.T_SID_ID,
	in_usergroup1_id		IN 	security_pkg.T_SID_ID,
	in_user1_id				IN 	security_pkg.T_SID_ID,
	in_usergroup2_id		IN 	security_pkg.T_SID_ID,
	in_user2_id				IN 	security_pkg.T_SID_ID
);

PROCEDURE PrepTeamroomExportViewFilter(
	in_teamroom_sid			IN  security_pkg.T_SID_ID,
	in_text_filter			IN  VARCHAR2, 
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN 	security_pkg.T_SID_ID,
	in_project_sid			IN 	security_pkg.T_SID_ID,
	in_rag_status_id		IN 	security_pkg.T_SID_ID,
	in_tag_id				IN 	security_pkg.T_SID_ID,
	in_usergroup1_id		IN 	security_pkg.T_SID_ID,
	in_user1_id				IN 	security_pkg.T_SID_ID,
	in_usergroup2_id		IN 	security_pkg.T_SID_ID,
	in_user2_id				IN 	security_pkg.T_SID_ID
);

PROCEDURE PrepPropertyExportViewFilter(
	in_property_sid			IN  security_pkg.T_SID_ID,
	in_text_filter			IN  VARCHAR2, 
	in_region_sid			IN 	security_pkg.T_SID_ID,
	in_flow_state_id		IN 	security_pkg.T_SID_ID,
	in_project_sid			IN 	security_pkg.T_SID_ID,
	in_rag_status_id		IN 	security_pkg.T_SID_ID,
	in_tag_id				IN 	security_pkg.T_SID_ID,
	in_usergroup1_id		IN 	security_pkg.T_SID_ID,
	in_user1_id				IN 	security_pkg.T_SID_ID,
	in_usergroup2_id		IN 	security_pkg.T_SID_ID,
	in_user2_id				IN 	security_pkg.T_SID_ID
);

PROCEDURE GetDataForExport (
	out_data				OUT	security_pkg.T_OUTPUT_CUR,
	out_initiatives			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_users				OUT	security_pkg.T_OUTPUT_CUR,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uoms				OUT	security_pkg.T_OUTPUT_CUR,
	out_assocs				OUT	security_pkg.T_OUTPUT_CUR,
	out_teams				OUT	security_pkg.T_OUTPUT_CUR,
	out_sponsors			OUT	security_pkg.T_OUTPUT_CUR
);

END initiative_export_pkg;
/