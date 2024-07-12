-- Please update version.sql too -- this keeps clean builds in sync
define version=3189
define minor_version=6
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
BEGIN
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(0, 'Success');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(1, 'Partial success');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(2, 'Fail');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(3, 'Fail (unexpected error)');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(4, 'Not attempted');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
	BEGIN
		INSERT INTO CSR.AUTOMATED_IMPORT_RESULT (AUTOMATED_IMPORT_RESULT_ID, LABEL) VALUES(5, 'Nothing To Do');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			null;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
