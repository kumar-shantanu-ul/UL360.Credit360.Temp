-- Please update version.sql too -- this keeps clean builds in sync
define version=2846
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
create index cms.ix_debug_ddl_log_csrimp_sessio on cms.debug_ddl_log (csrimp_session_id);
create index cms.ix_tab_oracle_schema on cms.tab (oracle_schema, oracle_table);
create index csr.ix_automated_imp_fileread_plug on csr.automated_import_class_step (fileread_plugin_id);
create index csr.ix_automated_imp_auto_imp_file on csr.automated_import_class_step (app_sid, auto_imp_fileread_ftp_id);
create index csr.ix_auto_imp_file_read_dbid on csr.automated_import_class_step (app_sid, auto_imp_fileread_db_id);
create index csr.ix_automated_imp_importer_plug on csr.automated_import_class_step (importer_plugin_id);
create index csr.ix_auto_exp_file_secondary_del on csr.auto_exp_filecreate_dsv (secondary_delimiter_id);
create index csr.ix_auto_imp_file_ftp_profile_i on csr.auto_imp_fileread_ftp (app_sid, ftp_profile_id);
create index csr.ix_auto_imp_impo_cms_imp_file_ on csr.auto_imp_importer_cms (cms_imp_file_type_id);
begin
	for r in (select 1 from all_tables where owner='CSR' and table_name='INITIATIVE_USER_FLOW_STATE') loop
		execute immediate 'drop table csr.INITIATIVE_USER_FLOW_STATE';
	end loop;
end;
/
create index csr.ix_meter_input_a_ind_sid_measu on csr.meter_input_aggr_ind (app_sid, ind_sid, measure_sid);
create index csr.ix_meter_input_a_measure_conve on csr.meter_input_aggr_ind (app_sid, measure_conversion_id, measure_sid);

begin
	for r in (
		select index_name,index_owner from (
		select aic.* , count(*) over (partition by aic.index_owner, aic.index_name) cols 
		 from all_ind_columns aic, all_indexes ai 
		where ai.table_name='METER_LIVE_DATA' and ai.owner='CSR'
		and ai.index_name = aic.index_name and ai.owner = aic.index_owner
		) where cols=2 and ( (column_name = 'APP_SID' and column_position = 1) or (column_name = 'METER_RAW_DATA_ID' and column_position = 2) )
		group by index_owner, index_name
		having count(*) = 2
	) loop
		execute immediate 'drop index '||r.index_owner||'.'||r.index_name;
	end loop;
end;
/	
	
create index csr.ix_meter_live_da_meter_raw_dat on csr.meter_live_data (app_sid, METER_RAW_DATA_ID);
create index csr.ix_plugin_portal_sid on csr.plugin (app_sid, portal_sid);
create index csr.ix_quick_survey__show_page_id_ on csr.quick_survey_expr_action (app_sid, show_page_id, survey_version);

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tables where owner='DONATIONS' and table_name='FC_DEFAULT_TAG';
	if v_exists = 1 then
		select count(*) into v_exists from all_indexes where table_owner='DONATIONS' and table_name='FC_DEFAULT_TAG' and index_name='IX_FC_DEFAULT_TA_TAG_ID';
		if v_exists = 0 then
			
			select count(*)
			  into v_exists
			   from (
			select * from (
				select aic.*,count(*) over (partition by ai.owner,ai.index_name) cols
				 from all_ind_columns aic, all_indexes ai where ai.table_name='FC_DEFAULT_TAG' and ai.table_owner='DONATIONS'
				and ai.owner = aic.index_owner and ai.index_name = aic.index_name
			) where cols = 2
			) where (column_name='APP_SID' and column_position = 1 ) or (column_name='TAG_ID' and column_position = 2 ) ;
			if v_exists != 2 then
				execute immediate 'create index donations.IX_FC_DEFAULT_TA_TAG_ID on DONATIONS.FC_DEFAULT_TAG (app_sid, tag_id)';
			end if;
		end if;
	end if;
end;
/

declare
	v_exists number;
begin
	select count(*) into v_exists from all_tables where owner='SUPPLIER' and table_name='CERT_SCHEME';
	if v_exists = 1 then
		select count(*) into v_exists from all_indexes where table_owner='SUPPLIER' and table_name='CERT_SCHEME' and index_name='IX_CERT_SCHEME_VERIFIED_FSCC';
		if v_exists = 0 then
			execute immediate 'create index supplier.ix_cert_scheme_verified_fscc on supplier.cert_scheme (verified_fscc)';
		end if;
		select count(*) into v_exists from all_indexes where table_owner='SUPPLIER' and table_name='CERT_SCHEME' and index_name='IX_CERT_SCHEME_NON_VERIFIED_';
		if v_exists = 0 then
			execute immediate 'create index supplier.ix_cert_scheme_non_verified_ on supplier.cert_scheme (non_verified_fscc)';
		end if;
	end if;
	select count(*) into v_exists from all_tables where owner='SUPPLIER' and table_name='GT_PRODUCT_USER';
	if v_exists = 1 then
		select count(*) into v_exists from all_indexes where table_owner='SUPPLIER' and table_name='GT_PRODUCT_USER' and index_name='IX_GT_PRODUCT_US_COMPANY_SID';
		if v_exists = 0 then
			execute immediate 'create index supplier.ix_gt_product_us_company_sid on supplier.gt_product_user (company_sid)';
		end if;
		select count(*) into v_exists from all_indexes where table_owner='SUPPLIER' and table_name='GT_PRODUCT_USER' and index_name='IX_GT_PRODUCT_US_USER_SID';
		if v_exists = 0 then
			execute immediate 'create index supplier.ix_gt_product_us_user_sid on supplier.gt_product_user (app_sid, user_sid)';
		end if;
	end if;
	select count(*) into v_exists from all_tables where owner='SUPPLIER' and table_name='RECYC_FSCC_CS_MAP';
	if v_exists = 1 then
		select count(*) into v_exists from all_indexes where table_owner='SUPPLIER' and table_name='RECYC_FSCC_CS_MAP' and index_name='IX_RECYC_FSCC_CS_CERT_SCHEME_I';
		if v_exists = 0 then
			execute immediate 'create index supplier.ix_recyc_fscc_cs_cert_scheme_i on supplier.recyc_fscc_cs_map (cert_scheme_id)';
		end if;
	end if;
end;
/


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../customer_body
@../schema_body
@../csrimp/imp_body

@update_tail
