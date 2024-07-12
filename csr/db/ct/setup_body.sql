CREATE OR REPLACE PACKAGE BODY ct.setup_pkg AS

PROCEDURE RegisterCards
AS
BEGIN
	chain.card_pkg.RegisterCard(
		'Company Details - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.CountryWizard',
		'/csr/site/ct/cards/companyDetails.js',
		'CarbonTrust.Cards.CompanyDetails'
	);

	chain.card_pkg.RegisterCard(
		'Countries of Operation - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.CountryWizard',
		'/csr/site/ct/cards/countriesOfOperation.js',
		'CarbonTrust.Cards.CountriesOfOperation'
	);

	chain.card_pkg.RegisterCard(
		'Business Travel - used by CarbonTrust hotspotter tool',
		'Credit360.Cards.Empty',
		'/csr/site/ct/cards/businessTravel.js',
		'CarbonTrust.Cards.BusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Industry Breakdown - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.CountryWizard',
		'/csr/site/ct/cards/industries.js',
		'CarbonTrust.Cards.Industries'
	);

	chain.card_pkg.RegisterCard(
		'Scope 1 and 2 Emissions - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.CountryWizard',
		'/csr/site/ct/cards/emissions.js',
		'CarbonTrust.Cards.Emissions'
	);

	chain.card_pkg.RegisterCard(
		'Water - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.CountryWizard',
		'/csr/site/ct/cards/water.js',
		'CarbonTrust.Cards.Water'
	);

	chain.card_pkg.RegisterCard(
		'Waste - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.CountryWizard',
		'/csr/site/ct/cards/waste.js',
		'CarbonTrust.Cards.Waste'
	);	

	chain.card_pkg.RegisterCard(
		'Group Definition - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.GroupWizard',
		'/csr/site/ct/cards/groupDefinition.js',
		'CarbonTrust.Cards.GroupDefinition'
	);

	chain.card_pkg.RegisterCard(
		'Group Composition - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.GroupWizard',
		'/csr/site/ct/cards/groupComposition.js',
		'CarbonTrust.Cards.GroupComposition'
	);

	chain.card_pkg.RegisterCard(
		'Group Country Breakdown - used by CarbonTrust hotspotter tool',
		'Credit360.CarbonTrust.Cards.GroupWizard',
		'/csr/site/ct/cards/groupCountries.js',
		'CarbonTrust.Cards.GroupCountries'
	);
	
	-- Employee Commuting Wizard
	chain.card_pkg.RegisterCard(
		'Employee Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/commutingBreakdown.js',
		'CarbonTrust.Cards.CommutingBreakdown'
	);

	chain.card_pkg.RegisterCard(
		'Car Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/carCommuting.js',
		'CarbonTrust.Cards.CarCommuting'
	);

	chain.card_pkg.RegisterCard(
		'Bus Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/busCommuting.js',
		'CarbonTrust.Cards.BusCommuting'
	);

	chain.card_pkg.RegisterCard(
		'Train Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/trainCommuting.js',
		'CarbonTrust.Cards.TrainCommuting'
	);

	chain.card_pkg.RegisterCard(
		'Motorbike Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/motorbikeCommuting.js',
		'CarbonTrust.Cards.MotorbikeCommuting'
	);

	chain.card_pkg.RegisterCard(
		'Bike Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/bikeCommuting.js',
		'CarbonTrust.Cards.BikeCommuting'
	);

	chain.card_pkg.RegisterCard(
		'Walk Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/ec/walkCommuting.js',
		'CarbonTrust.Cards.WalkCommuting'
	);

	-- Business Travel Wizard
	chain.card_pkg.RegisterCard(
		'Travellers Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/travellersBusinessTravel.js',
		'CarbonTrust.Cards.TravellersBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Motorbike Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/motorbikeBusinessTravel.js',
		'CarbonTrust.Cards.MotorbikeBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Car Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/carBusinessTravel.js',
		'CarbonTrust.Cards.CarBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Bus Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/busBusinessTravel.js',
		'CarbonTrust.Cards.BusBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Rail Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/railBusinessTravel.js',
		'CarbonTrust.Cards.RailBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Air Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/airBusinessTravel.js',
		'CarbonTrust.Cards.AirBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Bike Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/bikeBusinessTravel.js',
		'CarbonTrust.Cards.BikeBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Walking Business Travel - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelWizard',
		'/csr/site/ct/cards/bt/walkBusinessTravel.js',
		'CarbonTrust.Cards.WalkBusinessTravel'
	);

	-- Employee Commute Survey	
	chain.card_pkg.RegisterCard(
		'Employee Commute Survey - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommute',
		'/csr/site/ct/cards/surveys/employeeCommute.js',
		'CarbonTrust.Cards.EmployeeCommute'
	);

	-- Products and services
	chain.card_pkg.RegisterCard(
		'Products and Services Coverage - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.ProductsAndServicesManualWizard',
		'/csr/site/ct/cards/ps/productsAndServicesCoverage.js',
		'CarbonTrust.Cards.ProductsAndServicesCoverage'
	);

	chain.card_pkg.RegisterCard(
		'Products and Services Item Entry - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.ProductsAndServicesManualWizard',
		'/csr/site/ct/cards/ps/productsAndServicesItemEntry.js',
		'CarbonTrust.Cards.ProductsAndServicesItemEntry'
	);

	-- Module Configuration
	chain.card_pkg.RegisterCard(
		'Module Configuration Introduction - used by CarbonTrust tool',
		'Credit360.Cards.Empty',
		'/csr/site/ct/cards/moduleConfiguration/introduction.js',
		'CarbonTrust.Cards.ModuleConfiguration.Introduction'
	);

	chain.card_pkg.RegisterCard(
		'Employee Commuting Module Configuration - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.ModuleConfiguration.EmployeeCommuting',
		'/csr/site/ct/cards/moduleConfiguration/employeeCommuting.js',
		'CarbonTrust.Cards.ModuleConfiguration.EmployeeCommuting'
	);

	chain.card_pkg.RegisterCard(
		'Business Travel Module Configuration - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.ModuleConfiguration.BusinessTravel',
		'/csr/site/ct/cards/moduleConfiguration/businessTravel.js',
		'CarbonTrust.Cards.ModuleConfiguration.BusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Products and Services Module Configuration - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.ModuleConfiguration.ProductsAndServices',
		'/csr/site/ct/cards/moduleConfiguration/productsAndServices.js',
		'CarbonTrust.Cards.ModuleConfiguration.ProductsAndServices'
	);

	chain.card_pkg.RegisterCard(
		'Use Phase Module Configuration - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.ModuleConfiguration.UsePhase',
		'/csr/site/ct/cards/moduleConfiguration/usePhase.js',
		'CarbonTrust.Cards.ModuleConfiguration.UsePhase'
	);

	-- Business Travel Manual Wizard
	chain.card_pkg.RegisterCard(
		'Business Travel Coverage - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelManualWizard',
		'/csr/site/ct/cards/bt/businessTravelCoverage.js',
		'CarbonTrust.Cards.BusinessTravelCoverage'
	);

	chain.card_pkg.RegisterCard(
		'Business Travel Item Entry - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.BusinessTravelManualWizard',
		'/csr/site/ct/cards/bt/businessTravelItemEntry.js',
		'CarbonTrust.Cards.BusinessTravelItemEntry'
	);

	-- Hotspotter Invitation
	chain.card_pkg.RegisterCard(
		'Supplier user picker',
		'Credit360.CarbonTrust.Cards.HotspotterInvitation',
		'/csr/site/ct/cards/supplierUserPicker.js',
		'CarbonTrust.Cards.SupplierUserPicker'
	);


	-- Supplier Hotspotter
	chain.card_pkg.RegisterCard(
		'Company Details - used by CarbonTrust supplier hotspotter tool',
		'Credit360.CarbonTrust.Cards.SupplierHotspotter',
		'/csr/site/ct/cards/supplierDetails.js',
		'CarbonTrust.Cards.SupplierDetails'
	);

	chain.card_pkg.RegisterCard(
		'Countries of Operation - used by CarbonTrust supplier hotspotter tool',
		'Credit360.CarbonTrust.Cards.SupplierHotspotter',
		'/csr/site/ct/cards/supplierCountriesOfOperation.js',
		'CarbonTrust.Cards.SupplierCountriesOfOperation'
	);

	chain.card_pkg.RegisterCard(
		'Business Travel - used by CarbonTrust supplier hotspotter tool',
		'Credit360.Cards.Empty',
		'/csr/site/ct/cards/supplierBusinessTravel.js',
		'CarbonTrust.Cards.SupplierBusinessTravel'
	);

	chain.card_pkg.RegisterCard(
		'Industry Breakdown - used by CarbonTrust supplier hotspotter tool',
		'Credit360.CarbonTrust.Cards.SupplierHotspotter',
		'/csr/site/ct/cards/supplierIndustries.js',
		'CarbonTrust.Cards.SupplierIndustries'
	);

	chain.card_pkg.RegisterCard(
		'Scope 1 and 2 Emissions - used by CarbonTrust supplier hotspotter tool',
		'Credit360.CarbonTrust.Cards.SupplierHotspotter',
		'/csr/site/ct/cards/supplierEmissions.js',
		'CarbonTrust.Cards.SupplierEmissions'
	);

	chain.card_pkg.RegisterCard(
		'Defaults for the products and services upload',
		'Credit360.CarbonTrust.Cards.PSUploadDefaults',
		'/csr/site/ct/cards/psUploadDefaults.js',
		'CarbonTrust.Cards.PSUploadDefaults'
	);

	chain.card_pkg.RegisterCard(
		'Defaults for the business travel upload',
		'Credit360.CarbonTrust.Cards.BTUploadDefaults',
		'/csr/site/ct/cards/btUploadDefaults.js',
		'CarbonTrust.Cards.BTUploadDefaults'
	);
