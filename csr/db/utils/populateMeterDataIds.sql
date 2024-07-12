BEGIN
	-- 
	FOR r IN (
		SELECT DISTINCT app_sid, region_sid
		  FROM csr.meter_live_data
		 WHERE meter_data_id IS NULL
	) LOOP
		-- Cases where an id exists in meter_data_id
		FOR d IN (
			SELECT id.app_sid, id.region_sid, id.meter_bucket_id, id.meter_input_id, 
				id.aggregator, id.priority, id.start_dtm, id.meter_data_id
			  FROM csr.meter_live_data l
			  JOIN csr.meter_data_id id
			    ON id.app_sid = l.app_sid
			   AND id.region_sid = l.region_sid
			   AND id.meter_bucket_id = l.meter_bucket_id
			   AND id.meter_input_id = l.meter_input_id
			   AND id.aggregator = l.aggregator
			   AND id.priority = l.priority
			   AND id.start_dtm = l.start_dtm
			 WHERE l.app_sid = r.app_sid
			   AND l.region_Sid = r.region_sid
			   AND l.meter_data_id IS NULL
		) LOOP
			UPDATE csr.meter_live_data
			   SET meter_data_id = d.meter_data_id
			 WHERE app_sid = d.app_sid
			   AND region_sid = d.region_sid
			   AND meter_bucket_id = d.meter_bucket_id
			   AND meter_input_id = d.meter_input_id
			   AND aggregator = d.aggregator
			   AND priority = d.priority
			   AND start_dtm = d.start_dtm
			   AND meter_data_id IS NULL;
		END LOOP;

		-- Cases where there's no id in meter_data_id
		FOR d IN (
			SELECT l.app_sid, l.region_sid, l.meter_bucket_id, l.meter_input_id, 
				l.aggregator, l.priority, l.start_dtm
			  FROM csr.meter_live_data l
			 WHERE l.app_sid = r.app_sid
			   AND l.region_Sid = r.region_sid
			   AND l.meter_data_id IS NULL
			   AND NOT EXISTS (
				SELECT 1
				  FROM csr.meter_data_id id
				 WHERE id.app_sid = l.app_sid
				   AND id.region_sid = l.region_sid
				   AND id.meter_bucket_id = l.meter_bucket_id
				   AND id.meter_input_id = l.meter_input_id
				   AND id.aggregator = l.aggregator
				   AND id.priority = l.priority
				   AND id.start_dtm = l.start_dtm
			)
		) LOOP
			UPDATE csr.meter_live_data
			   SET meter_data_id = csr.meter_data_id_seq.NEXTVAL
			 WHERE app_sid = d.app_sid
			   AND region_sid = d.region_sid
			   AND meter_bucket_id = d.meter_bucket_id
			   AND meter_input_id = d.meter_input_id
			   AND aggregator = d.aggregator
			   AND priority = d.priority
			   AND start_dtm = d.start_dtm
			   AND meter_data_id IS NULL;
		END LOOP;

		-- Commit per region
		COMMIT;
	END LOOP;
END;
/
