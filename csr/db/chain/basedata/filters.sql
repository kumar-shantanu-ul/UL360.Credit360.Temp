PROMPT >> Creating Filter Types
BEGIN
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Core Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCore'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Tags Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyTagsFilter'
	);
	
/*	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Product Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyProductFilter'
	);*/
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Relationship Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyRelationshipFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Audit Filter Adapter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyAuditFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Business Relationship Filter Adapter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyBusinessRelationshipFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Survey Questionnaire Filter',
		in_helper_pkg => 'csr.quick_survey_pkg',
		in_js_class_type => 'Chain.Cards.Filters.SurveyQuestionnaire'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Survey Campaign Filter',
		in_helper_pkg => 'csr.quick_survey_pkg',
		in_js_class_type => 'Chain.Cards.Filters.SurveyCampaign'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Survey Response Filter',
		in_helper_pkg => 'csr.quick_survey_pkg',
		in_js_class_type => 'QuickSurvey.Cards.SurveyResultsFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Issue Filter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.StandardIssuesFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Issue Custom Fields Filter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.IssuesCustomFieldsFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Issue Filter Adapter',
		in_helper_pkg => 'csr.issue_report_pkg',
		in_js_class_type => 'Credit360.Filters.Issues.IssuesFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Internal Audit Filter',
		in_helper_pkg => 'csr.audit_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.InternalAuditFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Internal Audit Filter Adapter',
		in_helper_pkg => 'csr.audit_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.AuditFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Internal Audit CMS Filter',
		in_helper_pkg => 'csr.audit_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.AuditCMSFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Non-compliance Filter',
		in_helper_pkg => 'csr.non_compliance_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.NonComplianceFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Non-compliance Filter Adapter',
		in_helper_pkg => 'csr.non_compliance_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.NonComplianceFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'CMS Filter',
		in_helper_pkg => 'cms.filter_pkg',
		in_js_class_type => 'NPSL.Cms.Filters.CmsFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Property Filter',
		in_helper_pkg => 'csr.property_report_pkg',
		in_js_class_type => 'Credit360.Property.Filters.PropertyFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Property Issues Filter',
		in_helper_pkg => 'csr.property_report_pkg',
		in_js_class_type => 'Credit360.Property.Filters.PropertyIssuesFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Property CMS Filter',
		in_helper_pkg => 'csr.property_report_pkg',
		in_js_class_type => 'Credit360.Property.Filters.PropertyCmsFilter'
	);	
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Initiative Filter',
		in_helper_pkg => 'csr.initiative_report_pkg',
		in_js_class_type => 'Credit360.Initiatives.Filters.InitiativeFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Meter Data Filter',
		in_helper_pkg => 'csr.meter_report_pkg',
		in_js_class_type => 'Credit360.Metering.Filters.MeterDataFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Meter Filter',
		in_helper_pkg => 'csr.meter_list_pkg',
		in_js_class_type => 'Credit360.Metering.Filters.MeterFilter'
	);

	chain.filter_pkg.CreateFilterType(
		in_description => 'User Data Filter',
		in_helper_pkg => 'csr.user_report_pkg',
		in_js_class_type => 'Credit360.Users.Filters.UserDataFilter'
	);

	chain.filter_pkg.CreateFilterType(
		in_description => 'User CMS Filter',
		in_helper_pkg => 'csr.user_report_pkg',
		in_js_class_type => 'Credit360.Users.Filters.UserCmsFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType(
		in_description => 'Compliance Library Filter',
		in_helper_pkg => 'csr.compliance_library_report_pkg',
		in_js_class_type => 'Credit360.Compliance.Filters.ComplianceLibraryFilter'
	);
	
	chain.filter_pkg.CreateFilterType(
		in_description => 'Compliance Legal Register Filter',
		in_helper_pkg => 'csr.compliance_register_report_pkg',
		in_js_class_type => 'Credit360.Compliance.Filters.LegalRegisterFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Survey Response Filter',
		in_helper_pkg => 'csr.quick_survey_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.SurveyResponse'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Region Filter',
		in_helper_pkg => 'csr.region_report_pkg',
		in_js_class_type => 'Credit360.Region.Filters.RegionFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Activity Filter',
		in_helper_pkg => 'chain.activity_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ActivityFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Activity Filter Adapter',
		in_helper_pkg => 'chain.activity_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ActivityFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Business Relationship Filter',
		in_helper_pkg => 'chain.business_rel_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.BusinessRelationshipFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Business Relationship Filter Adapter',
		in_helper_pkg => 'chain.business_rel_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.BusinessRelationshipFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Company Cms Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCmsFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Product CMS Filter',
		in_helper_pkg => 'chain.product_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductCmsFilterAdapter'
	);
	chain.filter_pkg.CreateFilterType (
		in_description => 'Certification Filter',
		in_helper_pkg => 'chain.certification_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CertificationFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Company Certification Filter Adapter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCertificationFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Certification Company Filter Adapter',
		in_helper_pkg => 'chain.certification_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CertificationCompanyFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Filter',
		in_helper_pkg => 'chain.product_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Company Filter Adapter',
		in_helper_pkg => 'chain.product_report_pkg',
		in_js_class_type => 'Credit360.Chain.Filters.ProductCompanyFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Supplier Filter Adapter',
		in_helper_pkg => 'chain.product_report_pkg',
		in_js_class_type => 'Credit360.Chain.Filters.ProductSupplierFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Survey Response Filter',
		in_helper_pkg => 'csr.quick_survey_report_pkg',
		in_js_class_type => 'Credit360.QuickSurvey.Filters.SurveyResponseFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Survey Response Audit Filter Adapter',
		in_helper_pkg => 'csr.quick_survey_report_pkg',
		in_js_class_type => 'Credit360.QuickSurvey.Filters.SurveyResponseAuditFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Permit List Filter',
		in_helper_pkg => 'csr.permit_report_pkg',
		in_js_class_type => 'Credit360.Compliance.Filters.PermitFilter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Permit CMS Filter',
		in_helper_pkg => 'csr.permit_report_pkg',
		in_js_class_type => 'Credit360.Compliance.Filters.PermitCmsFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Dedupe Processed Record Filter',
		in_helper_pkg => 'chain.dedupe_proc_record_report_pkg',
		in_js_class_type => 'Chain.dedupe.filters.ProcessedRecordFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Company Product Filter Adapter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyProductFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Supplier Filter',
		in_helper_pkg => 'chain.product_supplier_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductSupplierFilter'
	);
	chain.filter_pkg.CreateFilterType (
		in_description => 'Company Request Filter',
		in_helper_pkg => 'chain.company_request_report_pkg',
		in_js_class_type => 'Chain.companyRequest.filters.CompanyRequestFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Supplier Company Filter Adapter',
		in_helper_pkg => 'chain.product_supplier_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Supplier Product Filter Adapter',
		in_helper_pkg => 'chain.product_supplier_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductSupplierProductFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Metric Value Filter',
		in_helper_pkg => 'chain.product_metric_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductMetricValFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Metric Value Product Filter Adapter',
		in_helper_pkg => 'chain.product_metric_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductMetricValProductFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Permit Audit Filter Adapter',
		in_helper_pkg => 'csr.permit_report_pkg',
		in_js_class_type => 'Credit360.Compliance.Filters.PermitAuditFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Supplier Metric Value Filter',
		in_helper_pkg => 'chain.prdct_supp_mtrc_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductMetricValFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Product Supplier Metric Value Product Supplier Filter Adapter',
		in_helper_pkg => 'chain.prdct_supp_mtrc_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.ProductSupplierMetricValProductSupplierFilterAdapter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Integration Question Answer Filter',
		in_helper_pkg => 'csr.integration_question_answer_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.IntegrationQuestionAnswerFilter'
	);

	chain.filter_pkg.CreateFilterType (
		in_description => 'Integration Question Answer Filter Adapter',
		in_helper_pkg => 'csr.integration_question_answer_report_pkg',
		in_js_class_type => 'Credit360.Audit.Filters.IntegrationQuestionAnswerFilterAdapter'
	);
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Sheet Filter',
		in_helper_pkg => 'csr.sheet_report_pkg',
		in_js_class_type => 'Credit360.Delegation.Sheet.Filters.DataFilter'
	);

	/* BSCI now obsolete
	chain.filter_pkg.CreateFilterType (
		in_description => 'BSCI Supplier Filter',
		in_helper_pkg => 'chain.bsci_supplier_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.BsciSupplierFilter'
	);
 
	chain.filter_pkg.CreateFilterType (
		in_description => 'BSCI 2009 Audit Filter',
		in_helper_pkg => 'chain.bsci_2009_audit_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.Bsci2009AuditFilter'
	);
 
	chain.filter_pkg.CreateFilterType (
		in_description => 'BSCI 2014 Audit Filter',
		in_helper_pkg => 'chain.bsci_2014_audit_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.Bsci2014AuditFilter'
	);
 
	chain.filter_pkg.CreateFilterType (
		in_description => 'BSCI External Audit Filter',
		in_helper_pkg => 'chain.bsci_ext_audit_report_pkg',
		in_js_class_type => 'Chain.Cards.Filters.BsciExternalAuditFilter'
	);
	*/
