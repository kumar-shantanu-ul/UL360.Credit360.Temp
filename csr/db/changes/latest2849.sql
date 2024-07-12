-- Please update version.sql too -- this keeps clean builds in sync
define version=2849
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index ct.ix_bt_air_trip_last_edited_b on ct.bt_air_trip (app_sid, last_edited_by_sid);
create index ct.ix_bt_bus_trip_last_edited_b on ct.bt_bus_trip (app_sid, last_edited_by_sid);
create index ct.ix_bt_cab_trip_last_edited_b on ct.bt_cab_trip (app_sid, last_edited_by_sid);
create index ct.ix_bt_car_trip_last_edited_b on ct.bt_car_trip (app_sid, last_edited_by_sid);
create index ct.ix_bt_motorbike__last_edited_b on ct.bt_motorbike_trip (app_sid, last_edited_by_sid);
create index ct.ix_bt_profile_modified_by_s on ct.bt_profile (app_sid, modified_by_sid);
create index ct.ix_bt_train_trip_last_edited_b on ct.bt_train_trip (app_sid, last_edited_by_sid);
create index ct.ix_customer_opti_supplier_comp on ct.customer_options (app_sid, supplier_company_type_id);
create index ct.ix_customer_opti_top_company_t on ct.customer_options (app_sid, top_company_type_id);
create index ct.ix_ec_profile_modified_by_s on ct.ec_profile (app_sid, modified_by_sid);
create index ct.ix_ps_item_created_by_si on ct.ps_item (app_sid, created_by_sid);
create index ct.ix_ps_item_worksheet_id_ on ct.ps_item (app_sid, worksheet_id, row_number);
create index ct.ix_ps_item_modified_by_s on ct.ps_item (app_sid, modified_by_sid);
create index ct.ix_supplier_company_sid on ct.supplier (app_sid, company_sid);
create index ct.ix_supplier_cont_user_sid on ct.supplier_contact (app_sid, user_sid);

-- *** Grants ***
grant delete on actions.import_template to csr;
grant delete on actions.import_template_mapping to csr;
grant delete on actions.instance_gas_ind to csr;
grant delete on actions.import_mapping_mru to csr;
grant delete on actions.csr_task_role_member to csr;
grant delete on actions.initiative_sponsor to csr;
grant delete on actions.project_region_role_member to csr;
grant delete on donations.custom_field_dependency to csr;
grant select, update on csr.axis_member to cms;
grant select on security.web_resource to cms;
grant execute on csr.strategy_pkg to cms;

begin
	for r in (select 1 from all_objects where owner='ETHICS' and object_name='ETHICS_PKG') loop
		execute immediate 'grant execute on ethics.ethics_pkg to csr';
	end loop;
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
@../strategy_pkg
@../strategy_body
@../snapshot_pkg
@../snapshot_body
@../../../aspen2/cms/db/web_publication_body
@../../../aspen2/cms/db/cms_tab_body
@../../../aspen2/cms/db/tab_body

column ethics_path new_value ethics_path noprint;
select '' "ethics_path" from dual where rownum=0;
select "ethics_path"
  from (select "ethics_path"
		  from (select '../ethics/ethics_pkg' "ethics_path", 0 priority from all_objects where owner='ETHICS' and object_name='ETHICS_PKG' AND object_type='PACKAGE'
				 union
				select 'null_script', 1
				  from dual)
		  order by priority)
  where rownum = 1;
PROMPT Running &ethics_path
@&ethics_path

column ethics_path new_value ethics_path noprint;
select '' "ethics_path" from dual where rownum=0;
select "ethics_path"
  from (select "ethics_path"
		  from (select '../ethics/ethics_body' "ethics_path", 0 priority from all_objects where owner='ETHICS' and object_name='ETHICS_PKG' AND object_type='PACKAGE'
				 union
				select 'null_script', 1
				  from dual)
		  order by priority)
  where rownum = 1;
PROMPT Running &ethics_path
@&ethics_path

@update_tail
