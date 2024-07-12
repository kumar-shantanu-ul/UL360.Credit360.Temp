CREATE OR REPLACE PACKAGE CSR.model_pkg IS

TYPE T_CELLS IS TABLE OF model_map.cell_name%TYPE INDEX BY PLS_INTEGER;
TYPE T_SHEETS IS TABLE OF model_sheet.sheet_name%TYPE INDEX BY PLS_INTEGER;
TYPE T_STRING IS TABLE OF clob INDEX BY PLS_INTEGER;
TYPE T_VALIDATION IS TABLE OF model_validation.validation_text%TYPE INDEX BY PLS_INTEGER;

FIELD_TYPE_UNKNOWN CONSTANT NUMBER := 0;
FIELD_TYPE_EDIT CONSTANT NUMBER := 1;
FIELD_TYPE_MAP CONSTANT NUMBER := 2;
FIELD_TYPE_FORMULA CONSTANT NUMBER := 3;
FIELD_TYPE_COMMENT CONSTANT NUMBER := 4;
FIELD_TYPE_IGNORE CONSTANT NUMBER := 5;
FIELD_TYPE_REGION CONSTANT NUMBER := 6;
FIELD_TYPE_EXPORTED_FORMULA CONSTANT NUMBER := 7;

m_bulk_field_set_base_sid NUMBER(10);
m_bulk_field_set_model_sid NUMBER(10);
m_bulk_field_set_sheet_id NUMBER(10);

integrity_violation EXCEPTION;
PRAGMA EXCEPTION_INIT(integrity_violation, -02291);

FUNCTION ShiftCellName(
	in_cell_name			IN	model_map.cell_name%TYPE,
	in_column_delta			IN	NUMBER,
	in_row_delta			IN	NUMBER
)
RETURN VARCHAR2;

-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id                Access token
 * @param in_sid_id                The sid of the object
 * @param in_class_id            The class Id of the object
 * @param in_name                The name
 * @param in_parent_sid_id        The sid of the parent object
 */
