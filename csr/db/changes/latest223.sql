-- Please update version.sql too -- this keeps clean builds in sync
define version=223
@update_header

prompt enter connection name (e.g. aspen)
connect aspen2/aspen2@&&1

begin 
	for r in (select username 
				from all_users 
			   where username in ('BOTB2','CSR','SUPPLIER','CSMART','ACTIONS','DONATIONS')) loop
		execute immediate 'grant select on filecache to '||r.username;
	end loop;
end;
/

connect csr/csr@&&1

alter table aspen2.filecache modify mime_type varchar2(255);

begin
	for r in (select owner,table_name
			    from all_tables 
			   where owner IN ('BOTB2','CSR','SUPPLIER','CSMART') and
			   		 table_name = 'FILECACHE') loop
		execute immediate 'lock table '||r.owner||'.'||r.table_name||' in exclusive mode';
		execute immediate 'insert into aspen2.filecache select * from '||r.owner||'.'||r.table_name;
		execute immediate 'drop table '||r.owner||'.'||r.table_name;
	end loop;
	for r in (select owner,table_name
			    from all_tables 
			   where owner IN ('BOTB2','CSR','SUPPLIER','CSMART') and
			   		 table_name = 'FILECACHEOPTIONS') loop
		execute immediate 'drop table '||r.owner||'.'||r.table_name;
	end loop;	
	for r in (select owner,job_name
				from dba_scheduler_jobs
			   where owner IN ('BOTB2','CSR','SUPPLIER','CSMART') and
			   	     job_name = 'EXPIREFILECACHE') loop
		dbms_scheduler.drop_job(
		   job_name => r.owner || '.' || r.job_name
		);
	end loop;
	for r in (select owner,object_name
				from all_objects
			   where owner IN ('BOTB2','CSR','SUPPLIER','CSMART') and
			   	     object_name = 'FILECACHE_PKG' and
			   	     object_type = 'PACKAGE') loop
		execute immediate 'drop package '||r.owner||'.'||r.object_name;
	end loop;
end;
/

@..\fileupload_pkg
@..\pending_pkg
@..\sheet_pkg
@..\template_pkg
@..\fileupload_body
@..\pending_body
@..\sheet_body
@..\template_body
@..\text\section_pkg
@..\text\section_body
@..\help\help_pkg
@..\help\help_body
alter session set current_schema="ACTIONS";
@..\actions\file_upload_pkg
@..\actions\file_upload_body
alter session set current_schema="DONATIONS";
@..\donations\letter_pkg
@..\donations\letter_body
alter session set current_schema="CSR";
@..\..\..\aspen2\tools\recompile_packages

@update_tail
