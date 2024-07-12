-- This code is legacy and only used by pending, newer code uses val_datasource_pkg or stored_calc_datasource_body

CREATE OR REPLACE PACKAGE CSR.datasource_Pkg AS

m_ind_sids			T_SID_AND_DESCRIPTION_TABLE;
m_value_ind_sids	security.T_SID_TABLE;
m_dependencies		T_DATASOURCE_DEP_TABLE;
m_is_initialised	BOOLEAN := FALSE;

PROCEDURE GetAllGasFactors(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllIndDetails(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIndDependencies(
	out_cur	OUT	security_pkg.T_OUTPUT_CUR
);


PROCEDURE GetAggregateChildren(
	out_cur	OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetRegionPctOwnership(
	out_cur	OUT security_pkg.T_OUTPUT_CUR
);
	
FUNCTION GetInds RETURN T_SID_AND_DESCRIPTION_TABLE;
FUNCTION GetValueInds RETURN security.T_SID_TABLE;
FUNCTION DependenciesTable RETURN T_DATASOURCE_DEP_TABLE;

PROCEDURE Init(
	in_ind_list				IN	T_SID_AND_DESCRIPTION_TABLE,
	in_include_stored_calcs	IN	NUMBER
);

PROCEDURE Dispose;

END datasource_Pkg;
/
