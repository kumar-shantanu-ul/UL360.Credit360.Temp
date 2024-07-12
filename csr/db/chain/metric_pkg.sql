CREATE OR REPLACE PACKAGE  CHAIN.metric_pkg
IS

PROCEDURE GetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION SetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	in_value				IN company_metric.metric_value%TYPE
) RETURN company_metric.normalised_value%TYPE;

PROCEDURE DeleteCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE
);


END metric_pkg;
/