END;

PROCEDURE HotspotterCardGroups
AS	
BEGIN
chain.card_pkg.SetGroupCards('Hotspotter Country Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.CompanyDetails',
		'CarbonTrust.Cards.CountriesOfOperation',
		'CarbonTrust.Cards.BusinessTravel',
		'CarbonTrust.Cards.Industries',
		'CarbonTrust.Cards.Emissions', 
		'CarbonTrust.Cards.Water',
		'CarbonTrust.Cards.Waste'
	));

	chain.card_pkg.SetGroupCards('Hotspotter Group Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.GroupDefinition',
		'CarbonTrust.Cards.GroupComposition',
		'CarbonTrust.Cards.BusinessTravel',
		'CarbonTrust.Cards.GroupCountries'
	));
END;

PROCEDURE VCCardGroups
AS	
BEGIN
	chain.card_pkg.SetGroupCards('Employee Commuting Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.CommutingBreakdown',
		'CarbonTrust.Cards.CarCommuting',
		'CarbonTrust.Cards.BusCommuting',
		'CarbonTrust.Cards.TrainCommuting',
		'CarbonTrust.Cards.MotorbikeCommuting',
		'CarbonTrust.Cards.BikeCommuting',
		'CarbonTrust.Cards.WalkCommuting'
	));

	chain.card_pkg.SetGroupCards('Business Travel Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.TravellersBusinessTravel',		
		'CarbonTrust.Cards.CarBusinessTravel',
		'CarbonTrust.Cards.MotorbikeBusinessTravel',
		'CarbonTrust.Cards.BusBusinessTravel',
		'CarbonTrust.Cards.RailBusinessTravel',
		'CarbonTrust.Cards.AirBusinessTravel',
		'CarbonTrust.Cards.BikeBusinessTravel',
		'CarbonTrust.Cards.WalkBusinessTravel'
	));

	chain.card_pkg.SetGroupCards('Employee Commute Survey', chain.T_STRING_LIST(
		'CarbonTrust.Cards.EmployeeCommute'
	));

	chain.card_pkg.SetGroupCards('Products and Services Manual Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.ProductsAndServicesCoverage',
		'CarbonTrust.Cards.ProductsAndServicesItemEntry'
	));
	
	chain.card_pkg.SetGroupCards('Module Configuration', chain.T_STRING_LIST(
		'CarbonTrust.Cards.ModuleConfiguration.Introduction',
		'CarbonTrust.Cards.ModuleConfiguration.EmployeeCommuting',
		'CarbonTrust.Cards.ModuleConfiguration.BusinessTravel',
		'CarbonTrust.Cards.ModuleConfiguration.ProductsAndServices'
		--'CarbonTrust.Cards.ModuleConfiguration.UsePhase'
	));

	chain.card_pkg.SetGroupCards('Business and Travel Manual Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.BusinessTravelCoverage',
		'CarbonTrust.Cards.BusinessTravelItemEntry'
	));
	
	chain.card_pkg.SetGroupCards('Products and Services Upload Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.PSUploadDefaults',
		'Credit360.Excel.Cards.SheetPicker',
		'Credit360.Excel.Cards.ColumnTagger',
		'Credit360.Excel.Cards.ValueMapper',
		'Credit360.Excel.Cards.TestResults'
	));
	
	chain.card_pkg.SetGroupCards('Business Travel Upload Wizard', chain.T_STRING_LIST(
		'CarbonTrust.Cards.BTUploadDefaults',
		'Credit360.Excel.Cards.SheetPicker',
		'Credit360.Excel.Cards.ColumnTagger',
		'Credit360.Excel.Cards.ValueMapper',
		'Credit360.Excel.Cards.TestResults'
	));
	
	chain.card_pkg.SetGroupCards('Hotspotter Invitation', chain.T_STRING_LIST(
		'CarbonTrust.Cards.SupplierUserPicker'
	));
	
	chain.card_pkg.SetGroupCards('Supplier Hotspotter', chain.T_STRING_LIST(
		'CarbonTrust.Cards.SupplierDetails',
		'CarbonTrust.Cards.SupplierCountriesOfOperation',
		'CarbonTrust.Cards.SupplierBusinessTravel',
		'CarbonTrust.Cards.SupplierIndustries',
		'CarbonTrust.Cards.SupplierEmissions'
	));
	
	chain.card_pkg.SetGroupCards('Questionnaire Invitation Landing', chain.T_STRING_LIST(
		'Chain.Cards.QuestionnaireInvitationConfirmation', --createnew or default
		'Chain.Cards.Login',
		'Chain.Cards.RejectInvitation',
		'Chain.Cards.SelfRegistration'
	));

	chain.card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.Login');
	chain.card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.SelfRegistration');
	chain.card_pkg.MarkTerminate('Questionnaire Invitation Landing', 'Chain.Cards.RejectInvitation');

	chain.card_pkg.RegisterProgression('Questionnaire Invitation Landing', 'Chain.Cards.QuestionnaireInvitationConfirmation', chain.T_CARD_ACTION_LIST(
		chain.T_CARD_ACTION_ROW('reject', 'Chain.Cards.RejectInvitation'),
		chain.T_CARD_ACTION_ROW('register', 'Chain.Cards.SelfRegistration'),
		chain.T_CARD_ACTION_ROW('login', 'Chain.Cards.Login')
	));

	chain.card_pkg.SetGroupCards('My Details', chain.T_STRING_LIST('Chain.Cards.EditUser'));
	chain.card_pkg.SetGroupCards('My Company', chain.T_STRING_LIST('Chain.Cards.ViewCompany', 'Chain.Cards.EditCompany', 'Chain.Cards.CompanyUsers', 'Chain.Cards.CreateCompanyUser'));
	chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.ViewCompany', chain.chain_pkg.COMPANY, security.security_pkg.PERMISSION_WRITE, TRUE);
	chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.EditCompany', chain.chain_pkg.COMPANY, security.security_pkg.PERMISSION_WRITE, FALSE);
	chain.card_pkg.MakeCardConditional('My Company', 'Chain.Cards.CreateCompanyUser', chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CREATE_USER);
