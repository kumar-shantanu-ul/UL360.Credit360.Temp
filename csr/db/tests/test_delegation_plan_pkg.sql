CREATE OR REPLACE PACKAGE csr.test_delegation_plan_pkg AS

-- The tests
-- Region Tree
-- v_regs(1) DELEG_PLAN_REGION_1 N
-- ----v_regs(2) DELEG_PLAN_REGION_1_1 P
-- --------v_regs(3) DELEG_PLAN_REGION_1_1_1 N
-- ----v_regs(4) DELEG_PLAN_REGION_1_2 P TAGGED
-- ----v_regs(5) DELEG_PLAN_REGION_1_3 N
-- --------v_regs(6) DELEG_PLAN_REGION_1_3_1 T TAGGED
-- ------------v_regs(7) DELEG_PLAN_REGION_1_3_1_1 T
-- ------------v_regs(8) DELEG_PLAN_REGION_1_3_1_2 P
-- v_regs(9) DELEG_PLAN_REGION_2 N

-- Tests
PROCEDURE CreateBasicDelegPlan;
PROCEDURE ApplyDelegationPlanStatic;

/* 
	Region selection:

	Below options create a delegation with all regions;

	CSR_DATA_PKG.DELEG_PLAN_SEL_S_REGION		R = select the specified region
	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWEST_RT		L = select leaf nodes of specified region type (or any)
	CSR_DATA_PKG.DELEG_PLAN_SEL_S_LOWER_RT		P = select nodes of specified region type (or any)

	Below options create an individual delegation per each region:

	CSR_DATA_PKG.DELEG_PLAN_SEL_M_REGION		RT = select the specified region
	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWEST_RT		LT = select leaf nodes of specified region type (or any)
	CSR_DATA_PKG.DELEG_PLAN_SEL_M_LOWER_RT		PT = select nodes of specified region type (or any)
*/
-- Rollout behaviours
-- Apply plan to single region
PROCEDURE ApplyDelegationPlan;
-- Multi form, this, any region type, without Tag
PROCEDURE MultiThisRTAnyWithoutTag;
-- Multi form, lower, any region type, without Tag
PROCEDURE MultiLowerRTAnyWithoutTag;
-- Multi form, lowest, any region type, without Tag
PROCEDURE MultiLowestRTAnyWithoutTag;
-- Multi form, this, specific region type, without Tag
PROCEDURE MultiThisRTTenantWithoutTag;
-- Multi form, lower, specific region type, without Tag
PROCEDURE MultiLowerRTTenantWithoutTag;
-- Multi form, lowest, specific region type, without Tag
PROCEDURE MultiLowestRTTenantWithoutTag;
-- Multi form, this, any region type, with Tag
PROCEDURE MultiThisRTAnyWithTag;
-- Multi form, lower, any region type, with Tag
PROCEDURE MultiLowerRTAnyWithTag;
-- Multi form, lowest, any region type, with Tag
PROCEDURE MultiLowestRTAnyWithTag;
-- Multi form, this, specific region type, with Tag
PROCEDURE MultiThisRTTenantWithTag;
-- Multi form, lower, specific region type, with Tag
PROCEDURE MultiLowerRTTenantWithTag;
-- Multi form, lowest, specific region type, with Tag
PROCEDURE MultiLowestRTTenantWithTag;
-- Single form, this, any region type, without Tag
PROCEDURE SingleThisRTAnyWithoutTag;
-- Single form, lower, any region type, without Tag
PROCEDURE SingleLowerRTAnyWithoutTag;
-- Single form, lowest, any region type, without Tag
PROCEDURE SingleLowestRTAnyWithoutTag;
-- Single form, this, specific region type, without Tag
PROCEDURE SingleThisRTTenantWithoutTag;
-- Single form, lower, specific region type, without Tag
PROCEDURE SingleLowerRTTenantWithoutTag;
-- Single form, lowest, specific region type, without Tag
PROCEDURE SingleLowestRTTenantWithoutTag;
-- Single form, this, any region type, with Tag
PROCEDURE SingleThisRTAnyWithTag;
-- Single form, lower, any region type, with Tag
PROCEDURE SingleLowerRTAnyWithTag;
-- Single form, lowest, any region type, with Tag
PROCEDURE SingleLowestRTAnyWithTag;
-- Single form, this, specific region type, with Tag
PROCEDURE SingleThisRTTenantWithTag;
-- Single form, lower, specific region type, with Tag
PROCEDURE SingleLowerRTTenantWithTag;
-- Single form, lowest, specific region type, with Tag
PROCEDURE SingleLowestRTTenantWithTag;
-- end rollout behaviours
-- Change rollouts
PROCEDURE LowestToLowerAny;
PROCEDURE LowerToLowestAny;
PROCEDURE LowestToLowerRT;
PROCEDURE LowerToLowestRT;
PROCEDURE LowestToLowerTag;
PROCEDURE LowerToLowestTag;
-- Date and periods tests
PROCEDURE CreateDelegPlanWithRecDates;
PROCEDURE CreateDelegPlanWithFixDates(
	in_start_dtm					IN DATE DEFAULT DATE '2018-01-01',
	in_end_dtm						IN DATE DEFAULT DATE '2019-01-01',
	in_period_set_id				IN NUMBER DEFAULT 1,
	in_period_interval_id			IN NUMBER DEFAULT 4
);
PROCEDURE CreateDelegPlanForCustomPeriod;
PROCEDURE CreateDPForCPComplex;
PROCEDURE ApplyDelegRecDatesPerTemplate;
PROCEDURE ApplyDelegFixDatesPerRole;
PROCEDURE ReApplyDelegationPlan;

