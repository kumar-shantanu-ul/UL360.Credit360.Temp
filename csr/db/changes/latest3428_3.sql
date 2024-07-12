-- Please update version.sql too -- this keeps clean builds in sync
define version=3428
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.gresb_property_sub_type
   SET pos = pos + 1
 WHERE gresb_property_type_id = 3 
   AND gresb_property_sub_type_id >= 1;

INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 5, 'Refrigerated Warehouse', 'IRFW', 1);
INSERT INTO csr.gresb_property_sub_type(gresb_property_type_id, gresb_property_sub_type_id, name, gresb_code, pos) VALUES (3, 6, 'Non-Refrigerated Warehouse', 'INRW', 0);

UPDATE csr.property_sub_type
   SET gresb_property_sub_type_id = 6
 WHERE gresb_property_type_id = 3 
   AND gresb_property_sub_type_id = 1;

DELETE FROM csr.gresb_property_sub_type
 WHERE gresb_property_type_id = 3
   AND gresb_property_sub_type_id = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
