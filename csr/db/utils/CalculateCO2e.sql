DECLARE
	v_a		NUMBER;
BEGIN
	FOR r in (
		SELECT std_factor_set_id, factor_type_id, geo_country, geo_region, egrid_ref, start_dtm, end_dtm, std_factor_id,
				CO2, CO2e, CH4, N2O,
				COALESCE(CO2_measure_conv_id, CO2e_measure_conv_id, CH4_measure_conv_id, N2O_measure_conv_id) std_measure_conversion_id
		  FROM (
				SELECT std_factor_set_id, factor_type_id, geo_country, geo_region, egrid_ref, start_dtm, end_dtm,
						SUM(CO2) CO2, SUM(CO2e) CO2e, SUM(CH4) CH4, SUM(N2O) N2O, SUM(std_factor_id) std_factor_id,
						SUM(CO2_measure_conv_id) CO2_measure_conv_id, SUM(CO2e_measure_conv_id) CO2e_measure_conv_id,
						SUM(CH4_measure_conv_id) CH4_measure_conv_id, SUM(N2O_measure_conv_id) N2O_measure_conv_id
				  FROM (
						SELECT std_factor_set_id, factor_type_id, geo_country, geo_region, egrid_ref, start_dtm, end_dtm,
								CASE gas_type_id WHEN 1 THEN value / a ELSE NULL END CO2,
								CASE gas_type_id WHEN 2 THEN value / a ELSE NULL END CO2e,
								CASE gas_type_id WHEN 3 THEN value / a ELSE NULL END CH4,
								CASE gas_type_id WHEN 4 THEN value / a ELSE NULL END N2O,
								CASE gas_type_id WHEN 1 THEN sf.std_measure_conversion_id ELSE NULL END CO2_measure_conv_id,
								CASE gas_type_id WHEN 2 THEN sf.std_measure_conversion_id ELSE NULL END CO2e_measure_conv_id,
								CASE gas_type_id WHEN 3 THEN sf.std_measure_conversion_id ELSE NULL END CH4_measure_conv_id,
								CASE gas_type_id WHEN 4 THEN sf.std_measure_conversion_id ELSE NULL END N2O_measure_conv_id,
								CASE gas_type_id WHEN 2 THEN sf.std_factor_id ELSE NULL END std_factor_id
						  FROM std_factor sf
						  JOIN std_measure_conversion smc ON sf.std_measure_conversion_id = smc.std_measure_conversion_id
				)
				 GROUP BY std_factor_set_id, factor_type_id, geo_country, geo_region, egrid_ref, start_dtm, end_dtm
		)
		 WHERE std_factor_set_id = 7
	)
	LOOP
		SELECT a
		  INTO v_a
		  FROM std_measure_conversion
		 WHERE std_measure_conversion_id = r.std_measure_conversion_id;
		
		IF r.std_factor_id IS NULL THEN
			INSERT INTO std_factor (std_factor_id, std_factor_set_id, factor_type_id, gas_type_id, start_dtm, end_dtm, geo_country, geo_region, value, note, std_measure_conversion_id, egrid_ref)
				VALUES (std_factor_id_seq.nextval, r.std_factor_set_id, r.factor_type_id, 2, r.start_dtm, r.end_dtm, r.geo_country, r.geo_region, (NVL(r.CO2, 0) + 21 * NVL(r.CH4, 0) + 310 * NVL(r.N2O, 0)) / v_a, 'Calculated as CO2 + 21CH_4 + 310N_20', r.std_measure_conversion_id, r.egrid_ref);
		ELSE
			UPDATE std_factor
			   SET value = (NVL(r.CO2, 0) + 21 * NVL(r.CH4, 0) + 310 * NVL(r.N2O, 0)) * v_a,
					note = 'Calculated as CO2 + 21CH_4 + 310N_20'
			 WHERE std_factor_id = r.std_factor_id;
		END IF;
	END LOOP;
END;
/
