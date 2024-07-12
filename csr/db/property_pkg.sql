CREATE OR REPLACE PACKAGE CSR.property_pkg IS

ERR_PM_BUILDING_ID				CONSTANT NUMBER := -20850;
PM_BUILDING_ID					EXCEPTION;
PRAGMA EXCEPTION_INIT(PM_BUILDING_ID, -20850);

ERR_ENERGY_STAR_COMPATIBILITY	CONSTANT NUMBER := -20851;
ENERGY_STAR_COMPATIBILITY		EXCEPTION;
PRAGMA EXCEPTION_INIT(ENERGY_STAR_COMPATIBILITY, -20851);

PROCEDURE INTERNAL_CallHelperPkg(
	in_procedure_name	IN	VARCHAR2,
	in_region_sid		IN	security_pkg.T_SID_Id
);

PROCEDURE GetFundProperties(
	in_fund_id				IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE CheckRolesForRegions(
	in_state				IN	property.state%TYPE DEFAULT NULL,	 
	in_country_code			IN  region.geo_country%TYPE,
	out_has_roles			OUT number
);

PROCEDURE CheckPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN	property.pm_building_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN  property.pm_building_id%TYPE
);

PROCEDURE SetPmBuildingId(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_pm_building_id	IN	property.pm_building_id%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetTagIds(
	in_region_sid   	IN  security_pkg.T_SID_ID,
	in_tag_group_id		IN  security_pkg.T_SID_ID,
	in_tag_ids		    IN  security_pkg.T_SID_IDS
);

PROCEDURE GetMeter(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetSpace(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetTransitions(
	in_region_sid		IN  security_pkg.T_SID_ID,
	out_cur 			OUT SYS_REFCURSOR
);

PROCEDURE GetPropertyTypes(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types 		OUT  SYS_REFCURSOR
);

PROCEDURE GetPropertyTypesMapSpaceTypes(
	out_property_types 		OUT  SYS_REFCURSOR,
	out_spaces_cur 			OUT  SYS_REFCURSOR
);

-- support for old pages, will remove after release
PROCEDURE GetPropertyOptions(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types 		OUT  SYS_REFCURSOR,
	out_tag_groups 				OUT  SYS_REFCURSOR,
	out_tag_group_members		OUT  SYS_REFCURSOR,
	out_metrics 				OUT  SYS_REFCURSOR,
	out_mgmt_companies			OUT  SYS_REFCURSOR,
	out_mgmt_company_contacts	OUT  SYS_REFCURSOR,
	out_property_element_layout	OUT  SYS_REFCURSOR
);

PROCEDURE GetPropertyOptions(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types 		OUT  SYS_REFCURSOR,
	out_tag_groups 				OUT  SYS_REFCURSOR,
	out_tag_group_members		OUT  SYS_REFCURSOR,
	out_metrics 				OUT  SYS_REFCURSOR,
	out_mgmt_companies			OUT  SYS_REFCURSOR,
	out_mgmt_company_contacts	OUT  SYS_REFCURSOR,
	out_property_element_layout	OUT  SYS_REFCURSOR,
	out_property_addr_options	OUT  SYS_REFCURSOR
);

PROCEDURE GetPropertyOptions(
	out_property_types 			OUT  SYS_REFCURSOR,
	out_property_sub_types		OUT  SYS_REFCURSOR,
	out_tag_groups 				OUT  SYS_REFCURSOR,
	out_tag_group_members		OUT  SYS_REFCURSOR,
	out_metrics 				OUT  SYS_REFCURSOR,
	out_mgmt_companies			OUT  SYS_REFCURSOR,
	out_mgmt_company_contacts	OUT  SYS_REFCURSOR,
	out_property_element_layout	OUT  SYS_REFCURSOR,
	out_property_addr_options	OUT  SYS_REFCURSOR,
	out_space_types				OUT	 SYS_REFCURSOR,
	out_property_char_layout	OUT	 SYS_REFCURSOR,
	out_meter_element_layout	OUT	 SYS_REFCURSOR
);

FUNCTION UNSEC_GetSpaceSid(
    in_region_sid	IN	security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;
PRAGMA RESTRICT_REFERENCES(UNSEC_GetSpaceSid, WNDS, WNPS);

PROCEDURE GetSpaceTypesForProperty(
	in_region_sid				IN	security_pkg.T_SID_ID,
	out_space_types_cur		 	OUT SYS_REFCURSOR
);

PROCEDURE GetProperty(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetProperty(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR,	
	out_roles_cur			OUT	SYS_REFCURSOR,
	out_tags_cur			OUT	SYS_REFCURSOR,
	out_metric_values_cur	OUT	SYS_REFCURSOR
);

PROCEDURE GetProperty(
	in_region_sid			 	IN	security_pkg.T_SID_ID,
	out_prop_cur			 	OUT SYS_REFCURSOR,
	out_roles_cur			 	OUT SYS_REFCURSOR,
	out_space_types_cur		 	OUT SYS_REFCURSOR,
	out_spc_typ_rgn_mtrc_cur 	OUT SYS_REFCURSOR,
	out_metrics_cur	 		 	OUT SYS_REFCURSOR,
	out_spaces_cur			 	OUT SYS_REFCURSOR,
	out_meters_cur			 	OUT SYS_REFCURSOR,
	out_tag_groups_cur 			OUT SYS_REFCURSOR,
	out_tag_group_members_cur 	OUT SYS_REFCURSOR,
	out_tags_cur			 	OUT SYS_REFCURSOR,
	out_metric_values_cur	 	OUT SYS_REFCURSOR,
	out_transitions			 	OUT SYS_REFCURSOR,
	out_flow_state_log_cur		OUT SYS_REFCURSOR,
	out_photos_cur			OUT	SYS_REFCURSOR
);

PROCEDURE GetPropertyPhotos(
	in_region_sid					IN security_pkg.T_SID_ID,
	out_photos_cur					OUT SYS_REFCURSOR
);

PROCEDURE GetPropertySpaces(
	in_region_sid				IN  security_pkg.T_SID_ID,
	out_spaces_cur				OUT SYS_REFCURSOR
);

PROCEDURE GetFunds(
	in_region_sid			IN  security_pkg.T_SID_ID	DEFAULT NULL,
	out_funds_cur			OUT SYS_REFCURSOR,
	out_mgmt_contacts		OUT	SYS_REFCURSOR
);

PROCEDURE GetFundCompanies(
	out_fund_companies		OUT	SYS_REFCURSOR
);

PROCEDURE SaveFund(
	in_fund_id					IN	fund.fund_id%TYPE,
	in_company_sid				IN	fund.company_sid%TYPE,
	in_fund_name				IN	fund.name%TYPE,
	in_year_of_incep			IN	fund.year_of_inception%TYPE,
	in_fund_type_id				IN	fund.fund_type_id%TYPE,
	in_mgr_contact_name			IN	fund.mgr_contact_name%TYPE,
	in_mgr_contact_email		IN	fund.mgr_contact_email%TYPE,
	in_mgr_contact_phone		IN	fund.mgr_contact_phone%TYPE,
	in_default_mgmt_company_id	IN fund.default_mgmt_company_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteFund(
	in_fund_id	IN	fund.fund_id%TYPE
);

PROCEDURE AddFundMgmtContact(
	in_fund_id						IN	fund.fund_id%TYPE,
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE
);

PROCEDURE DeleteAllMgmtContacts(
	in_fund_id		IN	fund.fund_id%TYPE
);

FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER;

PROCEDURE GetFlowAlerts(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetMyProperties(
	in_just_inactive			IN 	 NUMBER DEFAULT 0,
	in_restrict_to_region_sid	IN   security_pkg.T_SID_ID,
	out_cur 					OUT  SYS_REFCURSOR,
	out_roles   				OUT  SYS_REFCURSOR
);

PROCEDURE GetMyProperties(
	in_just_inactive			IN 	 NUMBER DEFAULT 0,
	in_restrict_to_region_sid	IN   security_pkg.T_SID_ID,
	in_tag_ids		    IN  security_pkg.T_SID_IDS,
	out_cur 					OUT  SYS_REFCURSOR,
	out_roles   				OUT  SYS_REFCURSOR
);
PROCEDURE GetPropertyParentSid(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,	 
	in_country_code			IN  region.geo_country%TYPE,
	in_state				IN	property.state%TYPE DEFAULT NULL,	
	in_city					IN	property.city%TYPE DEFAULT NULL, 
	out_region_sid			OUT	security_pkg.T_SID_Id
);

PROCEDURE CreateProperty(
	in_company_sid			IN  security_pkg.T_SID_ID,
	in_parent_sid			IN  security_pkg.T_SID_ID  DEFAULT NULL,				
	in_description			IN	region_description.description%TYPE,	
	in_region_ref			IN	region.region_ref%TYPE DEFAULT NULL,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL, 
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL, 
	in_city					IN	property.city%TYPE DEFAULT NULL, 
	in_state				IN	property.state%TYPE DEFAULT NULL,	 
	in_country_code			IN  region.geo_country%TYPE,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_geo_longitude		IN  region.geo_longitude%TYPE DEFAULT NULL,	
	in_geo_latitude			IN  region.geo_latitude%TYPE DEFAULT NULL,
	in_acquisition_dtm		IN	region.acquisition_dtm%TYPE DEFAULT TRUNC(SYSDATE),
	out_region_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE SetProperty(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_description			IN	region_description.description%TYPE,	
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL, 
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL, 
	in_city					IN	property.city%TYPE DEFAULT NULL, 
	in_state				IN	property.state%TYPE DEFAULT NULL,	 
	in_country_code			IN  region.geo_country%TYPE,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_region_ref			IN  region.region_ref%TYPE DEFAULT NULL,
	in_acquisition_dtm		IN  region.acquisition_dtm%TYPE DEFAULT NULL
);

PROCEDURE SetPropertyAndLocation(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_description			IN	region_description.description%TYPE,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL,
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL,
	in_city					IN	property.city%TYPE DEFAULT NULL,
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_country_code			IN  region.geo_country%TYPE,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_region_ref			IN  region.region_ref%TYPE DEFAULT NULL,
	in_acquisition_dtm		IN  region.acquisition_dtm%TYPE DEFAULT NULL,
	in_latitude				IN	region.geo_latitude%TYPE DEFAULT NULL,
	in_longitude			IN	region.geo_longitude%TYPE DEFAULT NULL
);

PROCEDURE SetPropertyAddress (
	in_region_sid					IN	security_pkg.T_SID_ID,
	in_street_addr_1				IN	property.street_addr_2%TYPE	DEFAULT NULL, 
	in_street_addr_2				IN	property.street_addr_2%TYPE DEFAULT NULL, 
	in_city							IN	property.city%TYPE DEFAULT NULL, 
	in_state						IN	property.state%TYPE DEFAULT NULL,	 
	in_country_code					IN  region.geo_country%TYPE,
	in_postcode						IN	property.postcode%TYPE DEFAULT NULL,	
	in_latitude						IN	region.geo_latitude%TYPE,
	in_longitude					IN	region.geo_longitude%TYPE
);

/**
 *	Converts a region into a property.
 *
 *	@param	in_is_create			A non-zero value causes the region to be inserted into the property 
 *									workflow and create notifications to be sent to the appropriate helper 
 *									packages. This should be set if the property is being made out of a new 
 *									region, or a region that was not previously a property.
 */
PROCEDURE MakeProperty(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_company_sid			IN  security_pkg.T_SID_ID DEFAULT NULL,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_property_type_id		IN	property.property_type_id%TYPE DEFAULT NULL,
	in_property_sub_type_id	IN	property.property_sub_type_id%TYPE DEFAULT NULL,
	in_street_addr_1		IN	property.street_addr_2%TYPE	DEFAULT NULL, 
	in_street_addr_2		IN	property.street_addr_2%TYPE DEFAULT NULL, 
	in_city					IN	property.city%TYPE DEFAULT NULL, 
	in_state				IN	property.state%TYPE DEFAULT NULL,
	in_postcode				IN	property.postcode%TYPE DEFAULT NULL,
	in_is_create			IN	NUMBER
);

PROCEDURE UnmakeProperty(
	in_act_id			IN	security_pkg.T_ACT_ID,
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_region_type			IN	region.region_type%TYPE
);

PROCEDURE SetMgmtCompany(
	in_region_sid				IN	security_pkg.T_SID_ID,
	in_mgmt_company_id			IN  property.mgmt_company_id%TYPE,
	in_mgmt_company_other		IN  property.mgmt_company_other%TYPE DEFAULT NULL,
	in_mgmt_company_contact_id	IN  property.mgmt_company_contact_id%TYPE DEFAULT NULL
);

PROCEDURE SetFund(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_name			IN  fund.name%TYPE,
	out_fund_id		OUT fund.fund_id%TYPE
);

PROCEDURE SetFund(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_fund_id		IN  fund.fund_id%TYPE
);

PROCEDURE AddToFlow(
	in_region_sid				IN  security_pkg.T_SID_ID,
	out_flow_item_id			OUT	flow_item.flow_item_id%TYPE
);

PROCEDURE SetFlowState(
	in_region_sids 		IN 	security_pkg.T_SID_IDS,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE SetFlowState(
	in_region_sid 		IN 	security_pkg.T_SID_ID,
	in_flow_item_id		IN	flow_item.flow_item_id%TYPE,
	in_to_state_Id		IN	flow_state.flow_state_id%TYPE,
	in_comment_text		IN	flow_state_log.comment_text%TYPE,
	in_cache_keys		IN	security_pkg.T_VARCHAR2_ARRAY,	
	out_property 		OUT SYS_REFCURSOR, 
	out_transitions		OUT SYS_REFCURSOR
);

PROCEDURE GetPropertiesNeedingAttn(
	out_summary			OUT  SYS_REFCURSOR,
	out_properties 		OUT  SYS_REFCURSOR,
	out_findings		OUT  SYS_REFCURSOR
);

PROCEDURE Validate(
	in_region_sid 				IN   security_pkg.T_SID_ID,
	in_reporting_period_sid		IN   security_pkg.T_SID_ID,
	out_findings_cur			OUT  SYS_REFCURSOR,
	out_mandatory_spaces_cur	OUT  SYS_REFCURSOR,
	out_mandatory_build_cur		OUT  SYS_REFCURSOR
);

PROCEDURE GetPropertyTabs (
	out_cur					OUT SYS_REFCURSOR,
	out_restrict_to_types	OUT SYS_REFCURSOR
);

PROCEDURE SavePropertyTab (
	in_plugin_id					IN  property_tab.plugin_id%TYPE,
	in_tab_label					IN  property_tab.tab_label%TYPE,
	in_pos							IN  property_tab.pos%TYPE,
	in_restrict_to_prop_type_ids	IN	security_pkg.T_SID_IDS,
	out_cur							OUT security_pkg.T_OUTPUT_CUR,
	out_restrict_to_types			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemovePropertyTab(
	in_plugin_id					IN  property_tab.plugin_id%TYPE
);

PROCEDURE SaveTenant(
	in_tenant_id	IN	tenant.tenant_id%TYPE,
	in_tenant_name	IN	tenant.name%TYPE,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteTenant(
	in_tenant_id	IN	tenant.tenant_id%TYPE
);

PROCEDURE GetTenants(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetTenantByName(
	in_tenant_name			IN  tenant.name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveFundType(
	in_fund_type_id		IN	fund_type.fund_type_id%TYPE,
	in_fund_type_label	IN	fund_type.label%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteFundType(
	in_fund_type_id	IN	fund_type.fund_type_id%TYPE
);

PROCEDURE GetFundTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveManagementCompany(
	in_mgmt_company_id		IN	mgmt_company.mgmt_company_id%TYPE,
	in_mgmt_company_name	IN	mgmt_company.name%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteManagementCompany(
	in_mgmt_company_id	IN	mgmt_company.mgmt_company_id%TYPE
);

PROCEDURE GetManagementCompany(
	in_mgmt_company_id				IN	mgmt_company.mgmt_company_id%TYPE,
	out_mgmt_company_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_mgmt_company_contacts_cur	OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetManagementCompanies(
	out_mgmt_companies_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_mgmt_company_contacts_cur	OUT	security_pkg.T_OUTPUT_CUR
);

-- This will go away after the code is released
PROCEDURE SaveManagementCompanyContact(
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE,
	in_mgmt_company_contact_name	IN  mgmt_company_contact.name%TYPE,
	in_mgmt_company_contact_email	IN  mgmt_company_contact.email%TYPE,
	in_mgmt_company_contact_phone	IN  mgmt_company_contact.phone%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveManagementCompanyContact(
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE,
	in_mgmt_company_contact_name	IN  mgmt_company_contact.name%TYPE,
	in_mgmt_company_contact_email	IN  mgmt_company_contact.email%TYPE,
	in_mgmt_company_contact_phone	IN  mgmt_company_contact.phone%TYPE,
	in_skip_security_check			IN	number,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE DeleteManagementCompanyContact(
	in_mgmt_company_id				IN	mgmt_company_contact.mgmt_company_id%TYPE,
	in_mgmt_company_contact_id		IN	mgmt_company_contact.mgmt_company_contact_id%TYPE
);

PROCEDURE SaveSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_space_type_name	IN	space_type.label%TYPE,
	in_is_tenantable	IN	space_type.is_tenantable%TYPE,
	out_space_type_id	OUT	space_type.space_type_id%TYPE
);

PROCEDURE SaveSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE,
	in_space_type_name	IN	space_type.label%TYPE,
	in_is_tenantable	IN	space_type.is_tenantable%TYPE,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveSpaceType(
	in_space_type_id		IN	space_type.space_type_id%TYPE,
	in_space_type_name		IN	space_type.label%TYPE,
	in_is_tenantable		IN	space_type.is_tenantable%TYPE,
	in_ind_sids				IN	VARCHAR2,
	in_property_type_ids	IN	VARCHAR2,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_properties_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE UpdateSpaceTypePropertyAssoc(
	in_space_type_id		IN	space_type.space_type_id%TYPE,
	in_property_type_ids	IN	VARCHAR2
);

PROCEDURE UpdatePropertyTypeSpaceAssoc(
	in_property_type_id	IN	property_type.property_type_id%TYPE,
	in_space_type_ids	IN	VARCHAR2
);

PROCEDURE DeleteSpaceType(
	in_space_type_id	IN	space_type.space_type_id%TYPE
);

PROCEDURE AddSpaceTypePropertyAssoc(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_space_type_id		IN	space_type.space_type_id%TYPE
);

PROCEDURE RemoveSpaceTypePropertyAssoc(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_space_type_id		IN	space_type.space_type_id%TYPE
);

PROCEDURE GetSpaceTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_properties_cur		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceTypes(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_properties_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_metrics_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetLease (
	in_lease_id				IN  lease.lease_id%TYPE,
	out_lease_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetSpaceLeases (
	in_property_region_sid	IN  security_pkg.T_SID_ID,
	in_tenant_id			IN  tenant.tenant_id%TYPE,
	out_lease_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_spaces_cur			OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE SaveLease (
	in_lease_id				IN  lease.lease_id%TYPE, 
	in_start_dtm			IN  lease.start_dtm%TYPE,
	in_end_dtm				IN  lease.end_dtm%TYPE,
	in_next_break_dtm		IN  lease.next_break_dtm%TYPE,
	in_current_rent			IN  lease.current_rent%TYPE,
	in_normalised_rent		IN  lease.normalised_rent%TYPE,
	in_next_rent_review		IN  lease.next_rent_review%TYPE,
	in_tenant_id			IN  lease.tenant_id%TYPE,
	in_currency_code		IN  lease.currency_code%TYPE,
	in_space_region_sid		IN  security_pkg.T_SID_ID,
	in_property_region_sid	IN  security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE ClearSpaceLease (
	in_space_region_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE SetLeasePostIt(
	in_lease_id	IN	security_pkg.T_SID_ID,
	in_postit_id			IN	postit.postit_id%TYPE,
	out_postit_id			OUT postit.postit_id%TYPE
);

PROCEDURE GetLeasePostIts(
	in_lease_id	IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetRegionPostIt(
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_postit_id	IN	postit.postit_id%TYPE,
	out_postit_id	OUT postit.postit_id%TYPE
);

PROCEDURE GetRegionPostIts(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR,
	out_cur_files			OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddPropertyPhoto (
	in_property_region_sid	IN	security_pkg.T_SID_ID,
	in_space_region_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	out_property_photo_id	OUT	property_photo.property_photo_id%TYPE
);

PROCEDURE DeletePropertyPhoto (
	in_property_photo_id	IN	property_photo.property_photo_id%TYPE
);

PROCEDURE GetPropertyPhoto (
	in_property_photo_id	IN	property_photo.property_photo_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetFundFormPlugins(
	out_cur		OUT		security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetStates(
	in_country	IN	postcode.country.country%TYPE,
	in_filter	IN	VARCHAR2,
	out_cur		OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetCities(
	in_country	IN	postcode.country.country%TYPE,
	in_state	IN	property.state%TYPE,
	in_filter	IN	VARCHAR2,
	out_cur		OUT Security_Pkg.T_OUTPUT_CUR
);

PROCEDURE GetAllProperties(
	out_cur 	OUT  SYS_REFCURSOR
);

PROCEDURE GetAllPropertiesWTagsMetrics(
	out_cur 				OUT SYS_REFCURSOR,
	out_tags_cur 			OUT SYS_REFCURSOR,
	out_region_metrics_cur 	OUT SYS_REFCURSOR
);

PROCEDURE GetAllPropertiesForPropType(
	in_property_type_id	IN	property.property_type_id%TYPE,
	out_cur 			OUT	SYS_REFCURSOR
);

PROCEDURE AddIssue(
	in_region_sid 					IN 	security_pkg.T_SID_ID,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE,
	in_is_urgent					IN	NUMBER,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id					OUT issue.issue_id%TYPE
);

PROCEDURE GetBenchmarkSpaces(
	out_cur				OUT security_pkg.T_OUTPUT_CUR
);



PROCEDURE GetPropertyMapSid(
	out_map_sid			OUT security_pkg.T_SID_ID
);

PROCEDURE GetPropertyFund(
	in_region_sid			IN	security_pkg.T_SID_ID,
	out_cur					OUT	SYS_REFCURSOR
);

FUNCTION IsMultiFundEnabled RETURN NUMBER;

/**
 *	Gets the funds associated with the property.
 */
PROCEDURE GetPropertyFunds(
	in_region_sid					IN	security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetPropertyFunds(
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_fund_id						IN	NUMBER DEFAULT NULL,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetPropertyFundOwnership(
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE GetPropertyFundOwnership(
	in_region_sid					IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_fund_id						IN	NUMBER DEFAULT NULL,
	out_cur							OUT SYS_REFCURSOR
);

PROCEDURE SetFundOwnership(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_id						IN NUMBER,
	in_ownership					IN NUMBER,
	in_start_date					IN DATE 
);

PROCEDURE SetFundOwnerships(
	in_region_sid					IN security_pkg.T_SID_ID,
	in_fund_ids						IN security_pkg.T_SID_IDS,
	in_ownerships					IN security_pkg.T_DECIMAL_ARRAY,
	in_start_dates					IN security_pkg.T_VARCHAR2_ARRAY
);

PROCEDURE ClearFundOwnership(
	in_region_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE EnableMultiFund;

PROCEDURE SavePropertySubType(
	in_property_sub_type_id			IN	property_sub_type.property_sub_type_id%TYPE,
	in_property_sub_type_name		IN	property_sub_type.label%TYPE,
	in_property_type_id				IN	property_sub_type.property_type_id%TYPE,
	in_gresb_property_type_id		IN	property_sub_type.gresb_property_type_id%TYPE,
	in_gresb_property_sub_type_id	IN	property_sub_type.gresb_property_sub_type_id%TYPE,
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePropertyType(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_property_type_name	IN	property_type.label%TYPE,
	in_space_type_ids		IN	VARCHAR2,
	in_gresb_prop_type		IN	property_type.gresb_property_type_id%TYPE,
	out_property_type_id	OUT	property_type.property_type_id%TYPE
);

PROCEDURE SavePropertyType(
	in_property_type_id		IN	property_type.property_type_id%TYPE,
	in_property_type_name	IN	property_type.label%TYPE,
	in_space_type_ids		IN	VARCHAR2,
	in_gresb_prop_type		IN	property_type.gresb_property_type_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION SetCmsPlugin(
	in_tab_sid				IN	security_pkg.T_SID_ID,
	in_form_path			IN	plugin.form_path%TYPE,
	in_description			IN	plugin.description%TYPE
) RETURN plugin.plugin_id%TYPE;

FUNCTION SetMeterPlugin(
	in_group_key			IN	plugin.group_key%TYPE,
	in_control_lookup_keys	IN  plugin.control_lookup_keys%TYPE,
	in_description			IN	plugin.description%TYPE
) RETURN plugin.plugin_id%TYPE;


PROCEDURE SetEnergyStar (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_pm_building_id		IN	property.pm_building_id%TYPE,
	in_sync					IN	property.energy_star_sync%TYPE,
	in_push					IN	property.energy_star_push%TYPE
);

PROCEDURE SetGresbAssetId (
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_asset_id				IN	property_gresb.asset_id%TYPE
);

PROCEDURE ClearGresbAssetId (
	in_region_sid			IN	security_pkg.T_SID_ID
);

PROCEDURE DeletePropertyType(
	in_property_type_id	IN	property_type.property_type_id%TYPE
);

PROCEDURE DeletePropertySubType(
	in_property_sub_type_id	IN	property_sub_type.property_sub_type_id%TYPE
);

PROCEDURE SetPropertyType(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_prop_type_id			IN	property_type.property_type_id%TYPE,
	in_prop_sub_type_id		IN	property_sub_type.property_sub_type_id%TYPE	DEFAULT NULL
);

PROCEDURE SetPropertyTypeWithCheck(
	in_region_sid			IN	security_pkg.T_SID_ID,
	in_prop_type_id			IN	property_type.property_type_id%TYPE,
	in_prop_sub_type_id		IN	property_sub_type.property_sub_type_id%TYPE	DEFAULT NULL
);

PROCEDURE GetEditPageBuildingElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddEditPageBuildingElement (
	in_element_name					IN	property_element_layout.element_name%TYPE,
	in_pos							IN	property_element_layout.pos%TYPE,
	in_ind_sid						IN  property_element_layout.ind_sid%TYPE,
	in_tag_group_id					IN  property_element_layout.tag_group_id%TYPE,
	in_is_mandatory					IN  region_metric.is_mandatory%TYPE,
	in_show_measure					IN  region_metric.show_measure%TYPE
);

PROCEDURE RemoveEditPageBuildingElement (
	in_element_name			IN	VARCHAR2
);


PROCEDURE GetViewPageBuildingElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddViewPageBuildingElement (	
	in_element_name			IN	property_character_layout.element_name%TYPE,
	in_pos					IN	property_character_layout.pos%TYPE,
	in_col					IN	property_character_layout.col%TYPE,
	in_ind_sid				IN  property_character_layout.ind_sid%TYPE,
	in_tag_group_id			IN  property_character_layout.tag_group_id%TYPE,
	in_show_measure			IN  region_metric.show_measure%TYPE
);

PROCEDURE RemoveViewPageBuildingElement (
	in_element_name			IN	VARCHAR2
);

PROCEDURE GetActiveCountries (
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetPageMeterElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddPageMeterElement (
	in_meter_element_layout_id		IN	meter_element_layout.meter_element_layout_id%TYPE,
	in_pos							IN	meter_element_layout.pos%TYPE,
	in_ind_sid						IN  meter_element_layout.ind_sid%TYPE,
	in_tag_group_id					IN  meter_element_layout.tag_group_id%TYPE,
	in_is_mandatory					IN  region_metric.is_mandatory%TYPE,
	in_show_measure					IN  region_metric.show_measure%TYPE,
	out_meter_element_layout_id		OUT	meter_element_layout.meter_element_layout_id%TYPE
);

PROCEDURE RemovePageMeterElement (
	in_meter_element_layout_id		IN	meter_element_layout.meter_element_layout_id%TYPE
);

PROCEDURE GetPropertiesToGeocode (
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE SetPropertyGeoData (
	in_region_sid		 			IN	security_pkg.T_SID_ID,
	in_latitude						IN	region.geo_latitude%TYPE,
	in_longitude					IN	region.geo_longitude%TYPE,
	in_state						IN	property.state%TYPE,
	in_city							IN	property.city%TYPE
);

FUNCTION CountProperiesNotGeocoded RETURN NUMBER;
FUNCTION PropertyGeocodeBatchJob RETURN NUMBER;

PROCEDURE GetGresbPropertyTypes (
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetGresbPropertySubTypes (
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetGresbServiceConfig (
	out_cur				OUT	SYS_REFCURSOR
);

PROCEDURE GetPropertyOptions(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SavePropertyOptions(
	in_fund_company_type_id			IN NUMBER,
	in_auto_assign_manager			IN NUMBER,
	in_gresb_service_config			IN VARCHAR2,
	in_show_inherited_roles			IN NUMBER
);

PROCEDURE GetMandatoryRoles(
	out_cur							OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SetMandatoryRoles(
	in_role_sids					IN security_pkg.T_SID_IDS
);

PROCEDURE CreatePropertyDocLibFolder(
	in_property_sid					IN	security_pkg.T_SID_ID,
	out_folder_sid					OUT security_pkg.T_SID_ID
);

PROCEDURE CreateMissingDocLibFolders;

FUNCTION GetPropertyDocLib RETURN security_pkg.T_SID_ID;

FUNCTION GetDocLibFolder (
	in_property_sid					IN security_pkg.T_SID_ID
) RETURN security_pkg.T_SID_ID;

FUNCTION CheckDocumentPermissions (
	in_property_sid					IN  security_pkg.T_SID_ID,
	in_permission_set				IN  security_pkg.T_PERMISSION
) RETURN BOOLEAN;

FUNCTION GetPermissibleDocumentFolders (
	in_doc_library_sid				IN  security_pkg.T_SID_ID
) RETURN security.T_SID_TABLE;

PROCEDURE GetAuditLogForPropertyPaged(
	in_region_sid		IN	security_pkg.T_SID_ID,
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	in_search			IN	VARCHAR2,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
);

FUNCTION CanViewProperty(
	in_region_sid  	IN  security_pkg.T_SID_ID,
	out_is_editable OUT NUMBER
) RETURN BOOLEAN;

FUNCTION CanViewProperty(
	in_region_sid  IN  security_pkg.T_SID_ID
) RETURN BOOLEAN;

END;
/