END;
/

/*
	Credit360.Analysis.SupplierAggregationType = {
 COUNT_OF_SUPPLIERS: 1
}

Credit360.Analysis.IssueAggregationType = {
 COUNT_OF_ISSUES: 1,
 SUM_OF_DAYS_OPEN: 2,
 SUM_OF_DAYS_OVERDUE: 3,
 AVERAGE_DAYS_OPEN: 4,
 AVERAGE_DAYS_OVERDUE: 5
}

Credit360.Analysis.AuditAggregationType = {
 COUNT_OF_AUDITS: 1
}

Credit360.Analysis.NonComplianceAggregationType = {
 COUNT_OF_NON_COMPLIANCES: 1
}
*/


PROMPT >> Creating Aggregate Types
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPANIES, chain.company_filter_pkg.SUPPLIER_COUNT, 'Number of suppliers');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.AGG_TYPE_COUNT, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.AGG_TYPE_DAYS_OPEN, 'Total days open');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.AGG_TYPE_DAYS_OVERDUE, 'Total days overdue');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.AGG_TYPE_AVG_DAYS_OPEN, 'Average days open');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.AGG_TYPE_AVG_DAYS_OVRDUE, 'Average days overdue');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT, 'Number of audits');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_NON_COMP, 'Number of findings');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_OPEN_NON_COMP, 'Number of open findings');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_ISSUES, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_OPEN_ISSUES, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_OVRD_ISSUES, 'Number of overdue actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES, 'Number of closed actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_IS_CLSD_ON_TIME, 'Number of actions closed on time');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.AGG_TYPE_COUNT_IS_CLSD_OVRD, 'Number of actions closed overdue');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT, 'Number of findings');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT_ISSUES, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT_OPEN_ISSUES, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT_OVRD_ISSUES, 'Number of overdue actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES, 'Number of closed actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT_IS_CLSD_ON_TIME, 'Number of actions closed on time');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.AGG_TYPE_COUNT_IS_CLSD_OVRD, 'Number of actions closed overdue');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_CMS, cms.filter_pkg.AGG_TYPE_COUNT, 'Number of items');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PROPERTY, csr.property_report_pkg.AGG_TYPE_COUNT, 'Number of properties');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_INITIATIVES, csr.initiative_report_pkg.AGG_TYPE_COUNT, 'Number of initiatives');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_METER_DATA, csr.meter_report_pkg.AGG_TYPE_SUM, 'Total');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_CSR_USER, csr.user_report_pkg.AGG_TYPE_COUNT, 'Number of users');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_METERS, csr.meter_list_pkg.AGG_TYPE_COUNT, 'Number of meters');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB, csr.compliance_library_report_pkg.AGG_TYPE_COUNT, 'Number of items');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT, 'Number of items');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_REG, 'Number of regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_OPEN_REG, 'Number of open regulations');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_REQ, 'Number of requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_OPEN_REQ, 'Number of open requirements');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_ISSUES, 'Number of actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_OPEN_ISSUES, 'Number of open actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_OVRD_ISSUES, 'Number of overdue actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES, 'Number of closed actions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_REGIONS, csr.region_report_pkg.AGG_TYPE_COUNT_REG, 'Number of regions');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ACTIVITIES, chain.activity_report_pkg.AGG_TYPE_COUNT, 'Number of activities');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_BUS_RELS, chain.business_rel_report_pkg.AGG_TYPE_COUNT, 'Number of business relationships');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT, chain.product_report_pkg.AGG_TYPE_COUNT, 'Number of products');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER, chain.product_supplier_report_pkg.AGG_TYPE_COUNT, 'Number of suppliers');
		
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PERMITS, csr.permit_report_pkg.AGG_TYPE_COUNT, 'Number of permits');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, csr.quick_survey_report_pkg.AGG_TYPE_COUNT, 'Number of survey responses');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, csr.quick_survey_report_pkg.AGG_TYPE_SUM_SCORES, 'Sum of survey response scores');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, csr.quick_survey_report_pkg.AGG_TYPE_AVG_SCORE, 'Average survey response score');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, csr.quick_survey_report_pkg.AGG_TYPE_MAX_SCORE, 'Maximum survey response score');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, csr.quick_survey_report_pkg.AGG_TYPE_MIN_SCORE, 'Minimum');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_CERTS, chain.certification_report_pkg.AGG_TYPE_COUNT, 'Number of certifications');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_DEDUPE_PROC_RECS, chain.dedupe_proc_record_report_pkg.AGG_TYPE_COUNT, 'Number of records');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPANY_REQUEST, chain.company_request_report_pkg.AGG_TYPE_COUNT, 'Number of records');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, chain.product_metric_report_pkg.AGG_TYPE_COUNT_METRIC_VAL, 'Number of records');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, chain.product_metric_report_pkg.AGG_TYPE_SUM_METRIC_VAL, 'Sum of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, chain.product_metric_report_pkg.AGG_TYPE_AVG_METRIC_VAL, 'Average of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, chain.product_metric_report_pkg.AGG_TYPE_MAX_METRIC_VAL, 'Maximum of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT_METRIC_VAL, chain.product_metric_report_pkg.AGG_TYPE_MIN_METRIC_VAL, 'Minimum of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_COUNT_METRIC_VAL, 'Number of records');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_SUM_METRIC_VAL, 'Sum of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_AVG_METRIC_VAL, 'Average of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_MAX_METRIC_VAL, 'Maximum of metric values');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRD_SUPP_MTRC_VAL, chain.prdct_supp_mtrc_report_pkg.AGG_TYPE_MIN_METRIC_VAL, 'Minimum of metric values');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER, csr.integration_question_answer_report_pkg.AGG_TYPE_COUNT, 'Number of records');
	
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_SHEET, csr.sheet_report_pkg.AGG_TYPE_COUNT, 'Number of records');
END;
/



