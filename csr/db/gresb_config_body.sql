CREATE OR REPLACE PACKAGE BODY csr.gresb_config_pkg AS
    
PROCEDURE GetIndicatorMappings(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT gi.gresb_indicator_id, gi.gresb_indicator_type_id, gi.title, gi.format, gi.description,
			   gi.unit, gi.std_measure_conversion_id, gi.system_managed, gi.sm_description,
			   gim.ind_sid, gim.measure_conversion_id, NVL(gim.not_applicable, 0) not_applicable, m.measure_sid
		  FROM gresb_indicator gi 
	 LEFT JOIN gresb_indicator_mapping gim
		    ON gi.gresb_indicator_id = gim.gresb_indicator_id
	 LEFT JOIN measure_conversion mc
			ON mc.measure_conversion_id = gim.measure_conversion_id
	 LEFT JOIN measure m
			ON m.measure_sid = mc.measure_sid
		   AND NVL(gim.app_sid, security_pkg.GetApp) = security_pkg.GetApp;
END;	

PROCEDURE GetIndicatorTypes(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT git.gresb_indicator_type_id, git.title, git.required
		  FROM gresb_indicator_type git
		 ORDER BY pos ASC;
END;	

PROCEDURE SaveMapping(
	in_gresb_indicator_id			IN  gresb_indicator_mapping.gresb_indicator_id%TYPE,
	in_ind_sid						IN  gresb_indicator_mapping.ind_sid%TYPE,
	in_measure_conversion_id		IN  gresb_indicator_mapping.measure_conversion_id%TYPE,
	in_not_applicable				IN  gresb_indicator_mapping.not_applicable%TYPE
)
AS
	v_count	NUMBER(10);
BEGIN	
	SELECT count(*)
	  INTO v_count
	  FROM gresb_indicator_mapping
	 WHERE gresb_indicator_id = in_gresb_indicator_id
	   AND app_sid = security_pkg.GetApp;
	   
	IF v_count > 0 THEN 
		UPDATE gresb_indicator_mapping 
		   SET ind_sid = in_ind_sid,
		       measure_conversion_id = in_measure_conversion_id,
			   not_applicable = in_not_applicable
		 WHERE gresb_indicator_id = in_gresb_indicator_id;
	ELSE
		INSERT INTO gresb_indicator_mapping(gresb_indicator_id, ind_sid, measure_conversion_id, not_applicable)
		     VALUES (in_gresb_indicator_id, in_ind_sid, in_measure_conversion_id, in_not_applicable);
		      
	END IF;
END;

FUNCTION GetMatchedMeasureConversion(
	in_ind_sid						IN  ind.ind_sid%TYPE,
	in_std_measure_conversion_id	IN	gresb_indicator.std_measure_conversion_id%TYPE
) RETURN NUMBER
AS
	v_matched_measure_conversion	NUMBER(10);
	v_measure_sid					measure.measure_sid%TYPE;
BEGIN

	SELECT measure_sid
	  INTO v_measure_sid
	  FROM ind
	 WHERE ind_sid = in_ind_sid;

	BEGIN
		SELECT measure_conversion_id
		  INTO v_matched_measure_conversion
		  FROM (SELECT -1 measure_conversion_id
				  FROM measure
				 WHERE std_measure_conversion_id = in_std_measure_conversion_id
				   AND measure_sid = v_measure_sid
		  UNION	SELECT measure_conversion_id 
				  FROM measure_conversion
				 WHERE std_measure_conversion_id = in_std_measure_conversion_id
				   AND measure_sid = v_measure_sid)
		  WHERE rownum =1;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN 0;
	END;
		
	RETURN v_matched_measure_conversion;
END;

PROCEDURE GetSubmissionLog(
	in_entity_id					IN	gresb_submission_log.gresb_entity_id%TYPE,
	in_start						IN	NUMBER DEFAULT 0,
	in_limit						IN	NUMBER DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM
			(SELECT gresb_submission_id, gresb_entity_id, gresb_asset_id, submission_type, submission_date, request_data, response_data
			   FROM gresb_submission_log
			  WHERE (in_entity_id IS NULL AND gresb_response_id IS NULL) OR in_entity_id = gresb_entity_id
			  ORDER BY gresb_submission_id DESC)
		 WHERE rownum >= in_start 
		   AND (in_limit IS NULL OR rownum < in_start + in_limit);
END;

PROCEDURE GetResponseSubmissionLog(
	in_response_id					IN	gresb_submission_log.gresb_response_id%TYPE,
	in_start						IN	NUMBER DEFAULT 0,
	in_limit						IN	NUMBER DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT * FROM
			(SELECT gresb_submission_id, gresb_response_id, submission_type, submission_date, request_data, response_data
			   FROM gresb_submission_log
			  WHERE (in_response_id IS NULL AND gresb_entity_id IS NULL) OR in_response_id = gresb_response_id
			  ORDER BY gresb_submission_id DESC)
		 WHERE rownum >= in_start 
		   AND (in_limit IS NULL OR rownum < in_start + in_limit);
END;

PROCEDURE LogSubmission(
	in_entity_id					IN	gresb_submission_log.gresb_entity_id%TYPE,
	in_asset_id						IN	gresb_submission_log.gresb_asset_id%TYPE,
	in_type							IN	gresb_submission_log.submission_type%TYPE,
	in_request_data					IN	gresb_submission_log.request_data%TYPE,
	in_response_data				IN	gresb_submission_log.response_data%TYPE
)
AS
BEGIN
	INSERT INTO gresb_submission_log (gresb_submission_id, gresb_entity_id, gresb_asset_id, submission_type, 
										  submission_date, request_data, response_data)
	VALUES (gresb_submission_seq.NEXTVAL, in_entity_id, in_asset_id, in_type, SYSTIMESTAMP, in_request_data, in_response_data);
END;


PROCEDURE GetValueErrors(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT gresb_error_id, description 
		  FROM gresb_error;
END;

END;
/
