-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.EST_METER ADD (
	INACTIVE_DTM		DATE,
	FIRST_BILL_DTM		DATE
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description, 
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,		
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
		ms.realtime_metering, ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type,
		r.acquisition_dtm, r.disposal_dtm
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	UPDATE csr.plugin
	   SET cs_class = 'Credit360.Metering.Plugins.MeterCharacteristics'
	 WHERE js_class = 'Credit360.Metering.MeterCharacteristicsTab';
END;
/

BEGIN
	-- Sync the est_meter table with the region's active state
	FOR r IN (
		SELECT r.app_sid, r.region_sid, r.active, r.disposal_dtm
		  FROM csr.region r
		  JOIN csr.est_meter m ON m.app_sid = r.app_sid AND m.region_sid = r.region_sid
		 WHERE r.active != m.active
		    OR (r.disposal_dtm IS NULL AND m.inactive_dtm IS NOT NULL)
		    OR (r.disposal_dtm IS NOT NULL AND m.inactive_dtm IS NULL)
		    OR r.disposal_dtm != m.inactive_dtm
	) LOOP
		UPDATE csr.est_meter
		   SET active = r.active,
		       inactive_dtm = DECODE(r.active, 1, NULL, r.disposal_dtm)
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../space_pkg
@../region_pkg
@../energy_star_pkg

@../region_body
@../meter_body
@../property_body
@../space_body
@../energy_star_body
@../energy_star_job_body
@../energy_star_job_data_body

@update_tail
