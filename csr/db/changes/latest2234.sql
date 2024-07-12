-- Please update version.sql too -- this keeps clean builds in sync
define version=2234
@update_header

begin
	for r in (select 1 from all_Tables where owner='CSRIMP' and table_name='TEMP_ROLE_MAP') loop
		dbms_output.put_line('drop table csrimp.temp_role_map');
		execute immediate 'drop table csrimp.temp_role_map';
	end loop;
end;
/

delete from csrimp.non_compliance_file where csrimp_session_id not in (select csrimp_session_id from csrimp.csrimp_session);

begin
	for r in (select 1 from all_constraints where owner='CSRIMP' and table_name='NON_COMPLIANCE_FILE' and constraint_name='FK_NON_COMPLIANCE_FILE_IS') loop
		execute immediate 'alter table CSRIMP.NON_COMPLIANCE_FILE drop constraint FK_NON_COMPLIANCE_FILE_IS';
	end loop;
end;
/

ALTER TABLE CSRIMP.NON_COMPLIANCE_FILE ADD
    CONSTRAINT FK_NON_COMPLIANCE_FILE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE;

declare
	v_exists number;
	v_sql varchar2(4000);
begin
	select count(*)
	  into v_exists
	  from all_tables
	 where owner='CSRIMP'
	   and table_name = 'SUPERADMIN_FOLDER';
	if v_exists = 0 then
		v_sql := '
CREATE TABLE CSRIMP.SUPERADMIN_FOLDER (
    CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') NOT NULL,
	CSR_USER_SID					NUMBER(10) 		NOT NULL,
	SID_ID							NUMBER(10) 		NOT NULL,
	NAME							VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_SUPERADMIN_FOLDER PRIMARY KEY (CSRIMP_SESSION_ID, SID_ID),
    CONSTRAINT FK_SUPERADMIN_FOLDER_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)';
		execute immediate v_sql;
	end if;
end;
/

grant insert,select,update,delete on csrimp.superadmin_folder to web_user;

@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
