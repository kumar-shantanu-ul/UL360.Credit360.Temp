-- Please update version.sql too -- this keeps clean builds in sync
define version=3034
define minor_version=3
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
	-- Remove old enums
	DELETE FROM csr.est_attr_enum
	 WHERE type_name = 'poolSizeType'
	   AND enum NOT IN (
		'Recreational (20 yards x 15 yards)',
		'Short Course (25 yards x 20 yards)',
		'Olympic (50 meters x 25 meters)'
	);

	-- Add new enums if required
	BEGIN
		INSERT INTO csr.est_attr_enum (type_name, enum, pos)
		VALUES ('poolSizeType', 'Recreational (20 yards x 15 yards)', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore
	END;

	BEGIN
		INSERT INTO csr.est_attr_enum (type_name, enum, pos)
		VALUES ('poolSizeType', 'Short Course (25 yards x 20 yards)', 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore
	END;

	BEGIN
		INSERT INTO csr.est_attr_enum (type_name, enum, pos)
		VALUES ('poolSizeType', 'Olympic (50 meters x 25 meters)', 2);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