END;

PROCEDURE HotspotterSecurity
AS
	v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
	-- well known sids	
	v_groups_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_csr_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
	v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
	v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	-- our sids	
	v_hu_group					security.security_pkg.T_SID_ID;
	v_rhu_group					security.security_pkg.T_SID_ID;
	v_ct_site_sid				security.security_pkg.T_SID_ID;
	v_ct_hs_site_sid			security.security_pkg.T_SID_ID;
	v_ct_hs_m_site_sid			security.security_pkg.T_SID_ID;
	v_ct_mgmt_sid				security.security_pkg.T_SID_ID;
	v_hotspot_menu				security.security_pkg.T_SID_ID;
	v_admin_menu				security.security_pkg.T_SID_ID;
	v_hs_wiz_menu				security.security_pkg.T_SID_ID;
	v_hs_breakdown_menu			security.security_pkg.T_SID_ID;

	v_hs_report_menu			security.security_pkg.T_SID_ID;
	v_about_menu				security.security_pkg.T_SID_ID;
	v_manage_templates			security.security_pkg.T_SID_ID;
BEGIN
		
	/**************************************************************************************
		CREATE A HOTSPOT USERS GROUP
	**************************************************************************************/
	BEGIN
		v_hu_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Hotspot Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Hotspot Users', v_hu_group);
	
			-- Add registered users group to the hotspot group
			security.group_pkg.AddMember(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers'), v_hu_group);
	END;

	BEGIN
		v_rhu_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Restricted Hotspot Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Restricted Hotspot Users', v_rhu_group);
	
			-- Add hotspot users group to the restricted hotspot users group
			security.group_pkg.AddMember(v_act_id, v_hu_group, v_rhu_group);
	END;

	/**************************************************************************************
		CREATE WEB RESOURCES
	**************************************************************************************/
	BEGIN
		v_ct_site_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_sid, 'ct');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_csr_site_sid, 'ct', v_ct_site_sid);	

			-- give the rhu group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_site_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_rhu_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;

		BEGIN
			v_ct_hs_site_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'hotspotter');
		EXCEPTION 
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.web_pkg.CreateResource(v_act_id, v_www_sid, v_ct_site_sid, 'hotspotter', v_ct_hs_site_sid);	
		END;

			BEGIN
				v_ct_hs_m_site_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_hs_site_sid, 'manage');
			EXCEPTION 
				WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
					security.web_pkg.CreateResource(v_act_id, v_www_sid, v_ct_hs_site_sid, 'manage', v_ct_hs_m_site_sid);	

					-- don't inherit dacls
					security.securableobject_pkg.SetFlags(v_act_id, v_ct_hs_m_site_sid, 0);
					-- clean existing rhu sid
					security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_hs_m_site_sid), v_rhu_group);

					-- give the hu group READ permission on the resource
					security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_hs_m_site_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
						security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);	
			END;

	BEGIN
		v_ct_mgmt_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_ct_site_sid, 'management');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_ct_site_sid, 'management', v_ct_mgmt_sid);

			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_mgmt_sid, 0);
			-- clean existing ACE's
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid));

			-- give SuperAdmins group READ permission on the resource - everyone else is blocked
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_mgmt_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_INHERITABLE, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;

	/**************************************************************************************
		CREATE MENUS
	**************************************************************************************/

	/* HOTSPOTTER MENU - postition 1 */
	BEGIN
		v_hotspot_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'hotspot_dashboard');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_menu, 'hotspot_dashboard',  'Hotspotter',  '/csr/site/ct/hotspotter/dashboard.acds',  1, null, v_hotspot_menu);

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hotspot_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_rhu_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	security.menu_pkg.SetPos(v_act_id, v_hotspot_menu, 1);

		-- Sub menu's under hotspot menu
		BEGIN
			v_hs_wiz_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'wizard');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_hotspot_menu, 'wizard',  'Run hotspotter',  '/csr/site/ct/hotspotter/countryWizard.acds',  1, null, v_hs_wiz_menu);
		END;

		BEGIN
			v_hs_breakdown_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'breakdown');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_hotspot_menu, 'breakdown',  'Business structure manager',  '/csr/site/ct/hotspotter/manage/breakdownmanager.acds',  2, null, v_hs_breakdown_menu);

				-- don't inherit dacls
				security.securableobject_pkg.SetFlags(v_act_id, v_hs_breakdown_menu, 0);
				-- clean existing rhu sid
				security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_breakdown_menu), v_rhu_group);

				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_breakdown_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
					security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
		END;

		BEGIN
			v_hs_report_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_hotspot_menu, 'reports');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.menu_pkg.CreateMenu(v_act_id, v_hotspot_menu, 'reports',  'Hotspot reports',  '/csr/site/ct/hotspotter/manage/reportdownload.acds',  0, null, v_hs_report_menu);

				-- don't inherit dacls
				security.securableobject_pkg.SetFlags(v_act_id, v_hs_report_menu, 0);
				-- clean existing rhu sid
				security.acl_pkg.RemoveACEsForSid(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_report_menu), v_rhu_group);


				security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_hs_report_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
					security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
		END;

	/* ABOUT MENU - postition 0 === right hand of menu */
	BEGIN
		v_about_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'ct_hs_about');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_menu, 'ct_hs_about',  'About',  '/csr/site/ct/hotspotter/about.acds',  0, null, v_about_menu);

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_about_menu), -1, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_hu_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	security.menu_pkg.SetPos(v_act_id, v_about_menu, 0);

	/**************************************************************************************
			CAPABILITIES
	**************************************************************************************/
	BEGIN
		v_manage_templates := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Manage CT Templates');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Manage CT Templates', 1);

			v_manage_templates := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Capabilities/Manage CT Templates');

			-- don't inherit dacls
			security.securableobject_pkg.SetFlags(v_act_id, v_manage_templates, 0);
			-- clean existing ACE's
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_manage_templates));

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_manage_templates), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_sa_sid, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;

