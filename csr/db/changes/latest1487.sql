-- Please update version.sql too -- this keeps clean builds in sync
define version=1487
@update_header

INSERT INTO csr.factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
VALUES (7167, 442, 'Common / Domestic', 1, 0);

INSERT INTO csr.factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
VALUES (7168, 442, 'Compostable Waste', 1, 0);

INSERT INTO csr.factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
VALUES (7169, 442, 'Dangerous / Industrial', 1, 0);

INSERT INTO csr.factor_type (factor_type_id, parent_id, name, std_measure_id, egrid)
VALUES (7170, 442, 'Sewage Sludge', 1, 0);

BEGIN
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63190,20,7167,3,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.945,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63191,20,7167,1,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63192,20,7167,2,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.945,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63193,20,7167,4,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63194,20,7168,3,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.084,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63195,20,7168,1,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63196,20,7168,2,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.084,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63197,20,7168,4,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.093,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63198,20,7169,3,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.945,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63199,20,7169,1,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63200,20,7169,2,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.945,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63201,20,7169,4,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63202,20,7170,3,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.315,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63203,20,7170,1,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63204,20,7170,2,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0.315,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63205,20,7170,4,NULL,NULL,NULL,2357,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,0,NULL);
END;
/

@update_tail
