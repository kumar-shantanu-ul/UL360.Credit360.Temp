-- Please update version.sql too -- this keeps clean builds in sync
define version=3234
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE VIEW csr.v$meter_reading_urjanet
AS
SELECT x.app_sid, x.region_sid, x.start_dtm, x.end_dtm, MAX(x.val_number) val_number, MAX(x.cost) cost,
	   LISTAGG(x.note, '; ') WITHIN GROUP (ORDER BY NULL) note
  FROM (
	-- Consumption + Cost (value part)
	SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm,
			CASE WHEN ip.LOOKUP_KEY='CONSUMPTION' THEN sd.consumption END val_number,
			CASE WHEN ip.LOOKUP_KEY='COST' THEN sd.consumption END cost, NULL note
	  FROM all_meter m
	  JOIN v$aggr_meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.region_sid
	  JOIN meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key IN ('CONSUMPTION', 'COST') AND sd.meter_input_id = ip.meter_input_id
	  JOIN meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
	-- Consumption + cost (distinct note part)
	UNION
	SELECT sd.app_sid, sd.region_sid, CAST(sd.start_dtm AS DATE) start_dtm, CAST(sd.end_dtm AS DATE) end_dtm, NULL val_number, NULL cost, sd.note
	  FROM all_meter m
	  JOIN csr.meter_source_data sd on sd.app_sid = m.app_sid AND sd.region_sid = m.region_sid
	  JOIN csr.meter_input ip on ip.app_sid = m.app_sid AND ip.lookup_key IN ('CONSUMPTION', 'COST') AND sd.meter_input_id = ip.meter_input_id
	  JOIN csr.meter_input_aggr_ind ai on ai.app_sid = m.app_sid AND ai.region_sid = m.region_sid AND ai.meter_input_id = ip.meter_input_id AND ai.aggregator = 'SUM'
 ) x
 GROUP BY x.app_sid, x.region_sid, x.start_dtm, x.end_dtm
;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\meter_body

@update_tail
