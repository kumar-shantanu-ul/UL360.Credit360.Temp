-- Please update version.sql too -- this keeps clean builds in sync
define version=3477
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
BEGIN
    EXECUTE IMMEDIATE 'ALTER TABLE gt.location_lookup DISABLE CONSTRAINT FK_LOCATION_LOOKUP_REGION';
EXCEPTION
    WHEN OTHERS THEN
        -- ORA-00942: table or view does not exist
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
