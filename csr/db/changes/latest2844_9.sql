-- Please update version.sql too -- this keeps clean builds in sync
define version=2844
define minor_version=9
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

DECLARE
	v_exists NUMBER;
BEGIN
	UPDATE csr.ind
	   SET gas_type_id = NULL,
		   map_to_ind_sid = NULL
	 WHERE DECODE(map_to_ind_sid, NULL, 0, 1) != DECODE(gas_type_id, NULL, 0, 1);

	SELECT COUNT(*)
	  INTO v_exists
	  FROM sys.all_constraints
	 WHERE owner = 'CSR'
	   AND table_name = 'IND'
	   AND constraint_name = 'CK_IND_GAS_SETTINGS';

	IF v_exists = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.ind 
							 ADD CONSTRAINT ck_ind_gas_settings CHECK (
								(gas_type_id IS NULL AND map_to_ind_sid IS NULL) OR
								(gas_type_id IS NOT NULL AND map_to_ind_sid IS NOT NULL)
						   )';
	END IF;
END;
/

-- ** New package grants **

-- *** Packages ***

@update_tail
