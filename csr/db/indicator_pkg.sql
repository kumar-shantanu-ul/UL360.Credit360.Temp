CREATE OR REPLACE PACKAGE CSR.Indicator_Pkg AS

IND_DISALLOW_RECALC			CONSTANT NUMBER(10) := 1;
IND_DISALLOW_AGGREGATION	CONSTANT NUMBER(10) := 2;
IND_INSERT_ONLY				CONSTANT NUMBER(10) := 4;
/*
	Cascade percentage ownership up the region tree
	e.g. if we have:
	
	Megacorp					100% owned (default)
	  Widget company			10% owned
	    Acme screws company		30% owned

	then % owned means "% owned by parent", so Megacorp owns 3% of acme screws
	
	Most people seem to want this so it's the default if aggregation_engine_version=2
 */
IND_CASCADE_PCT_OWNERSHIP	CONSTANT NUMBER(10) := 8;
IND_SKIP_UPDATE_ALERTS		CONSTANT NUMBER(10) := 16;


/**
 * Create a new indicator
 *
 * @param	in_act_id				Access token
 * @param	in_parent_sid_id		Parent object
 * @param	in_name					Name
 * @param	in_description			Description
 * @param	in_active				1 or 0 (active / inactive)
 * @param	in_lookup_key			Help text
 * @param	in_owner_sid			Owner SID
 * @param	in_measure_sid			The measure that this indicator is associated with.
 * @param	in_multiplier			Multiplier
 * @param	in_scale				Scale
 * @param	in_format_mask			Format mask
 * @param	in_target_direction		Target direction
 * @param	in_gri					GRI
 * @param	in_pos					Sort order
 * @param   in_info_xml				XML
 * @param	out_sid_id				The SID of the created indicator
 *
 */
PROCEDURE CreateIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_parent_sid_id				IN	security_pkg.T_SID_ID,      		
	in_app_sid 						IN	security_pkg.T_SID_ID				DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_name 						IN	ind.name%TYPE,
	in_description 					IN	ind_description.description%TYPE,
	in_active	 					IN	ind.active%TYPE 					DEFAULT 1,
	in_measure_sid					IN	security_pkg.T_SID_ID 				DEFAULT NULL,
	in_multiplier					IN	ind.multiplier%TYPE 				DEFAULT 0,
	in_scale						IN	ind.scale%TYPE 						DEFAULT NULL,
	in_format_mask					IN	ind.format_mask%TYPE				DEFAULT NULL,
	in_target_direction				IN	ind.target_direction%TYPE 			DEFAULT 1,
	in_gri							IN	ind.gri%TYPE						DEFAULT NULL,
	in_pos							IN	ind.pos%TYPE						DEFAULT NULL,
	in_info_xml						IN	ind.info_xml%TYPE					DEFAULT NULL,
	in_divisibility					IN	ind.divisibility%TYPE				DEFAULT NULL,
	in_start_month					IN	ind.start_month%TYPE				DEFAULT 1,
	in_ind_type						IN	ind.ind_type%TYPE					DEFAULT 0,
	in_aggregate					IN	ind.aggregate%TYPE					DEFAULT 'NONE',
	in_is_gas_ind					IN	NUMBER								DEFAULT 0,
	in_factor_type_id				IN	ind.factor_type_id%TYPE				DEFAULT NULL,
	in_gas_measure_sid				IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_gas_type_id					IN	ind.gas_type_id%TYPE				DEFAULT NULL,
	in_core							IN	ind.core%TYPE						DEFAULT 1,
	in_roll_forward					IN	ind.roll_forward%TYPE				DEFAULT 0,
	in_normalize					IN	ind.normalize%TYPE					DEFAULT 0,
	in_tolerance_type				IN	ind.tolerance_type%TYPE				DEFAULT 0,
	in_pct_upper_tolerance			IN	ind.pct_upper_tolerance%TYPE		DEFAULT 1,
	in_pct_lower_tolerance			IN	ind.pct_lower_tolerance%TYPE		DEFAULT 1,
	in_tolerance_number_of_periods	IN	ind.tolerance_number_of_periods%TYPE	DEFAULT NULL,
	in_tolerance_number_of_standard_deviations_from_average	IN	ind.tolerance_number_of_standard_deviations_from_average%TYPE	DEFAULT NULL,
	in_prop_down_region_tree_sid	IN	ind.prop_down_region_tree_sid%TYPE 	DEFAULT NULL,
	in_is_system_managed			IN	ind.is_system_managed%TYPE			DEFAULT 0,
	in_lookup_key					IN	ind.lookup_key%TYPE					DEFAULT NULL,
	in_calc_output_round_dp			IN	ind.calc_output_round_dp%TYPE		DEFAULT NULL,
	in_calc_description				IN	ind.calc_description%TYPE			DEFAULT NULL,
	out_sid_id						OUT security_pkg.T_SID_ID
);

/**
 * Move an existing indicator
 *
 * @param	in_act_id				Access token
 * @param	in_move_ind_sid			ind to move
 * @param   in_parent_sid 			New parent object
 * @param	out_sid_id				The SID of the created ind
 *
 */
PROCEDURE MoveIndicator(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_ind_sid 				IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID
);

/**
 * Copy an existing indicator
 *
 * @param	in_act_id				Access token
 * @param	in_copy_ind_sid			ind to copy
 * @param   in_parent_sid 			Parent object
 * @param	out_sid_id				The SID of the created ind
 *
 */
