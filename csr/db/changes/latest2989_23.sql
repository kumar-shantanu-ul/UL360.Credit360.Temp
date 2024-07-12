-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=23
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
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Solar', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Electric on Site Wind', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Natural Gas', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 1', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 1', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 2', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 2', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 4', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 4', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 5 or 6', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Fuel Oil No 5 or 6', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Diesel', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Diesel', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Kerosene', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Kerosene', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'ccf');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'Gallons (UK)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Propane', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Steam', 'kg');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Hot Water', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Electric-Driven Chiller', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('District Chilled Water - Other', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'Tonnes (metric)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Anthracite', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'Tonnes (metric)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coal Bituminous', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'Tonnes (metric)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Coke', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Wood', 'Tonnes (metric)');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Wood', 'GJ');
INSERT INTO csr.est_meter_conv (meter_type, uom) VALUES ('Other (Energy)', 'GJ');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
