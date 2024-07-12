-- Please update version.sql too -- this keeps clean builds in sync
define version=3131
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW CSR.V$METER_TYPE AS
	SELECT
		mi.app_sid,
		mi.meter_type_id,
		mi.label,
		iip.ind_sid consumption_ind_sid,
		ciip.ind_sid cost_ind_sid,
		mi.group_key,
		mi.days_ind_sid,
		mi.costdays_ind_sid
	 FROM meter_type mi
	-- Legacy consumption if available
	 LEFT JOIN csr.meter_input ip ON ip.app_sid = mi.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 LEFT JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 LEFT JOIN csr.meter_type_input iip ON iip.app_sid = mi.app_sid AND iip.meter_type_id = mi.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 -- Legacy cost if available
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = mi.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = mi.app_sid AND ciip.meter_type_id = mi.meter_type_id AND ciip.meter_input_id = ciag.meter_input_id
;

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../meter_body

@update_tail
