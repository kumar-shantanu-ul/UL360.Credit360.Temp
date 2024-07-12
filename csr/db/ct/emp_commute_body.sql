CREATE OR REPLACE PACKAGE BODY ct.emp_commute_pkg AS

PROCEDURE GetRegionFactors(
    in_region_id            		IN ec_region_factors.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR 
)
AS
	v_default_car_id 					ec_car_type.car_type_id%TYPE;
	v_default_bus_id					ec_bus_type.bus_type_id%TYPE;
	v_default_train_id					ec_train_type.train_type_id%TYPE;
	v_default_motorbike_id				ec_motorbike_type.motorbike_type_id%TYPE;
	
	v_car_kg_co2_per_km 				ec_car_type.kg_co2_per_km_contribution%TYPE;
	v_bus_kg_co2_per_km					ec_bus_type.kg_co2_per_km_contribution%TYPE;
	v_train_kg_co2_per_km				ec_train_type.kg_co2_per_km_contribution%TYPE;
	v_motorbike_kg_co2_per_km			ec_motorbike_type.kg_co2_per_km_contribution%TYPE;

	v_cnt							NUMBER := 0;
BEGIN

	SELECT car_type_id, kg_co2_per_km_contribution INTO v_default_car_id, v_car_kg_co2_per_km FROM ec_car_type WHERE is_default = 1; 
	SELECT bus_type_id, kg_co2_per_km_contribution INTO v_default_bus_id, v_bus_kg_co2_per_km FROM ec_bus_type WHERE is_default = 1; 
	SELECT train_type_id, kg_co2_per_km_contribution INTO v_default_train_id, v_train_kg_co2_per_km FROM ec_train_type WHERE is_default = 1; 
	SELECT motorbike_type_id, kg_co2_per_km_contribution INTO v_default_motorbike_id, v_motorbike_kg_co2_per_km FROM ec_motorbike_type WHERE is_default = 1; 

	SELECT COUNT(*) INTO v_cnt
	  FROM ec_region_factors 
	 WHERE region_id = in_region_id;
	
	-- fall back to the Rest Of The World if the factor for this region is not found
	IF v_cnt > 0 THEN
		OPEN out_cur FOR
			SELECT region_id, holidays, car_avg_pct_use, 
				   bus_avg_pct_use, train_avg_pct_use, motorbike_avg_pct_use, 
				   bike_avg_pct_use, walk_avg_pct_use, car_avg_journey_km, 
				   bus_avg_journey_km, train_avg_journey_km, motorbike_avg_journey_km, 
				   bike_avg_journey_km, walk_avg_journey_km, 
				   v_default_car_id default_car_id, v_car_kg_co2_per_km car_kg_co2_per_km,
				   v_default_bus_id default_bus_id, v_bus_kg_co2_per_km bus_kg_co2_per_km, 
				   v_default_train_id default_train_id, v_train_kg_co2_per_km train_kg_co2_per_km,
				   v_default_motorbike_id default_motorbike_id, v_motorbike_kg_co2_per_km motorbike_kg_co2_per_km,
				   0 is_row 
			  FROM ec_region_factors 
			 WHERE region_id = in_region_id;
	ELSE
		OPEN out_cur FOR
			SELECT region_id, holidays, car_avg_pct_use, 
				   bus_avg_pct_use, train_avg_pct_use, motorbike_avg_pct_use, 
				   bike_avg_pct_use, walk_avg_pct_use, car_avg_journey_km, 
				   bus_avg_journey_km, train_avg_journey_km, motorbike_avg_journey_km, 
				   bike_avg_journey_km, walk_avg_journey_km, 
				   v_default_car_id default_car_id, v_car_kg_co2_per_km car_kg_co2_per_km,
				   v_default_bus_id default_bus_id, v_bus_kg_co2_per_km bus_kg_co2_per_km, 
				   v_default_train_id default_train_id, v_train_kg_co2_per_km train_kg_co2_per_km,
				   v_default_motorbike_id default_motorbike_id, v_motorbike_kg_co2_per_km motorbike_kg_co2_per_km,
				   1 is_row 
			  FROM ec_region_factors 
			 WHERE region_id = admin_pkg.ROW_COUNTRY_CODE_ID;	
	END IF;
END;

