-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
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
BEGIN
	BEGIN
		INSERT INTO csr.est_attr_type (type_name, basic_type)
		VALUES ('m'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'NUMERIC');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore dupes
	END;

	BEGIN
		INSERT INTO csr.est_attr_for_building (attr_name, type_name, is_mandatory, label)
		VALUES ('waterIntensityTotal', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 0, 'Water Intensity (All Water Sources)');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL; -- Ignore dupes
	END;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