PROCEDURE CopyIndicator(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_ind_sid 		IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	out_sid_id				OUT security_pkg.T_SID_ID
);

PROCEDURE CopyIndicatorFlags(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_ind_sid_from 		IN security_pkg.T_SID_ID,
	in_ind_sid_to	 		IN security_pkg.T_SID_ID
);

PROCEDURE CopyIndicatorValidationRules(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_ind_sid_from 		IN security_pkg.T_SID_ID,
	in_ind_sid_to	 		IN security_pkg.T_SID_ID
);

PROCEDURE CopyIndicatorReturnMap(
	in_act_id 				IN security_pkg.T_ACT_ID,
	in_copy_ind_sid 		IN security_pkg.T_SID_ID,
	in_parent_sid_id 		IN security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR
);

PROCEDURE CreateGasIndicators(
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_override_factor_type_id		IN	ind.factor_type_id%TYPE DEFAULT NULL
);

/**
 * Amend an existing indicator
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator
 * @param	in_description			Description
 * @param	in_active				1 or 0 (active / inactive)
 * @param	in_measure_sid			The measure that this indicator is associated with.
 * @param	in_multiplier			Multiplier
 * @param	in_scale				Scale
 * @param	in_format_mask			Format mask
 * @param	in_target_direction		Target direction
 * @param	in_gri					GRI
 * @param	in_pos					Sort order
 * @param   in_info_xml				XML
 *
 */
PROCEDURE AmendIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	ind_description.description%TYPE,
	in_active	 					IN	ind.active%TYPE 					DEFAULT 1,
	in_measure_sid					IN	security_pkg.T_SID_ID 				DEFAULT NULL,
	in_multiplier					IN	ind.multiplier%TYPE 				DEFAULT 0,
	in_scale						IN	ind.scale%TYPE 						DEFAULT NULL,
	in_format_mask					IN	ind.format_mask%TYPE				DEFAULT NULL,
	in_target_direction				IN	ind.target_direction%TYPE 			DEFAULT 1,
	in_gri							IN	ind.gri%TYPE						DEFAULT NULL,
	in_pos							IN	ind.pos%TYPE						DEFAULT NULL,
	in_info_xml						IN	ind.info_xml%TYPE					DEFAULT NULL,
	in_divisibility					IN	ind.divisibility%TYPE				DEFAULT NULL,
	in_start_month					IN	ind.start_month%TYPE				DEFAULT 1,
	in_ind_type						IN	ind.ind_type%TYPE					DEFAULT 0,
	in_aggregate					IN	ind.aggregate%TYPE					DEFAULT 'NONE',
	in_is_gas_ind					IN	NUMBER								DEFAULT 0,
	in_factor_type_id				IN	ind.factor_type_id%TYPE				DEFAULT NULL,
	in_gas_measure_sid				IN	security_pkg.T_SID_ID				DEFAULT NULL,
	in_gas_type_id					IN	ind.gas_type_id%TYPE				DEFAULT NULL,
	in_core							IN	ind.core%TYPE						DEFAULT 1,
	in_roll_forward					IN	ind.roll_forward%TYPE				DEFAULT 0,
	in_normalize					IN	ind.normalize%TYPE					DEFAULT 0,
	in_tolerance_type				IN	ind.tolerance_type%TYPE				DEFAULT 0,
	in_pct_upper_tolerance			IN	ind.pct_upper_tolerance%TYPE		DEFAULT 1,
	in_pct_lower_tolerance			IN	ind.pct_lower_tolerance%TYPE		DEFAULT 1,
	in_tolerance_number_of_periods	IN	ind.tolerance_number_of_periods%TYPE	DEFAULT NULL,
	in_tolerance_number_of_standard_deviations_from_average	IN	ind.tolerance_number_of_standard_deviations_from_average%TYPE	DEFAULT NULL,
	in_prop_down_region_tree_sid	IN	ind.prop_down_region_tree_sid%TYPE	DEFAULT NULL,
	in_is_system_managed			IN	ind.is_system_managed%TYPE			DEFAULT 0,
	in_lookup_key					IN	ind.lookup_key%TYPE					DEFAULT NULL,
	in_calc_output_round_dp			IN	ind.calc_output_round_dp%TYPE		DEFAULT NULL
);

/**
 * Amend an existing aggregate indicator
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator's SID
 * @param	in_description			Description
 * @param	in_active				1 or 0 (active / inactive)
 * @param	in_scale				Scale
 * @param	in_format_mask			Format mask
 *
 */
PROCEDURE AmendAggregateIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	ind_description.description%TYPE,
	in_active	 					IN	ind.active%TYPE 					DEFAULT 1,
	in_scale						IN	ind.scale%TYPE 						DEFAULT NULL,
	in_format_mask					IN	ind.format_mask%TYPE				DEFAULT NULL	
);

PROCEDURE SetAggregateIndicator(
	in_act_id 						IN	security_pkg.T_ACT_ID				DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_is_aggregate_ind				IN  ind.is_system_managed%TYPE
);

PROCEDURE SetLookupKey(
	in_ind_sid				IN	ind.ind_sid%TYPE,
	in_new_lookup_key		IN	ind.lookup_key%TYPE
);

