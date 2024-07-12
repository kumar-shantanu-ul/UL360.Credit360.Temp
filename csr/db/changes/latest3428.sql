define version=3428
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



ALTER TABLE csr.auto_exp_class_qc_settings ADD encoding_name VARCHAR2(255);
BEGIN
	security.user_pkg.logonadmin;
	UPDATE csr.auto_exp_class_qc_settings SET encoding_name = 'Windows-1252';
END;
/










INSERT INTO csr.gresb_indicator(gresb_indicator_id, gresb_indicator_type_id, title, format, description, unit, std_measure_conversion_id)
	VALUES (1162,1,'asset_ownership','Decimal','Percentage of the asset owned by the reporting entity.','%',NULL);
	
UPDATE csr.gresb_indicator SET gresb_indicator_type_id = 7 WHERE gresb_indicator_id = 1162;






@..\automated_export_pkg


@..\automated_export_body
@..\chain\company_body
@..\deleg_plan_body
@..\non_compliance_report_body



@update_tail