END;

PROCEDURE VCSecurity (
	in_side_by_side				BOOLEAN DEFAULT TRUE
)
AS
	v_act_id 					security.security_pkg.T_ACT_ID DEFAULT security.security_pkg.GetAct;
	v_app_sid 					security.security_pkg.T_SID_ID DEFAULT security.security_pkg.GetApp;
	-- well known sids	
	v_groups_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups');
	v_hu_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Hotspot Users');
	v_admins_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Administrators');
	v_everyone_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Everyone');
	v_reg_users_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'RegisteredUsers');
	v_ucd_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Users/UserCreatorDaemon');
	v_www_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot');
	v_csr_site_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'wwwroot/csr/site');
	v_site_ct_sid				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_csr_site_sid, 'ct');
	v_menu						security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'menu');
	v_admin_menu				security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'admin');
	v_chain_menu				security.security_pkg.T_SID_ID;-- DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain');
	v_my_details_menu			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'my_details');
	v_sa_sid					security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, security.security_pkg.SID_ROOT, 'csr/SuperAdmins');
	v_capabilities_sid			security.security_pkg.T_SID_ID DEFAULT security.securableobject_pkg.GetSIDFromPath(v_act_id, v_app_sid, 'capabilities');
	v_site_excel_sid			security.security_pkg.T_SID_ID;
	-- our sids	
	-- groups
	v_ec_users_group			security.security_pkg.T_SID_ID;
	v_ec_admins_group			security.security_pkg.T_SID_ID;
	v_bt_users_group			security.security_pkg.T_SID_ID;
	v_bt_admins_group			security.security_pkg.T_SID_ID;
	v_ps_users_group			security.security_pkg.T_SID_ID;
	v_ps_admins_group			security.security_pkg.T_SID_ID;
	v_up_users_group			security.security_pkg.T_SID_ID;
	v_up_admins_group			security.security_pkg.T_SID_ID;
	v_vc_users_group			security.security_pkg.T_SID_ID;
	v_vc_admins_group			security.security_pkg.T_SID_ID;
	-- menus
	v_vc_menu					security.security_pkg.T_SID_ID;
	v_supplier_details_menu		security.security_pkg.T_SID_ID;
	v_vc_ec_menu				security.security_pkg.T_SID_ID;
	v_vc_bt_menu				security.security_pkg.T_SID_ID;
	v_vc_ps_menu				security.security_pkg.T_SID_ID;
	v_vc_up_menu				security.security_pkg.T_SID_ID;
	v_vc_reports				security.security_pkg.T_SID_ID;
	v_admin_apport_menu			security.security_pkg.T_SID_ID;
	v_admin_config_menu			security.security_pkg.T_SID_ID;
	-- web resources
	v_ct_public_sid				security.security_pkg.T_SID_ID;
	v_ct_admin_sid				security.security_pkg.T_SID_ID;
	v_ct_ec_sid					security.security_pkg.T_SID_ID;
	v_ct_bt_sid					security.security_pkg.T_SID_ID;
	v_ct_ps_sid					security.security_pkg.T_SID_ID;
	v_ct_up_sid					security.security_pkg.T_SID_ID;
	v_ct_card_sid				security.security_pkg.T_SID_ID;
	v_ct_component_sid			security.security_pkg.T_SID_ID;
	-- capabilities
	v_admin_ec_cap_sid			security.security_pkg.T_SID_ID;
	v_admin_bt_cap_sid			security.security_pkg.T_SID_ID;
	v_admin_ps_cap_sid			security.security_pkg.T_SID_ID;
	v_admin_up_cap_sid			security.security_pkg.T_SID_ID;
	v_edit_ec_cap_sid			security.security_pkg.T_SID_ID;
	v_edit_bt_cap_sid			security.security_pkg.T_SID_ID;
	v_edit_ps_cap_sid			security.security_pkg.T_SID_ID;
	v_edit_up_cap_sid			security.security_pkg.T_SID_ID;
	-- chain
	v_top_company_sid			security.security_pkg.T_SID_ID;
	v_top_company_admins_sid	security.security_pkg.T_SID_ID;
	v_top_company_users_sid		security.security_pkg.T_SID_ID;