-- useful for scripting purposes
PROCEDURE RenameIndicator(
	in_ind_sid		 				IN	security_pkg.T_SID_ID,
	in_description 					IN	ind_description.description%TYPE
);

PROCEDURE SetTranslationAndUpdateGasChildren(
	in_ind_sid		IN 	security_pkg.T_SID_ID,
	in_lang			IN	aspen2.tr_pkg.T_LANG,
	in_description	IN	VARCHAR2
);

PROCEDURE SetExtraInfoValue(
	in_act		IN	security_pkg.T_ACT_ID,
	in_ind_sid	IN	security_pkg.T_SID_ID,
	in_key		IN	VARCHAR2,		
	in_value	IN	VARCHAR2
);

PROCEDURE SetTolerance(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_tolerance_type	IN	ind.tolerance_type%TYPE,
	in_lower_tolerance	IN	ind.pct_lower_tolerance%TYPE,
	in_upper_tolerance	IN	ind.pct_upper_tolerance%TYPE
);

PROCEDURE SetTolerance(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_tolerance_type	IN	ind.tolerance_type%TYPE,
	in_lower_tolerance	IN	ind.pct_lower_tolerance%TYPE,
	in_upper_tolerance	IN	ind.pct_upper_tolerance%TYPE,
	in_tolerance_number_of_periods	IN	ind.tolerance_number_of_periods%TYPE,
	in_tolerance_number_of_standard_deviations_from_average	IN	ind.tolerance_number_of_standard_deviations_from_average%TYPE
);

/**
 * Set a translation for an indicator
 *
 * @param	in_ind_sid				The indicator to set a translation for
 * @param	in_culture				The culture the translation is for
 * @param	in_translation			The translation
 */
PROCEDURE SetTranslation(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
);

/**
 * Set a translation for an indicator attribute
 *
 * @param	in_ind_sid				The indicator to set a translation for
 * @param	in_node			        The info xml key thing the translation is for
 * @param	in_culture				The culture the translation is for
 * @param	in_translation			The translation
 */
PROCEDURE SetInfoXmlTranslation(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	in_node             IN  VARCHAR2,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN  VARCHAR2
);

/**
 * Get translations for an indicator description
 *
 * @param	in_ind_sid				The indicator to set a translation for
 * @param	out_tr_description		Output rowset of the form lang, translated for the description
 */
PROCEDURE GetTranslations(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Get translations for an indicator description
 *
 * @param	in_ind_sid				The indicator to set a translation for
 * @param	out_tr_description		Output rowset of the form culture, translated for the description
 * @param	out_tr_info_xml		    Output rowset of the form node_key, culture, translated
 */
PROCEDURE GetTranslations(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	out_tr_description	OUT	SYS_REFCURSOR,
	out_tr_info_xml     OUT SYS_REFCURSOR,
	out_tr_flags	    OUT SYS_REFCURSOR
);

/**
 * Bind an indicator to a measure.  Removes any dataset binding.
 *
 * @param	in_act_id				Access token
 * @param	in_ind_sid				The indicator
 * @param	in_measure_sid			The measure that this indicator is associated with
 *
 */
PROCEDURE BindToMeasure(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_measure_sid			IN security_pkg.T_SID_ID
);

-- Securable object callbacks
/**
 * CreateObject
 * 
 * @param in_act_id				Access token
 * @param in_sid_id				The sid of the object
 * @param in_class_id			The class Id of the object
 * @param in_name				The name
 * @param in_parent_sid_id		The sid of the parent object
 */
PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

/**
 * RenameObject
 * 
 * @param in_act_id			Access token
 * @param in_sid_id			The sid of the object
 * @param in_new_name		The name
 */
PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
);

/**
 * DeleteObject
 * 
 * @param in_act_id		Access token
 * @param in_sid_id		The sid of the object
 */
PROCEDURE DeleteObject(
	in_act_id						IN security_pkg.T_ACT_ID,
	in_sid_id						IN security_pkg.T_SID_ID
);

/**
 * MoveObject
 * 
 * @param in_act_id					Access token
 * @param in_sid_id					The sid of the object
 * @param in_new_parent_sid_id		.
 */
PROCEDURE MoveObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid_id	IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
);

PROCEDURE GetTrashBlockers(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	out_calc_cur					OUT	SYS_REFCURSOR,	
	out_user_cur					OUT	SYS_REFCURSOR
);

/**
 * TrashObject
 * 
 * @param in_act_id		Access token
 * @param in_ind_sid	The sid of the object
 */
PROCEDURE TrashObject(
	in_act_id						IN 	security_pkg.T_ACT_ID,
	in_ind_sid						IN 	security_pkg.T_SID_ID
);

/**
 * RestoreFromTrash
 * 
 * @param in_object_sids			The objects being restored
 */
PROCEDURE RestoreFromTrash(
	in_object_sids					IN	security.T_SID_TABLE
);

PROCEDURE GetDependencies(
	in_act			IN	security_pkg.T_ACT_ID,
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_calcs		OUT	SYS_REFCURSOR,
	out_delegations	OUT	SYS_REFCURSOR
);

/**
 * GetFlags
 * 
 * @param in_act_id		Access token
 * @param in_ind_sid	The sid of the object
 * @param out_cur		The rowset
 */
