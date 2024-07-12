define version=3248
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

ALTER TABLE csrimp.issue_type MODIFY region_is_mandatory DEFAULT NULL;

INSERT INTO CSR.FACTOR_TYPE (FACTOR_TYPE_ID,NAME,STD_MEASURE_ID,EGRID,PARENT_ID) VALUES (15890, 'Stationary Fuel - Biodiesel (from used cooking oil) (Energy - GCV/HHV) (Upstream)', 9, 0, 7179);

@..\region_body
@..\region_tree_body
@..\tag_body
@..\chain\company_body
@..\chain\company_dedupe_body
@..\supplier_body

@update_tail
