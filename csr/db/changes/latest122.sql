-- Please update version.sql too -- this keeps clean builds in sync
define version=122
@update_header

VARIABLE version NUMBER
BEGIN :version := 122; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

declare
	v_cons_name user_constraints.constraint_name%TYPE;
begin
	select constraint_name
	  into v_cons_name
	  from user_constraints where owner='CSR' AND table_name='DOC_LIBRARY' and r_constraint_name='PK_DOC_FOLDER';
	execute immediate 'alter table doc_library drop constraint '||v_cons_name;
end;
/

alter table doc_library add documents_sid number(10) references doc_folder(doc_folder_sid);
alter table doc_library add trash_folder_sid number(10);


create or replace view v$doc_folder_root as
	select dl.doc_library_sid, t.documents_sid, dl.trash_folder_sid, t.sid_id from (
		select connect_by_root sid_id documents_sid, so.sid_id
	  	  from security.securable_object so
	           start with sid_id in (select documents_sid from doc_library dl)
	       	   connect by prior sid_id = parent_sid_id) t, doc_library dl
     where t.documents_sid = dl.documents_sid;

create or replace view v$doc_current as
	select d.parent_sid, dv.doc_id, dv.version, dv.filename, dv.description, dv.change_description, 
		   dv.changed_by_sid, dv.changed_dtm, dd.doc_data_id, dd.data, dd.sha1, dd.mime_type, 
		   d.locked_by_sid
	  from doc d, doc_version dv, doc_data dd
	 where d.doc_id = dv.doc_id and d.version = dv.version and dv.doc_data_id = dd.doc_data_id;


declare
	v_act_id security_pkg.t_act_id;
	v_name security_pkg.t_so_name;
	v_lib_sid_id security_pkg.t_sid_id;
	v_trash_sid_id security_pkg.t_sid_id;
begin
	user_pkg.logonauthenticated(security_pkg.sid_builtin_administrator,600,v_act_id);
	for r in (select doc_library_sid, so.parent_sid_id, so.name
				from doc_library dl, security.securable_object so
			   where so.sid_id = dl.doc_library_sid) loop
		securableobject_pkg.createso(v_act_id, r.parent_sid_id, security_pkg.SO_CONTAINER, user_pkg.GenerateACT(), v_lib_sid_id);
		securableobject_pkg.moveso(v_act_id, r.doc_library_sid, v_lib_sid_id);
		securableobject_pkg.createso(v_act_id, v_lib_sid_id, security_pkg.SO_CONTAINER, 'Trash', v_trash_sid_id);
		insert into doc_folder (doc_folder_sid, description)
		values (v_trash_sid_id, empty_clob());
		update doc_library
		   set trash_folder_sid = v_trash_sid_id, documents_sid = r.doc_library_sid, doc_library_sid = v_lib_sid_id
		 where doc_library_sid = r.doc_library_sid;
		securableobject_pkg.renameso(v_act_id, v_lib_sid_id, r.name);
	end loop;
	commit;
end;
/

alter table doc_library modify documents_sid not null;
alter table doc_library modify trash_folder_sid not null;

create global temporary table temp_translations
(
	original	varchar2(4000) not null,
	translated	varchar2(4000) not null
) on commit delete rows;

create global temporary table temp_tree (
	sid_id 			number(10),
	parent_sid_id	number(10),
	dacl_id			number(10),
	sacl_id			number(10),
	class_id		number(10),
	name			varchar2(255),
	flags			number(10),
	owner			number(10),
	so_level		number(10),
	is_leaf			number(1),
	path			varchar2(4000)
) on commit delete rows;

create global temporary table temp_mime_types
(
	mime_type		varchar2(100)
) on commit delete rows;

create index ix_doc_search on doc_data(data) indextype is ctxsys.context
parameters('datastore ctxsys.default_datastore stoplist ctxsys.empty_stoplist');

DECLARE
    job BINARY_INTEGER;
BEGIN
    -- now and every day afterwards
    -- 10g w/low_priority_job created
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'doclib_text',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'ctx_ddl.sync_index(''ix_doc_search'');',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 01:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=MINUTELY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise doclib text indexes');
       COMMIT;
END;
/


@..\doc_pkg
@..\doc_body
@..\doc_folder_pkg
@..\doc_folder_body

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
