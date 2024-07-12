-- Please update version.sql too -- this keeps clean builds in sync
define version=1637
@update_header

CREATE OR REPLACE VIEW csr.v$region_metric_region AS
    SELECT rmr.source_type_id, rmr.ind_sid, rmr.region_sid, rmr.measure_sid, NVL(mc.description, m.description) measure_description,
        NVL(i.format_mask, m.format_mask) format_mask, rmr.measure_conversion_id, i.description ind_description
      FROM region_metric_region rmr
      JOIN region_metric rm ON rmr.ind_sid = rm.ind_sid AND rmr.app_sid = rm.app_sid
      JOIN v$ind i ON rm.ind_sid = i.ind_sid AND rm.app_sid = i.app_sid
      JOIN measure m ON rmr.measure_sid = m.measure_sid AND rmr.app_sid = m.app_sid
      LEFT JOIN measure_conversion mc ON rmr.measure_conversion_id = mc.measure_conversion_id 
        AND rmr.measure_sid = mc.measure_sid AND rmr.app_sid = mc.app_sid;   
	   
@..\property_pkg
@..\property_body

@update_tail
