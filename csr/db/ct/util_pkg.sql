CREATE OR REPLACE PACKAGE ct.util_pkg AS


FUNCTION GetRegionIdFromName (
    in_description                   IN region.description%TYPE
) RETURN region.region_id%TYPE;

FUNCTION GetRegionIdFromCode (
    in_country_code                   IN region.country%TYPE
) RETURN region.region_id%TYPE;

FUNCTION GetEioIdFromName (
    in_description                   IN eio.description%TYPE
) RETURN eio.eio_id%TYPE;

FUNCTION GetEioGroupIdFromName (
    in_description                   IN eio.description%TYPE
) RETURN eio_group.eio_group_id%TYPE;

FUNCTION GetScope3CatIdFromName (
    in_description                   IN scope_3_category.description%TYPE
) RETURN scope_3_category.scope_category_id%TYPE;

FUNCTION GetScope3CatNameFromId (
    in_scope_category_id                   IN scope_3_category.scope_category_id%TYPE
) RETURN scope_3_category.description%TYPE;

FUNCTION GetScopeInputTypeId RETURN ct.company.scope_input_type_id%TYPE;

FUNCTION GetConversionToDollar (
	in_currency_id					IN  currency_period.currency_id%TYPE,
	in_period_id                    IN  period.period_id%TYPE
) RETURN currency_period.conversion_to_dollar%TYPE;
	
FUNCTION GetConversionToDollar (
	in_currency_id					IN  currency_period.currency_id%TYPE,
	in_date							IN  DATE
) RETURN currency_period.conversion_to_dollar%TYPE;

FUNCTION GetConversionFromDollar (
	in_currency_id					IN  currency_period.currency_id%TYPE,
	in_date							IN  DATE
) RETURN currency_period.conversion_to_dollar%TYPE;

FUNCTION IsValueChain RETURN customer_options.is_value_chain%TYPE;

FUNCTION IsAlongsideChain RETURN customer_options.is_alongside_chain%TYPE;

FUNCTION CanCopyToIndicators RETURN customer_options.copy_to_indicators%TYPE;

PROCEDURE EnableHotspotterDashboard (
	in_company_sid					IN security_pkg.T_SID_ID
);

PROCEDURE EnableValueChainDashboard (
	in_company_sid			IN security_pkg.T_SID_ID
);

PROCEDURE FillStringTable (
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE FillStringTable (
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values_2				IN  security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_column_type_id_2		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values_2				IN  security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE FillIdMapperTable (
	in_column_type_id_1		IN  NUMBER,
	in_column_type_id_2		IN  NUMBER,
	in_values_1				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_values_2				IN  security_pkg.T_VARCHAR2_ARRAY,
	in_ids					IN  chain.helper_pkg.T_NUMBER_ARRAY
);

PROCEDURE GetTravelMode (
	in_travel_mode_id		IN  travel_mode.travel_mode_id%TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTravelModes (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetHideFlags (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ResetAllDashboards;

PROCEDURE ResetFull;

PROCEDURE ResetSuppliers;

PROCEDURE ResetWorksheets;

FUNCTION GetTopCompanyTypeId
RETURN customer_options.top_company_type_id%TYPE;

FUNCTION GetSupplierCompanyTypeId
RETURN customer_options.supplier_company_type_id%TYPE;

END util_pkg;
/
