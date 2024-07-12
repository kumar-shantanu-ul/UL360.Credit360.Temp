define version=3260
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


ALTER TABLE CSR.CUSTOMER ADD CHART_ALGORITHM_VERSION NUMBER(10);
ALTER TABLE CSRIMP.CUSTOMER ADD CHART_ALGORITHM_VERSION NUMBER(1);










INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (64, 'Chart Algorithm Version', 'Algorithm for DE charts', 'ChartAlgorithmVersion', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos) VALUES (64, 'Version (1 (default), 2)', 'The version to use.', 0);






@..\..\..\aspen2\cms\db\form_pkg
@..\util_script_pkg


@..\..\..\aspen2\cms\db\form_body
@..\customer_body
@..\schema_body
@..\util_script_body
@..\csrimp\imp_body



@update_tail
