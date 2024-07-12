-- Please update version.sql too -- this keeps clean builds in sync
define version=2769
@update_header

-- Clean
-- DELETE FROM csr.batch_job_type WHERE batch_job_type_id = 17;

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
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) 
      INTO v_count
      FROM csr.batch_job_type 
     WHERE batch_job_type_id = 17;

    IF v_count = 0 THEN
        INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name)
             VALUES (17, 'CASA import', 'casa-import');
    END IF;
END;
/

-- ** New package grants **

-- *** Packages ***
@../batch_job_pkg

@update_tail
