CREATE OR REPLACE PACKAGE CSR.Measure_Pkg AS

MIN_ROW_START		CONSTANT NUMBER := 0;
MIN_PAGE_SIZE		CONSTANT NUMBER := 1;
NO_PAGING			CONSTANT NUMBER := -1;
DEFAULT_ORDER_BY	CONSTANT VARCHAR2(50) := 'measure_description';
DEFAULT_ORDER_DIR	CONSTANT VARCHAR2(50) := 'ASC';

TYPE t_measure_cur IS RECORD (
	measure_sid measure.measure_sid%TYPE, 
	format_mask measure.format_mask%TYPE, 
	scale measure.scale%TYPE, 
	name measure.name%TYPE, 
	description measure.description%TYPE, 
	custom_field measure.custom_field%TYPE, 
	pct_ownership_applies measure.pct_ownership_applies%TYPE, 
	std_measure_conversion_id measure.std_measure_conversion_id%TYPE, 
	divisibility measure.divisibility%TYPE,
	factor measure.factor%TYPE, 
	m measure.m%TYPE, 
	kg measure.kg%TYPE, 
	s measure.s%TYPE, 
	a measure.a%TYPE, 
	k measure.k%TYPE, 
	mol measure.mol%TYPE,
	cd measure.cd%TYPE, 
	std_measure_description std_measure_conversion.description%TYPE,
	option_set_id measure.option_set_id%TYPE, 
	lookup_key measure.lookup_key%TYPE
);


/**
 * Create a new measure
 *
 * @param	in_act_id				Access token
 * @param   in_parent_sid 			Parent Sid
 * @param   in_app_sid 				CSR Root SID
 * @param	in_name					Name of the measure
 * @param	in_description			Describes the measure
 * @param	in_scale				Gives the scale for the measure for presentation
 * @param	in_format_mask			Format mask
 * @param	out_measure_sid			The SID of the created measure.
 *
 */
PROCEDURE CreateMeasure(
	in_act_id			    		IN	security_pkg.T_ACT_ID					DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_parent_sid_id	    		IN	security_pkg.T_SID_ID					DEFAULT NULL,
	in_app_sid 	    				IN	security_pkg.T_SID_ID					DEFAULT SYS_CONTEXT('SECURITY','APP'),
	in_name					    	IN	measure.name%TYPE,
	in_description		    		IN	measure.description%TYPE,
	in_scale			    		IN	measure.scale%TYPE						DEFAULT 0,
	in_format_mask		    		IN	measure.format_mask%TYPE				DEFAULT '#,##0',
	in_custom_field			    	IN	measure.custom_field%TYPE				DEFAULT NULL,
	in_std_measure_conversion_id	IN	measure.std_measure_conversion_id%TYPE	DEFAULT NULL,
	in_pct_ownership_applies    	IN	measure.pct_ownership_applies%TYPE		DEFAULT 1,
	in_divisibility					IN	measure.divisibility%TYPE				DEFAULT csr_data_pkg.DIVISIBILITY_DIVISIBLE,
	in_option_set_id				IN	measure.option_set_id%TYPE				DEFAULT NULL,
	in_lookup_key					IN	measure.lookup_key%TYPE					DEFAULT NULL,
	out_measure_sid			    	OUT measure.measure_sid%TYPE
);

/**
 * Set a translation for a measure
 *
 * @param	in_measure_sid			The measure to set a translation for
 * @param	in_culture				The culture the translation is for
 * @param	in_translation			The translation
 */
PROCEDURE SetTranslation(
	in_measure_sid		IN 	security_pkg.T_SID_ID,
	in_lang				IN	aspen2.tr_pkg.T_LANG,
	in_translated		IN	VARCHAR2
);

/**
 * Get translations for a measure description
 *
 * @param	in_measure_sid			The region to set a translation for
 * @param	out_cur					Output rowset of the form culture, translated
 */
