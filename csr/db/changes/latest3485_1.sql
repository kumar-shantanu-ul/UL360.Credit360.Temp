-- Please update version.sql too -- this keeps clean builds in sync
define version=3485
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE
	v_audit_bsci_plugin_id		csr.plugin.plugin_id%TYPE;
	v_chain_bsci_plugin_id		csr.plugin.plugin_id%TYPE;
	TYPE card_id_list 			IS TABLE OF CHAIN.CARD.CARD_ID%TYPE;
	v_card_ids card_id_list 	:= card_id_list();
BEGIN
	security.user_pkg.logonadmin();

	BEGIN
		SELECT plugin_id INTO v_audit_bsci_plugin_id
		  FROM csr.plugin
		 WHERE LOWER(js_class) = 'audit.controls.bscisupplierdetailstab';
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
			v_audit_bsci_plugin_id := -1;
	END;
		
	BEGIN
			SELECT plugin_id INTO v_chain_bsci_plugin_id
			  FROM csr.plugin
			 WHERE LOWER(js_class) = 'chain.managecompany.bscisupplierdetailstab';
			EXCEPTION
				WHEN NO_DATA_FOUND THEN
					v_chain_bsci_plugin_id := -1;
	END;

	DELETE FROM chain.company_tab_company_type_role
	 WHERE company_tab_id IN (
		SELECT company_tab_id FROM chain.company_tab
		 WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id)
	);

	DELETE FROM chain.company_tab
	 WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id);

	DELETE FROM csr.audit_type_tab
		WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id);

	DELETE FROM csr.plugin
	 WHERE plugin_id IN (v_audit_bsci_plugin_id,v_chain_bsci_plugin_id);
	
	/*
	extension_card_group_id		Record Name
	64							bsciSupplier
	65							bsci2009Audit
	66							bsci2014Audit
	67							bsciExternalAudit */
	
	DELETE FROM chain.customer_grid_extension
	 WHERE grid_extension_id IN (
				SELECT cge.grid_extension_id
				  FROM chain.customer_grid_extension cge
				  JOIN chain.grid_extension ge ON cge.grid_extension_id = ge.grid_extension_id
				 WHERE ge.extension_card_group_id BETWEEN 64 AND 67
			);
		
	DELETE FROM chain.card_group_card
	 WHERE card_group_id BETWEEN 64 AND 67;
 
	DELETE FROM chain.grid_extension
	 WHERE extension_card_group_id BETWEEN 64 AND 67;

	DELETE FROM chain.card_group_column_type
	 WHERE card_group_id BETWEEN 64 AND 67;

	DELETE FROM chain.aggregate_type
	 WHERE card_group_id BETWEEN 64 AND 67;

	DELETE FROM chain.card_group
	 WHERE card_group_id BETWEEN 64 AND 67;

	SELECT card_id BULK COLLECT 
	  INTO v_card_ids
	  FROM chain.card
	 WHERE LOWER(js_class_type) LIKE '%bsci%';

	FOR i IN 1..v_card_ids.COUNT LOOP
		 DELETE FROM chain.filter_type WHERE card_id = v_card_ids(i);
		 DELETE FROM chain.card_progression_action WHERE card_id = v_card_ids(i);
		 DELETE FROM chain.card_group_card WHERE card_id = v_card_ids(i);
		 DELETE FROM chain.card WHERE card_id = v_card_ids(i);
	END LOOP;

	-- Removing BSCI Jobs
	DELETE FROM csr.batch_job WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batch_job_type_app_cfg WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batch_job_type_app_stat WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batched_export_type WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batched_import_type WHERE batch_job_type_id IN (26, 28);
	DELETE FROM csr.batch_job_type WHERE batch_job_type_id IN (26, 28);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
DROP PACKAGE chain.bsci_supplier_report_pkg;
DROP PACKAGE chain.bsci_2009_audit_report_pkg;
DROP PACKAGE chain.bsci_2014_audit_report_pkg;
DROP PACKAGE chain.bsci_ext_audit_report_pkg;
DROP PACKAGE chain.bsci_pkg;

@..\chain\helper_pkg
@..\chain\helper_body
@..\chain\filter_body
@..\chain\company_body
@..\audit_body

@update_tail
