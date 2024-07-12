PROMPT This removes all responses for a given survey
PROMPT ===============================================================
PROMPT please enter: host name
DEFINE host='&&1'
PROMPT please enter: survey short name
DEFINE survey_name='&&2'

DECLARE
	v_survey_sid security_pkg.T_SID_ID;
BEGIN
	
	user_pkg.logonadmin('&host');
	v_survey_sid := securableobject_pkg.getsidfrompath(security_pkg.getact, security_pkg.getapp, 'wwwroot/surveys/&survey_name');
	
  DELETE FROM qs_answer_log
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = v_survey_sid
	 );
	
  DELETE FROM quick_survey_answer
	 WHERE survey_response_id IN (
		SELECT survey_response_id
		  FROM quick_survey_response
		 WHERE survey_sid = v_survey_sid
	 );
	 
   DELETE FROM quick_survey_submission
     WHERE survey_response_id IN (
      SELECT survey_response_id
        FROM quick_survey_response
       WHERE survey_sid = v_survey_sid
     );
   
    DELETE FROM supplier_survey_response
     WHERE survey_response_id IN (
      SELECT survey_response_id
        FROM quick_survey_response
       WHERE survey_sid = v_survey_sid
     );
   
	 DELETE FROM quick_survey_response
	  WHERE survey_sid = v_survey_sid;

END;
/