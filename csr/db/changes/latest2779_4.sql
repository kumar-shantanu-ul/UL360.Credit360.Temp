--Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=4
@update_header

-- FB72374 Remove ind_detail from view as it more than doubled the time taken to get property details
CREATE OR REPLACE FORCE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description, 
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,		
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
		ms.realtime_metering, ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_ind_id, r.active, r.region_type
	  FROM all_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_ind mi ON a.meter_ind_id = mi.meter_ind_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;

-- Added it directly to the GetProperty() stored procedure in property_pkg
@..\property_body
	
@update_tail
