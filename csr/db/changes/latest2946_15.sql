-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=15
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

begin
	begin
		INSERT INTO csr.std_measure (
			std_measure_id, name, description, scale, format_mask, regional_aggregation, custom_field, pct_ownership_applies, m, kg, s, a, k, mol, cd
		) VALUES (
			39, 'm^2/kg', 'm^2/kg', 0, '#,##0', 'sum', NULL, 0, 2, -1, 0, 0, 0, 0, 0
		);
	exception
		when dup_val_on_index then
			null;
	end;

	begin			
		INSERT INTO csr.std_measure_conversion (
			std_measure_conversion_id, std_measure_id, description, a, b, c, divisible
		) VALUES (
			28185, 39, 'm^3/(tonne.km)', 1000000, 1, 0, 1
		);
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
