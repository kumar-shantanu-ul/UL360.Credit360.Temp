-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=36
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

UPDATE csr.est_meter
   SET meter_type = 'Other - Outdoor'
 WHERE meter_type = 'Outdoor';
 
UPDATE csr.est_meter
   SET meter_type = 'Other - Mixed Indoor/Outdoor (Water)'
 WHERE meter_type IN ('Mixed Indoor/Outdoor (Water)', 'Wastewater/Sewer', 'Indoor/Outdoor');

UPDATE csr.est_meter
   SET meter_type = 'Fuel Oil No 5 or 6'
 WHERE meter_type = 'Fuel Oil (No. 5 and No. 6)';

UPDATE csr.est_meter
   SET meter_type = 'Fuel Oil No 2'
 WHERE meter_type = 'Fuel Oil (No. 2)';

UPDATE csr.est_meter
   SET meter_type = 'Electric'
 WHERE meter_type = 'Electricity';
 
UPDATE csr.est_meter
   SET meter_type = 'Other (Energy)'
 WHERE meter_type = 'Other';
 
UPDATE csr.est_meter
   SET meter_type = 'Other - Indoor'
 WHERE meter_type = 'Indoor';
 
UPDATE csr.est_meter
   SET meter_type = 'District Chilled Water - Other'
 WHERE meter_type = 'District Chilled Water';


ALTER TABLE csr.est_meter
ADD CONSTRAINT FK_EST_METER_TYPE
FOREIGN KEY (meter_type) REFERENCES csr.est_meter_type (meter_type);

CREATE INDEX CSR.IX_EST_METER_TYPE ON CSR.EST_METER(meter_type);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
