define version=3318
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE CSR.INITIATIVES_OPTIONS MODIFY (
    METRICS_END_YEAR              NUMBER(10, 0)     DEFAULT 2030
);


GRANT EXECUTE ON actions.file_upload_pkg TO CSR;

@@latest3316_2_packages

DECLARE
  out_cur security.security_pkg.T_OUTPUT_CUR;
BEGIN
	-- ~175 records at 28.08.2020, will increase daily
  FOR apps IN (
		SELECT app_sid, host
		  FROM csr.customer
		 WHERE app_sid IN (10016697, 27503257, 49728743) -- Process jmfamily, Hyatt, lendlease. Ignore BritishLand, Danske Bank, hm, UL
	)
  LOOP
    security.user_pkg.logonadmin(apps.host);
    FOR r IN (
      SELECT meter_raw_data_id
        FROM csr.meter_raw_data
       WHERE 
           orphan_count != 0 AND
           meter_raw_data_id >= 2846459 --i.e. where received_dtm > DATE '2020-06-26' or thereabouts
    )
    LOOP
      dbms_output.put_line(r.meter_raw_data_id);
      csr.temp_meter_monitor_pkg.ResubmitRawData(r.meter_raw_data_id, out_cur);
    END LOOP;
    security.user_pkg.logonadmin();
	END LOOP;
END;
/
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (46, 'Metrics End Year', 1, '(e.g. 2030)');
DELETE FROM csr.emission_factor_profile_factor
 WHERE (app_sid, profile_id, factor_type_id, custom_factor_set_id, region_sid, geo_country) IN (
	SELECT efpf.app_sid, efpf.profile_id, efpf.factor_type_id, efpf.custom_factor_set_id, efpf.region_sid, efpf.geo_country
      FROM csr.emission_factor_profile_factor efpf
      LEFT JOIN csr.factor f ON f.factor_type_id = efpf.factor_type_id AND f.region_sid = efpf.region_sid
     WHERE efpf.region_sid IS NOT NULL 
	   AND f.factor_type_id IS NULL
	);

DROP PACKAGE csr.temp_meter_monitor_pkg;

@..\deleg_plan_pkg
@..\region_pkg
@..\unit_test_pkg
@..\enable_pkg
@..\initiative_pkg


@..\deleg_plan_body
@..\region_body
@..\unit_test_body
@..\enable_body
@..\initiative_body
@..\quick_survey_report_body
@..\chain\company_body
@..\chain\company_filter_body
@..\issue_report_body



@update_tail
