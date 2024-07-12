CREATE OR REPLACE PACKAGE csr.gresb_config_pkg AS
   
SUBMISSION_TYPE_ASSET_UPLOAD		CONSTANT NUMBER := 0;
SUBMISSION_TYPE_DELETE				CONSTANT NUMBER := 1;

PROCEDURE GetIndicatorMappings(
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetIndicatorTypes(
	out_cur						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveMapping(
	in_gresb_indicator_id			IN  gresb_indicator_mapping.gresb_indicator_id%TYPE,
	in_ind_sid						IN  gresb_indicator_mapping.ind_sid%TYPE,
	in_measure_conversion_id		IN  gresb_indicator_mapping.measure_conversion_id%TYPE,
	in_not_applicable				IN  gresb_indicator_mapping.not_applicable%TYPE
);

FUNCTION GetMatchedMeasureConversion(
	in_ind_sid						IN  ind.ind_sid%TYPE,
	in_std_measure_conversion_id	IN	gresb_indicator.std_measure_conversion_id%TYPE
) RETURN NUMBER;


PROCEDURE GetSubmissionLog(
	in_entity_id					IN	gresb_submission_log.gresb_entity_id%TYPE,
	in_start						IN	NUMBER DEFAULT 0,
	in_limit						IN	NUMBER DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

/**
 *	Reads data from the gresb submission log.
 *	
 *	@param in_response_id			The GRESB response ID to filter results by, or NULL to include all 
 *									responses.
 *
 *	@param in_start					The index of the first row to return.
 *
 *	@param in_limit					The maximum number of rows to return.
 *
 *	@param out_cur					A cursor that will recieve the results. The output record set has the 
 *									format:
 *
 *									Name                                      Null?    Type
 *	 								----------------------------------------- -------- --------------------
 *	 								GRESB_SUBMISSION_ID                       NOT NULL NUMBER(10)
 *	 								GRESB_RESPONSE_ID                         NOT NULL VARCHAR2(255)
 *	 								SUBMISSION_TYPE                           NOT NULL NUMBER(10)
 *	 								SUBMISSION_DATE                           NOT NULL DATE
 *									REQUEST_DATA                                       CLOB
 *	 								RESPONSE_DATA                                      CLOB
 *
 *									If SUBMISSION_TYPE = SUBMISSION_TYPE_ASSET_UPLOAD the RESPONSE_DATA 
 *									column contains the JSON serialised submission data, including errors 
 *									if any. 
 */
PROCEDURE GetResponseSubmissionLog(
	in_response_id					IN	gresb_submission_log.gresb_response_id%TYPE,
	in_start						IN	NUMBER DEFAULT 0,
	in_limit						IN	NUMBER DEFAULT NULL,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE LogSubmission(
	in_entity_id					IN	gresb_submission_log.gresb_entity_id%TYPE,
	in_asset_id						IN	gresb_submission_log.gresb_asset_id%TYPE,
	in_type							IN	gresb_submission_log.submission_type%TYPE,
	in_request_data					IN	gresb_submission_log.request_data%TYPE,
	in_response_data				IN	gresb_submission_log.response_data%TYPE
);

PROCEDURE GetValueErrors(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

END;
/
