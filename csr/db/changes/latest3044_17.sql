-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=17
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
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AQ'
	   AND source_region = 'US';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AU'
	   AND source_region = 'LG';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'BE'
	   AND source_region = 'WAL';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'BA'
	   AND source_region = 'BRC';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'CHD';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'DAL';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'DON';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'GGU';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'HNG';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'PIN';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'SQI';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'GSH';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'SUZ';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'FXI';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'XIA';
	 
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'IN'
	   AND source_region = 'BA';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'IN'
	   AND source_region = 'TG';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AE'
	   AND source_region = 'YZA';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'AE'
	   AND source_region = 'RUW';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'CN'
	   AND source_region = 'MAC';
	
	DELETE FROM CSR.COMPLIANCE_REGION_MAP
	 WHERE source_country = 'FR'
	   AND source_region = 'NC';
	
	UPDATE CSR.COMPLIANCE_REGION_MAP
	   SET REGION = NULL
	 WHERE source_country = 'CO'
	   AND source_region = 'BOG';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
