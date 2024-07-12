-- Please update version.sql too -- this keeps clean builds in sync
define version=3057
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
create or replace procedure csr.createIndex(
	in_sql							in	varchar2
) authid current_user
as
	e_name_in_use					exception;
	pragma exception_init(e_name_in_use, -00955);
begin
	begin
		dbms_output.put_line(in_sql);
		execute immediate in_sql;
	exception
		when e_name_in_use then
			null;
	end;
end;
/

begin
	csr.createIndex('create index chain.ix_company_prod_prod_type on chain.company_product (app_sid, product_type_id)');
	csr.createIndex('create index chain.ix_company_produ_certification on chain.company_product_certification (app_sid, certification_id)');
	csr.createIndex('create index chain.ix_company_produ_cert_type on chain.company_product_required_cert (app_sid, certification_type_id)');
	csr.createIndex('create index chain.ix_company_tab_default_saved on chain.company_tab (app_sid, default_saved_filter_sid)');
	csr.createIndex('create index chain.ix_company_tab_r_company_type_ on chain.company_tab_related_co_type (app_sid, company_type_id)');
	csr.createIndex('create index chain.ix_dedupe_stagin_staging_tab_s on chain.dedupe_staging_link (app_sid, staging_tab_sid, staging_source_lookup_col_sid)');
	csr.createIndex('create index chain.ix_higg_config_m_score_type_id on chain.higg_config_module (app_sid, score_type_id)');
	csr.createIndex('create index chain.ix_product_heade_plugin_type_i on chain.product_header (plugin_type_id)');
	csr.createIndex('create index chain.ix_product_heade_plugin_id on chain.product_header (plugin_id)');
	csr.createIndex('create index chain.ix_product_heade_product_col_s on chain.product_header (app_sid, product_col_sid)');
	csr.createIndex('create index chain.ix_product_heade_user_company_ on chain.product_header (app_sid, user_company_col_sid)');
	csr.createIndex('create index chain.ix_product_heade_company_type_ on chain.product_header_company_type (app_sid, company_type_id)');
	csr.createIndex('create index chain.ix_product_heade_product_type_ on chain.product_header_product_type (app_sid, product_type_id)');
	csr.createIndex('create index chain.ix_product_metri_agg_rule_type on chain.product_metric_ind (agg_rule_type_id)');
	csr.createIndex('create index chain.ix_product_metri_ind_sid on chain.product_metric_val (app_sid, ind_sid)');
	csr.createIndex('create index chain.ix_product_metri_entered_by_si on chain.product_metric_val (app_sid, entered_by_sid)');
	csr.createIndex('create index chain.ix_product_suppl_purchaser_com on chain.product_supplier (app_sid, purchaser_company_sid, supplier_company_sid)');
	csr.createIndex('create index chain.ix_product_suppl_product_id on chain.product_supplier (app_sid, product_id)');
	csr.createIndex('create index chain.ix_product_suppl_certification on chain.product_supplier_certification (app_sid, certification_id)');
	csr.createIndex('create index chain.ix_product_suppl_entered_by_si on chain.product_supplier_metric_val (app_sid, entered_by_sid)');
	csr.createIndex('create index chain.ix_product_suppl_ind_sid on chain.product_supplier_metric_val (app_sid, ind_sid)');
	csr.createIndex('create index chain.ix_product_tab_user_company_ on chain.product_tab (app_sid, user_company_col_sid)');
	csr.createIndex('create index chain.ix_product_tab_product_col_s on chain.product_tab (app_sid, product_col_sid)');
	csr.createIndex('create index chain.ix_product_tab_plugin_id on chain.product_tab (plugin_id)');
	csr.createIndex('create index chain.ix_product_tab_plugin_type_i on chain.product_tab (plugin_type_id)');
	csr.createIndex('create index chain.ix_product_tab_c_company_type_ on chain.product_tab_company_type (app_sid, company_type_id)');
	csr.createIndex('create index chain.ix_product_tab_p_product_type_ on chain.product_tab_product_type (app_sid, product_type_id)');
	csr.createIndex('create index chain.ix_prod_supp_tab_company_type_ on chain.prod_supp_tab_company_type (app_sid, company_type_id)');
	csr.createIndex('create index chain.ix_prod_supp_tab_product_type_ on chain.prod_supp_tab_product_type (app_sid, product_type_id)');
	csr.createIndex('create index chain.ix_reference_reference_val on chain.reference (reference_validation_id)');
	csr.createIndex('create index csr.ix_compliance_pe_activity_type on csr.compliance_permit (app_sid, activity_type_id, activity_sub_type_id)');
	csr.createIndex('create index csr.ix_intl_audi_lock_tag_group_id on csr.internal_audit_locked_tag (app_sid, tag_group_id)');
end;
/

drop procedure csr.createIndex;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail

