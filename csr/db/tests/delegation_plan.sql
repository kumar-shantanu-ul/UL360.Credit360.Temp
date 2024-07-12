SET serveroutput ON
SET echo OFF

@@test_delegation_plan_pkg
@@test_delegation_plan_body

BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'DROP TABLE csr.temp_deleg_test_schedule_entry';
	EXCEPTION
		WHEN OTHERS THEN
		  NULL;
	END;

	EXECUTE IMMEDIATE 'CREATE GLOBAL TEMPORARY TABLE csr.temp_deleg_test_schedule_entry(
								role_sid			NUMBER(10),
								deleg_plan_col_id	NUMBER(10),
								start_dtm 			DATE,
								creation_dtm		DATE,
								submission_dtm		DATE,
								reminder_dtm		DATE
							) ON COMMIT DELETE ROWS';
							
	csr.unit_test_pkg.RunTests('csr.test_delegation_plan_pkg', csr.unit_test_pkg.T_TESTS(
		'CreateBasicDelegPlan',
		'ApplyDelegationPlanStatic',
		'ApplyDelegationPlan',
		'MultiThisRTAnyWithoutTag',
		'MultiLowerRTAnyWithoutTag',
		'MultiLowestRTAnyWithoutTag',
		'MultiThisRTTenantWithoutTag',
		'MultiLowerRTTenantWithoutTag',
		'MultiLowestRTTenantWithoutTag',
		'MultiThisRTAnyWithTag',
		'MultiLowerRTAnyWithTag',
		'MultiLowestRTAnyWithTag',
		'MultiThisRTTenantWithTag',
		'MultiLowerRTTenantWithTag',
		'MultiLowestRTTenantWithTag',
		'SingleThisRTAnyWithoutTag',
		'SingleLowerRTAnyWithoutTag',
		'SingleLowestRTAnyWithoutTag',
		'SingleThisRTTenantWithoutTag',
		'SingleLowerRTTenantWithoutTag',
		'SingleLowestRTTenantWithoutTag',
		'SingleThisRTAnyWithTag',
		'SingleLowerRTAnyWithTag',
		'SingleLowestRTAnyWithTag',
		'SingleThisRTTenantWithTag',
		'SingleLowerRTTenantWithTag',
		'SingleLowestRTTenantWithTag',
		'LowestToLowerAny',
		'LowerToLowestAny',
		'LowestToLowerRT',
		'LowerToLowestRT',
		'LowestToLowerTag',
		'LowerToLowestTag',
		'CreateDelegPlanWithRecDates',
		'CreateDelegPlanWithFixDates',
		'CreateDelegPlanForCustomPeriod',
		'CreateDPForCPComplex',
		'ApplyDelegRecDatesPerTemplate',
		'ApplyDelegFixDatesPerRole',
		'ReApplyDelegationPlan',
		'AddDelegTemplateToDelegPlan',
		'RemoveTemplateFromPlanNoData',
		'RemoveTemplFromPlanWithData_',
		'HideTemplateFromPlan',
		'ApplyDelegIndicatorWithOverlap',
		'ApplyDelegRegionWithOverlap',
		'ApplyDelegRegionWithOverlapRemovesOverlapWhenRelinked',
		'AddRegionToDelegPlan',
		'DeselectRegionFromDelPlan',
		'DeselectRegWithDataFromDelPlan',
		'RemoveRegionFromDelegPlan',
		'RemoveRegWithDataFromDelPlan',
		'ChangeRegionTagWithDynamicPlanSingleLowerTagged',
		'ChangeRegionTagWithDynamicPlanSingleLowestTagged',
		'ChangeRegionTagWithStaticPlanSingleLowestTagged',
		'ChangeRegionTagWithDynamicPlanMultiLowerTagged',
		'ChangeRegionTagWithDynamicPlanMultiLowestTagged',
		'ChangeRegionTagWithStaticPlanMultiLowestTagged',
		'ChangeRegionTypeWithDynamicPlanSingleLower',
		'ChangeRegionTypeWithDynamicPlanSingleLowest',
		'ChangeRegionTypeWithStaticPlanSingleLowest',
		'ChangeRegionTypeWithDynamicPlanMultiLower',
		'ChangeRegionTypeWithDynamicPlanMultiLowest',
		'ChangeRegionTypeWithStaticPlanMultiLowest',
		'AddLowestRegionToMultiLowestRTAnyWithoutTag',
		'AddLowerRegionToMultiLowerRTAnyWithoutTag',
		'RemoveDelegPlanWithNoData',
		'RemoveDelegPlanWithData',
		'RemoveDelegPlanWithoutDelegs',
		'AddRoleToDelegPlan',
		'RemoveRoleFromDelegPlan',
		'RemoveRoleFromPlanWithData',
		'GetPlanStatusForDelegationWithSpecifiedRegionsHasCorrectSheets',
		'GetPlanStatusForDelegationPlanWithOneDelegationPerRegionHasCorrectSheets',
		'GetPlanStatusForDelegationPlanWithMultipleRegionsOnOneDelegationHasCorrectSheets',
		'RTAnyWithoutTagDoesNotIncorrectlyDeleteDelegations',
		'GetActiveDelegPlansReturnsNothingWhenNoActivePlansExist',
		'GetActiveDelegPlansReturnsActivePlanWhenPlansExist',
		'GetHiddenDelegPlansReturnsNothingWhenNoInactivePlansExist',
		'GetHiddenDelegPlansReturnsInactivePlanWhenPlansExist',
		'SetAsTemplate_False_FailsIfAnyVisibleDelegPlanReference',
		'SetAsTemplate_False_SucceedsIfAllDelegPlanReferencesHidden',
		'MovingARegionOutRemovesRegionFromPlan',
		'MovingARegionOutMarksForDeletionForAppliedPlans',
		'MovingARegionBackInUnMarksForDeletionForAppliedPlans',
		'MovingARegionBackDoeNotUnMarkUnrelatedRegionsForDeletionForAppliedPlans',
		'MovingARegionUnderAMarkedRegionMarksForDeletionForAppliedPlans',
		'SelectingAParentRegionWillMarkAllChildSelectionsForDeletion',
		'ChangingSingleDelegationLevelDoesNotCreateDuplicateRegions',
		'SelectingAChildRegionWillErrorIfParentSelected',
		'ChangingTypeRelinksExistingDelegations',
		'PlanDoesNotRelinkDelegForSelfWhenRolloutChangedToChildren',
		'ApplyPlanCreatesSheetCreatedAlerts'
	), :bv_site_name);	
	
	EXECUTE IMMEDIATE 'DROP TABLE csr.temp_deleg_test_schedule_entry';
END;
/

DROP PACKAGE csr.test_delegation_plan_pkg;

SET echo ON
