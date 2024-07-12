-- Please update version.sql too -- this keeps clean builds in sync
define version=2847
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant delete on supplier.alert_batch to csr;
grant delete on supplier.all_company to csr;
grant delete on supplier.all_procurer_supplier to csr;
grant select, delete on supplier.all_product to csr;
grant delete on supplier.all_product_questionnaire to csr;
grant delete on supplier.chain_questionnaire to csr;
grant delete on supplier.company_questionnaire_response to csr;
grant delete on supplier.company_user to csr;
grant delete on supplier.contact to csr;
grant delete on supplier.customer_options to csr;
grant delete on supplier.customer_period to csr;
grant delete on supplier.gt_product_user to csr;
grant delete on supplier.invite to csr;
grant delete on supplier.invite_questionnaire to csr;
grant select, delete on supplier.message to csr;
grant delete on supplier.message_contact to csr;
grant delete on supplier.message_procurer_supplier to csr;
grant delete on supplier.message_questionnaire to csr;
grant delete on supplier.message_user to csr;
begin
	/*grant delete on supplier.np_component_description to csr;
	grant delete on supplier.np_part_description to csr;
	grant delete on supplier.np_part_evidence to csr;
	grant delete on supplier.np_product_answers to csr;*/
	null;
end;
/
grant delete on supplier.product_revision to csr;
grant delete on supplier.product_sales_volume to csr;
grant delete on supplier.product_questionnaire_group to csr;
grant select, delete on supplier.product_part to csr;
grant delete on supplier.product_tag to csr;
grant select, delete on supplier.questionnaire_group to csr;
grant delete on supplier.questionnaire_group_membership to csr;
grant delete on supplier.questionnaire_request to csr;
grant delete on supplier.tag_group to csr;

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tables where owner='CSR' and table_name='WOOD_PART_DESCRIPTION';
	if v_exists = 1 then
		execute immediate 'grant delete on supplier.wood_part_description to csr';
	end if;
	select count(*) into v_exists from all_tables where owner='CSR' and table_name='WOOD_PART_WOOD';
	if v_exists = 1 then
		execute immediate 'grant delete on supplier.wood_part_wood to csr';
	end if;
end;
/

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../csr_app_body

@update_tail
