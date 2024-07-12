set serveroutput on

declare
	v_exists						number;
begin
	select count(*)
	  into v_exists
	  from all_tables
	 where UPPER(owner) = UPPER(SYS_CONTEXT('USERENV','SESSION_USER'))
	   and table_name = 'DISABLED_JOB';
	if v_exists = 0 then
		execute immediate 
			'create table disabled_job ('||chr(10)||
				'owner 		varchar2(300),'||chr(10)||
				'job_name 	varchar2(30),'||chr(10)||
				'constraint pk_disabled_job primary key (owner, job_name)'||chr(10)||
			')';
	end if;
end;
/

prompt enter 0 to disable jobs, 1 to enable
declare
	v_enabled						number := &1;

	procedure disable(
		in_job_name						in	varchar2
	) as
		e_not_running					exception;
		pragma exception_init(e_not_running, -27366);
	begin
		begin
			dbms_scheduler.stop_job(in_job_name);
		exception
			when e_not_running then
				null;
		end;
		dbms_scheduler.disable(in_job_name);
		dbms_output.put_line('Disabled ' || in_job_name);
	end;

	procedure disableAll
	as
	begin
		for r in (
			select owner, job_name
			  from dba_scheduler_jobs
			 where enabled = 'TRUE'
			   and owner not in (
					'ANONYMOUS', 'APEX_030200', 'APEX_PUBLIC_USER', 'APPQOSSYS', 'CTXSYS', 'DBSNMP', 'DIP', 'DMSYS',
					'EXFSYS', 'FLOWS_30000', 'FLOWS_FILES', 'LBACSYS', 'MDDATA', 'MDSYS', 'MGMT_VIEW', 'MTSSYS',
					'OLAPSYS', 'ORACLE_OCM', 'ORDDATA', 'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'OWBSYS', 'OWBSYS_AUDIT',
					'SI_INFORMTN_SCHEMA', 'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'SYS', 'SYSMAN',
					'SYSTEM', 'TSMSYS', 'WKPROXY', 'WKSYS', 'WK_TEST', 'WMSYS', 'XDB', 'XS$NULL'
			   )
		) loop
			dbms_output.put_line('disabling job '||r.owner||'.'||r.job_name);
			disable('"'||r.owner||'"."'||r.job_name||'"');
			insert into disabled_job (owner, job_name)
			values (r.owner, r.job_name);
			commit;
		end loop;
	end;
	
	procedure enableAll
	as
	begin
		for r in (
			select dj.owner, dj.job_name, case when j.owner is not null then 1 else 0 end job_exists
			  from disabled_job dj
			  left join dba_scheduler_jobs j on j.owner = dj.owner and j.job_name = dj.job_name
		) loop
			if r.job_exists = 1 then
				dbms_output.put_line('enabling job '||r.owner||'.'||r.job_name);
				dbms_scheduler.enable('"'||r.owner||'"."'||r.job_name||'"');
			else
				dbms_output.put_line('skipping deleted job '||r.owner||'.'||r.job_name);
			end if;
			delete from disabled_job
			 where owner = r.owner and job_name = r.job_name;
			commit;
		end loop;
	end;
begin
	if v_enabled = 0 then
		disableAll;
	else
		enableAll;
	end if;
end;
/

exit
