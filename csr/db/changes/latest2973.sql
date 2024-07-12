-- Please update version.sql too -- this keeps clean builds in sync
define version=2973
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.tpl_report_reg_data_type ADD (
	hide_if_properties_not_enabled		NUMBER(1,0) DEFAULT 0 NOT NULL,
	hide_if_metering_not_enabled		NUMBER(1,0) DEFAULT 0 NOT NULL
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.tpl_report_reg_data_type
   SET hide_if_properties_not_enabled = 1
 WHERE tpl_report_reg_data_type_id IN (1, 2, 3, 6, 7, 8);

UPDATE csr.tpl_report_reg_data_type
   SET hide_if_metering_not_enabled = 1
 WHERE tpl_report_reg_data_type_id IN (4, 5);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../templated_report_body

@update_tail
