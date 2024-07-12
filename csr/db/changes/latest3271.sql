define version=3271
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/












UPDATE csr.util_script
   SET description = '[CHECK WITH DEV/INFRASTRUCTURE BEFORE USE] - Sets the number of years to bound calculation "end of time". Updates Calc End Dtm.'
 WHERE util_script_id = 40;
INSERT INTO CSR.ISSUE_ACTION_TYPE (ISSUE_ACTION_TYPE_ID, DESCRIPTION) VALUES (24, 'Deleted');






@..\audit_pkg
@..\csr_data_pkg


@..\util_script_body
@..\audit_body
@..\issue_body



@update_tail