PROCEDURE CreateObject(
    in_act_id             IN security_pkg.T_ACT_ID,
    in_sid_id             IN security_pkg.T_SID_ID,
    in_class_id           IN security_pkg.T_CLASS_ID,
    in_name               IN security_pkg.T_SO_NAME,
    in_parent_sid_id      IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id            Access token
 * @param in_sid_id            The sid of the object
 * @param in_new_name        The name
 */
PROCEDURE RenameObject(
    in_act_id        IN security_pkg.T_ACT_ID,
    in_sid_id        IN security_pkg.T_SID_ID,
    in_new_name      IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id        Access token
 * @param in_sid_id        The sid of the object
 */
PROCEDURE DeleteObject(
    in_act_id        IN security_pkg.T_ACT_ID,
    in_sid_id        IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id                    Access token
 * @param in_sid_id                    The sid of the object
 * @param in_new_parent_sid_id        .
 */
PROCEDURE MoveObject(
    in_act_id				IN security_pkg.T_ACT_ID,
    in_sid_id				IN security_pkg.T_SID_ID,
    in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
); 

---------



FUNCTION GetSidFromLookupKey(
    in_lookup_key   IN   model.lookup_key%TYPE
) RETURN security_pkg.T_SID_ID;

PROCEDURE GetLookupKeyFromSid(
	in_model_sid	IN   security_pkg.T_SID_ID,
	out_lookup_key	OUT  model.lookup_key%TYPE 
);
/**
 * Get list of available models for this user
 *
 */
PROCEDURE GetModelList(
    out_cur         OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetModelInstanceList(
    in_model_sid		IN  model.model_sid%TYPE,
	out_instance_cur	OUT	security_pkg.T_OUTPUT_CUR,
	out_region_cur		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveModelThumbnail(
	in_model_sid			IN	security_pkg.T_SID_ID, 
	out_data				OUT	MODEL.thumb_img%TYPE
);

PROCEDURE SaveModelExcel(
    in_model_sid            IN security_pkg.T_SID_ID,
    in_file_name			IN model.file_name%TYPE,
    in_data                 IN model.excel_doc%TYPE
);

PROCEDURE GetExcel(
    in_model_sid            IN  model.model_sid%TYPE,
    out_model_data          OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetThumbnail(
    in_model_sid            IN security_pkg.T_SID_ID,
    out_cur                 OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveModel(
	in_model_sid					IN	security_pkg.T_SID_ID,
	in_name							IN	model.name%TYPE,
	in_description					IN	model.description%TYPE,
	in_revision						IN	model.revision%TYPE,
	in_scenario_run_sid				IN	model.scenario_run_sid%TYPE,
	out_model_sid					OUT	model.model_sid%TYPE
);

PROCEDURE SaveModelInstance(
	in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_description			IN	model_instance.description%TYPE
);

PROCEDURE ClearFields(
    in_model_sid            IN	security_pkg.T_SID_ID,
    in_sheet_id				IN  model_map.sheet_id%TYPE
);

PROCEDURE PrepareForBulkFieldSet(
    in_model_sid            IN	security_pkg.T_SID_ID,
    in_sheet_id				IN  model_map.sheet_id%TYPE,
    in_purge				IN	NUMBER DEFAULT(0)
);

PROCEDURE CompleteBulkFieldSet(
    in_model_sid            IN	security_pkg.T_SID_ID
);

PROCEDURE BulkSetBasicField(
    in_cell_name			IN	model_map.cell_name%TYPE
);

PROCEDURE BulkSetInstanceBasicField(
    in_cell_name			IN	model_map.cell_name%TYPE
);

PROCEDURE BulkSetMappedField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_indicator_sid		IN	model_map.map_to_indicator_sid%TYPE,
	in_region_type_offset	IN	model_map.region_type_offset%TYPE,
	in_region_offset_tag_id	IN	model_map.region_offset_tag_id%TYPE,
	in_period_offset		IN	model_map.period_offset%TYPE,
	in_period_year_offset	IN	model_map.period_year_offset%TYPE
);

PROCEDURE BulkSetInstanceMappedField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
	in_map_to_indicator_sid	IN	model_instance_map.map_to_indicator_sid%TYPE,
	in_map_to_region_sid	IN	model_instance_map.map_to_region_sid%TYPE,
	in_period_offset		IN	model_instance_map.period_offset%TYPE,
	in_period_year_offset	IN	model_instance_map.period_year_offset%TYPE,
    in_cell_value			IN	model_instance_map.cell_value%TYPE
);

PROCEDURE BulkSetFormulaField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_indicator_sid		IN	model_map.map_to_indicator_sid%TYPE
);

PROCEDURE BulkSetInstanceFormulaField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_indicator_sid		IN	model_map.map_to_indicator_sid%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
    in_cell_value			IN	model_instance_map.cell_value%TYPE
);

PROCEDURE BulkSetVariableField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_previous_sheet_id	IN	model_map.sheet_id%TYPE,
    in_previous_cell_name	IN	model_map.cell_name%TYPE
);

PROCEDURE BulkSetInstanceVariableField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
    in_cell_value			IN	model_instance_map.cell_value%TYPE
);

PROCEDURE BulkSetVariableFieldValidation(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_index				IN	model_validation.display_seq%TYPE,
    in_option				IN	model_validation.validation_text%TYPE
);

PROCEDURE BulkSetRegionField(
    in_cell_name			IN	model_map.cell_name%TYPE,
	in_region_type_offset	IN	model_map.region_type_offset%TYPE,
	in_region_offset_tag_id	IN	model_map.region_offset_tag_id%TYPE
);

PROCEDURE BulkSetInstanceRegionField(
    in_cell_name			IN	model_map.cell_name%TYPE,
    in_source_cell_name		IN	model_map.cell_name%TYPE,
	in_map_to_region_sid	IN	model_instance_map.map_to_region_sid%TYPE
);

PROCEDURE SetFieldComment(
    in_model_sid            IN security_pkg.T_SID_ID,
    in_sheet_id		        IN  model_map.sheet_id%TYPE,
    in_cell_name            IN  model_map.cell_name%TYPE,
    in_comment              IN  model_map.cell_comment%TYPE
);

PROCEDURE ClearInstanceData(
    in_model_sid            IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateInstanceFields(
	in_model_sid			IN security_pkg.T_SID_ID,
	in_sheet_id				IN model_map.sheet_id%TYPE,
	in_cell_name			IN model_map.cell_name%TYPE,
	in_cell_value			IN model_instance_map.cell_value%TYPE
);

PROCEDURE SetFieldMapping(
    in_model_sid            IN  security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
    in_cell_name            IN  model_map.cell_name%TYPE,
    in_map_type_id          IN  model_map.model_map_type_id%TYPE,
    in_map_to_indicator_sid IN  security_pkg.T_SID_ID
);

PROCEDURE SetEditField(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
    in_cell_name            IN  model_map.cell_name%TYPE,
    in_previous_cell_name   IN  model_map.cell_name%TYPE,
    in_validation          IN  T_VALIDATION
);

PROCEDURE GetValidation(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
    in_cell_name            IN  model_map.cell_name%TYPE,
    out_validation          OUT security_pkg.t_output_cur
);

PROCEDURE PurgeSheets(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_sheets               IN  T_SHEETS
);

PROCEDURE BeginUpload(
    in_model_sid            IN  security_pkg.T_SID_ID
);

PROCEDURE UploadCompleted(
    in_model_sid            IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateSheet(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
    in_sheet_index          IN  model_sheet.sheet_index%TYPE,
    in_sheet_name			IN  model_sheet.sheet_name%TYPE,
    in_user_editable        IN  model_sheet.user_editable_boo%TYPE,
    in_display_charts       IN  model_sheet.display_charts_boo%TYPE,
    in_chart_count          IN  model_sheet.chart_count%TYPE,        
	in_structure			IN	CLOB,
	out_sheet_id			OUT	model_map.sheet_id%TYPE
);

PROCEDURE UpdateInstanceSheet(
    in_base_model_sid       IN  security_pkg.T_SID_ID,
    in_model_instance_sid	IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
	in_structure			IN	CLOB
);

PROCEDURE UpdateSheetDetails(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_sheet_id             IN  model_map.sheet_id%TYPE,
    in_user_editable        IN  model_sheet.user_editable_boo%TYPE,
    in_display_charts       IN  model_sheet.display_charts_boo%TYPE    
);

PROCEDURE LoadModel(
    in_model_sid            IN  security_pkg.T_SID_ID,
    in_load_definition      IN  NUMBER,
    in_instance_run			IN	NUMBER,
    out_model_info          OUT security_pkg.T_OUTPUT_CUR,
    out_sheet_info          OUT security_pkg.T_OUTPUT_CUR,
    out_cell_info           OUT security_pkg.T_OUTPUT_CUR,
	out_range_info			OUT	security_pkg.T_OUTPUT_CUR,
	out_region_range_info	OUT	security_pkg.T_OUTPUT_CUR,
	out_validation_info		OUT	security_pkg.T_OUTPUT_CUR,
	out_charts				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetModelInstance(
    in_base_model_sid       IN  security_pkg.T_SID_ID,
    in_description			IN	VARCHAR2,
    in_region_sids          IN  security_pkg.T_SID_IDS,
    in_period_start         IN  date,
    in_period_end           IN  date,
    out_model_sid           OUT security_pkg.T_SID_ID
);

PROCEDURE UpdateRunState(
    in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_run_state			IN	VARCHAR2
);

PROCEDURE LoadInstance(
    in_model_instance_sid	IN	security_pkg.T_SID_ID,
	out_instance_info		OUT	security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteModel(
	in_model_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE ClearRanges(
	in_model_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE CreateRegionRange(
	in_model_sid			IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_cells				IN	T_CELLS,
	in_region_repeat_id		IN	model_region_range.region_repeat_id%TYPE,
	out_range_id			OUT	model_range.range_id%TYPE
);

PROCEDURE RemoveRegionRange(
	in_model_sid			IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_anchor				IN	model_map.cell_name%TYPE
);

PROCEDURE UpdateInstanceStructure(
	in_base_model_sid		IN	security_pkg.T_SID_ID,
	in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_structure			IN	XMLTYPE
);

PROCEDURE ResetInstance(
	in_base_model_sid		IN	security_pkg.T_SID_ID,
	in_model_instance_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE UpdateInstanceChart(
	in_base_model_sid		IN	security_pkg.T_SID_ID,
	in_model_instance_sid	IN	security_pkg.T_SID_ID,
	in_sheet_id				IN	model_map.sheet_id%TYPE,
	in_chart_index			IN	model_instance_chart.chart_index%TYPE,
	in_top					IN	model_instance_chart.top%TYPE,
	in_left					IN	model_instance_chart.left%TYPE,
	in_width				IN	model_instance_chart.width%TYPE,
	in_height				IN	model_instance_chart.height%TYPE,
	in_source_data			IN	model_instance_chart.source_data%TYPE
);

PROCEDURE GetRegionTags(
	out_tag_groups	OUT	security_pkg.T_OUTPUT_CUR,
	out_tags		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionTypes(
	out_region_types	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE LookupRegionOffsets(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_tag_ids			IN	security_pkg.T_SID_IDS,
	out_region_offsets	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE LookupRegionTypeOffsets(
	in_region_sids		IN	security_pkg.T_SID_IDS,
	in_region_type_ids	IN	security_pkg.T_SID_IDS,
	out_region_offsets	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE LoadIntoCalculationEngine(
	in_model_sid					IN	security_pkg.T_SID_ID,
	in_period_set_id				IN	period_set.period_set_id%TYPE,
	in_period_interval_id			IN	period_interval.period_interval_id%TYPE
);

PROCEDURE UnloadFromCalculationEngine(
	in_model_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE QueueModelRun(
    in_model_instance_sid	IN	security_pkg.T_SID_ID,
    in_instance_run			IN	NUMBER,
    out_batch_job_id		OUT	batch_job.batch_job_id%TYPE
);

PROCEDURE GetBatchJobDetails(
	in_batch_job_id		IN	batch_job.batch_job_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetModelForImport(
    in_model_sid        IN   security_pkg.T_SID_ID,
    out_cur             OUT  SYS_REFCURSOR
);

PROCEDURE GetModelAndSheetsForImport(
	in_model_sid 		IN   security_pkg.T_SID_ID,
	in_region_sid  		IN   security_pkg.T_SID_ID,
	in_period_offset	IN   NUMBER, -- null means take first sheet
	out_cur  			OUT  SYS_REFCURSOR
);

PROCEDURE GetModelSheetStatus(
	in_model_sid		IN 	security_pkg.T_SID_ID,
	in_region_sid		IN 	security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE GetDelegationImport(
    in_delegation_sid   IN  security_pkg.T_SID_ID,
    out_cur             OUT SYS_REFCURSOR
);

PROCEDURE GetDelegationModels(
	out_cur 			OUT SYS_REFCURSOR
);
END model_pkg;
/
