-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=10
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

begin
	for r in (select * from all_objects where owner='CHAIN' and object_name='TEST_PRODUCT_DATA_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package chain.test_product_data_pkg';
	end loop;
end;
/


@update_tail
