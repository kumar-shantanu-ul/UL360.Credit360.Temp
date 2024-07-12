-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=21
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	-- Get all sheet value hidden cache items with measure conversion ids that don't exist
	FOR r IN (
		SELECT entry_measure_conversion_id, sheet_value_id
		  FROM csr.sheet_value_hidden_cache
		 WHERE entry_measure_conversion_id NOT IN (
		 	SELECT measure_conversion_id
		 	  FROM csr.measure_conversion
	 	)
	)
	LOOP
		-- Update the hidden cache
		UPDATE csr.sheet_value_hidden_cache
		   SET entry_measure_conversion_id = (
				SELECT entry_measure_conversion_id
		  		  FROM csr.sheet_value
		 		 WHERE sheet_value_id = r.sheet_value_id
		 		)
		 WHERE entry_measure_conversion_id = r.entry_measure_conversion_id;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***
ALTER TABLE csr.SHEET_VALUE_HIDDEN_CACHE ADD CONSTRAINT FK_SHEET_VALUE_HIDDEN_CACHE_MC
	FOREIGN KEY (APP_SID, ENTRY_MEASURE_CONVERSION_ID)
	REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID);

@update_tail
