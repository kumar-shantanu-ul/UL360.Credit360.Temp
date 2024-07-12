-- Please update version.sql too -- this keeps clean builds in sync
define version=3012
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
declare
	v_exists number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCH_JOB' and column_name='FAILED';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batch_job ADD failed NUMBER(1) DEFAULT 0 NOT NULL';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name='BATCH_JOB' and constraint_name='CK_BATCH_JOB_FAILED';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batch_job ADD CONSTRAINT ck_batch_job_failed CHECK (failed IN (0, 1))';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_export_type ADD batch_job_type_id NUMBER(10)';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_import_type ADD batch_job_type_id NUMBER(10)';
	end if;
end;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW CSR.v$batch_job AS
	SELECT bj.app_sid, bj.batch_job_id, bj.batch_job_type_id, bj.description,
		   bjt.description batch_job_type_description, bj.requested_by_user_sid, bj.requested_by_company_sid,
	 	   cu.full_name requested_by_full_name, cu.email requested_by_email, bj.requested_dtm,
	 	   bj.email_on_completion, bj.started_dtm, bj.completed_dtm, bj.updated_dtm, bj.retry_dtm,
	 	   bj.work_done, bj.total_work, bj.running_on, bj.result, bj.result_url, bj.aborted_dtm, bj.failed
      FROM batch_job bj, batch_job_type bjt, csr_user cu
     WHERE bj.app_sid = cu.app_sid AND bj.requested_by_user_sid = cu.csr_user_sid
       AND bj.batch_job_type_id = bjt.batch_job_type_id;


-- *** Data changes ***
-- RLS

