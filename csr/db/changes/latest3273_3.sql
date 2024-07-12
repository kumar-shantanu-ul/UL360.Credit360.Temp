-- Please update version.sql too -- this keeps clean builds in sync
define version=3273
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
ALTER TABLE csr.est_conv_mapping DISABLE constraint FK_ESTMETCON_ESTCONMAP;

UPDATE csr.est_conv_mapping
   SET uom = 'Kilogram'
 WHERE meter_type = 'District Steam'
  AND uom = 'kg';

UPDATE csr.est_meter_conv
   SET uom = 'Kilogram'
 WHERE meter_type = 'District Steam'
  AND uom = 'kg';

ALTER TABLE csr.est_conv_mapping ENABLE constraint FK_ESTMETCON_ESTCONMAP;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