PROCEDURE GetFlags(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * SetFlags
 * 
 * @param in_act_id					Access token
 * @param in_ind_sid				The indicator sid
 * @param in_flags					The flags
 * @param in_require_notes			Array of numbers (0 or 1) if we require notes for each flag
 */
PROCEDURE SetFlags(
	in_act_id			IN  security_pkg.T_ACT_ID,
	in_ind_sid			IN  security_pkg.T_SID_ID,
    in_flags			IN	csr_data_pkg.T_VARCHAR_ARRAY,
    in_requires_note	IN	csr_data_pkg.T_NUMBER_ARRAY
);


PROCEDURE DeleteVal(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_val_id	IN	val.val_id%TYPE,
	in_reason	IN	VARCHAR2
);

/**
 * Set a value
 *
 * @param	in_act_id				Access token
 * @param	in_indicator_sid		The indicator
 * @param	in_region_sid			The region
 * @param	in_period_start			The start date
 * @param	in_period_end			The end date
 * @param	in_val_number			The value
 * @param	in_flags				Number is flags
 * @param	out_val_id				The ID of the inserted value
 *
 */
 PROCEDURE SetValueWithReason(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_region_sid			IN security_pkg.T_SID_ID,
	in_period_start			IN val.period_start_dtm%TYPE,
	in_period_end			IN val.period_end_dtm%TYPE,
	in_val_number			IN val.val_number%TYPE,
	in_flags				IN val.flags%TYPE,
	in_source_type_id		IN val.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN val.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN val.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN val.entry_val_number%TYPE DEFAULT NULL,
	in_update_flags			IN NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_reason				IN val_change.reason%type,
	in_note					IN val.note%type,
	out_val_id				OUT val.val_id%TYPE
);

/**
 * Set a value
 *
 * @param	in_act_id				Access token
 * @param	in_indicator_sid		The indicator
 * @param	in_region_sid			The region
 * @param	in_period_start			The start date
 * @param	in_period_end			The end date
 * @param	in_val_number			The value
 * @param	in_flags				Number is flags
 * @param	in_source_type_id		The source of the value
 * @param	in_source_id			The source specific id from which the value came
 * @param	in_entry_conversion_id	The measure conversion used when entering the value
 * @param	in_entry_val_number		The actual value entered
 * @param	in_error_code			An error code (if an error occurred)
 * @param	in_update_flags			Flags for the set operation
 * @param	in_reason				The reason for the change
 * @param	in_note					A note about the value
 * @param	in_have_file_uploads	true if the file uploads list show be used (since in_file_uploads cannot be null)
 * @param	in_file_uploads			A list of file_upload.file_upload_sids associated with the value
 * @param	out_val_id				The ID of the inserted value
 */
 PROCEDURE SetValueWithReasonWithSid(
	in_user_sid						IN	security_pkg.T_SID_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_period_start					IN	val.period_start_dtm%TYPE,
	in_period_end					IN	val.period_end_dtm%TYPE,
	in_val_number					IN	val.val_number%TYPE,
	in_flags						IN	val.flags%TYPE DEFAULT 0,
	in_source_type_id				IN	val.source_type_id%TYPE DEFAULT 0,
	in_source_id					IN	val.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id			IN	val.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number				IN	val.entry_val_number%TYPE DEFAULT NULL,
	in_error_code					IN	val.error_code%TYPE DEFAULT NULL,
	in_update_flags					IN	NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_reason						IN	val_change.reason%TYPE,
	in_note							IN	val.note%TYPE DEFAULT NULL,
	in_have_file_uploads			IN	NUMBER,
	in_file_uploads					IN	security_pkg.T_SID_IDS,
	out_val_id						OUT	val.val_id%TYPE
);

/**
 * A SetValue wrapper that doesn't poke file uploads for old code.
 * If this was removed direct value editing, rollback, etc. would clear file uploads.  We have to 
 * pass a flag to say if we have supplied file uploads to the main function since security_pkg.T_SID_IDS
 * cannot be null.
 *
 * @param	in_act_id				Access token
 * @param	in_indicator_sid		The indicator
 * @param	in_region_sid			The region
 * @param	in_period_start			The start date
 * @param	in_period_end			The end date
 * @param	in_val_number			The value
 * @param	in_flags				Number is flags
 * @param	in_source_type_id		The source of the value
 * @param	in_source_id			The source specific id from which the value came
 * @param	in_entry_conversion_id	The measure conversion used when entering the value
 * @param	in_entry_val_number		The actual value entered
 * @param	in_error_code			An error code (if an error occurred)
 * @param	in_update_flags			Flags for the set operation
 * @param	in_reason				The reason for the change
 * @param	in_note					A note about the value
 * @param	in_file_uploads			A list of file_upload.file_upload_sids associated with the value
 * @param	out_val_id				The ID of the inserted value
 */
PROCEDURE SetValueWithReasonWithSid(
	in_user_sid				IN	security_pkg.T_SID_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_period_start			IN	val.period_start_dtm%TYPE,
	in_period_end			IN	val.period_end_dtm%TYPE,
	in_val_number			IN	val.val_number%TYPE,
	in_flags				IN	val.flags%TYPE DEFAULT 0,
	in_source_type_id		IN	val.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN	val.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN	val.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN	val.entry_val_number%TYPE DEFAULT NULL,
	in_error_code			IN	val.error_code%TYPE DEFAULT NULL,
	in_update_flags			IN	NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_reason				IN	val_change.reason%TYPE,
	in_note					IN	val.note%TYPE DEFAULT NULL,
	out_val_id				OUT	val.val_id%TYPE
);

PROCEDURE SetValue(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_region_sid			IN security_pkg.T_SID_ID,
	in_period_start			IN VAL.period_start_dtm%TYPE,
	in_period_end			IN VAL.period_end_dtm%TYPE,
	in_val_number			IN VAL.val_number%TYPE,
	in_flags				IN VAL.flags%TYPE,
	in_source_type_id		IN VAL.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN VAL.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN VAL.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN VAL.entry_val_number%TYPE DEFAULT NULL,
	in_update_flags			IN NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_note					IN VAL.NOTE%TYPE,
	out_val_id				OUT VAL.val_id%TYPE
);


/**
 * SetNewValueOnly
 * 
 * @param in_act_id					Access token
 * @param in_ind_sid				The sid of the object
 * @param in_region_sid				The sid of the object
 * @param in_period_start			.
 * @param in_period_end				.
 * @param in_val_number				.
 * @param in_flags					.
 * @param in_source_type_id			.
 * @param in_source_id				.
 * @param in_entry_conversion_id	.
 * @param in_entry_val_number		.
 * @param in_update_flags			.
 * @param in_note					.
 * @param out_cur					The rowset
 */
PROCEDURE SetNewValueOnly(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_ind_sid				IN security_pkg.T_SID_ID,
	in_region_sid			IN security_pkg.T_SID_ID,
	in_period_start			IN VAL.period_start_dtm%TYPE,
	in_period_end			IN VAL.period_end_dtm%TYPE,
	in_val_number			IN VAL.val_number%TYPE,
	in_flags				IN VAL.flags%TYPE,
	in_source_type_id		IN VAL.source_type_id%TYPE DEFAULT 0,
	in_source_id			IN VAL.source_id%TYPE DEFAULT NULL,
	in_entry_conversion_id	IN VAL.entry_measure_conversion_id%TYPE DEFAULT NULL,
	in_entry_val_number		IN VAL.entry_val_number%TYPE DEFAULT NULL,
	in_update_flags			IN NUMBER DEFAULT 0, -- misc flags incl do we allow recalc jobs to be written and override locks
	in_note					IN VAL.NOTE%TYPE,
	out_cur					OUT SYS_REFCURSOR
);

/**
 * RollbackToDate
 * 
 * @param in_act_id					Access token
 * @param in_ind_sid				The sid of the object
 * @param in_region_sid				The sid of the object
 * @param in_period_start_dtm		.
 * @param in_period_end_dtm			.
 */
PROCEDURE RollbackToDate(
	in_act_id			security_pkg.T_ACT_ID,
	in_ind_sid			security_pkg.T_SID_ID,
	in_period_start_dtm	val.period_start_dtm%TYPE,
	in_period_end_dtm	val.period_end_dtm%TYPE,
	in_dtm				DATE
);


/**
 * AddNote
 * 
 * @param in_act_id					Access token
 * @param in_ind_sid				The sid of the object
 * @param in_region_sid				The sid of the object
 * @param in_period_start_dtm		.
 * @param in_period_end_dtm			.
 * @param in_note					.
 * @param out_val_note_id			.
 */
PROCEDURE AddNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_period_start_dtm		IN	VAL_NOTE.period_start_dtm%TYPE,
	in_period_end_dtm		IN	VAL_NOTE.period_end_dtm%TYPE,
	in_note					IN 	VAL_NOTE.NOTE%TYPE,
	out_val_note_id			OUT	VAL_NOTE.val_note_id%TYPE
);