BEGIN
	
	/**************************************************************************************
		CREATE USER GROUPS
	**************************************************************************************/
	-- Employee Commute Admins
	BEGIN
		v_ec_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Employee Commute Admins');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Employee Commute Admins', v_ec_admins_group);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_ec_admins_group);
	END;
	
	-- Employee Commute Users
	BEGIN
		v_ec_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Employee Commute Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Employee Commute Users', v_ec_users_group);
			security.group_pkg.AddMember(v_act_id, v_ec_admins_group, v_ec_users_group);
	END;
	
	-- Business Travel Admins
	BEGIN
		v_bt_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Business Travel Admins');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Business Travel Admins', v_bt_admins_group);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_bt_admins_group);
	END;
	
	-- Business Travel Users
	BEGIN
		v_bt_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Business Travel Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Business Travel Users', v_bt_users_group);
			security.group_pkg.AddMember(v_act_id, v_bt_admins_group, v_bt_users_group);
	END;
	
	-- Products Services Admins
	BEGIN
		v_ps_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Products Services Admins');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Products Services Admins', v_ps_admins_group);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_ps_admins_group);
	END;
	
	-- Products Services Users
	BEGIN
		v_ps_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Products Services Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Products Services Users', v_ps_users_group);
			security.group_pkg.AddMember(v_act_id, v_ps_admins_group, v_ps_users_group);
	END;
	
	-- Use Phase Admins
	BEGIN
		v_up_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Use Phase Admins');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Use Phase Admins', v_up_admins_group);
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_up_admins_group);
	END;
	
	-- Use Phase Users
	BEGIN
		v_up_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Use Phase Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Use Phase Users', v_up_users_group);
			security.group_pkg.AddMember(v_act_id, v_up_admins_group, v_up_users_group);
	END;
	
	-- Value Chain Admins
	BEGIN
		v_vc_admins_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Admins');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Value Chain Admins', v_vc_admins_group);
			-- TODO: This is a temporary addition for development purposes - I think it should be the admins of the first company created that added via link_pkg
			security.group_pkg.AddMember(v_act_id, v_admins_sid, v_vc_admins_group);
			-- 
			security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_ec_admins_group);
			security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_bt_admins_group);
			security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_ps_admins_group);
			security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_up_admins_group);
			-- add the UserCreatorDaemon as well
			security.group_pkg.AddMember(v_act_id, v_ucd_sid, v_vc_admins_group);
	END;
	
	-- Value Chain Users
	BEGIN
		v_vc_users_group := security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Value Chain Users');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.group_pkg.CreateGroup(v_act_id, v_groups_sid, security.security_pkg.GROUP_TYPE_SECURITY, 'Value Chain Users', v_vc_users_group);
			security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_vc_users_group);
			security.group_pkg.AddMember(v_act_id, v_ec_users_group, v_vc_users_group);
			security.group_pkg.AddMember(v_act_id, v_bt_users_group, v_vc_users_group);
			security.group_pkg.AddMember(v_act_id, v_ps_users_group, v_vc_users_group);
			security.group_pkg.AddMember(v_act_id, v_up_users_group, v_vc_users_group);
			-- add these users as hotspot users
			security.group_pkg.AddMember(v_act_id, v_vc_users_group, security.securableobject_pkg.GetSidFromPath(v_act_id, v_groups_sid, 'Hotspot Users'));
	END;
		
		
	/**************************************************************************************
		CREATE WEB RESOURCES
	**************************************************************************************/
	-- /csr/site/ct/public/
	BEGIN
		v_ct_public_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'public');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'public', v_ct_public_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_public_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_public_sid));
			
			-- give the Everyone group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_public_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/admin/
	BEGIN
		v_ct_admin_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'admin');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'admin', v_ct_admin_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_admin_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_admin_sid));
			
			-- give the Value Chain Admins group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_admin_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/ec/
	BEGIN
		v_ct_ec_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'ec');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'ec', v_ct_ec_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_ec_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_ec_sid));
			
			-- give the ec users group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_ec_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_users_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/bt/
	BEGIN
		v_ct_bt_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'bt');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'bt', v_ct_bt_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_bt_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_bt_sid));
			
			-- give the bt users group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_bt_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_users_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/ps/
	BEGIN
		v_ct_ps_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'ps');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'ps', v_ct_ps_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_ps_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_ps_sid));
			
			-- give the ps users group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_ps_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/up/
	BEGIN
		v_ct_up_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'up');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'up', v_ct_up_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_up_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_up_sid));
			
			-- give the use phase group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_up_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_users_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/cards/
	BEGIN
		v_ct_card_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'cards');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'cards', v_ct_card_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_card_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_card_sid));
			
			-- give the Everyone group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_card_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	-- /csr/site/ct/components/
	BEGIN
		v_ct_component_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_site_ct_sid, 'components');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'components', v_ct_component_sid);	

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_ct_component_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_component_sid));
			
			-- give the Everyone group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_ct_component_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_everyone_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	/**************************************************************************************
		CREATE MENUS
	**************************************************************************************/
	-- Value Chain
	BEGIN
		v_vc_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'vc_dashboard');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_menu, 'vc_dashboard',  'Value chain',  '/csr/site/ct/dashboard.acds',  2, null, v_vc_menu);
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
		
	-- Value Chain -- Employee commuting
	BEGIN
		v_vc_ec_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_ec_landing');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_vc_menu, 'vc_ec_landing',  'Employee commuting',  '/csr/site/ct/ec/landing.acds',  1, null, v_vc_ec_menu);
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_vc_ec_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ec_menu));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ec_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Value Chain -- Business travel
	BEGIN
		v_vc_bt_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_bt_landing');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_vc_menu, 'vc_bt_landing',  'Business travel',  '/csr/site/ct/bt/landing.acds',  2, null, v_vc_bt_menu);
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_vc_bt_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_bt_menu));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_bt_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Value Chain -- Products and services
	BEGIN
		v_vc_ps_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_ps_landing');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_vc_menu, 'vc_ps_landing',  'Purchased goods',  '/csr/site/ct/ps/landing.acds',  3, null, v_vc_ps_menu);
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_vc_ps_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ps_menu));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_ps_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Value Chain -- Use phase
	BEGIN
		v_vc_up_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_up_landing');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_vc_menu, 'vc_up_landing',  'Use phase',  '/csr/site/ct/up/landing.acds',  4, null, v_vc_up_menu);
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_vc_up_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_up_menu));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_up_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Value Chain -- Value chain reports
	BEGIN
		v_vc_reports := security.securableobject_pkg.GetSidFromPath(v_act_id, v_vc_menu, 'vc_reports');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_vc_menu, 'vc_reports',  'Value chain reports',  '/csr/site/ct/reportDownload.acds',  0, null, v_vc_reports);

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_vc_reports, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_reports));

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_vc_reports), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;

	-- Admin -- VC Apportionment
	BEGIN
		v_admin_apport_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'vc_apportionment');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'vc_apportionment',  'VC Business structure',  '/csr/site/ct/admin/businessStructureManagement.acds',  0, null, v_admin_apport_menu);
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_admin_apport_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_apport_menu));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_apport_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Admin -- VC Module config
	BEGIN
		v_admin_config_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'vc_module_config');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'vc_module_config',  'VC Module config',  '/csr/site/ct/admin/moduleconfig.acds',  0, null, v_admin_config_menu);
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_admin_config_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_config_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_admins_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;
	
	-- Admin -- Supplier details
	BEGIN
		v_supplier_details_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_admin_menu, 'chain_supplier_search');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.menu_pkg.CreateMenu(v_act_id, v_admin_menu, 'chain_supplier_search',  'Supplier search',  '/csr/site/chain/supplierDetails.acds',  0, null, v_supplier_details_menu);

			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_supplier_details_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_supplier_details_menu));

			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_supplier_details_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW, 
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_READ);
	END;	
	
	/**************************************************************************************
		CREATE CAPABILITIES
	**************************************************************************************/
	-- Admin Employee Commuting
	BEGIN
		v_admin_ec_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Employee Commuting');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Admin Employee Commuting', 1);
			
			v_admin_ec_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Employee Commuting');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_admin_ec_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ec_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ec_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Admin Business Travel
	BEGIN
		v_admin_bt_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Business Travel');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Admin Business Travel', 1);
			
			v_admin_bt_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Business Travel');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_admin_bt_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_bt_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_bt_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Admin Products Services
	BEGIN
		v_admin_ps_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Products Services');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Admin Products Services', 1);
			
			v_admin_ps_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Products Services');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_admin_ps_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ps_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_ps_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Admin Use Phase
	BEGIN
		v_admin_up_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Use Phase');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Admin Use Phase', 1);
			
			v_admin_up_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Admin Use Phase');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_admin_up_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_up_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_admin_up_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_admins_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Edit Employee Commuting
	BEGIN
		v_edit_ec_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Employee Commuting');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Edit Employee Commuting', 1);
			
			v_edit_ec_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Employee Commuting');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_edit_ec_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ec_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ec_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ec_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Edit Business Travel
	BEGIN
		v_edit_bt_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Business Travel');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Edit Business Travel', 1);
			
			v_edit_bt_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Business Travel');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_edit_bt_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_bt_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_bt_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_bt_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Edit Products Services
	BEGIN
		v_edit_ps_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Products Services');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Edit Products Services', 1);
			
			v_edit_ps_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Products Services');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_edit_ps_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ps_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_ps_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_ps_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	-- Edit Use Phase
	BEGIN
		v_edit_up_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Use Phase');
	EXCEPTION
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			csr.csr_data_pkg.EnableCapability('Edit Use Phase', 1);
			
			v_edit_up_cap_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_capabilities_sid, 'Edit Use Phase');
			
			-- don't inherit dacls, clean existing ACE's
			security.securableobject_pkg.SetFlags(v_act_id, v_edit_up_cap_sid, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_up_cap_sid));
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_edit_up_cap_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_up_users_group, security.security_pkg.PERMISSION_STANDARD_ALL);	
	END;
	
	/**************************************************************************************
		LOCKDOWN HOTSPOTTER
	**************************************************************************************/
	-- remove registered users as hotspot users
	security.group_pkg.DeleteMember(v_act_id, v_reg_users_sid, v_hu_sid);
	-- add value chain admins as hotspot users
	security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_hu_sid);

	SELECT top_company_sid
	  INTO v_top_company_sid
	  FROM chain.customer_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	 
	IF v_top_company_sid IS NOT NULL THEN
		v_top_company_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_top_company_sid, 'Administrators');
		v_top_company_users_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_top_company_sid, 'Users');
		
		-- remove hotspot users from company admins
		security.group_pkg.DeleteMember(v_act_id, v_hu_sid, v_top_company_admins_sid);
		-- add value chain admins as company admins
		security.group_pkg.AddMember(v_act_id, v_vc_admins_group, v_top_company_admins_sid);
		-- add value chain users as company users
		security.group_pkg.AddMember(v_act_id, v_vc_users_group, v_top_company_users_sid);
	END IF;
	
	
	/**************************************************************************************
			MISC
	**************************************************************************************/
	-- give vc users permission on the my details menu item
	security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_my_details_menu), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_vc_users_group, security.security_pkg.PERMISSION_STANDARD_READ);	
	
	-- ensure that the excel web resource is created
	BEGIN
		v_site_excel_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, v_csr_site_sid, 'excel');
	EXCEPTION 
		WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
			security.web_pkg.CreateResource(v_act_id, v_www_sid, v_site_ct_sid, 'excel', v_site_excel_sid);	

			-- give the registered users group READ permission on the resource
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_site_excel_sid), security.security_pkg.ACL_INDEX_LAST, security.security_pkg.ACE_TYPE_ALLOW,
				security.security_pkg.ACE_FLAG_DEFAULT, v_reg_users_sid, security.security_pkg.PERMISSION_STANDARD_READ);	
	END;
	
	IF in_side_by_side THEN
		 NULL; 
		--- to do	- set up based on side by side
		-- for the moment just want to stop chain menu being nuked
	ELSE
		-- don't inherit dacls, clean existing ACE's
		BEGIN
			v_chain_menu := security.securableobject_pkg.GetSidFromPath(v_act_id, v_menu, 'chain');
			security.securableobject_pkg.SetFlags(v_act_id, v_chain_menu, 0);
			security.acl_pkg.DeleteAllACEs(v_act_id, security.acl_pkg.GetDACLIDForSID(v_chain_menu));
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
	END IF;
