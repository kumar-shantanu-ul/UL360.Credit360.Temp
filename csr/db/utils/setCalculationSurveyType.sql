PROMPT please enter: host, survey short name
DEFINE host = '&&1'
DEFINE survey = '&&2'

DECLARE
	v_survey_sid		security.security_pkg.T_ACT_ID;
	v_survey_type_id	csr.quick_survey_type.quick_survey_type_id%TYPE;
BEGIN
	security.user_pkg.LogonAdmin('&&host');
	v_survey_sid := security.securableobject_pkg.GetSidFromPath(
		SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'wwwroot/surveys/&&survey'
	);
	
	BEGIN
		SELECT quick_survey_type_id
		  INTO v_survey_type_id
		  FROM csr.quick_survey_type
		 WHERE cs_class = 'Credit360.QuickSurvey.CalculationSurveyType';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			INSERT INTO csr.quick_survey_type (quick_survey_type_id, description, cs_class)
			VALUES (csr.quick_survey_type_id_seq.NEXTVAL, 'Calculation survey type', 'Credit360.QuickSurvey.CalculationSurveyType')
			RETURNING quick_survey_type_id INTO v_survey_type_id;
	END;
	
	UPDATE csr.quick_survey
	   SET quick_survey_type_id = v_survey_type_id
	 WHERE survey_sid = v_survey_sid;
	
END;
/

exit
