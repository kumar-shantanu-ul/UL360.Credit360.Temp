-- Please update version.sql too -- this keeps clean builds in sync
define version=123
@update_header

VARIABLE version NUMBER
BEGIN :version := 123; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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

alter table doc drop constraint fk_doc_version;
rename doc to doc_current;
alter table doc_current rename constraint pk_doc to pk_doc_current;
alter index pk_doc rename to pk_doc_current;
alter table doc_current add constraint fk_doc_version
foreign key (doc_id, version) references doc_version (doc_id, version);

create table doc (
	doc_id number(10) not null,
	constraint pk_doc primary key (doc_id)
	using index tablespace indx
);

insert into doc (doc_id)
	select distinct doc_id from doc_version;
	
alter table doc_version add constraint fk_doc_version_doc
foreign key (doc_id) references doc(doc_id);

create table doc_subscription (
	doc_id		number(10) not null references doc(doc_id),
	notify_sid	number(10) not null references csr_user(csr_user_sid),
	constraint pk_doc_subscription primary key (doc_id, notify_sid)
	using index tablespace indx
);
insert into doc_subscription (doc_id, notify_sid)
	select doc_id, notify_sid
	  from doc_notification;
drop table doc_notification;

create table doc_notification (
	doc_notification_id		number(10) not null,
	doc_id					number(10) not null,
	version					number(10) not null,
	notify_sid				number(10) not null references csr_user(csr_user_sid),
	sent_dtm				date,
	constraint pk_doc_notification primary key (doc_notification_id)
	using index tablespace indx
);
alter table doc_notification add constraint fk_doc_notification_version
foreign key (doc_id, version) references doc_version (doc_id, version);
create index ix_doc_notification_sent on doc_notification(sent_dtm, doc_notification_id);

create sequence doc_notification_id_seq;

create or replace view v$doc_current as
	select d.parent_sid, dv.doc_id, dv.version, dv.filename, dv.description, dv.change_description, 
		   dv.changed_by_sid, dv.changed_dtm, dd.doc_data_id, dd.data, dd.sha1, dd.mime_type, 
		   d.locked_by_sid
	  from doc_current d, doc_version dv, doc_data dd
	 where d.doc_id = dv.doc_id and d.version = dv.version and dv.doc_data_id = dd.doc_data_id;

create or replace view v$doc_folder_root as
	select dl.doc_library_sid, dl.documents_sid, dl.trash_folder_sid, t.sid_id doc_folder_sid from (
		select connect_by_root sid_id doc_library_sid, so.sid_id
	  	  from security.securable_object so
	           start with sid_id in (select doc_library_sid from doc_library dl)
	       	   connect by prior sid_id = parent_sid_id) t, doc_library dl
     where t.doc_library_sid = dl.doc_library_sid;

begin
	INSERT INTO ALERT_TYPE ( ALERT_TYPE_ID, DESCRIPTION, GET_DATA_SP, PARAMS_XML ) VALUES (19, 'Mail sent when a document in the document library is updated', NULL, 
		'<params>'||
			'<param name="BODY"/>'||
		'</params>'); 
	commit;
end;
/

DECLARE
	v_act_id	security_pkg.T_ACT_ID;
	v_class_id	security_pkg.T_CLASS_ID;
BEGIN
	user_pkg.LogonAuthenticated(security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, v_act_id);	
	class_pkg.CreateClass(v_act_id, class_pkg.GetClassId('Container'), 'DocLibrary', 'csr.doc_lib_pkg', null, v_class_id);
	COMMIT;
END;
/

begin
	update security.securable_object 
	   set class_id = class_pkg.GetClassId('DocLibrary')
	 where sid_id in (select doc_library_sid from doc_library);
	commit;
end;
/

@..\doc_pkg
@..\doc_folder_pkg
@..\doc_lib_pkg
@..\doc_body
@..\doc_folder_body
@..\doc_lib_body
@..\..\..\aspen2\tools\recompile_packages
grant execute on doc_lib_pkg to security;

UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT

@update_tail