/**
 * UpdateNote
 * 
 * @param in_act_id			Access token
 * @param in_val_note_id	.
 * @param in_note			.
 */
PROCEDURE UpdateNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_val_note_id			IN	VAL_NOTE.val_note_id%TYPE,
	in_note					IN 	VAL_NOTE.NOTE%TYPE
);


/**
 * DeleteNote
 * 
 * @param in_act_id			Access token
 * @param in_val_note_id	.
 */
PROCEDURE DeleteNote(
	in_act_id				IN 	security_pkg.T_ACT_ID,
	in_val_note_id			IN	VAL_NOTE.val_note_id%TYPE
);

/**
 * GetValChangeList
 * 
 * @param in_act_id			Access token
 * @param in_val_id			.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE GetValChangeList(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_val_id			IN security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * UNSEC_GetValEnteredAsInfo
 * 
 * @param in_val_ids		The val IDs to fetch
 * @param out_cur			The rowset
 */
PROCEDURE UNSEC_GetValEnteredAsInfo(
	in_val_ids			IN	security_pkg.T_SID_IDS,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * GetValues
 * 
 * @param in_act_id			Access token
 * @param in_ind_sid		The sid of the object
 * @param in_region_sid		The sid of the object
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param in_interval		The period interval (m|q|h|y)
 * @param out_cur			The rowset
 */
PROCEDURE GetValues(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_region_sid		    IN	security_pkg.T_SID_ID,
	in_start_dtm		    IN	DATE,
	in_end_dtm			    IN	DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER,
	out_cur				    OUT SYS_REFCURSOR
);


/**
 * GetValuesForRegionList
 * 
 * @param in_act_id			Access token
 * @param in_ind_sid		The sid of the object
 * @param in_start_dtm		The start date
 * @param in_end_dtm		The end date
 * @param in_interval		The period interval (m|q|h|y)
 * @param out_cur			The rowset
 */
PROCEDURE GetValuesForRegionList(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_start_dtm		    IN	DATE,
	in_end_dtm			    IN	DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER,
	out_cur				    OUT SYS_REFCURSOR
);

/**
 * GetValuesAsTable
 * 
 * @param in_act_id			Access token
 * @param in_ind_sid		The sid of the object
 * @param in_region_sid		The sid of the object
 * @param in_interval		The period interval (m|q|h|y)
 * @return 					.
 */
FUNCTION GetValuesAsTable(
	in_act_id			    IN	security_pkg.T_ACT_ID,
	in_ind_sid			    IN	security_pkg.T_SID_ID,
	in_region_sid		    IN	security_pkg.T_SID_ID,
	in_period_start_dtm  	IN  DATE,
	in_period_end_dtm 		IN  DATE,
	in_interval			    IN	CHAR,
	in_ignore_pct_ownership IN  NUMBER
) RETURN T_VAL_TABLE;

PROCEDURE GetIndicatorFromKey(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_app_sid			IN security_pkg.T_SID_ID,
	in_lookup_key		IN ind.lookup_key%TYPE,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * Return a row set containing info about an indicator
 *
 * @param	in_act_id		Access token
 * @param	in_ind_sid		The indicator
 * @param	out_cur			The indicator details
 */
PROCEDURE GetIndicator(
	in_act_id						IN	security_pkg.T_ACT_ID,
	in_ind_sid						IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

/**
 * Return a row set containing info about multiple indicators
 *
 * @param	in_ind_sids			The indicator sids
 * @param	in_skip_missing		Just skip missing indicators (otherwise raises security_pkg.OBJECT_NOT_FOUND)
 * @param	in_skip_denid		Just skip indicators without read permission (otherwise raises security_pkg.ACCESS_DENIED)
 * @param	out_ind_cur			Indicator details
 * @param	out_tag_cur			Indicator tags
 */
 PROCEDURE GetIndicators(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicators(
	in_ind_sids						IN	security_pkg.T_SID_IDS,
	in_skip_missing					IN	NUMBER DEFAULT 0,
	in_skip_denied					IN	NUMBER DEFAULT 0,
	in_ignore_trashed				IN	NUMBER DEFAULT 0,
	out_ind_cur						OUT	SYS_REFCURSOR,
	out_tag_cur						OUT	SYS_REFCURSOR,
	out_trashed_inds				OUT SYS_REFCURSOR
);

/**
 * As for GetIndicator, but insecure
 *
 * @param	in_ind_sid		The indicator
 * @param	out_cur			The indicator details
 */
PROCEDURE GetIndicator_INSECURE(
	in_ind_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetIndicatorAccuracyTypes(
	in_act_id	IN	security_pkg.T_ACT_ID,
	in_ind_sid	IN	security_pkg.T_SID_ID,
	out_cur		OUT	SYS_REFCURSOR
);

/**
 * GetIndicatorsForList
 * 
 * @param in_act_id				Access token
 * @param in_indicator_list		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_indicator_list	IN	VARCHAR2,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * GetIndicatorChildren
 * 
 * @param in_act_id			Access token
 * @param in_parent_sid		The sid of the parent object
 * @param out_cur			The rowset
 */
PROCEDURE GetIndicatorChildren(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_parent_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * As for GetIndicatorChildren, but doesn't do a security check
 * 
 * @param in_parent_sid		The sid of the parent object
 * @param out_cur			The rowset
 */
PROCEDURE GetIndicatorChildren_INSECURE(
	in_parent_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * GetIndicatorPath
 * 
 * @param in_act_id		Access token
 * @param in_ind_sid	The sid of the object
 * @param out_cur		The rowset
 */
PROCEDURE GetIndicatorPath(
	in_act_id			IN security_pkg.T_ACT_ID,
	in_ind_sid			IN security_pkg.T_SID_ID,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * Returns array of Indicator descriptions from an array of SIDs 
 * 
 * @param in_ind_sids			Array of indicator sids
 * @param out_ind_desc_cur		The rowset
 */
PROCEDURE GetIndicatorDescriptions(
	in_ind_sids			IN security_pkg.T_SID_IDS,
	out_ind_desc_cur	OUT	SYS_REFCURSOR
);

/**
 * As for GetIndicatorDescriptions, but doesn't do a security check
 * 
 * @param in_ind_sids			Array of indicator sids
 * @param out_ind_desc_cur		The rowset
 */
PROCEDURE GetIndicatorDescriptions_UNSEC(
	in_ind_sids			IN security_pkg.T_SID_IDS,
	out_ind_desc_cur	OUT	SYS_REFCURSOR
);

/**
 * INTERNAL
 * 
 * @param in_ind_sid	The sid of the object
 * @return 				.
 */
FUNCTION INTERNAL_GetIndPathString(
	in_ind_sid			IN security_pkg.T_SID_ID
) RETURN VARCHAR2;
PRAGMA RESTRICT_REFERENCES(INTERNAL_GetIndPathString, WNDS, WNPS);

/**
 * Sets XML and optionally removes rows from the calc dependency table
 *
 * @param	in_act_id			Access token
 * @param	in_calc_ind_sid		The indicator
 * @param	in_calc_xml			The xml
 * @param	in_remove_deps		Whether to remove dependencies or not
 */
PROCEDURE SetCalcXML(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_calc_ind_sid			IN security_pkg.T_SID_ID,
	in_calc_xml				IN IND.calc_xml%TYPE,
	in_ind_type				IN ind.ind_type%TYPE DEFAULT Csr_Data_Pkg.IND_TYPE_CALC,
	in_remove_deps			IN NUMBER DEFAULT 1
);

/**
 * GetDataOverviewIndicators
 * 
 * @param in_act_id					Access token
 * @param in_root_indicator_sid		.
 * @param out_cur					The rowset
 * @param out_tag_groups_cur	 	Tag Groups info + maximum number of tags in use
 * @param out_ind_tag_cur			Tags rowset
 */
PROCEDURE GetDataOverviewIndicators(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_root_indicator_sids	IN security_pkg.T_SID_IDS,
	in_app_sid			IN security_pkg.T_SID_ID,
	out_cur					OUT SYS_REFCURSOR,
	out_tag_groups_cur		OUT SYS_REFCURSOR,
	out_ind_tag_cur			OUT SYS_REFCURSOR,
	out_flags_cur			OUT	SYS_REFCURSOR,
	out_ind_baseline_cur	OUT SYS_REFCURSOR
);



/********************************************************************/
/* NOT SURE WHERE ALL THIS STUFF BELOW THIS POINT BELONGS IF AT ALL */
/********************************************************************/

PROCEDURE GetTreeSinceDate(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_modified_since_dtm			IN	audit_log.audit_date%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithDepth(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeWithSelect(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_select_sid					IN	security_pkg.T_SID_ID,
	in_fetch_depth					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetTreeTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_app_sid						IN	security_pkg.T_SID_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTextFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive				IN  NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetListTagFiltered(
	in_act_id   					IN  security_pkg.T_ACT_ID,
	in_parent_sids					IN	security_pkg.T_SID_IDS,
	in_include_root					IN	NUMBER,
	in_show_inactive 				IN 	NUMBER,
	in_search_phrase				IN	VARCHAR2,
	in_tag_group_count				IN	NUMBER,
	in_fetch_limit					IN	NUMBER,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE SetActivityType(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_activity_type_id		IN	ind_activity_type.ind_activity_type_id%TYPE
);

/**
 * Rolls forward an indicator, or all indicators if in_ind_sid is null
 * there is no security here as it's either called from a scheduled task
 * or from AmendIndicator (which does check security)
 *
 * @param in_ind_sid		Optional indicator to roll forward
 */
PROCEDURE RollForward(
	in_ind_sid				IN	ind.ind_sid%TYPE
);

/**
 * Monthly job to roll data forward for all apps
 */
PROCEDURE RollForward;

PROCEDURE LookupIndicator(
	in_text			IN	ind_description.description%TYPE,
	in_ancestors	IN	security_pkg.T_VARCHAR2_ARRAY,
	out_ind_sid		OUT	security_pkg.T_SID_ID
);

PROCEDURE FindIndicatorByPath(
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE FindCoreIndicatorByPath(
	in_path				IN	VARCHAR2,
	in_separator		IN	VARCHAR2 DEFAULT '/',
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetNormalizationInds(
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE CopyValues(
	in_from_ind_sid		IN	security_pkg.T_SID_ID,
	in_new_ind_sid		IN	security_pkg.T_SID_ID,
	in_period_start_dtm	IN	DATE 			DEFAULT NULL,
	in_period_end_dtm	IN	DATE 			DEFAULT NULL,
	in_reason			IN	VARCHAR2		DEFAULT NULL,
	in_move				IN	NUMBER			DEFAULT 0
);

/**
* Check if indicator is used the system returns 1 (for true) if found or 0 (for false if not used)
* Used numbers for use in RUNSF where BOOLEAN cannot be used
*/
FUNCTION IsIndicatorUsed(
	in_ind_sid		IN	security_pkg.T_SID_ID
)RETURN NUMBER;

PROCEDURE RemoveUnusedValidationRules (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_used_rule_ids	IN  security_pkg.T_SID_IDS
);

PROCEDURE RemoveValidationRule (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_rule_id			IN  security_pkg.T_SID_ID
);

PROCEDURE SaveValidationRule (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_validation_id	IN  ind_validation_rule.ind_validation_rule_id%TYPE,
	in_expr				IN  ind_validation_rule.expr%TYPE,
	in_message			IN  ind_validation_rule.message%TYPE,
	in_type				IN  ind_validation_rule.type%TYPE,
	out_validation_id   OUT ind_validation_rule.ind_validation_rule_id%TYPE
);

PROCEDURE EditValidationRule (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	in_validation_id	IN  ind_validation_rule.ind_validation_rule_id%TYPE,
	in_expr				IN  ind_validation_rule.expr%TYPE,
	in_message			IN  ind_validation_rule.message%TYPE,
	in_type				IN  ind_validation_rule.type%TYPE
);

PROCEDURE GetValidationRules (
	in_ind_sid			IN  security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAllValidationRulesBasic(
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetValidationRulesFrom (
	in_root_indicator_sids	IN 	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetAllIndSelectionGroupInds(
	in_app_sid			IN	security_pkg.T_SID_ID DEFAULT SYS_CONTEXT('SECURITY', 'APP'),
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Get selections (quality flags as separate indicators) for the given indicator
 *
 * @param in_ind_sid				The indicator to get selections for
 * @param out_sel_ind_cur			The selection indicators
 * @param out_sel_tr_cur			Translations of the selection indicator descriptions
 */
PROCEDURE GetIndSelections(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	out_sel_ind_cur					OUT	SYS_REFCURSOR,
	out_sel_tr_cur					OUT	SYS_REFCURSOR
);

/**
 * Set selections (quality flags as separate indicators) for the given indicator
 *
 * @param in_ind_sid				The indicator to set selections on
 * @param in_selection_sids			Sids of the indicators to set selection on (NULL for new selections)
 * @param in_selection_name			The selection names
 * @param in_active					Active flags for the indicators
 * @param in_langs					Languages for translations
 * @param in_selection_translations	The translations as a single array containing per language a translation for each selection,
 * 									i.e. lang1ind1, lang1ind2, lang1ind3, lang2ind1, lang2ind2, ...
 * @param out_removals_skipped		A flag set to 1 if removing selections was skipped due to data being present (0 if not)
 */
PROCEDURE SetIndSelections(
	in_ind_sid						IN	ind.ind_sid%TYPE,
	in_selection_sids				IN	security_pkg.T_SID_IDS,
	in_selection_names				IN	security_pkg.T_VARCHAR2_ARRAY,
	in_active						IN	security_pkg.T_SID_IDS,
	in_langs						IN	security_pkg.T_VARCHAR2_ARRAY,
	in_selection_translations		IN	security_pkg.T_VARCHAR2_ARRAY,
	out_removals_skipped			OUT	NUMBER
);

/**
 * Check if the given indicator is system managed
 *
 * @param in_ind_sid				The indicator to check
 * @return							1 if system managed, 0 if not
 */
FUNCTION IsSystemManaged(
	in_ind_sid						IN	ind.ind_sid%TYPE
)
RETURN NUMBER;

/**
 * GetIndicatorsForList
 * 
 * @param in_act_id				Access token
 * @param in_indicator_list		.
 * @param out_cur				The rowset
 */
PROCEDURE GetIndicatorsForList(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_indicator_list	IN	security_pkg.T_SID_IDS,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * EnableIndicator
 * 
 * @param in_ind_sid			Parent indicator
 */
PROCEDURE EnableIndicator(
	in_ind_sid			IN	security_pkg.T_SID_ID
);

/**
 * EnableChildIndicators
 * 
 * @param in_act_id				Access token
 * @param in_ind_sid			Parent indicator
 */
PROCEDURE EnableChildIndicators(
	in_ind_sid			IN	security_pkg.T_SID_ID
);

/**
 * DisableChildIndicators
 * 
 * @param in_act_id				Access token
 * @param in_ind_sid			Parent indicator
 */
PROCEDURE DisableChildIndicators(
	in_ind_sid			IN	security_pkg.T_SID_ID
);

/**
 * Check if an indicator is part of the reporting only calc indicator tree
 *
 * @param in_ind_sid				The indicator
 * @return 1 if the indicator is in the reporting only calc tree, 0 if not
 */
FUNCTION IsInReportingIndTree(
	in_ind_sid						IN	ind.ind_sid%TYPE
)
RETURN NUMBER;

PROCEDURE GetAllTranslations(
	in_root_indicator_sids	IN security_pkg.T_SID_IDS,
	in_validation_lang		IN	region_description.lang%TYPE,
	in_changed_since		IN	DATE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateTranslations(
	in_ind_sids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetAllSelectionGrpTranslations(
	in_root_indicator_sids	IN	security_pkg.T_SID_IDS,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE ValidateSelectGrpTranslations(
	in_ind_sids				IN	security.security_pkg.T_SID_IDS,
	in_descriptions			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_validation_lang		IN	region_description.lang%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE SetIndSelectGrpTranslation(
	in_ind_sid			IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
);

PROCEDURE GetScragIndicators(
	in_ind_sids				IN	security.security_pkg.T_SID_IDS,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION GetTrashedIndSids
RETURN security.T_SID_TABLE;

PROCEDURE GetCoreIndicators(
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE GetCoreIndicatorsByLookupKey(
	in_lookup_keys			IN	security.security_pkg.T_VARCHAR2_ARRAY,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreIndsByDescription(
	in_description			IN	ind_description.description%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreIndsByMeasureSid(
	in_measure_sid			IN	ind.measure_sid%TYPE,
	in_skip					IN	NUMBER,
	in_take					IN	NUMBER,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR,
	out_total_rows_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreIndBySid(
	in_sid					IN	ind.ind_sid%TYPE,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
);

PROCEDURE UNSEC_GetCoreIndByPath(
	in_path					IN	VARCHAR2,
	out_ind_cur				OUT	SYS_REFCURSOR,
	out_description_cur		OUT	SYS_REFCURSOR
);


PROCEDURE GetIndicatorScripts(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorScript(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UpdateIndicatorScript(
	in_ind_sid				IN	security_pkg.T_SID_ID,
	in_script				IN	VARCHAR2
);

PROCEDURE ClearIndicatorScript(
	in_ind_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE GetIndicators(
	in_indicator_sids				IN	security.security_pkg.T_SID_IDS,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetIndicatorFactor(
	in_ind_sid						IN	security.security_pkg.T_SID_ID,
	out_factor_set					OUT	SYS_REFCURSOR
);

END Indicator_Pkg;
/
