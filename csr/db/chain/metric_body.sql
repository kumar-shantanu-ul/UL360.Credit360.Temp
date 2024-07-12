CREATE OR REPLACE PACKAGE BODY CHAIN.metric_pkg
IS

PROCEDURE GetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.METRICS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied to metrics for company with sid '||in_company_sid);
	END IF;

	
	OPEN out_cur FOR
		SELECT metric_value, max_value, normalised_value
		  FROM company_metric cm, company_metric_type cmt
		 WHERE cm.app_sid = cmt.app_sid
		   AND cm.company_metric_type_id = cmt.company_metric_type_id
		   AND cm.app_sid = security_pkg.GetApp
		   AND cm.company_sid = in_company_sid
		   AND cmt.class = in_class;
	
END;


FUNCTION SetCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE,
	in_value				IN company_metric.metric_value%TYPE
) RETURN company_metric.normalised_value%TYPE
AS
	v_company_metric_type_id   company_metric.company_metric_type_id%TYPE;
	v_max_value				   company_metric_type.max_value%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.METRICS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to metrics for company with sid '||in_company_sid);
	END IF;
	
	SELECT company_metric_type_id, max_value 
	  INTO v_company_metric_type_id, v_max_value
	  FROM company_metric_type
	 WHERE app_sid = security_pkg.GetApp
	   AND class = in_class;
	
	BEGIN
	   INSERT INTO company_metric (app_sid, company_metric_type_id, company_sid, metric_value, normalised_value) 
			VALUES (security_pkg.GetApp, v_company_metric_type_id, in_company_sid, in_value, 100*(in_value/v_max_value)); -- normalize to 100
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
	  
	  UPDATE company_metric 
	     SET metric_value = in_value, 
		     normalised_value = 100*(in_value/v_max_value) -- normalize to 100
	   WHERE app_sid = security_pkg.GetApp
	     AND company_metric_type_id = v_company_metric_type_id
		 AND company_sid = in_company_sid;
		 
	END;
	
	RETURN 100*(in_value/v_max_value);
	
END;

PROCEDURE DeleteCompanyMetric(	
	in_company_sid			IN security_pkg.T_SID_ID,
	in_class				IN company_metric_type.class%TYPE
) 
AS
	v_company_metric_type_id   company_metric.company_metric_type_id%TYPE;
BEGIN
	
	IF NOT capability_pkg.CheckCapability(in_company_sid, chain_pkg.METRICS, security_pkg.PERMISSION_WRITE)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Write access denied to metrics for company with sid '||in_company_sid);
	END IF;
	
	SELECT company_metric_type_id 
	  INTO v_company_metric_type_id
	  FROM company_metric_type
	 WHERE app_sid = security_pkg.GetApp
	   AND class = in_class;
	
	DELETE FROM company_metric 
     WHERE app_sid = security_pkg.GetApp
       AND company_metric_type_id = v_company_metric_type_id
       AND company_sid = in_company_sid;
END;

END metric_pkg;
/
