PROMPT please enter: host
PROMPT please enter: survey name
whenever oserror exit failure rollback
whenever sqlerror exit failure rollback

DECLARE
	in_ind_survey_root_sid		security_pkg.T_SID_ID;
	in_ind_root_sid				security_pkg.T_SID_ID;
	in_survey_sid				security_pkg.T_SID_ID;
	v_survey_label				quick_survey.label%TYPE;
	tbl_primary					T_SID_AND_DESCRIPTION_TABLE;
	v_aggregate_ind_group_id	csr.aggregate_ind_group.aggregate_ind_group_id%TYPE;
BEGIN
	security.user_pkg.logonadmin('&&1');
	in_survey_sid := securableobject_pkg.getsidfrompath(security_pkg.getact, security_pkg.getapp, 'wwwroot/surveys/&&2');
	
	SELECT label
	  INTO v_survey_label
	  FROM quick_survey
	 WHERE survey_sid = in_survey_sid;
	
	SELECT root_ind_sid, aggregate_ind_group_id
	  INTO in_ind_root_sid, v_aggregate_ind_group_id
	  FROM quick_survey
	 WHERE survey_sid = in_survey_sid;
	
	FOR r IN (
		SELECT i.ind_sid, i.name, i.ind_type
		  FROM ind i
		  JOIN (
			SELECT ind_sid, LEVEL lev
			  FROM ind 
			 START WITH parent_sid = in_ind_root_sid
			CONNECT BY PRIOR ind_sid = parent_sid
		  ) x ON i.ind_sid = x.ind_sid
		 WHERE ind_type = csr.csr_data_pkg.IND_TYPE_CALC
		 ORDER BY x.lev DESC
	)
	LOOP
		csr.calc_pkg.SetCalcXMLAndDeps(in_act_id => security_pkg.GetAct,
				in_calc_ind_sid => r.ind_sid,
				in_calc_xml => SYS.XMLTYPE('<nop />'),
				in_is_stored => 0,
				in_default_interval => NULL,
				in_do_temporal_aggregation => 0,
				in_calc_description => 'Remove calculation'
			);
	END LOOP;
	
	securableobject_pkg.deleteso(security_pkg.getact, in_ind_root_sid);
	
END;
/

exit
