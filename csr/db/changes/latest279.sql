-- Please update version.sql too -- this keeps clean builds in sync
define version=279
@update_header

create index ix_file_upload_search on file_upload(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist nopopulate');

create index ix_sh_val_note_search on sheet_value(note) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist nopopulate');

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'file_upload_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_file_upload_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise file upload text content indexes');
       COMMIT;
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'sheet_note_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_sh_val_note_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2009/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise sheet note text indexes');
       COMMIT;
END;
/


@..\delegation_pkg
@..\delegation_body
@..\sheet_pkg
@..\sheet_body

begin
	update file_upload
	   set data = data;
	update sheet_value
	   set note = note;
	commit;
end;
/
		
@update_tail
