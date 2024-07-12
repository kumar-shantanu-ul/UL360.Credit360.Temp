-- Please update version.sql too -- this keeps clean builds in sync
define version=1488
@update_header

-- Insert the DEFTRA 2012 factor set if it doesn't already exist.
BEGIN
	INSERT INTO csr.std_factor_set (std_factor_set_id, name)
	VALUES (15, 'DEFRA 2012');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

INSERT INTO csr.factor_type (factor_type_id, name, std_measure_id, egrid, parent_id)
VALUES (7171, 'Wood Pellets', 1, 0, 5);

BEGIN
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63206,15,7171,3,NULL,NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,107.1,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63207,15,7171,1,NULL,NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,1904,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63208,15,7171,2,NULL,NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,2032.18,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63209,15,7171,4,NULL,NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,21.08,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63210,20,7171,3,'br',NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,81.7682,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63211,20,7171,1,'br',NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,1453.657,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63212,20,7171,2,'br',NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,97.86227,NULL);
	INSERT INTO csr.std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, geo_country, geo_region, egrid_ref, std_measure_conversion_id, start_dtm, end_dtm, value, note) VALUES (63213,20,7171,4,'br',NULL,NULL,2,TO_DATE('2000-01-01 00:00:00', 'yyyy-mm-dd hh24:mi:ss'),NULL,16.09406,NULL);
END;
/

@update_tail
