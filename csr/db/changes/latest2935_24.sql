-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=24
@update_header

-- *** DDL ***
-- Create tables
-- Conditionally add missing Initiatives sequence (we have: INITIATIVE_METRID_ID_SEQ 
-- on live (typo which was created in a latest script in 2013) but also have INITIATIVE_METRIC_ID_SEQ (no typo)
-- on live (no latest script) both missing from schema but on live).
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences
	 WHERE sequence_owner = 'CSR'
	   AND sequence_name = 'INITIATIVE_METRIC_ID_SEQ';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.INITIATIVE_METRIC_ID_SEQ
								START WITH 1
								INCREMENT BY 1
								NOMINVALUE
								NOMAXVALUE
								CACHE 20
								NOORDER';
	END IF;
END;
/

-- Drop un-used sequence if it exists.
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences
	 WHERE sequence_owner = 'CSR'
	   AND sequence_name = 'INITIATIVE_METRID_ID_SEQ';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'DROP SEQUENCE CSR.INITIATIVE_METRID_ID_SEQ';
	END IF;
END;
/

-- Missing from schema.
DECLARE
	v_count	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_sequences
	 WHERE sequence_owner = 'CSR'
	   AND sequence_name = 'AGGR_TAG_GROUP_ID_SEQ';

	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE SEQUENCE CSR.AGGR_TAG_GROUP_ID_SEQ
								START WITH 1
								INCREMENT BY 1
								NOMINVALUE
								NOMAXVALUE
								CACHE 20
								NOORDER';
	END IF;
END;
/
	
-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
