-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- NOTE: This column seems to already exist on live, but there is no corresponding change script.
DECLARE
  v_exists NUMBER;
  v_sql VARCHAR2(1024);
BEGIN
    SELECT COUNT(*) 
      INTO v_exists 
      FROM all_tab_cols 
     WHERE column_name = 'NAME' 
       AND table_name = 'DELEGATION_LAYOUT'
       AND owner = 'CSR';
     
    IF v_exists = 0 THEN
        EXECUTE IMMEDIATE q'{
            ALTER TABLE CSR.DELEGATION_LAYOUT ADD (
                NAME VARCHAR2(255) DEFAULT 'New Layout' NOT NULL)}';
    END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\delegation_pkg
@..\delegation_body

@update_tail
