-- Please update version.sql too -- this keeps clean builds in sync
define version=2786
define minor_version=0
@update_header

declare
	v_exists NUMBER;
begin
	select count(*)
	  into v_exists 
	  from all_constraints 
	 where constraint_name = 'FK_ISSUE_TYPE' and owner = 'CSRIMP' and table_name = 'INTERNAL_AUDIT_TYPE_GROUP';

	if v_exists = 1 then
		execute immediate 'alter table csrimp.internal_audit_type_group drop constraint fk_issue_type';
	end if;
end;
/

DECLARE
  v_exists NUMBER;
  v_sql VARCHAR2(1024);
BEGIN
    SELECT COUNT(*) 
      INTO v_exists 
      FROM all_tab_cols 
     WHERE column_name = 'NAME' 
       AND table_name = 'DELEGATION_LAYOUT'
       AND owner = 'CSRIMP';
     
    IF v_exists = 0 THEN
		for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION' and temporary='N') loop
			--dbms_output.put_line('tab '||r.table_name);
			execute immediate 'truncate table csrimp.'||r.table_name;
		end loop;

        EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.DELEGATION_LAYOUT ADD NAME VARCHAR2(255) NOT NULL';
    END IF;
END;
/

@../schema_body
@../csrimp/imp_body

@update_tail
