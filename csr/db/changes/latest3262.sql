define version=3262
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


UPDATE csr.factor_type
   SET std_measure_id = (SELECT std_measure_id from csr.std_measure WHERE name = 'kg/m')
 WHERE name = 'Air Passenger Distance - International - Average Class (+8% uplift) (Direct)';


@..\user_profile_pkg
@..\meter_patch_pkg


@..\user_profile_body
@..\audit_body
@..\meter_body
@..\meter_patch_body



@update_tail
