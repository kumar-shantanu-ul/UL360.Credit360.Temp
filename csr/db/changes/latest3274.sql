define version=3274
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


alter table csr.internal_audit_type add 
    involve_auditor_in_issues number(1,0) default 0 not null;
alter table csrimp.internal_audit_type add 
    involve_auditor_in_issues number(1,0) default 0 not null;
alter table csr.internal_audit_type add constraint chk_involve_auditor_in_issues check (involve_auditor_in_issues in (1,0));
alter table csrimp.internal_audit_type add constraint chk_involve_auditor_in_issues check (involve_auditor_in_issues in (1,0));










ALTER TABLE csr.est_conv_mapping DISABLE constraint FK_ESTMETCON_ESTCONMAP;
UPDATE csr.est_conv_mapping
   SET uom = 'Kilogram'
 WHERE meter_type = 'District Steam'
  AND uom = 'kg';
UPDATE csr.est_meter_conv
   SET uom = 'Kilogram'
 WHERE meter_type = 'District Steam'
  AND uom = 'kg';
ALTER TABLE csr.est_conv_mapping ENABLE constraint FK_ESTMETCON_ESTCONMAP;






@..\audit_pkg


@..\audit_body
@..\enable_body
@..\schema_body
@..\csrimp\imp_body
@..\issue_body
@..\issue_report_body
@..\quick_survey_report_body
@..\region_report_body



@update_tail
