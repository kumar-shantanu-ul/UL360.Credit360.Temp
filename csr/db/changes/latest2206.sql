-- Please update version.sql too -- this keeps clean builds in sync
define version=2206
@update_header

BEGIN
	--chain.capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMMON, chain.chain_pkg.MANAGE_WORKFLOWS, chain.chain_pkg.BOOLEAN_PERMISSION, chain.chain_pkg.IS_SUPPLIER_CAPABILITY);
	INSERT INTO chain.capability (capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES (chain.capability_id_seq.NEXTVAL, 'Manage workflows', 0, 1, 1);

END;
/

ALTER TABLE chain.customer_options ADD flow_helper_class_path VARCHAR2(1000) NULL;

@..\chain\chain_pkg
@..\chain\flow_form_pkg
@..\chain\type_capability_pkg

@..\chain\helper_body
@..\chain\questionnaire_body
@..\chain\flow_form_body
@..\chain\type_capability_body

@update_tail
