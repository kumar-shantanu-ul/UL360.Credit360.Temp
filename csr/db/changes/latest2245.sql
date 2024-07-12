-- Please update version.sql too -- this keeps clean builds in sync
define version=2245
@update_header

CREATE OR REPLACE VIEW chain.v$company_action_capability
AS
    SELECT c.capability_id, x.company_function_id, x.company_sid, x.id company_group_type_id, ctr.role_sid, qa.questionnaire_action_id, x.action_security_type_id, qa.permission_set
	  FROM (
			 SELECT company_sid, company_function_id, action_security_type_id, id, CASE WHEN company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY') AND company_function_id = 1 THEN 1 ELSE 0 END is_supplier
			   FROM (
				SELECT DISTINCT action_security_type_id, id, company_sid, company_function_id 
				  FROM TT_QNR_SECURITY_ENTRY 
				 WHERE action_security_type_id = 1
				 )
		   ) x
	  JOIN company_func_qnr_action cfqa ON x.company_function_id = cfqa.company_function_id
	  JOIN chain.v$qnr_action_capability qa ON qa.questionnaire_action_id = cfqa.questionnaire_action_id 
	  JOIN capability c ON x.is_supplier = c.is_supplier AND qa.capability_name = c.capability_name
	  LEFT JOIN chain.company_type_role ctr ON x.id = ctr.role_sid
	 WHERE qa.capability_name = c.capability_name
	   AND qa.questionnaire_action_id = cfqa.questionnaire_action_id
	   AND x.company_function_id = cfqa.company_function_id
	   AND x.is_supplier = c.is_supplier;

@../chain/chain_link_pkg
@../chain/type_capability_pkg

@../chain/chain_link_body
@../chain/type_capability_body
@../chain/questionnaire_body
@../chain/questionnaire_security_body
@../chain/company_type_body

@update_tail