-- Template delegation tests
PROCEDURE AddDelegTemplateToDelegPlan;
PROCEDURE RemoveTemplateFromPlanNoData;
PROCEDURE RemoveTemplFromPlanWithData_;
PROCEDURE HideTemplateFromPlan;

-- Overlap tests
PROCEDURE ApplyDelegIndicatorWithOverlap;
PROCEDURE ApplyDelegRegionWithOverlap;
PROCEDURE ApplyDelegRegionWithOverlapRemovesOverlapWhenRelinked;

-- Region Tests
PROCEDURE AddRegionToDelegPlan;
PROCEDURE DeselectRegionFromDelPlan;
PROCEDURE DeselectRegWithDataFromDelPlan;
PROCEDURE RemoveRegionFromDelegPlan;
PROCEDURE RemoveRegWithDataFromDelPlan;
PROCEDURE ChangeRegionTagWithDynamicPlanSingleLowerTagged;
PROCEDURE ChangeRegionTagWithDynamicPlanSingleLowestTagged;
PROCEDURE ChangeRegionTagWithStaticPlanSingleLowestTagged;
PROCEDURE ChangeRegionTagWithDynamicPlanMultiLowerTagged;
PROCEDURE ChangeRegionTagWithDynamicPlanMultiLowestTagged;
PROCEDURE ChangeRegionTagWithStaticPlanMultiLowestTagged;
PROCEDURE ChangeRegionTypeWithDynamicPlanSingleLower;
PROCEDURE ChangeRegionTypeWithDynamicPlanSingleLowest;
PROCEDURE ChangeRegionTypeWithStaticPlanSingleLowest;
PROCEDURE ChangeRegionTypeWithDynamicPlanMultiLower;
PROCEDURE ChangeRegionTypeWithDynamicPlanMultiLowest;
PROCEDURE ChangeRegionTypeWithStaticPlanMultiLowest;
PROCEDURE AddLowestRegionToMultiLowestRTAnyWithoutTag;
PROCEDURE AddLowerRegionToMultiLowerRTAnyWithoutTag;
PROCEDURE MovingARegionOutRemovesRegionFromPlan;
PROCEDURE MovingARegionOutMarksForDeletionForAppliedPlans;
PROCEDURE MovingARegionBackInUnMarksForDeletionForAppliedPlans;
PROCEDURE MovingARegionBackDoeNotUnMarkUnrelatedRegionsForDeletionForAppliedPlans;
PROCEDURE MovingARegionUnderAMarkedRegionMarksForDeletionForAppliedPlans;
PROCEDURE ChangingTypeRelinksExistingDelegations;

-- Delete Plans
PROCEDURE RemoveDelegPlanWithNoData;
PROCEDURE RemoveDelegPlanWithData;
PROCEDURE RemoveDelegPlanWithoutDelegs;

-- Role tests
PROCEDURE AddRoleToDelegPlan;
PROCEDURE RemoveRoleFromDelegPlan;
PROCEDURE RemoveRoleFromPlanWithData;

-- Plan status export tests
PROCEDURE GetPlanStatusForDelegationWithSpecifiedRegionsHasCorrectSheets;
PROCEDURE GetPlanStatusForDelegationPlanWithOneDelegationPerRegionHasCorrectSheets;
PROCEDURE GetPlanStatusForDelegationPlanWithMultipleRegionsOnOneDelegationHasCorrectSheets;

PROCEDURE UpdateDelegPlanColRegionThrowsIfGivenNegativeOne;
PROCEDURE RTAnyWithoutTagDoesNotIncorrectlyDeleteDelegations;

-- Plan list tests
PROCEDURE GetActiveDelegPlansReturnsNothingWhenNoActivePlansExist;
PROCEDURE GetActiveDelegPlansReturnsActivePlanWhenPlansExist;
PROCEDURE GetHiddenDelegPlansReturnsNothingWhenNoInactivePlansExist;
PROCEDURE GetHiddenDelegPlansReturnsInactivePlanWhenPlansExist;

-- Template tests
PROCEDURE SetAsTemplate_False_FailsIfAnyVisibleDelegPlanReference;
PROCEDURE SetAsTemplate_False_SucceedsIfAllDelegPlanReferencesHidden; 

-- Dedupe tests
PROCEDURE SelectingAParentRegionWillMarkAllChildSelectionsForDeletion;
PROCEDURE ChangingSingleDelegationLevelDoesNotCreateDuplicateRegions;
PROCEDURE SelectingAChildRegionWillErrorIfParentSelected;
PROCEDURE PlanDoesNotRelinkDelegForSelfWhenRolloutChangedToChildren;

PROCEDURE ApplyPlanCreatesSheetCreatedAlerts;

-- Called before each test
PROCEDURE SetUp;
-- Called after each PASSED test
PROCEDURE TearDown;
-- Called once before starting a test fixture
PROCEDURE SetUpFixture(in_site_name VARCHAR2);
-- Called once after all tests have PASSED
PROCEDURE TearDownFixture;

END;
/