-- Please update version.sql too -- this keeps clean builds in sync
define version=978
@update_header


ALTER TABLE CSR.METER_RAW_DATA_SOURCE ADD (
    ORPHAN_COUNT          NUMBER(10, 0),
    MATCHED_COUNT         NUMBER(10, 0)
);

ALTER TABLE CSR.METER_RAW_DATA ADD (
    ORPHAN_COUNT          NUMBER(10, 0),
    MATCHED_COUNT         NUMBER(10, 0)
);

CREATE INDEX CSR.IDX_METER_LIVE_RAWDATA ON CSR.METER_LIVE_DATA(APP_SID, REGION_SID, LIVE_DATA_DURATION_ID, METER_RAW_DATA_ID);
CREATE INDEX CSR.IDX_ORPHAN_RAWDATA ON CSR.METER_ORPHAN_DATA(APP_SID, SERIAL_ID, METER_RAW_DATA_ID);
CREATE INDEX CSR.IDX_MTRSRC_RAWDATA ON CSR.METER_SOURCE_DATA(APP_SID, REGION_SID, METER_RAW_DATA_ID);


@../meter_monitor_pkg
@../meter_monitor_body

-- Update orpahn/matched counts for 
-- existing data sources and raw data
SET SERVEROUTPUT ON
BEGIN
	FOR h IN (
		SELECT DISTINCT host
		  FROM csr.customer cu, csr.meter_raw_data_source rds
		 WHERE cu.app_sid = rds.app_sid
	) LOOP
		dbms_output.put_line('Processing '||h.host);
		security.user_pkg.logonadmin(h.host);
		
		-- Update data source
		UPDATE csr.meter_raw_data_source rdsu
		   SET (orphan_count, matched_count) = 
		   (
		   		SELECT MAX(orphan_count), MAX(matched_count)
				  FROM (
				  SELECT ds.raw_data_source_id, COUNT(DISTINCT od.serial_id) orphan_count, NULL matched_count
				    FROM csr.meter_raw_data_source ds, csr.meter_raw_data rd, csr.meter_orphan_data od
				   WHERE ds.app_sid = SYS_CONTEXT('SECURITY','APP')
				     AND rd.raw_data_source_id(+) = ds.raw_data_source_id
				     AND od.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP')
				     AND od.meter_raw_data_id(+) = rd.meter_raw_data_id
				      GROUP BY NULL, ds.raw_data_source_id
				  UNION
				  SELECT ds.raw_data_source_id, NULL orphan_count, COUNT(DISTINCT sd.region_sid) matched_count
				    FROM csr.meter_raw_data_source ds, csr.meter_raw_data rd, csr.meter_source_data sd
				   WHERE ds.app_sid = SYS_CONTEXT('SECURITY','APP')
				     AND rd.raw_data_source_id(+) = ds.raw_data_source_id
				     AND sd.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP')
				     AND sd.meter_raw_data_id(+) = rd.meter_raw_data_id
				      GROUP BY NULL, ds.raw_data_source_id
				) x
				WHERE rdsu.raw_data_source_id = x.raw_data_source_id
				GROUP BY raw_data_source_id
			);
			
		-- Update raw data
		UPDATE csr.meter_raw_data rdu
		   SET (orphan_count, matched_count) = 
		   (
			SELECT MAX(orphan_count) orphan_count, MAX(matched_count) matched_count
			  FROM ( 
				SELECT rd.meter_raw_data_id, COUNT(DISTINCT od.serial_id) orphan_count, NULL matched_count
				  FROM csr.meter_raw_data rd, csr.meter_orphan_data od 
				 WHERE rd.app_sid = SYS_CONTEXT('SECURITY', 'APP') 
				   AND od.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP') 
				   AND od.meter_raw_data_id(+) = rd.meter_raw_data_id  
					GROUP BY NULL, rd.meter_raw_data_id
				UNION 
				SELECT rd.meter_raw_data_id, NULL orphan_count, COUNT(DISTINCT sd.region_sid) matched_count
				  FROM csr.meter_raw_data rd, csr.meter_source_data sd 
				 WHERE rd.app_sid = SYS_CONTEXT('SECURITY', 'APP')
				   AND sd.app_sid(+) = SYS_CONTEXT('SECURITY', 'APP') 
				   AND sd.meter_raw_data_id(+) = rd.meter_raw_data_id
					GROUP BY NULL, rd.meter_raw_data_id
			) x 
			WHERE rdu.meter_raw_data_id = x.meter_raw_data_id
			GROUP BY meter_raw_data_id
		);
		
		security.user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

@update_tail
