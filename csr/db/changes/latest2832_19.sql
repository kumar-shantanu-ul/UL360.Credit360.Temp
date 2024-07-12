-- Please update version.sql too -- this keeps clean builds in sync
define version=2832
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.PLUGIN ADD (
	USE_REPORTING_PERIOD    	NUMBER(10) DEFAULT 0
);

	
ALTER TABLE CSRIMP.PLUGIN ADD (	
	USE_REPORTING_PERIOD    	NUMBER(10) DEFAULT 0
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.plugin
   SET use_reporting_period = 1
 WHERE js_class = 'Controls.CmsTab';
-- ** New package grants **

-- *** Packages ***

@../plugin_pkg

@../schema_body
@../csrimp/imp_body
@../plugin_body
@../property_body
@update_tail