END;

PROCEDURE HotspotterPortlets
AS
	v_tab_id		NUMBER(10);
	v_tab_ids		security.security_pkg.T_SID_IDS;
	v_dummy			NUMBER(10);
BEGIN
	FOR r IN (
		SELECT portlet_id FROM csr.portlet WHERE type IN (
			'Credit360.Portlets.CarbonTrust.BreakdownPicker',
			'Credit360.Portlets.CarbonTrust.Advice',
			'Credit360.Portlets.CarbonTrust.HotspotChart',
			'Credit360.Portlets.CarbonTrust.Welcome',
			'Credit360.Portlets.CarbonTrust.ChartPicker'
		)
		AND portlet_id NOT IN (SELECT portlet_id FROM csr.customer_portlet WHERE app_sid = security.security_pkg.GetApp)
	) LOOP
		csr.portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;

	BEGIN
		SELECT tab_id
		  INTO v_tab_id
		  FROM csr.tab
		 WHERE portal_group = 'CT Welcome';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;		

	IF v_tab_id IS NULL THEN
		-- create a new tab 
		INSERT INTO csr.tab 
		(tab_id, layout, name, app_sid, is_shared, portal_group)
		VALUES 
		(csr.tab_id_seq.nextval, 2, 'Hotspotter', security.security_pkg.GetApp, 1, 'CT Welcome')
		RETURNING tab_id INTO v_tab_id;

		SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
		csr.portlet_pkg.SetTabsForGroup('CT Welcome', security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Groups/Hotspot Users'), v_tab_ids);

		csr.portlet_pkg.AddPortletToTab(v_tab_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.Welcome'), '{ height: 300 }', v_dummy);
	END IF;
END;

PROCEDURE VCPortlets
AS
	v_tab_id		NUMBER(10);
	v_tab_ids		security.security_pkg.T_SID_IDS;
	v_dummy			NUMBER(10);
BEGIN
	FOR r IN (
		SELECT portlet_id FROM csr.portlet WHERE type IN (
			'Credit360.Portlets.CarbonTrust.FlashMap',
			'Credit360.Portlets.CarbonTrust.WhatsNext',
			'Credit360.Portlets.CarbonTrust.VCBeforeHotspot',
			'Credit360.Portlets.CarbonTrust.VCBeforeSnapshot',
			'Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration',
			'Credit360.Portlets.Chain.RecentActivity'
		)
		AND portlet_id NOT IN (SELECT portlet_id FROM csr.customer_portlet WHERE app_sid = security_pkg.GetApp)
	) LOOP
		csr.portlet_pkg.EnablePortletForCustomer(r.portlet_id);
	END LOOP;	

	v_tab_id := NULL;	
	BEGIN
		SELECT tab_id
		  INTO v_tab_id
		  FROM csr.tab
		 WHERE portal_group = 'CT VC Before Hotspot';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;		

	IF v_tab_id IS NULL THEN
		-- create a new tab 
		INSERT INTO csr.tab 
		(tab_id, layout, name, app_sid, is_shared, portal_group)
		VALUES 
		(csr.tab_id_seq.nextval, 2, 'CT VC Before Hotspot', security_pkg.GetApp, 1, 'CT VC Before Hotspot')
		RETURNING tab_id INTO v_tab_id;

		SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
		csr.portlet_pkg.SetTabsForGroup('CT VC Before Hotspot', securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Value Chain Users'), v_tab_ids);

		csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.VCBeforeHotspot'), '{ height: 300 }', v_dummy);
	END IF;

	v_tab_id := NULL;		
	BEGIN
		SELECT tab_id
		  INTO v_tab_id
		  FROM csr.tab
		 WHERE portal_group = 'CT VC Before Snapshot';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;		

	IF v_tab_id IS NULL THEN
		-- create a new tab 
		INSERT INTO csr.tab 
		(tab_id, layout, name, app_sid, is_shared, portal_group)
		VALUES 
		(csr.tab_id_seq.nextval, 2, 'CT VC Before Snapshot', security.security_pkg.GetApp, 1, 'CT VC Before Snapshot')
		RETURNING tab_id INTO v_tab_id;

		SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
		csr.portlet_pkg.SetTabsForGroup('CT VC Before Snapshot', securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Value Chain Users'), v_tab_ids);

		csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.VCBeforeSnapshot'), '{ height: 300 }', v_dummy);
	END IF;

	v_tab_id := NULL;
	BEGIN
		SELECT tab_id
		  INTO v_tab_id
		  FROM csr.tab
		 WHERE portal_group = 'CT VC Before Module Configuration';
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;		

	IF v_tab_id IS NULL THEN
		-- create a new tab 
		INSERT INTO csr.tab 
		(tab_id, layout, name, app_sid, is_shared, portal_group)
		VALUES 
		(csr.tab_id_seq.nextval, 2, 'CT VC Before Module Configuration', security_pkg.GetApp, 1, 'CT VC Before Module Configuration')
		RETURNING tab_id INTO v_tab_id;

		SELECT v_tab_id BULK COLLECT INTO v_tab_ids FROM DUAL;
		csr.portlet_pkg.SetTabsForGroup('CT VC Before Module Configuration', securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Groups/Value Chain Users'), v_tab_ids);

		csr.portlet_pkg.AddPortletToTab(v_tab_id, securableobject_pkg.GetSidFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Portlets/Credit360.Portlets.CarbonTrust.VCBeforeModuleConfiguration'), '{ height: 300 }', v_dummy);
	END IF;
END;

PROCEDURE VCQuestionnaires
AS
BEGIN
	chain.questionnaire_pkg.CreateQuestionnaireType(
		1,
		'/csr/site/ct/hotSpotter/supplierHotspotter.acds?companySid={companySid}',
		'/csr/site/ct/hotSpotter/supplierHotspotter.acds?companySid={companySid}',
		chain.chain_pkg.INACTIVE, 	-- owner can review
		'Supplier hotspotter questionnaire',
		hotspot_pkg.HOTSPOTTER_QNR_CLASS, 		-- class
		NULL, 						-- db class
		NULL,						-- group
		1, 							-- position
		1  							-- requires review
	);
END;

PROCEDURE VCAlerts
AS
	v_frame_id				csr.alert_frame.alert_frame_id%TYPE;
	v_cust_alert_type_id	csr.customer_alert_type.customer_alert_type_id%TYPE;
BEGIN
	FOR r IN (
		SELECT * FROM csr.default_alert_frame ORDER BY default_alert_frame_id
	) LOOP
		BEGIN
			INSERT INTO csr.alert_frame (alert_frame_id, name) 
			VALUES (csr.alert_frame_id_seq.nextval, r.name);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	-- we'll use the minimum alert frame id for lack of better choice
	SELECT MIN(alert_frame_id) 
	  INTO v_frame_id
	  FROM csr.alert_frame;

	-- switch on all of our alert types for this app
	FOR r IN (
		SELECT std_alert_type_id FROM csr.std_alert_type WHERE std_alert_type_id IN (5000) AND std_alert_type_id NOT IN (SELECT std_alert_type_id FROM csr.customer_alert_type)
	) LOOP
		INSERT INTO csr.customer_alert_type (std_alert_type_id, customer_alert_type_id) 
		VALUES (r.std_alert_type_id, csr.customer_alert_type_id_seq.nextval);
	END LOOP;


	SELECT customer_alert_type_id INTO v_cust_alert_type_id FROM csr.customer_alert_type WHERE std_alert_type_id = 5000;
	-- Chain invitation
	csr.alert_pkg.SaveTemplateAndBody (
		v_cust_alert_type_id, v_frame_id, 'automatic', null, null, 'en',
		-- subject
		'<template>Value Chain Program for <mergefield name="TO_COMPANY_NAME" /></template>', 
		-- body
		'<template>'||
			'Dear <mergefield name="TO_FRIENDLY_NAME" />,<br /><br />'||
			'You are invited to complete the Value Chain Hotspotter. You will either need to log in or create your account by clicking on the following link:<br /><br />'||
			'<mergefield name="LINK" /><br />'||
			'<i>(Please note that this invitation link is only valid until <mergefield name="EXPIRATION" />.)</i><br /><br />'||
			'Thank you for your cooperation. <br />'||
			'<mergefield name="FROM_NAME" />'||
		'</template>',
		-- empty item template
		'<template>-</template>'
	);
END;

PROCEDURE SetupHotspotter (
	in_overwrite_default_url	BOOLEAN DEFAULT TRUE,
	in_top_company_type			chain.company_type.lookup_key%TYPE DEFAULT NULL,
	in_supplier_company_type	chain.company_type.lookup_key%TYPE DEFAULT NULL
)
AS
	v_is_value_chain			customer_options.is_value_chain%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'SetupHotspotter can only be run as BuiltIn/Administrator');
	END IF;
	
	BEGIN
		SELECT is_value_chain
		  INTO v_is_value_chain
		  FROM customer_options
		 WHERE app_sid = security.security_pkg.GetApp;

		 RAISE_APPLICATION_ERROR(-20001, 'The module is already enabled');
	EXCEPTION
		WHEN NO_DATA_FOUND THEN NULL;
	END;
	
	IF NOT chain.setup_pkg.IsChainEnabled THEN
		chain.setup_pkg.EnableSite(
			in_site_name => 'Value Chain Hotspotter'
		);
		
		chain.setup_pkg.EnableTwoTier;
	END IF;
	
	chain.setup_pkg.AddImplementation('CT', 'ct.link_pkg');
	
	RegisterCards;
	HotspotterCardGroups;
	HotspotterSecurity;
	HotspotterPortlets;
	
	INSERT INTO ct.customer_options (app_sid, top_company_type_id, supplier_company_type_id) 
	SELECT security.security_pkg.GetApp, t.company_type_id, s.company_type_id
	  FROM chain.company_type t, chain.company_type s
	 WHERE t.app_sid = security.security_pkg.GetApp
	   AND t.app_sid = s.app_sid
	   AND (
	   			t.lookup_key = UPPER(in_top_company_type) OR (
	   					in_top_company_type IS NULL AND t.is_top_company = 1
	   			)
	   		)
	   AND (
	   			s.lookup_key = UPPER(in_supplier_company_type) OR (
	   					in_supplier_company_type IS NULL AND s.is_default = 1
	   			)
	   		);
	   
	IF SQL%ROWCOUNT = 0 THEN
		RAISE_APPLICATION_ERROR(-20001, 'Could not set company types');
	END IF;
	
	IF in_overwrite_default_url THEN
		security.securableobject_pkg.SetNamedStringAttribute(security.security_pkg.GetAct, security.security_pkg.GetApp, 'default-url', '/csr/site/ct/hotspotter/dashboard.acds');
	END IF;
END;

PROCEDURE SetupValueChain (
	in_overwrite_default_url	BOOLEAN DEFAULT TRUE,
	in_side_by_side				BOOLEAN DEFAULT TRUE,
	in_top_company_type			chain.company_type.lookup_key%TYPE DEFAULT NULL,
	in_supplier_company_type	chain.company_type.lookup_key%TYPE DEFAULT NULL
)
AS
	v_is_value_chain			customer_options.is_value_chain%TYPE;
	v_alongside_chain			customer_options.is_alongside_chain%TYPE := 0;
	
	v_top_company_type			chain.company_type.lookup_key%TYPE;
	v_supplier_company_type		chain.company_type.lookup_key%TYPE;
BEGIN
	IF NOT security.security_pkg.IsAdmin(security.security_pkg.GetAct) THEN
		RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'SetupValueChain can only be run as BuiltIn/Administrator');
	END IF;
	
	IF in_side_by_side THEN 
		v_alongside_chain := 1;
	END IF;
	
	BEGIN
		SELECT is_value_chain
		  INTO v_is_value_chain
		  FROM customer_options
		 WHERE app_sid = security.security_pkg.GetApp;
		 
		 IF v_is_value_chain = 1 THEN
			RAISE_APPLICATION_ERROR(-20001, 'The module is already enabled');
		 END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN 
			SetupHotspotter(FALSE, in_top_company_type, in_supplier_company_type);
	END;
	
	SELECT t.lookup_key, s.lookup_key
	  INTO v_top_company_type, v_supplier_company_type
	  FROM customer_options co, chain.company_type t, chain.company_type s
	 WHERE co.app_sid = security.security_pkg.GetApp
	   AND co.app_sid = t.app_sid
	   AND co.app_sid = s.app_sid
	   AND co.top_company_type_id = t.company_type_id
	   AND co.supplier_company_type_id = s.company_type_id;

	-- this may not be ideal in a mixed implmentation...
	chain.type_capability_pkg.SetPermission(v_top_company_type, v_supplier_company_type, chain.chain_pkg.USER_GROUP, chain.chain_pkg.SEND_QUESTIONNAIRE_INVITE);
	-- allow users to read companies
	chain.type_capability_pkg.SetPermission(v_top_company_type, v_supplier_company_type, chain.chain_pkg.USER_GROUP, chain.chain_pkg.SUPPLIERS, security.security_pkg.PERMISSION_READ);
	-- allow admins to read and write companies
	chain.type_capability_pkg.SetPermission(v_top_company_type, v_supplier_company_type, chain.chain_pkg.ADMIN_GROUP, chain.chain_pkg.SUPPLIERS, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	
	VCCardGroups;
	VCQuestionnaires;
	VCAlerts;
	VCSecurity(in_side_by_side);
	VCPortlets;
	
	UPDATE CT.CUSTOMER_OPTIONS 
	   SET is_value_chain = 1, is_alongside_chain = v_alongside_chain
 	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
 	 
 	IF in_overwrite_default_url THEN
		security.securableobject_pkg.SetNamedStringAttribute(security_pkg.GetAct, security_pkg.GetApp, 'default-url', '/csr/site/ct/dashboard.acds');
	END IF;
END;

END setup_pkg;
/
