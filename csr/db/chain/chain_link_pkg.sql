CREATE OR REPLACE PACKAGE  chain.chain_link_pkg
IS

PROCEDURE AddCompanyUser (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_user_sid					IN  security_pkg.T_SID_ID
);

PROCEDURE RemoveUserFromCompany (
	in_user_sid				IN  security_pkg.T_SID_ID,
	in_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE AddCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE VirtualDeleteCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE SetTags (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteUpload (
	in_upload_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE InviteCreated (
	in_invitation_id			IN	invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE EstablishRelationship(
	in_purchaser_sid	IN  security_pkg.T_SID_ID,
	in_supplier_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE DeleteRelationship (
	in_purchaser_sid	IN	security_pkg.T_SID_ID,
	in_supplier_sid		IN  security_pkg.T_SID_ID
);

PROCEDURE UpdateRelationship(
	in_purchaser_sid				IN	security_pkg.T_SID_ID,
	in_supplier_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE QuestionnaireAdded (
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_to_user_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
);

PROCEDURE QuestionnaireStatusChange (
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE,
	in_status_id				IN	chain_pkg.T_QUESTIONNAIRE_STATUS
);

PROCEDURE QuestionnaireShareStatusChange (
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid	IN	security_pkg.T_SID_ID,
	in_qnr_owner_company_sid	IN	security_pkg.T_SID_ID,
	in_status					IN	chain_pkg.T_SHARE_STATUS
);

PROCEDURE QuestionnaireExpired (
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE,
	in_share_with_company_sid	IN	security_pkg.T_SID_ID,
	in_qnr_owner_company_sid	IN	security_pkg.T_SID_ID
);

PROCEDURE QuestionnaireOverdue (
	in_questionnaire_id			IN	questionnaire.questionnaire_id%TYPE
);

PROCEDURE ActivateCompany(
	in_company_sid				IN	security_pkg.T_SID_ID
);

PROCEDURE DeactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE ReactivateCompany (
	in_company_sid				IN  security_pkg.T_SID_ID
);

PROCEDURE ActivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE DeactivateUser (
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ApproveUser (
	in_company_sid				IN	security_pkg.T_SID_ID,
	in_user_sid					IN	security_pkg.T_SID_ID
);

PROCEDURE ActivateRelationship(
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE TerminateRelationship (
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE FindSupplierRelFlowItemId (
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_flow_sid					IN	security_pkg.T_SID_ID,
	out_flow_item_id			OUT supplier_relationship.flow_item_id%TYPE
);

PROCEDURE AfterRelFlowItemActivate (
	in_new_item_created			IN 	NUMBER,
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID,
	in_flow_sid					IN	security_pkg.T_SID_ID,
	in_flow_item_id				IN 	supplier_relationship.flow_item_id%TYPE	
);

PROCEDURE AcceptReqQnnaireInvitation (
	in_purchaser_company_sid	IN	security_pkg.T_SID_ID,
	in_supplier_company_sid		IN	security_pkg.T_SID_ID
);

PROCEDURE GetWizardTitles (
	in_card_group_id			IN  card_group.card_group_id%TYPE,
	out_titles					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE AddProduct (
	in_product_id				IN  product.product_id%TYPE
);

PROCEDURE KillProduct (
	in_product_id				IN  product.product_id%TYPE
);

PROCEDURE CopyComponent (
	in_component_id			  					IN component.component_id%TYPE,
	in_new_component_id	  					IN component.component_id%TYPE,	
	in_from_company_sid 						IN security.security_pkg.T_SID_ID,
	in_to_company_sid							IN security.security_pkg.T_SID_ID,
	in_container_component_id				IN component.component_id%TYPE DEFAULT NULL,
	in_new_container_component_id		IN component.component_id%TYPE DEFAULT NULL	
);

PROCEDURE CreateNewProductRevision (
	in_product_id				IN  product.product_id%TYPE
);

FUNCTION FindProdWithUnitMismatch 
RETURN T_NUMERIC_TABLE;

PROCEDURE GetUnitsSuppSellsProdIn (
	in_component_id			IN  purchased_component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE SupplierScoreUpdated(
	in_company_sid				IN  security_pkg.T_SID_ID,
	in_score_type_id			IN	csr.supplier_score_log.score_type_id%TYPE,
	in_score					IN	csr.supplier_score_log.score%TYPE,
	in_score_threshold_id		IN	csr.supplier_score_log.score_threshold_id%TYPE,
	in_supplier_score_id		IN	csr.supplier_score_log.score_threshold_id%TYPE
);

-- subscribers of this method are expected to modify data in the tt_component_type_containment table
PROCEDURE FilterComponentTypeContainment;

PROCEDURE MessageRefreshed (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE,
	in_message_definition_id	IN	message.message_definition_id%TYPE
);

PROCEDURE MessageCreated (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE,
	in_message_definition_id	IN	message.message_definition_id%TYPE
);

PROCEDURE MessageCompleted (
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_message_id				IN  message.message_id%TYPE
);

PROCEDURE InvitationAccepted (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE InvitationRejected (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_reason					IN  chain_pkg.T_INVITATION_STATUS
);

PROCEDURE InvitationExpired (
	in_invitation_id			IN  invitation.invitation_id%TYPE,
	in_from_company_sid			IN  security_pkg.T_SID_ID,
	in_to_company_sid			IN  security_pkg.T_SID_ID
);

PROCEDURE FilterTaskCards (
	in_card_group_id			IN  card_group.card_group_id%TYPE, 
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
); 

FUNCTION GetTaskSchemeId (
	in_owner_company_sid		IN  security_pkg.T_SID_ID,
	in_supplier_company_sid		IN  security_pkg.T_SID_ID
) RETURN task_scheme.task_scheme_id%TYPE;

PROCEDURE TaskStatusChanged (
	in_task_change_id			IN  task.change_group_id%TYPE,
	in_task_id					IN  task.task_id%TYPE,
	in_status_id				IN  chain_pkg.T_TASK_STATUS
);

PROCEDURE TaskEntryChanged (
	in_task_change_id			IN  task.change_group_id%TYPE,
	in_task_entry_id			IN  task_entry.task_entry_id%TYPE
);

PROCEDURE SearchQuestionnairesByType (
	in_questionnaire_type_id	IN	questionnaire_type.questionnaire_type_id%TYPE,
	in_page   					IN  number,
	in_page_size    			IN  number,
	in_phrase					IN	VARCHAR2,
	out_count_cur				OUT	security_pkg.T_OUTPUT_CUR,
	out_result_cur				OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterCompaniesForTaskSummary (
	in_companies		IN	security.T_SID_TABLE,
	out_companies		OUT	security.T_SID_TABLE
);

PROCEDURE FilterExportExtras (
	in_filtered_sids	IN	T_FILTERED_OBJECT_TABLE,
	out_cur_extras2		OUT	security_pkg.T_OUTPUT_CUR
);

PROCEDURE FilterTasksAgainstMetricType;

PROCEDURE ClearDuplicatesForTaskSummary;

PROCEDURE GetOnBehalfOfCompanies (
	in_company_sids		IN	security.T_SID_TABLE,
	out_obo_cur			OUT	security_pkg.T_OUTPUT_CUR
);

FUNCTION IsTopCompany
RETURN NUMBER;

FUNCTION IsSidTopCompany (
	in_company_sid		IN  security_pkg.T_SID_ID
)
RETURN NUMBER;

PROCEDURE NukeChain;

PROCEDURE GenerateCompanyUploadsData(
	in_to_company_sid			IN  security_pkg.T_SID_ID,
	in_root_folder						IN  VARCHAR2,
	out_success						OUT BOOLEAN
);

PROCEDURE StartWorkflowForRegion (
	in_region_sid 				IN security.security_pkg.T_SID_ID, 
	in_flow_sid  				IN security.security_pkg.T_SID_ID,
	in_oracle_schema		    IN cms.tab.oracle_schema%TYPE,
	in_oracle_table		 		IN cms.tab.oracle_table%TYPE,
	in_flow_item_id				IN security_pkg.T_SID_ID
);

PROCEDURE AuditRequested(
	in_auditor_company_sid			IN security.security_pkg.T_SID_ID,
	in_auditee_company_sid			IN security.security_pkg.T_SID_ID,
	in_requested_by_company_sid		IN security.security_pkg.T_SID_ID,
	in_audit_request_id				IN audit_request.audit_request_id%TYPE
);

PROCEDURE AuditRequestAuditSet(
	in_audit_request_id				IN audit_request.audit_request_id%TYPE,
	in_auditor_company_sid			IN security.security_pkg.T_SID_ID,
	in_auditee_company_sid			IN security.security_pkg.T_SID_ID,
	in_audit_sid					IN security.security_pkg.T_SID_ID
);

PROCEDURE SaveSupplierAudit(
	in_audit_sid					IN security.security_pkg.T_SID_ID,
	in_supplier_company_sid			IN security.security_pkg.T_SID_ID,
	in_auditor_company_sid			IN security.security_pkg.T_SID_ID,
	in_created_by_company_sid		IN security.security_pkg.T_SID_ID
);

PROCEDURE OnQnnairePermissionsChange(
	in_questionnaire_id			IN	chain.questionnaire.questionnaire_id%TYPE
);

FUNCTION GetDefaultRevisionStartDate
RETURN DATE;

PROCEDURE OnPurchaseSaved(
	in_purchase_id		IN purchase.purchase_id%TYPE
);

PROCEDURE OnProductMapped(
	in_component_id			IN  component.component_id%TYPE,
	in_product_id			IN  product.product_id%TYPE
);

FUNCTION GetAlterShareStatusDescr
RETURN chain.T_VARCHAR_TABLE;

FUNCTION CanViewUnstartedProductQnr
RETURN NUMBER;

PROCEDURE BusinessRelationshipCreated(
	in_bus_rel_id			IN	business_relationship.business_relationship_id%TYPE
);

PROCEDURE BusinessRelationshipUpdated(
	in_bus_rel_id			IN	business_relationship.business_relationship_id%TYPE
);

PROCEDURE CompanyProductCreated(
	in_product_id				IN  company_product.product_id%TYPE
);

PROCEDURE CompanyProductUpdated(
	in_product_id				IN  company_product.product_id%TYPE
);

PROCEDURE DeletingCompanyProduct(
	in_product_id				IN  company_product.product_id%TYPE
);

PROCEDURE CompanyProductDeleted(
	in_product_id				IN  company_product.product_id%TYPE
);

PROCEDURE CompanyProductDeactivated(
	in_product_id				IN  company_product.product_id%TYPE
);

PROCEDURE CompanyProductReactivated(
	in_product_id				IN  company_product.product_id%TYPE
);

PROCEDURE ProductCertReqAdded
(
	in_product_id				IN  company_product_required_cert.product_id%TYPE,
	in_certification_type_id	IN	company_product_required_cert.certification_type_id%TYPE
);

PROCEDURE ProductCertReqRemoved
(
	in_product_id				IN  company_product_required_cert.product_id%TYPE,
	in_certification_type_id	IN	company_product_required_cert.certification_type_id%TYPE
);

PROCEDURE ProductCertAdded
(
	in_product_id				IN  company_product_certification.product_id%TYPE,
	in_certification_id			IN	company_product_certification.certification_id%TYPE
);

PROCEDURE ProductCertRemoved
(
	in_product_id				IN  company_product_certification.product_id%TYPE,
	in_certification_id			IN	company_product_certification.certification_id%TYPE
);

PROCEDURE ProductSupplierAdded
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
);

PROCEDURE ProductSupplierUpdated
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
);

PROCEDURE ProductSupplierDeactivated
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
);

PROCEDURE ProductSupplierReactivated
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
);

PROCEDURE RemovingProductSupplier
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
);

PROCEDURE ProductSupplierRemoved
(
	in_product_supplier_id		IN  product_supplier.product_supplier_id%TYPE
);

PROCEDURE ProdSuppCertAdded
(
	in_product_supplier_id		IN  product_supplier_certification.product_supplier_id%TYPE,
	in_certification_id			IN	product_supplier_certification.certification_id%TYPE
);

PROCEDURE ProdSuppCertRemoved
(
	in_product_supplier_id		IN  product_supplier_certification.product_supplier_id%TYPE,
	in_certification_id			IN	product_supplier_certification.certification_id%TYPE
);

PROCEDURE RiskLevelUpdated(
	in_risk_level_id		IN	risk_level.risk_level_id%TYPE
);

PROCEDURE CountryRiskLevelUpdated(
	in_risk_level_id		IN	risk_level.risk_level_id%TYPE DEFAULT NULL,
	in_country				IN	country_risk_level.country%TYPE DEFAULT NULL,
	in_dtm					IN	chain.country_risk_level.start_dtm%TYPE DEFAULT NULL
);

END chain_link_pkg;
/