PROCEDURE GetQuestionnaires
(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	OPEN out_cur FOR
		SELECT eq.ec_questionnaire_id, eq.guid, eq.breakdown_id, eq.region_id, 
		      (SELECT COUNT(*) FROM ec_questionnaire_answers eqa WHERE eq.ec_questionnaire_id = eqa.ec_questionnaire_id) total_responses
		  FROM ec_questionnaire eq
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');	
END;

PROCEDURE GetQuestionnaireByGuid
(
	in_guid							IN  ec_questionnaire.guid%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- No security/app checks as this is used by public survey pages.
	OPEN out_cur FOR
		SELECT eq.ec_questionnaire_id, eq.guid, eq.breakdown_id, eq.region_id, 
		      (SELECT COUNT(*) FROM ec_questionnaire_answers eqa WHERE eq.ec_questionnaire_id = eqa.ec_questionnaire_id) total_responses
		  FROM ec_questionnaire eq
		 WHERE guid = in_guid;	
END;

PROCEDURE GetCarTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT car_type_id id, description, kg_co2_per_km_contribution, is_default
		  FROM ec_car_type;
END;

PROCEDURE GetBusTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT bus_type_id id, description, kg_co2_per_km_contribution, is_default
		  FROM ec_bus_type;
END;

PROCEDURE GetTrainTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT train_type_id id, description, kg_co2_per_km_contribution, is_default
		  FROM ec_train_type;
END;

PROCEDURE GetMotorbikeTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT motorbike_type_id id, description, kg_co2_per_km_contribution, is_default
	      FROM ec_motorbike_type;
END;

PROCEDURE GetCarTypeEmissFact(
    in_car_type_id                	IN ec_car_type.car_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN

 	OPEN out_cur FOR 
		SELECT kg_co2_per_km_contribution
		  FROM ec_car_type
		 WHERE car_type_id = in_car_type_id;
END;

PROCEDURE GetBusTypeEmissFact(
    in_bus_type_id                	IN ec_bus_type.bus_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
 	OPEN out_cur FOR 
		SELECT kg_co2_per_km_contribution
		  FROM ec_bus_type
		 WHERE bus_type_id = in_bus_type_id;
END;

PROCEDURE GetTrainTypeEmissFact(
    in_train_type_id                IN ec_train_type.train_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
 	OPEN out_cur FOR 
		SELECT kg_co2_per_km_contribution
		  FROM ec_train_type
		 WHERE train_type_id = in_train_type_id;
END;

PROCEDURE GetMotorbikeTypeEmissFact(
    in_motorbike_type_id            IN ec_motorbike_type.motorbike_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
 	OPEN out_cur FOR 
		SELECT kg_co2_per_km_contribution
		  FROM ec_motorbike_type
		 WHERE motorbike_type_id = in_motorbike_type_id;
END;

PROCEDURE GetECProfile(
	in_breakdown_group_id			IN  ct.ec_profile.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	OPEN out_cur FOR
		SELECT  breakdown_group_id,
		        annual_leave_days,
				car_pct_use, 
				car_avg_dist, 
				car_distance_unit_id, 
				bus_pct_use, 
				bus_avg_dist, 
				bus_distance_unit_id, 
				train_pct_use, 
				train_avg_dist, 
				train_distance_unit_id, 
				motorbike_pct_use, 
				motorbike_avg_dist, 
				motorbike_distance_unit_id, 
				bike_pct_use, 
				bike_avg_dist, 
				bike_distance_unit_id, 
				walk_pct_use, 
				walk_avg_dist, 
				walk_distance_unit_id,
				DECODE(modified_by_sid, NULL, 1, 0) is_default
		  FROM ec_profile
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetCarModelsForManufacturer(
	in_car_id						IN  ct.ec_car_model.car_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TO DO - what sort of sec check

	OPEN out_cur FOR
		SELECT car_id, description 
		  FROM ct.ec_car_model 
		 WHERE manufacturer_id = in_car_id;
END;

PROCEDURE GetCarBreakdowns(
	in_breakdown_group_id			IN  ct.ec_car_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	OPEN out_cur FOR
		SELECT ve.car_type_id id,
			   breakdown_group_id,
		       pct, 
			   kg_co2_per_km_contribution
		  FROM ec_car_entry ve, ec_car_type vt
		 WHERE ve.car_type_id = vt.car_type_id
		   AND ve.app_sid = security_pkg.getApp
		   AND ve.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ve.breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetBusBreakdowns(
	in_breakdown_group_id			IN  ct.ec_bus_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	OPEN out_cur FOR
		SELECT ve.bus_type_id id,
			   breakdown_group_id,
		       pct, 
			   kg_co2_per_km_contribution
		  FROM ec_bus_entry ve, ec_bus_type vt
		 WHERE ve.bus_type_id = vt.bus_type_id
		   AND ve.app_sid = security_pkg.getApp
		   AND ve.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ve.breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetMotorbikeBreakdowns(
	in_breakdown_group_id			IN  ct.ec_motorbike_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	OPEN out_cur FOR
		SELECT ve.motorbike_type_id id,
			   breakdown_group_id,
		       pct, 
			   kg_co2_per_km_contribution
		  FROM ec_motorbike_entry ve, ec_motorbike_type vt
		 WHERE ve.motorbike_type_id = vt.motorbike_type_id
		   AND ve.app_sid = security_pkg.getApp
		   AND ve.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ve.breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetTrainBreakdowns(
	in_breakdown_group_id			IN  ct.ec_train_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	OPEN out_cur FOR
		SELECT ve.train_type_id id,
			   breakdown_group_id,
		       pct, 
			   kg_co2_per_km_contribution
		  FROM ec_train_entry ve, ec_train_type vt
		 WHERE ve.train_type_id = vt.train_type_id
		   AND ve.app_sid = security_pkg.getApp
		   AND ve.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ve.breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE GetCarManufacturers(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR 
		SELECT manufacturer_id id, manufacturer description
		  FROM ec_car_manufacturer;
END;

PROCEDURE GetDistanceUom(
	in_distance_unit_id				IN  distance_unit.distance_unit_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT distance_unit_id id,
		       description,
			   symbol,
			   conversion_to_km
		  FROM distance_unit
		 WHERE distance_unit_id = in_distance_unit_id;
END;

PROCEDURE GetDistanceUoms(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT distance_unit_id id,
		       description,
			   symbol,
			   conversion_to_km
		  FROM distance_unit;
END;

PROCEDURE GetVolumeUom(
	in_volume_unit_id				IN  volume_unit.volume_unit_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT volume_unit_id id,
		       description,
			   symbol,
			   conversion_to_litres
		  FROM volume_unit
		 WHERE volume_unit_id = in_volume_unit_id;
END;

PROCEDURE GetVolumeUoms(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT volume_unit_id id,
		       description,
			   symbol,
			   conversion_to_litres
		  FROM volume_unit;
END;

-- rubbish place for this to live - but these units need moving to be compatible with csr/standard units
PROCEDURE GetTimeUom(
	in_time_unit_id				IN  time_unit.time_unit_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT time_unit_id id,
		       description,
			   symbol,
			   conversion_to_secs
		  FROM time_unit
		 WHERE time_unit_id = in_time_unit_id;
END;

PROCEDURE GetTimeUoms(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT time_unit_id id,
		       description,
			   symbol,
			   conversion_to_secs
		  FROM time_unit;
END;

PROCEDURE GetOptions(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	-- TO DO - review this - needed in hotspotter model
	--IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
	--	RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	--END IF;
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to read Employee Commute options');
	END IF;

	OPEN out_cur FOR
		SELECT annual_leave_days,
		       breakdown_type_id,
		       extrapolate,
    		   extrapolation_pct
		  FROM ec_options
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
END;

PROCEDURE GetResults(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	GetResult(null, out_cur);
END;

PROCEDURE GetResult(
	in_breakdown_group_id			IN  ct.ec_profile.breakdown_group_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	OPEN out_cur FOR
        SELECT  e.breakdown_group_id, total_fte,
                ROUND(total_emissions/1000, 0) total_emissions_tonnes, 
                ROUND(DECODE(total_fte, 0, 0, total_emissions/total_fte) /10, 0)*10 emissions_per_fte, 
                ROUND(DECODE(total_fte, 0, 0, total_emissions/total_fte)/(365 - (52*2) - NVL(ecp.annual_leave_days, 0)),1) emissions_per_fte_per_day, 
                NVL2(modified_by_sid, 0, 1) is_default, modified_by_sid
        FROM
        (
            SELECT bg.breakdown_group_id,
                   SUM(car_kg_co2 + bus_kg_co2 + train_kg_co2 + motorbike_kg_co2 + bike_kg_co2 + walk_kg_co2) total_emissions, 
                   SUM(b.fte) total_fte
              FROM v$ec_emissions ece
              JOIN breakdown_region_group brg ON ece.breakdown_id = brg.breakdown_id AND ece.region_id = brg.region_id AND ece.app_sid = brg.app_sid
              JOIN breakdown b ON b.breakdown_id = ece.breakdown_id AND b.app_sid = ece.app_sid
              JOIN breakdown_group bg ON brg.breakdown_group_id = bg.breakdown_group_id AND brg.app_sid = bg.app_sid
			  JOIN ec_options o ON ece.app_sid = o.app_sid            
			  WHERE bg.breakdown_group_id = NVL(in_breakdown_group_id, bg.breakdown_group_id)
               AND bg.group_key = 'EC'
			   AND ece.app_sid = security_pkg.getApp
			   AND ece.breakdown_id IN (SELECT breakdown_id FROM breakdown WHERE breakdown_type_id = o.breakdown_type_id)
               AND ece.calculation_source_id = ct_pkg.EC_DS_PROFILE
            GROUP BY bg.breakdown_group_id
        ) e, ec_profile ecp
         WHERE e.breakdown_group_id = ecp.breakdown_group_id(+)
           AND ecp.app_sid = security_pkg.getApp
           AND ecp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
	
END;

PROCEDURE SetQuestionnaire
(
	in_breakdown_id					IN  ec_questionnaire.breakdown_id%TYPE,
	in_region_id					IN  ec_questionnaire.region_id%TYPE
)
AS
BEGIN
	SetQuestionnaire(null, in_breakdown_id, in_region_id);
END;

PROCEDURE SetQuestionnaire
(
	in_ec_questionnaire_id			IN  ec_questionnaire.ec_questionnaire_id%TYPE,
	in_breakdown_id					IN  ec_questionnaire.breakdown_id%TYPE,
	in_region_id					IN  ec_questionnaire.region_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;

	IF in_ec_questionnaire_id IS NULL THEN
		INSERT INTO ec_questionnaire (app_sid, company_sid, ec_questionnaire_id, guid, breakdown_id, region_id)
			 VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), 
						 ec_questionnaire_id_seq.NEXTVAL, security.user_pkg.RawAct, in_breakdown_id, in_region_id);
	ELSE
		UPDATE ec_questionnaire
		   SET breakdown_id = in_breakdown_id,
		       region_id = in_region_id
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND ec_questionnaire_id = in_ec_questionnaire_id;
			   
	END IF;
END;

PROCEDURE SetECQuestionnaireAnswer
(
	in_ec_questionnaire_id		 	IN ec_questionnaire_answers.ec_questionnaire_id%TYPE,
	in_ec_questionnaire_answers_id 	IN ec_questionnaire_answers.ec_questionnaire_answers_id%TYPE,
	in_working_days_per_wk 			IN ec_questionnaire_answers.working_days_per_wk%TYPE,
	in_vacation_days_per_yr 		IN ec_questionnaire_answers.vacation_days_per_yr%TYPE,
	in_other_leave_days_per_yr 		IN ec_questionnaire_answers.other_leave_days_per_yr%TYPE,
	in_car_days 			 		IN ec_questionnaire_answers.car_days%TYPE,
	in_car_distance 				IN ec_questionnaire_answers.car_distance%TYPE,
	in_car_distance_unit_id 		IN ec_questionnaire_answers.car_distance_unit_id%TYPE,
	in_car_id 			 			IN ec_questionnaire_answers.car_id%TYPE,
	in_bus_days 					IN ec_questionnaire_answers.bus_days%TYPE,
	in_bus_distance 				IN ec_questionnaire_answers.bus_distance%TYPE,
	in_bus_distance_unit_id 		IN ec_questionnaire_answers.bus_distance_unit_id%TYPE,
	in_bus_type_id 					IN ec_questionnaire_answers.bus_type_id%TYPE,
	in_train_days 					IN ec_questionnaire_answers.train_days%TYPE,
	in_train_distance 				IN ec_questionnaire_answers.train_distance%TYPE,
	in_train_distance_unit_id 		IN ec_questionnaire_answers.train_distance_unit_id%TYPE,
	in_train_type_id 				IN ec_questionnaire_answers.train_type_id%TYPE,
	in_motorbike_days 				IN ec_questionnaire_answers.motorbike_days%TYPE,
	in_motorbike_distance 			IN ec_questionnaire_answers.motorbike_distance%TYPE,
	in_motorbike_distance_unit_id 	IN ec_questionnaire_answers.motorbike_distance_unit_id%TYPE,
	in_motorbike_type_id 			IN ec_questionnaire_answers.motorbike_type_id%TYPE,
	in_bike_days 					IN ec_questionnaire_answers.bike_days%TYPE,
	in_bike_distance 				IN ec_questionnaire_answers.bike_distance%TYPE,
	in_bike_distance_unit_id 		IN ec_questionnaire_answers.bike_distance_unit_id%TYPE,
	in_walk_days 					IN ec_questionnaire_answers.walk_days%TYPE,
	in_walk_distance 				IN ec_questionnaire_answers.walk_distance%TYPE,
	in_walk_distance_unit_id		IN ec_questionnaire_answers.walk_distance_unit_id%TYPE
)
AS
	v_app_sid						security_pkg.T_SID_ID;
	v_company_sid					security_pkg.T_SID_ID;
BEGIN
	-- no security, public questionnaire
	
	-- grab app_sid/company_sid from questionnaire table, as they aren't set in context.
	SELECT app_sid, company_sid
	  INTO v_app_sid, v_company_sid
	  FROM ec_questionnaire
	 WHERE ec_questionnaire_id = in_ec_questionnaire_id;
	
	IF in_ec_questionnaire_answers_id IS NULL THEN
		INSERT INTO ec_questionnaire_answers(
			app_sid,
			company_sid,
			ec_questionnaire_id,
			ec_questionnaire_answers_id,
			working_days_per_wk,
			vacation_days_per_yr,
			other_leave_days_per_yr,
			car_days,
			car_distance,
			car_distance_unit_id,
			car_id,
			bus_days,
			bus_distance,
			bus_distance_unit_id,
			bus_type_id,
			train_days,
			train_distance,
			train_distance_unit_id,
			train_type_id,
			motorbike_days,
			motorbike_distance,
			motorbike_distance_unit_id,
			motorbike_type_id,
			bike_days,
			bike_distance,
			bike_distance_unit_id,
			walk_days,
			walk_distance,
			walk_distance_unit_id
		) VALUES(
			v_app_sid,
			v_company_sid,
			in_ec_questionnaire_id,
			ec_questionnaire_ans_id_seq.NEXTVAL,
			in_working_days_per_wk,
			in_vacation_days_per_yr,
			in_other_leave_days_per_yr,
			in_car_days,
			in_car_distance,
			in_car_distance_unit_id,
			in_car_id,
			in_bus_days,
			in_bus_distance,
			in_bus_distance_unit_id,
			in_bus_type_id,
			in_train_days,
			in_train_distance,
			in_train_distance_unit_id,
			in_train_type_id,
			in_motorbike_days,
			in_motorbike_distance,
			in_motorbike_distance_unit_id,
			in_motorbike_type_id,
			in_bike_days,
			in_bike_distance,
			in_bike_distance_unit_id,
			in_walk_days,
			in_walk_distance,
			in_walk_distance_unit_id
		);
	ELSE
		UPDATE ec_questionnaire_answers
			SET 
				ec_questionnaire_id			=	in_ec_questionnaire_id,
				working_days_per_wk 		=	in_working_days_per_wk,
				vacation_days_per_yr 		=	in_vacation_days_per_yr,
				other_leave_days_per_yr 	=	in_other_leave_days_per_yr,
				car_days					=	in_car_days,
				car_distance 				=	in_car_distance,
				car_distance_unit_id 		=	in_car_distance_unit_id,
				car_id						= 	in_car_id,
				bus_days		 			=	in_bus_days,
				bus_distance 				=	in_bus_distance,
				bus_distance_unit_id 		=	in_bus_distance_unit_id,
				bus_type_id					= 	in_bus_type_id,
				train_days 				=	in_train_days,
				train_distance 				=	in_train_distance,
				train_distance_unit_id 		=	in_train_distance_unit_id,
				train_type_id				= 	in_train_type_id,
				motorbike_days 			=	in_motorbike_days,
				motorbike_distance 			=	in_motorbike_distance,
				motorbike_distance_unit_id 	=	in_motorbike_distance_unit_id,
				motorbike_type_id			= 	in_motorbike_type_id,
				bike_days 					=	in_bike_days,
				bike_distance 				=	in_bike_distance,
				bike_distance_unit_id 		=	in_bike_distance_unit_id,
				walk_days 					=	in_walk_days,
				walk_distance 				=	in_walk_distance,
				walk_distance_unit_id		=	in_walk_distance_unit_id
			WHERE app_sid = v_app_sid
			AND company_sid = v_company_sid
			AND ec_questionnaire_answers_id = in_ec_questionnaire_answers_id;
	END IF;
END;

PROCEDURE GetECQuestionnaireAnswers
(
    in_breakdown_id 				IN bt_emissions.breakdown_id%TYPE,
    in_region_id 					IN bt_emissions.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_cnt							NUMBER;
	v_holidays 						ec_region_factors.holidays%TYPE;
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	SELECT COUNT(*) INTO v_cnt
	  FROM ec_region_factors 
	 WHERE region_id = in_region_id;
	
	-- fall back to the Rest Of The World if the avg holidays for this region is not found
	IF v_cnt > 0 THEN
		SELECT holidays 
		  INTO v_holidays
		  FROM ec_region_factors 
		 WHERE region_id = in_region_id;
	ELSE
		SELECT holidays
		  INTO v_holidays
		  FROM ec_region_factors 
		 WHERE region_id = admin_pkg.ROW_COUNTRY_CODE_ID;	
	END IF;

	OPEN out_cur FOR
		SELECT 
			   ecqa.company_sid, ecqa.ec_questionnaire_id, 
			   ecqa.ec_questionnaire_answers_id, working_days_per_wk, NVL(vacation_days_per_yr, v_holidays) vacation_days_per_yr, 
			   NVL(other_leave_days_per_yr, 0) other_leave_days_per_yr, car_days, car_distance, 
			   car_distance_unit_id, ecqa.car_id, car_kg_co2_per_km, bus_days, 
			   bus_distance, bus_distance_unit_id, ecqa.bus_type_id, b.kg_co2_per_km_contribution bus_kg_co2_per_km,
			   train_days, train_distance, train_distance_unit_id, t.kg_co2_per_km_contribution train_kg_co2_per_km,
			   ecqa.train_type_id, ecqa.motorbike_days, motorbike_distance, 
			   motorbike_distance_unit_id, ecqa.motorbike_type_id, m.kg_co2_per_km_contribution motorbike_kg_co2_per_km, bike_days, 
			   bike_distance, bike_distance_unit_id, walk_days, 
			   walk_distance, walk_distance_unit_id
		  FROM ec_questionnaire_answers ecqa
		  JOIN ec_questionnaire ecq ON ecq.ec_questionnaire_id = ecqa.ec_questionnaire_id AND ecq.app_sid = ecqa.app_sid
		  LEFT JOIN (SELECT car_id, ecm.efficiency_ltr_per_km * ft.kg_co2_per_litre car_kg_co2_per_km FROM ec_car_model ecm JOIN ec_fuel_type ft ON ecm.fuel_type_id = ft.fuel_type_id) c ON ecqa.car_id = c.car_id
		  LEFT JOIN ec_bus_type b ON ecqa.bus_type_id = b.bus_type_id
		  LEFT JOIN ec_train_type t ON ecqa.train_type_id = t.train_type_id
		  LEFT JOIN ec_motorbike_type m ON ecqa.motorbike_type_id = m.motorbike_type_id
		 WHERE ecq.app_sid = security_pkg.getApp
		   AND ecqa.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		   AND breakdown_id = in_breakdown_id
		   AND region_id = in_region_id;
END;



PROCEDURE SetProfile(
	in_breakdown_group_id            IN ec_profile.breakdown_group_id%TYPE,
	in_annual_leave_days             IN ec_profile.annual_leave_days%TYPE,
	in_car_pct_use                   IN ec_profile.car_pct_use%TYPE,
	in_car_avg_dist                  IN ec_profile.car_avg_dist%TYPE,
	in_car_distance_unit_id          IN ec_profile.car_distance_unit_id%TYPE,
	in_bus_pct_use                   IN ec_profile.bus_pct_use%TYPE,
	in_bus_avg_dist                  IN ec_profile.bus_avg_dist%TYPE,
	in_bus_distance_unit_id          IN ec_profile.bus_distance_unit_id%TYPE,
	in_train_pct_use                 IN ec_profile.train_pct_use%TYPE,
	in_train_avg_dist                IN ec_profile.train_avg_dist%TYPE,
	in_train_distance_unit_id        IN ec_profile.train_distance_unit_id%TYPE,
	in_motorbike_pct_use             IN ec_profile.motorbike_pct_use%TYPE,
	in_motorbike_avg_dist            IN ec_profile.motorbike_avg_dist%TYPE,
	in_motorbike_distance_unit_id    IN ec_profile.motorbike_distance_unit_id%TYPE,
	in_bike_pct_use                  IN ec_profile.bike_pct_use%TYPE,
	in_bike_avg_dist                 IN ec_profile.bike_avg_dist%TYPE,
	in_bike_distance_unit_id         IN ec_profile.bike_distance_unit_id%TYPE,
	in_walk_pct_use                  IN ec_profile.walk_pct_use%TYPE,
	in_walk_avg_dist                 IN ec_profile.walk_avg_dist%TYPE,
	in_walk_distance_unit_id         IN ec_profile.walk_distance_unit_id%TYPE, 
	in_is_default					 IN NUMBER
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
		
	BEGIN
		INSERT INTO ec_profile (app_sid, company_sid, breakdown_group_id, annual_leave_days, car_pct_use, 
								car_avg_dist, car_distance_unit_id, bus_pct_use, bus_avg_dist, 
								bus_distance_unit_id, train_pct_use, train_avg_dist, train_distance_unit_id, 
								motorbike_pct_use, motorbike_avg_dist, motorbike_distance_unit_id, 
								bike_pct_use, bike_avg_dist, bike_distance_unit_id, walk_pct_use, 
								walk_avg_dist, walk_distance_unit_id, modified_by_sid, last_modified_dtm)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_group_id, 
					in_annual_leave_days, in_car_pct_use, in_car_avg_dist, in_car_distance_unit_id, 
					in_bus_pct_use, in_bus_avg_dist, in_bus_distance_unit_id, in_train_pct_use, 
					in_train_avg_dist, in_train_distance_unit_id, in_motorbike_pct_use, in_motorbike_avg_dist,
					in_motorbike_distance_unit_id, in_bike_pct_use, in_bike_avg_dist, in_bike_distance_unit_id,
					in_walk_pct_use, in_walk_avg_dist, in_walk_distance_unit_id, DECODE(in_is_default, 1, null, SYS_CONTEXT('SECURITY', 'SID')), DECODE(in_is_default, 1, null, SYSDATE)); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN		
			UPDATE ec_profile
			   SET annual_leave_days = in_annual_leave_days,
			       car_pct_use = in_car_pct_use,
			       car_avg_dist = in_car_avg_dist,
			       car_distance_unit_id = in_car_distance_unit_id,
			       bus_pct_use = in_bus_pct_use,
			       bus_avg_dist = in_bus_avg_dist,
			       bus_distance_unit_id = in_bus_distance_unit_id,
			       train_pct_use = in_train_pct_use,
			       train_avg_dist = in_train_avg_dist,
			       train_distance_unit_id = in_train_distance_unit_id,
			       motorbike_pct_use = in_motorbike_pct_use,
			       motorbike_avg_dist = in_motorbike_avg_dist,
			       motorbike_distance_unit_id = in_motorbike_distance_unit_id,
			       bike_pct_use = in_bike_pct_use,
			       bike_avg_dist = in_bike_avg_dist,
			       bike_distance_unit_id = in_bike_distance_unit_id,
			       walk_pct_use = in_walk_pct_use,
			       walk_avg_dist = in_walk_avg_dist,
			       walk_distance_unit_id = in_walk_distance_unit_id,
				   modified_by_sid = DECODE(in_is_default, 1, null, SYS_CONTEXT('SECURITY', 'SID')), -- don't set for default profile
				   last_modified_dtm = DECODE(in_is_default, 1, null, SYSDATE) -- don't set for default profile
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND breakdown_group_id = in_breakdown_group_id;	
	END;
END;

PROCEDURE SetBusBreakdown(
	in_breakdown_group_id			IN  ec_bus_entry.breakdown_group_id%TYPE,
	in_bus_type_id					IN  ec_bus_entry.bus_type_id%TYPE,
	in_percentage					IN  ec_bus_entry.pct%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	BEGIN
		INSERT INTO ec_bus_entry (app_sid, company_sid, breakdown_group_id, bus_type_id, pct)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_group_id, in_bus_type_id, in_percentage); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_bus_entry
			   SET pct = in_percentage
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND breakdown_group_id = in_breakdown_group_id
			   AND bus_type_id = in_bus_type_id;	
	END;
END;

PROCEDURE SetCarBreakdown(
	in_breakdown_group_id			IN  ec_car_entry.breakdown_group_id%TYPE,
	in_car_type_id					IN  ec_car_entry.car_type_id%TYPE,
	in_percentage					IN  ec_car_entry.pct%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	BEGIN
		INSERT INTO ec_car_entry (app_sid, company_sid, breakdown_group_id, car_type_id, pct)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_group_id, in_car_type_id, in_percentage); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_car_entry
			   SET pct = in_percentage
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND breakdown_group_id = in_breakdown_group_id
			   AND car_type_id = in_car_type_id;	
	END;
END;

PROCEDURE SetMotorbikeBreakdown(
	in_breakdown_group_id			IN  ec_motorbike_entry.breakdown_group_id%TYPE,
	in_motorbike_type_id			IN  ec_motorbike_entry.motorbike_type_id%TYPE,
	in_percentage					IN  ec_motorbike_entry.pct%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	BEGIN
		INSERT INTO ec_motorbike_entry (app_sid, company_sid, breakdown_group_id, motorbike_type_id, pct)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_group_id, in_motorbike_type_id, in_percentage); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_motorbike_entry
			   SET pct = in_percentage
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND breakdown_group_id = in_breakdown_group_id
			   AND motorbike_type_id = in_motorbike_type_id;	
	END;
END;

PROCEDURE SetTrainBreakdown(
	in_breakdown_group_id			IN  ec_train_entry.breakdown_group_id%TYPE,
	in_train_type_id				IN  ec_train_entry.train_type_id%TYPE,
	in_percentage					IN  ec_train_entry.pct%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	BEGIN
		INSERT INTO ec_train_entry (app_sid, company_sid, breakdown_group_id, train_type_id, pct)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_breakdown_group_id, in_train_type_id, in_percentage); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_train_entry
			   SET pct = in_percentage
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			   AND breakdown_group_id = in_breakdown_group_id
			   AND train_type_id = in_train_type_id;	
	END;
END;

PROCEDURE SetOptions(
	in_annual_leave_days			IN  ec_options.annual_leave_days%TYPE,
	in_breakdown_type_id			IN  ec_options.breakdown_type_id%TYPE,
	in_extrapolate					IN  ec_options.extrapolate%TYPE,
	in_extrapolation_pct			IN  ec_options.extrapolation_pct%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.ADMIN_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	BEGIN
		INSERT INTO ec_options (app_sid, company_sid, annual_leave_days, breakdown_type_id)
		     VALUES (security_pkg.getApp, SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), in_annual_leave_days, in_breakdown_type_id); 
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_options
			   SET annual_leave_days = in_annual_leave_days,
			       breakdown_type_id = in_breakdown_type_id,
			       extrapolate = in_extrapolate,
			       extrapolation_pct = in_extrapolation_pct
			 WHERE app_sid = security_pkg.getApp
			   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');	
	END;
END;

PROCEDURE DeleteQuestionnaire(
	in_ec_questionnaire_id			IN  ec_questionnaire.ec_questionnaire_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	-- DELETE CHILD RECORDS
	DeleteQuestionnaireAnswers(in_ec_questionnaire_id);
	
	-- DELETE RECORD
	DELETE FROM ec_questionnaire
	      WHERE app_sid = security_pkg.getApp
		    AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND ec_questionnaire_id = in_ec_questionnaire_id;			
END;

PROCEDURE DeleteQuestionnaireAnswers(
	in_ec_questionnaire_id			IN  ec_questionnaire.ec_questionnaire_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DELETE FROM ec_questionnaire_answers
	      WHERE app_sid = security_pkg.getApp
		    AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND ec_questionnaire_id = in_ec_questionnaire_id;			
END;

PROCEDURE DeleteProfile(
	in_breakdown_group_id			IN  ec_profile.breakdown_group_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DeleteBusBreakdowns(in_breakdown_group_id);
	DeleteCarBreakdowns(in_breakdown_group_id);
	DeleteMotorbikeBreakdowns(in_breakdown_group_id);
	DeleteTrainBreakdowns(in_breakdown_group_id);
	
	DELETE FROM ec_profile
	      WHERE app_sid = security_pkg.getApp
	        AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE DeleteBusBreakdowns(
	in_breakdown_group_id			IN  ec_bus_entry.breakdown_group_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DELETE FROM ec_bus_entry
	      WHERE app_sid = security_pkg.getApp
	        AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
		    AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE DeleteCarBreakdowns(
	in_breakdown_group_id			IN  ec_car_entry.breakdown_group_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DELETE FROM ec_car_entry
	      WHERE app_sid = security_pkg.getApp
	        AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE DeleteMotorbikeBreakdowns(
	in_breakdown_group_id			IN  ec_motorbike_entry.breakdown_group_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DELETE FROM ec_motorbike_entry
	      WHERE app_sid = security_pkg.getApp
	        AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE DeleteTrainBreakdowns(
	in_breakdown_group_id			IN  ec_train_entry.breakdown_group_id%TYPE
)
AS
BEGIN
	IF NOT csr.csr_data_pkg.CheckCapability(ct_pkg.EDIT_EMPLOYEE_COMMUTING) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DELETE FROM ec_train_entry
	      WHERE app_sid = security_pkg.getApp
	        AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
			AND breakdown_group_id = in_breakdown_group_id;
END;

PROCEDURE SaveResult(
    in_breakdown_id 				IN ec_emissions_all.breakdown_id%TYPE,
    in_region_id 					IN ec_emissions_all.region_id%TYPE,
	in_calculation_source_id		IN ec_calculation_source.calculation_source_id%TYPE,
	in_contribution_source_id		IN ec_calculation_source.calculation_source_id%TYPE,
    in_car_kg_co2 					IN ec_emissions_all.car_kg_co2%TYPE,
    in_bus_kg_co2 					IN ec_emissions_all.bus_kg_co2%TYPE,
    in_train_kg_co2 				IN ec_emissions_all.train_kg_co2%TYPE,
    in_motorbike_kg_co2				IN ec_emissions_all.motorbike_kg_co2%TYPE,
    in_bike_kg_co2 					IN ec_emissions_all.bike_kg_co2%TYPE,
    in_walk_kg_co2 					IN ec_emissions_all.walk_kg_co2%TYPE
)
AS
BEGIN

	-- used in hotspotter - so this isn't a mistake
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing hotspot results data');
	END IF;

	BEGIN
		INSERT INTO ec_emissions_all
		(
			breakdown_id,
			region_id,
			calculation_source_id,
			contribution_source_id,
			car_kg_co2,
			bus_kg_co2,
			train_kg_co2,
			motorbike_kg_co2,
			bike_kg_co2,
			walk_kg_co2
		)
		VALUES
		(
			in_breakdown_id,
			in_region_id,
			in_calculation_source_id,
			in_contribution_source_id,
			in_car_kg_co2,
			in_bus_kg_co2,
			in_train_kg_co2,
			in_motorbike_kg_co2,
			in_bike_kg_co2,
			in_walk_kg_co2
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ec_emissions_all
			SET    
				   car_kg_co2             = in_car_kg_co2,
				   bus_kg_co2             = in_bus_kg_co2,
				   train_kg_co2           = in_train_kg_co2,
				   motorbike_kg_co2       = in_motorbike_kg_co2,
				   bike_kg_co2            = in_bike_kg_co2,
				   walk_kg_co2            = in_walk_kg_co2
			WHERE  app_sid                = security_pkg.getApp
			AND    breakdown_id           = in_breakdown_id
			AND    region_id              = in_region_id
			AND    calculation_source_id  = in_calculation_source_id
			AND    contribution_source_id = in_contribution_source_id;
	END;

END;

PROCEDURE ClearEmissionResults(
	in_calculation_source_id	IN ec_calculation_source.calculation_source_id%TYPE
)
AS
BEGIN

	-- used in hotspotter - so this isn't a mistake
	IF NOT chain.capability_pkg.CheckCapability(SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'), chain.chain_pkg.CT_HOTSPOTTER, security.security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied - you do not have permission to modify employee commuting data');
	END IF;
	
	DELETE FROM ec_emissions_all 
	 WHERE calculation_source_id = in_calculation_source_id 
	   AND app_sid = security_pkg.getApp;
	   
END;

END  emp_commute_pkg;
/
