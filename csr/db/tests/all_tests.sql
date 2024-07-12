@@cleanup
@@common

COLUMN 1 NEW_VALUE 1
SELECT '' "1" FROM DUAL WHERE ROWNUM = 0;
-- Just to use more meaningful variable, i will give it a name
DEF SITE_NAME='&1'

VARIABLE bv_site_name VARCHAR2(100);
BEGIN
    :bv_site_name := '&&SITE_NAME';

	IF :bv_site_name IS NULL OR LENGTH(:bv_site_name) = 0 THEN
	  :bv_site_name := 'rag.credit360.com';
	END IF;

    dbms_output.put_line('site set to '||:bv_site_name);
END;
/

@@failtest

@@aggregate_inds
@@recurrence_pattern
@@dag
@@user_cover
@@cms_role_col
@@cms_company_col
@@cms_company_workflow
@@cms_permissible
@@cms_register_table
@@calc_xml
@@period
@@period_set
@@chain_company
@@chain_dedupe :bv_site_name
@@chain_bus_rel
@@chain_ref_perms
@@chain_followers
@@chain_filter
@@aspen2_utils
@@chain_capability
@@product_type
@@integration_api_tags
@@emission_factors
@@core_api
@@issues
@@finding_permission
@@delegation_plan
@@delegation
@@audit_migration
@@enable
@@region
@@region_tree
@@meter
@@merge_sequence
@@meter_monitor
@@meter_patch
--not currently required: @@meter_processing_job
@@portlet
@@property
@@property_fund
@@customer
@@audits
@@tags
@@compliance
@@permits
@@indicator
@@scheduled_import_export
@@credential_management
@@target_profile
@@initiatives
@@context_sensitive_help
@@integration_question_answer
@@region_certificates
@@sheet
@@landing_page
@@workflow
@@excel_export
@@cms_flow_alert_gen
@@like_for_like
@@supplier
@@val_datasource
@@region_metric
@@util_script
@@baseline
@@energy_star
@@alert
@@schema
@@core_access
@@automated_export
@@automated_import
@@target_planning
@@anonymise_users

@@cleanup