PROMPT >> Creating Column Types
BEGIN
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPANIES, chain.company_filter_pkg.COL_TYPE_SUPPLIER_REGION, chain.filter_pkg.COLUMN_TYPE_REGION, 'Supplier region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Action region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.COL_TYPE_RAISED_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Raised date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.COL_TYPE_RESOLVED_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Resolved date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.COL_TYPE_DUE_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Due date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ISSUES, csr.issue_report_pkg.COL_TYPE_FORECAST_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Forecast date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Audit region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_AUDITS, csr.audit_report_pkg.COL_TYPE_AUDIT_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Audit date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Finding region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES, csr.non_compliance_report_pkg.COL_TYPE_AUDIT_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Audit date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PROPERTY, csr.property_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Property region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_INITIATIVES, csr.property_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Initiative region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_METER_DATA, csr.meter_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Meter region');
		
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_METER_DATA, csr.meter_report_pkg.COL_TYPE_START_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Start date');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_CSR_USER, csr.user_report_pkg.COL_TYPE_ROLE_REGION, chain.filter_pkg.COLUMN_TYPE_REGION, 'Role region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_CSR_USER, csr.user_report_pkg.COL_TYPE_ASSOC_REGION, chain.filter_pkg.COLUMN_TYPE_REGION, 'Associated region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_CSR_USER, csr.user_report_pkg.COL_TYPE_START_REGION, chain.filter_pkg.COLUMN_TYPE_REGION, 'Start point region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_METERS, csr.meter_list_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Meter region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_LIB, csr.compliance_library_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Compliance item region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_COMPLIANCE_REG, csr.compliance_register_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Compliance item region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_REGIONS, csr.region_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_ACTIVITIES, chain.activity_report_pkg.COL_TYPE_SUPPLIER_REGION, chain.filter_pkg.COLUMN_TYPE_REGION, 'Supplier region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_BUS_RELS, chain.business_rel_report_pkg.COL_TYPE_SUPPLIER_REGION, chain.filter_pkg.COLUMN_TYPE_REGION, 'Company region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PRODUCT, chain.product_report_pkg.COL_TYPE_LAST_EDITED_DTM, chain.filter_pkg.COLUMN_TYPE_DATE, 'Last edited');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_QS_RESPONSE, csr.quick_survey_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Survey response region');
	
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_PERMITS, csr.permit_report_pkg.COL_TYPE_REGION_SID, chain.filter_pkg.COLUMN_TYPE_REGION, 'Permit item region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (chain.filter_pkg.FILTER_TYPE_INTEGRATION_QUESTION_ANSWER, csr.integration_question_answer_report_pkg.COL_TYPE_LAST_UPDATED, chain.filter_pkg.COLUMN_TYPE_DATE, 'Last updated');
END;
/
