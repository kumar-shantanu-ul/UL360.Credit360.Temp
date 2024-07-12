define version=3323
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


DELETE FROM csr.emission_factor_profile_factor pf
 WHERE (pf.app_sid, pf.profile_id, pf.factor_type_id) IN (
	SELECT pf.app_sid, pf.profile_id, pf.factor_type_id
	  FROM csr.emission_factor_profile_factor pf
	  JOIN csr.factor_type ft ON ft.factor_type_id = pf.factor_type_id
	 WHERE ft.std_measure_id IS NULL
);



@..\audit_body


@update_tail
