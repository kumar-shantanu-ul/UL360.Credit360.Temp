CREATE OR REPLACE PACKAGE ct.emp_commute_pkg AS

PROCEDURE GetRegionFactors(
    in_region_id            		IN ec_region_factors.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR 
);

PROCEDURE GetQuestionnaires
(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetQuestionnaireByGuid
(
	in_guid							IN  ec_questionnaire.guid%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCarTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBusTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTrainTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMotorbikeTypes(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCarTypeEmissFact(
    in_car_type_id                	IN ec_car_type.car_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetBusTypeEmissFact(
    in_bus_type_id                	IN ec_bus_type.bus_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetTrainTypeEmissFact(
    in_train_type_id                IN ec_train_type.train_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetMotorbikeTypeEmissFact(
    in_motorbike_type_id            IN ec_motorbike_type.motorbike_type_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetECProfile(
	in_breakdown_group_id			IN  ct.ec_profile.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCarModelsForManufacturer(
	in_car_id						IN  ct.ec_car_model.car_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);
PROCEDURE GetCarBreakdowns(
	in_breakdown_group_id			IN  ct.ec_car_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetBusBreakdowns(
	in_breakdown_group_id			IN  ct.ec_bus_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMotorbikeBreakdowns(
	in_breakdown_group_id			IN  ct.ec_motorbike_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTrainBreakdowns(
	in_breakdown_group_id			IN  ct.ec_train_entry.breakdown_group_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetCarManufacturers(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDistanceUom(
	in_distance_unit_id				IN  distance_unit.distance_unit_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetDistanceUoms(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetVolumeUom(
	in_volume_unit_id				IN  volume_unit.volume_unit_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetVolumeUoms(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTimeUom(
	in_time_unit_id				IN  time_unit.time_unit_id%TYPE,
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTimeUoms(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetOptions(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResults(
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetResult(
	in_breakdown_group_id			IN  ct.ec_profile.breakdown_group_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetQuestionnaire
(
	in_breakdown_id					IN  ec_questionnaire.breakdown_id%TYPE,
	in_region_id					IN  ec_questionnaire.region_id%TYPE
);

PROCEDURE SetQuestionnaire
(
	in_ec_questionnaire_id			IN  ec_questionnaire.ec_questionnaire_id%TYPE,
	in_breakdown_id					IN  ec_questionnaire.breakdown_id%TYPE,
	in_region_id					IN  ec_questionnaire.region_id%TYPE
);

PROCEDURE SetECQuestionnaireAnswer
(
	in_ec_questionnaire_id			IN ec_questionnaire_answers.ec_questionnaire_id%TYPE,
	in_ec_questionnaire_answers_id	IN ec_questionnaire_answers.ec_questionnaire_answers_id%TYPE,
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
);

PROCEDURE GetECQuestionnaireAnswers
(
    in_breakdown_id 				IN bt_emissions.breakdown_id%TYPE,
    in_region_id 					IN bt_emissions.region_id%TYPE,
	out_cur							OUT security_pkg.T_OUTPUT_CUR
);


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
	in_is_default					IN 	NUMBER
);

PROCEDURE SetBusBreakdown(
	in_breakdown_group_id			IN  ec_bus_entry.breakdown_group_id%TYPE,
	in_bus_type_id					IN  ec_bus_entry.bus_type_id%TYPE,
	in_percentage					IN  ec_bus_entry.pct%TYPE
);

PROCEDURE SetCarBreakdown(
	in_breakdown_group_id			IN  ec_car_entry.breakdown_group_id%TYPE,
	in_car_type_id					IN  ec_car_entry.car_type_id%TYPE,
	in_percentage					IN  ec_car_entry.pct%TYPE
);

PROCEDURE SetMotorbikeBreakdown(
	in_breakdown_group_id			IN  ec_motorbike_entry.breakdown_group_id%TYPE,
	in_motorbike_type_id			IN  ec_motorbike_entry.motorbike_type_id%TYPE,
	in_percentage					IN  ec_motorbike_entry.pct%TYPE
);

PROCEDURE SetTrainBreakdown(
	in_breakdown_group_id			IN  ec_train_entry.breakdown_group_id%TYPE,
	in_train_type_id				IN  ec_train_entry.train_type_id%TYPE,
	in_percentage					IN  ec_train_entry.pct%TYPE
);

PROCEDURE SetOptions(
	in_annual_leave_days			IN  ec_options.annual_leave_days%TYPE,
	in_breakdown_type_id			IN  ec_options.breakdown_type_id%TYPE,
	in_extrapolate		IN  ec_options.extrapolate%TYPE,
	in_extrapolation_pct			IN  ec_options.extrapolation_pct%TYPE
);

PROCEDURE DeleteProfile(
	in_breakdown_group_id			IN  ec_profile.breakdown_group_id%TYPE
);

PROCEDURE DeleteBusBreakdowns(
	in_breakdown_group_id			IN  ec_bus_entry.breakdown_group_id%TYPE
);

PROCEDURE DeleteCarBreakdowns(
	in_breakdown_group_id			IN  ec_car_entry.breakdown_group_id%TYPE
);

PROCEDURE DeleteMotorbikeBreakdowns(
	in_breakdown_group_id			IN  ec_motorbike_entry.breakdown_group_id%TYPE
);

PROCEDURE DeleteTrainBreakdowns(
	in_breakdown_group_id			IN  ec_train_entry.breakdown_group_id%TYPE
);

PROCEDURE DeleteQuestionnaire(
	in_ec_questionnaire_id			IN  ec_questionnaire.ec_questionnaire_id%TYPE
);

PROCEDURE DeleteQuestionnaireAnswers(
	in_ec_questionnaire_id			IN  ec_questionnaire.ec_questionnaire_id%TYPE
);

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
);

PROCEDURE ClearEmissionResults(
	in_calculation_source_id		IN ec_calculation_source.calculation_source_id%TYPE
);

END emp_commute_pkg;
/