-- Data
-- EXPORTS
BEGIN
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (30, 'Full user export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (31, 'Filtered user export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (32, 'Region list export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (33, 'Indicator list export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (34, 'Data export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (35, 'Region role membership export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (36, 'Region and meter export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (37, 'Measure list export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (38, 'Emission profile export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (39, 'Factor set export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (40, 'Indicator translations', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (41, 'Region translations', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (42, 'CMS quick chart exporter', null, 'batch-exporter', 1, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (43, 'CMS exporter', null, 'batch-exporter', 1, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (44, 'Forecasting Slot export', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (45, 'Delegation translations', null, 'batch-exporter', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (46, 'Filter list export', null, 'batch-exporter', 1, null);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

declare
	v_exists number;
begin	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and column_name='BATCH_EXPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'begin
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 30
	 WHERE batch_export_type_id = 0;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 31
	 WHERE batch_export_type_id = 1;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 32
	 WHERE batch_export_type_id = 2;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 33
	 WHERE batch_export_type_id = 3;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 34
	 WHERE batch_export_type_id = 4;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 35
	 WHERE batch_export_type_id = 5;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 36
	 WHERE batch_export_type_id = 6;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 37
	 WHERE batch_export_type_id = 7;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 38
	 WHERE batch_export_type_id = 8;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 39
	 WHERE batch_export_type_id = 9;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 40
	 WHERE batch_export_type_id = 11;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 41
	 WHERE batch_export_type_id = 12;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 42
	 WHERE batch_export_type_id = 13;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 43
	 WHERE batch_export_type_id = 14;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 44
	 WHERE batch_export_type_id = 15;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 45
	 WHERE batch_export_type_id = 16;
	UPDATE csr.batched_export_type
	   SET batch_job_type_id = 46
	 WHERE batch_export_type_id = 10;
	 
	UPDATE csr.batch_job bj
	   SET bj.batch_job_type_id = ( 
			SELECT bet.batch_job_type_id 
			  FROM csr.batched_export_type bet
			 WHERE LOWER(bj.description) = LOWER(bet.label)
		  )
	 WHERE batch_job_type_id = 27;
	 end;';
	end if;

	DELETE FROM csr.batch_job_type WHERE batch_job_type_id = 27;

END;
/

declare
	v_exists	number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCH_JOB_BATCHED_EXPORT' and column_name = 'BATCH_EXPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batch_job_batched_export DROP COLUMN batch_export_type_id';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and column_name = 'BATCH_EXPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_export_type DROP COLUMN batch_export_type_id';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name='BATCHED_EXPORT_TYPE' and constraint_name = 'FK_BTCH_EXP_TYP_BTCH_JB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_export_type ADD CONSTRAINT fk_btch_exp_typ_btch_jb_type 
			FOREIGN KEY (batch_job_type_id) 
			REFERENCES csr.batch_job_type(batch_job_type_id)';
	end if;

	select count(*) into v_exists from all_constraints where owner='CSR' and table_name = 'BATCHED_EXPORT_TYPE' and constraint_name = 'PK_BATCHED_EXP_TYPE_JOB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_export_type	ADD CONSTRAINT pk_batched_exp_type_job_type PRIMARY KEY (batch_job_type_id)';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name = 'BATCHED_EXPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID' and nullable = 'Y';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_export_type MODIFY batch_job_type_id NOT NULL';
	end if;
end;
/


-- IMPORTS
BEGIN
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (47, 'Indicator translations import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (48, 'Region translations import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (49, 'Delegation translations import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (50, 'Meter readings import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (51, 'Forecasting Slot import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
	begin
		INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, one_at_a_time, file_data_sp)
		VALUES (52, 'Factor set import', null, 'batch-importer', 0, null);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

declare
	v_exists number;
begin	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and column_name='BATCH_IMPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'begin	
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 47
	 WHERE batch_import_type_id = 0;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 48
	 WHERE batch_import_type_id = 1;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 49
	 WHERE batch_import_type_id = 2;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 50
	 WHERE batch_import_type_id = 3;
	UPDATE csr.batched_import_type
	   SET batch_job_type_id = 51
	 WHERE batch_import_type_id = 4;
	 UPDATE csr.batched_import_type
	   SET batch_job_type_id = 52
	 WHERE batch_import_type_id = 5;
	
	 
	UPDATE csr.batch_job bj
	   SET bj.batch_job_type_id = ( 
			SELECT bet.batch_job_type_id 
			  FROM csr.batched_import_type bet
			 WHERE LOWER(bj.description) = LOWER(bet.label)
		  )
	 WHERE batch_job_type_id = 29;
	end;';
	end if;
	
	DELETE FROM csr.batch_job_type WHERE batch_job_type_id = 29;
END;
/
	
declare
	v_exists	number;
begin
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCH_JOB_BATCHED_IMPORT' and column_name = 'BATCH_IMPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batch_job_batched_import DROP COLUMN batch_import_type_id';
	end if;

	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and column_name = 'BATCH_IMPORT_TYPE_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_import_type DROP COLUMN batch_import_type_id';
	end if;
	
	select count(*) into v_exists from all_constraints where owner='CSR' and table_name='BATCHED_IMPORT_TYPE' and constraint_name = 'FK_BTCH_IMP_TYP_BTCH_JB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_import_type ADD CONSTRAINT fk_btch_imp_typ_btch_jb_type 
			FOREIGN KEY (batch_job_type_id) 
			REFERENCES csr.batch_job_type(batch_job_type_id)';
	end if;

	select count(*) into v_exists from all_constraints where owner='CSR' and table_name = 'BATCHED_IMPORT_TYPE' and constraint_name = 'PK_BATCHED_IMP_TYPE_JOB_TYPE';
	if v_exists = 0 then
		execute immediate 'ALTER TABLE csr.batched_import_type	ADD CONSTRAINT pk_batched_imp_type_job_type PRIMARY KEY (batch_job_type_id)';
	end if;
	
	select count(*) into v_exists from all_tab_columns where owner='CSR' and table_name = 'BATCHED_IMPORT_TYPE' and column_name='BATCH_JOB_TYPE_ID' and nullable = 'Y';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE csr.batched_import_type MODIFY batch_job_type_id NOT NULL';
	end if;
end;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../batch_exporter_pkg
@../batch_importer_pkg

@../batch_job_body
@../batch_exporter_body
@../batch_importer_body

@update_tail