PROCEDURE GetTranslations(
	in_measure_sid		IN 	security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Amend an existing measure
 *
 * @param	in_act_id				Access token
 * @param	in_measure_sid_id		The measure to update
 * @param	in_name					The new name of the measure
 * @param	in_description			The new description of the measure
 * @param	in_scale				The new scale
 * @param	in_format_mask			Format mask
 */
PROCEDURE AmendMeasure(
	in_act_id			    		IN	security_pkg.T_ACT_ID					DEFAULT SYS_CONTEXT('SECURITY','ACT'),
	in_measure_sid_id	    		IN	security_pkg.T_SID_ID,
	in_name					    	IN	measure.name%TYPE,
	in_description		    		IN	measure.description%TYPE,
	in_scale			    		IN	measure.scale%TYPE,
	in_format_mask		    		IN	measure.format_mask%TYPE,
	in_custom_field			    	IN	measure.custom_field%TYPE,
	in_std_measure_conversion_id	IN	measure.std_measure_conversion_id%TYPE,
	in_pct_ownership_applies    	IN	measure.pct_ownership_applies%TYPE,
	in_divisibility					IN	measure.divisibility%TYPE,
	in_option_set_id				IN	measure.option_set_id%TYPE,
	in_lookup_key					IN	measure.lookup_key%TYPE
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
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
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

/**
 * GetMeasure
 * 
 * @param in_act_id			Access token
 * @param in_measure_sid	.
 * @param out_cur			The rowset
 */
PROCEDURE GetMeasure(
    in_act_id       				IN  security_pkg.T_ACT_ID,
	in_measure_sid					IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

FUNCTION TryGetMeasureSIDFromKey(
	in_lookup_key					IN	ind.lookup_key%TYPE
) RETURN measure.measure_sid%TYPE;
PRAGMA RESTRICT_REFERENCES(TryGetMeasureSIDFromKey, WNDS, WNPS);

FUNCTION GetMeasureSIDFromKey(
	in_lookup_key					IN	ind.lookup_key%TYPE
) RETURN measure.measure_sid%TYPE;
PRAGMA RESTRICT_REFERENCES(GetMeasureSIDFromKey, WNDS, WNPS);

FUNCTION TryGetMeasureConvIDFromKey(
	in_lookup_key					IN	measure_conversion.lookup_key%TYPE
) RETURN measure_conversion.measure_conversion_Id%TYPE;
PRAGMA RESTRICT_REFERENCES(TryGetMeasureConvIDFromKey, WNDS, WNPS);

FUNCTION INTERNAL_GetMeasureRefCount(
	in_measure_sid	IN  security_pkg.T_SID_ID
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(INTERNAL_GetMeasureRefCount, WNDS, WNPS);

/**
 * Return a row set containing info about all measures
 *
 * @param	in_act_id					Access token
 * @param	in_app_sid					The application sid
 * @param	out_measure_cur				Measure details
 */
PROCEDURE GetAllMeasures(
    in_act_id       				IN  security_pkg.T_ACT_ID,
	in_app_sid						IN  security_pkg.T_SID_ID,
	out_measure_cur					OUT SYS_REFCURSOR
);

/**
 * Return a row set containing info about all measures
 *
 * @param	in_act_id					Access token
 * @param	in_app_sid					The application sid
 * @param	out_measure_cur				Measure details
 * @param	out_measure_conv_cur		Measure conversion details
 * @param	out_measure_conv_date_cur	Values for time varying measure conversions
 *
 */
PROCEDURE GetAllMeasures(
    in_act_id       				IN  security_pkg.T_ACT_ID,
	in_app_sid						IN  security_pkg.T_SID_ID,
	out_measure_cur					OUT SYS_REFCURSOR,
	out_measure_conv_cur			OUT SYS_REFCURSOR,
	out_measure_conv_date_cur		OUT	SYS_REFCURSOR
);

/**
 * Return a row set containing info about all measures for current act and appsid
 *
 * @param	out_measure_cur				Measure details
 * @param	out_measure_conv_cur		Measure conversion details
 * @param	out_measure_conv_date_cur	Values for time varying measure conversions
 *
 */
PROCEDURE GetAllMeasures(
	out_measure_cur					OUT SYS_REFCURSOR,
	out_measure_conv_cur			OUT SYS_REFCURSOR,
	out_measure_conv_date_cur		OUT	SYS_REFCURSOR
);

/**
 * GetMeasureList
 * 
 * @param in_act_id				Access token
 * @param in_app_sid		The sid of the Application/CSR object
 * @param in_order_by			.
 * @param out_cur				The rowset
 */
PROCEDURE GetMeasureList(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_app_sid IN  security_pkg.T_SID_ID,
	in_order_by		IN	VARCHAR2,
	out_cur			OUT SYS_REFCURSOR
);

/**
 * GetConversion
 * 
 * @param in_act_id				Access token
 * @param in_conversion_id		.
 * @param in_dtm				.
 * @param out_cur				The rowset
 */
PROCEDURE GetConversion(
    in_act_id     	 	IN  security_pkg.T_ACT_ID,
	in_conversion_id	IN  MEASURE_CONVERSION.MEASURE_CONVERSION_ID%TYPE,
    in_dtm				IN  DATE,
	out_cur				OUT SYS_REFCURSOR
);

/**
 * Get the result of apply a measure conversion to a value
 * 
 * @param in_act_id				Access token
 * @param in_val_number			Value to convert
 * @param in_conversion_id		The conversion to apply
 * @param in_dtm				Start date of the period the value covers
 * @param out_cur				Rowset of the form: VAL_NUMBER
 */
PROCEDURE GetConvertedValue(
	in_act_id					IN	security_pkg.T_ACT_ID,
	in_val_number				IN	val.entry_val_number%TYPE,
	in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_dtm						IN	DATE,
	out_cur						OUT	SYS_REFCURSOR
);

/**
 * Get the result of apply a measure conversion to a value
 * 
 * @param in_val_number			Value to convert
 * @param in_conversion_id		The conversion to apply
 * @param in_dtm				Start date of the period the value covers
 */
FUNCTION UNSEC_GetConvertedValue(
	in_val_number				IN	val.entry_val_number%TYPE,
	in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_dtm						IN	DATE
) RETURN val.val_number%TYPE;
PRAGMA RESTRICT_REFERENCES(UNSEC_GetConvertedValue, WNDS, WNPS);

/**
 * Get the base value given a value in one of the measure's conversion units
 * 
 * @param in_val_number			Value to convert
 * @param in_conversion_id		The conversion to apply
 * @param in_dtm				Start date of the period the value covers
 */
FUNCTION UNSEC_GetBaseValue(
	in_val_number				IN	val.entry_val_number%TYPE,
	in_conversion_id			IN	measure_conversion.measure_conversion_id%TYPE,
	in_dtm						IN	DATE
) RETURN val.val_number%TYPE;
PRAGMA RESTRICT_REFERENCES(UNSEC_GetBaseValue, WNDS, WNPS);

/**
 * DeleteConversion
 * 
 * @param in_act_id				Access token
 * @param in_conversion_id		.
 */
PROCEDURE DeleteConversion(
    in_act_id     	 	IN  security_pkg.T_ACT_ID,
	in_conversion_id	IN  MEASURE_CONVERSION.MEASURE_CONVERSION_ID%TYPE
);			  			

/**
 * SetConversion
 * 
 * @param in_act_id					Access token
 * @param in_conversion_id			.
 * @param in_measure_sid			.
 * @param in_description			The description
 * @param in_conversion_factor		.
 * @param out_conversion_id			.
 */
PROCEDURE SetConversion(
    in_act_id     	 		IN  security_pkg.t_act_id,
	in_conversion_id		IN  measure_conversion.measure_conversion_id%TYPE,	   
	in_measure_sid			IN  security_pkg.t_sid_id,
	in_description			IN	measure_conversion.description%TYPE,
	in_a					IN	measure_conversion.a%TYPE,
	in_b					IN	measure_conversion.b%TYPE,
	in_c					IN	measure_conversion.c%TYPE,
	out_conversion_id		OUT	measure_conversion.measure_conversion_id%TYPE
);

/**
 * SetConversion
 * 
 * @param in_act_id							Access token
 * @param in_conversion_id					.
 * @param in_measure_sid					.
 * @param in_description					The description
 * @param in_std_measure_conversion_id		.
 * @param out_conversion_id					.
 */
PROCEDURE SetConversion(
    in_act_id     	 				IN  security_pkg.t_act_id,
	in_conversion_id				IN  measure_conversion.measure_conversion_id%TYPE,	   
	in_measure_sid					IN  security_pkg.t_sid_id,
	in_description					IN	measure_conversion.description%TYPE,
	in_std_measure_conversion_id	IN	std_measure_conversion.std_measure_conversion_id%TYPE,
	out_conversion_id				OUT	measure_conversion.measure_conversion_id%TYPE
);

/**
 * Return a row set containing info about all measures
 *
 * @param	in_act_id		Access token
 * @param	in_measure_sid	The master measure
 
 * The rowset is of the fixed form:
 * measure_conversion_id, description, convesion factor
 */
PROCEDURE GetConversions(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_measure_sid	IN  security_pkg.T_SID_ID,
	out_cur			OUT SYS_REFCURSOR
);

-- creates a new CP
PROCEDURE SetConversionPeriod(
    in_act_id     	 			IN  security_pkg.T_ACT_ID,
    in_measure_sid              IN  security_pkg.T_SID_ID,
    in_description          	IN	measure_conversion.description%TYPE,
    in_a						IN	measure_conversion.a%TYPE,
    in_b						IN	measure_conversion.b%TYPE,
    in_c						IN	measure_conversion.c%TYPE,
    in_start_dtm				IN	measure_conversion_period.start_dtm%TYPE,
    out_measure_conversion_id	OUT	measure_conversion.measure_conversion_id%TYPE
);

-- update an existing CP
PROCEDURE UpdateConversionPeriod(
    in_act_id     	 			IN  security_pkg.T_ACT_ID,
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
    in_description          	IN	measure_conversion.description%TYPE,
    in_a						IN	measure_conversion.a%TYPE,
    in_b						IN	measure_conversion.b%TYPE,
    in_c						IN	measure_conversion.c%TYPE,
    in_start_dtm				IN	measure_conversion_period.start_dtm%TYPE
);

-- setting to null = delete
/**
 * SetConversionPeriod
 * 
 * @param in_act_id						Access token
 * @param in_measure_conversion_id		.
 * @param in_conversion_factor			.
 * @param in_start_dtm					The start date
 */
PROCEDURE SetConversionPeriod(
    in_act_id     	 			IN  security_pkg.T_ACT_ID,	   
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
    in_a						IN	measure_conversion.a%TYPE,
    in_b						IN	measure_conversion.b%TYPE,
    in_c						IN	measure_conversion.c%TYPE,
    in_start_dtm				IN	date
);
 
/**
 * GetConversionPeriods
 * 
 * @param in_act_id						Access token
 * @param in_measure_conversion_id		The measure conversion id to get the periods for.
 * @param out_cur						The rowset
 */
PROCEDURE GetConversionPeriods(
    in_act_id       			IN  security_pkg.T_ACT_ID,
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

/**
 * GetMeasureConversionPeriods - Get Measure and Conversion Period data.
 * 
 * @param in_act_id						Access token
 * @param in_measure_conversion_id		.
 * @param out_cur						The rowset
 */
PROCEDURE GetMeasureConversionPeriods(
    in_act_id       			IN  security_pkg.T_ACT_ID,
    in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE GetMeasureConversionPeriods(
	in_act_id					IN  security_pkg.T_ACT_ID,
	in_measure_conversion_id	IN	measure_conversion.measure_conversion_id%TYPE,
	in_start_row				IN	INTEGER,
	in_row_count				IN	INTEGER,
	in_order_by					IN	VARCHAR2 DEFAULT 'measure_description',
	in_order_dir				IN	VARCHAR2 DEFAULT 'ASC',
	in_filter_text				IN	VARCHAR2,
	out_total_rows				OUT	INTEGER,
	out_cur						OUT SYS_REFCURSOR
);

FUNCTION INTERNAL_GetConversionRefCount(
	in_measure_conversion_id	IN  measure_conversion.measure_conversion_id%TYPE
) RETURN NUMBER;
PRAGMA RESTRICT_REFERENCES(INTERNAL_GetConversionRefCount, WNDS, WNPS);


/**
 * GetConversionList
 * 
 * @param in_act_id			Access token
 * @param in_measure_sid	.
 * @param in_order_by		.
 * @param out_cur			The rowset
 */
PROCEDURE GetConversionList(
    in_act_id       IN  security_pkg.T_ACT_ID,
	in_measure_sid	IN  security_pkg.T_SID_ID,
	in_order_by		IN	VARCHAR2,
	out_cur			OUT SYS_REFCURSOR
);

/**
 * SetOptionItems
 * 
 * @param in_act_id				Access token
 * @param in_measure_sid		.
 * @param in_options			.
 * @param out_option_set_id		.
 */
PROCEDURE SetOptionItems(
	in_act_id			IN  security_pkg.T_ACT_ID,  
	in_measure_sid		IN  security_pkg.T_SID_ID,			
    in_options			IN	VARCHAR2,
    out_option_set_id	OUT	option_set.option_set_id%TYPE
);

/**
 * GetOptionItems
 * 
 * @param in_act_id			Access token
 * @param in_measure_sid	.
 * @param out_cur			The rowset
 */
PROCEDURE GetOptionItems(
	in_act_id			IN  security_pkg.T_ACT_ID,  
	in_measure_sid		IN  security_pkg.T_SID_ID,			
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetStdMeasureConversions(
	out_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetStdMeasureConversion(
	in_std_measure_conversion_id	IN security_pkg.T_SID_ID,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetStdMeasureConvOfConv(
	in_measure_sid		IN security_pkg.T_SID_ID,
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetStdMeasureConvOfConv(
	in_measure_sid					IN security_pkg.T_SID_ID,
	in_std_measure_conversion_id	IN std_measure_conversion.std_measure_conversion_id%TYPE,
	out_a							OUT measure_conversion.a%TYPE,
	out_b							OUT measure_conversion.b%TYPE,
	out_c							OUT measure_conversion.c%TYPE
);

PROCEDURE GetStdMeasureConversion(
	in_m							IN std_measure.m%TYPE,
	in_kg							IN std_measure.kg%TYPE,
	in_s							IN std_measure.s%TYPE,
	in_a							IN std_measure.a%TYPE,
	in_k							IN std_measure.k%TYPE,
	in_mol							IN std_measure.mol%TYPE,
	in_cd							IN std_measure.cd%TYPE,
	out_cur							OUT	SYS_REFCURSOR
);

PROCEDURE GetOtherStdMeasureConversions(
	out_cur				OUT SYS_REFCURSOR
);

FUNCTION ConvertValue(
	in_val			IN	NUMBER,
	in_from			IN	vARCHAR2,
	in_to			IN	vARCHAR2
) RETURN csr_data_pkg.T_DOTNET_NUMBER;

PROCEDURE GetLastUsedMeasureConv(
	in_sheet_id		IN	sheet.sheet_id%TYPE,
	out_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetLastUsedMeasureConv(
	in_ind_sid		IN	security_pkg.T_SID_ID,
	out_id			OUT	measure_conversion.measure_conversion_id%TYPE
);

FUNCTION MeasureConversionsExist
RETURN NUMBER;

/**
 * GetUserMeasureConversions
 * 
 * @param in_start_row
 * @param in_page_size
 * @param out_measures_cur		The measures with user conversion preferences
 */
PROCEDURE GetUserMeasureConversions(
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	out_total			OUT	NUMBER,
	out_measures_cur	OUT SYS_REFCURSOR,
	out_conversions_cur	OUT SYS_REFCURSOR
);

PROCEDURE SetUserMeasureConversion(
	in_measure_sid		IN security_pkg.T_SID_ID,
	in_conversion_id	IN measure_conversion.measure_conversion_id%TYPE
);

PROCEDURE GetStdMeasures(
	out_cur				OUT SYS_REFCURSOR
);

END Measure_Pkg;
/
