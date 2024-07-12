-- Please update version.sql too -- this keeps clean builds in sync
define version=1470
@update_header

CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.region_sid, a.reference, r.description, r.parent_sid, a.note,
			a.primary_ind_sid, i.description primary_description, NVL(mc.description, m.description) primary_measure, a.primary_measure_conversion_id,
			ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
			ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
			ms.realtime_metering, ms.show_in_meter_list
		  FROM all_meter a
			JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
			JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
			JOIN v$ind i ON a.primary_ind_sid = i.ind_sid AND a.app_sid = i.app_sid
			JOIN measure m ON i.measure_sid = m.measure_sid AND i.app_sid = m.app_sid
			LEFT JOIN measure_conversion mc ON a.primary_measure_conversion_id = mc.measure_conversion_id AND a.app_sid = mc.app_sid;
            

@update_tail
