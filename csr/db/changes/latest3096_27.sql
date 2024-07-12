-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	-- Update affected meters to generic "other" types
	-- (there were onlt 2 affected meters on live at the time of writing this script)
	UPDATE csr.est_meter
	   SET meter_type = 'Other - Indoor'
	 WHERE meter_type = 'Alternative Water Generated On-Site - Indoor';

	UPDATE csr.est_meter
	   SET meter_type = 'Other - Mixed Indoor/Outdoor (Water)'
	 WHERE meter_type = 'Alternative Water Generated On-Site - Mixed Indoor/Outdoor';

	UPDATE csr.est_meter
	   SET meter_type = 'Other - Outdoor'
	 WHERE meter_type = 'Alternative Water Generated On-Site - Outdoor';

	-- Remove the old meter type mappings
	DELETE FROM csr.est_conv_mapping
	 WHERE meter_type IN (
	 	'Alternative Water Generated On-Site - Indoor',
	 	'Alternative Water Generated On-Site - Mixed Indoor/Outdoor',
	 	'Alternative Water Generated On-Site - Outdoor'
	 );

	DELETE FROM csr.est_meter_type_mapping
	 WHERE meter_type IN (
	 	'Alternative Water Generated On-Site - Indoor',
	 	'Alternative Water Generated On-Site - Mixed Indoor/Outdoor',
	 	'Alternative Water Generated On-Site - Outdoor'
	 );

	-- Insert the new meter types
	INSERT INTO csr.est_meter_type (meter_type) 
	VALUES ('Well Water - Indoor');

	INSERT INTO csr.est_meter_type (meter_type) 
	VALUES ('Well Water - Mixed Indoor/Outdoor');
	
	INSERT INTO csr.est_meter_type (meter_type) 
	VALUES ('Well Water - Outdoor');

	-- Switch out the conversions, use them for the new meter types as the
	-- UOMs are the same for the new meter types as the ones being removed
	UPDATE csr.est_meter_conv 
	   SET meter_type = 'Well Water - Indoor' 
	 WHERE meter_type = 'Alternative Water Generated On-Site - Indoor';

	UPDATE csr.est_meter_conv 
	   SET meter_type = 'Well Water - Mixed Indoor/Outdoor' 
	 WHERE meter_type = 'Alternative Water Generated On-Site - Mixed Indoor/Outdoor';

	UPDATE csr.est_meter_conv 
	   SET meter_type = 'Well Water - Outdoor' 
	 WHERE meter_type = 'Alternative Water Generated On-Site - Outdoor';

	-- Remove the old meter types
	DELETE FROM csr.est_meter_type
	 WHERE meter_type IN (
	 	'Alternative Water Generated On-Site - Indoor',
	 	'Alternative Water Generated On-Site - Mixed Indoor/Outdoor',
	 	'Alternative Water Generated On-Site - Outdoor'
	 );
END;
/

BEGIN
	-- Remove disused metrics (we might not have all of these in our system)
	DELETE FROM csr.est_building_metric_mapping
	 WHERE metric_name IN (
	 	'alternativeWaterGeneratedOnsiteMixedUse',
	 	'alternativeWaterGeneratedOnsiteTotalUse',
	 	'alternativeWaterGeneratedOnsiteIndoorUse',
	 	'alternativeWaterGeneratedOnsiteOutdoorUse',
	 	'alternativeWaterGeneratedOnsiteTotalCost',
	 	'alternativeWaterGeneratedOnsiteMixedCost',
	 	'alternativeWaterGeneratedOnsiteIndoorCost',
	 	'alternativeWaterGeneratedOnsiteOutdoorCost',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteMixedUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteIndoorUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteOutdoorUse'
	);

	DELETE FROM csr.est_attr_for_building
	 WHERE attr_name IN (
	 	'alternativeWaterGeneratedOnsiteMixedUse',
	 	'alternativeWaterGeneratedOnsiteTotalUse',
	 	'alternativeWaterGeneratedOnsiteIndoorUse',
	 	'alternativeWaterGeneratedOnsiteOutdoorUse',
	 	'alternativeWaterGeneratedOnsiteTotalCost',
	 	'alternativeWaterGeneratedOnsiteMixedCost',
	 	'alternativeWaterGeneratedOnsiteIndoorCost',
	 	'alternativeWaterGeneratedOnsiteOutdoorCost',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteMixedUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteIndoorUse',
	 	'estimatedDataFlagAlternativeWaterGeneratedOnSiteOutdoorUse'
	);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
