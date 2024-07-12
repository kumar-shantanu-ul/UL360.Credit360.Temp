define version=3215
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

ALTER TABLE csr.flow_alert_class ADD (
	allow_create	NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT CHK_FLOW_ALERT_CLASS_CREATE CHECK (ALLOW_CREATE IN (0, 1))
);

UPDATE csr.flow_alert_class
   SET allow_create = 0
 WHERE flow_alert_class IN ('regulation', 'requirement', 'permit', 'application', 'condition');

@..\compliance_body
@..\calc_body
@..\deleg_plan_body
@..\flow_body
@..\chain\company_filter_body
@..\form_body
@..\indicator_body



@update_tail
