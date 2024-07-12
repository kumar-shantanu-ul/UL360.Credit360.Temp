-- Please update version.sql too -- this keeps clean builds in sync
define version=108
@update_header

VARIABLE version NUMBER
BEGIN :version := 108; END; -- CHANGE THIS TO MATCH VERSION NUMBER
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




ALTER TABLE AUDIT_TYPE_OBJECT_CLASS RENAME TO AUDIT_TYPE_GROUP;

alter table audit_type_group rename column AUDIT_TYPE_OBJECT_CLASS_ID to audit_type_group_id;

alter table audit_type rename column AUDIT_TYPE_OBJECT_CLASS_ID to audit_type_group_id;

alter table audit_type modify audit_type_group_id null;

create table audit_type_copy as select * from audit_type;

update audit_type set audit_type_group_id = null;

create table audit_type_group_copy as select * from audit_type_group;

delete from audit_type_group;

alter table audit_type_group modify audit_type_group_id number(10);

insert into audit_type_group select * from audit_type_group_copy;

drop table audit_type_group_copy purge;

update audit_type set audit_type_group_id = (select audit_type_group_id from audit_type_copy where audit_type.audit_type_id = audit_type_copy.audit_type_id);

alter table audit_type modify audit_type_group_id not null;

drop table audit_type_copy purge;

alter table audit_type_group drop column name;


UPDATE csr.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT



@update_tail
