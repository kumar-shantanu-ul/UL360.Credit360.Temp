-- Please update version.sql too -- this keeps clean builds in sync
define version=2821
define minor_version=5
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
  FOR x IN (SELECT t.tab_sid,r.description FROM cms.tab t JOIN cms.fk f ON f.fk_tab_sid =t.tab_sid AND f.r_owner = t.oracle_schema  
            JOIN cms.tab r ON r.tab_sid = f.r_tab_sid WHERE t.oracle_table LIKE 'I$%' AND t.description IS NULL)
  LOOP
    UPDATE cms.tab SET description = x.description || ' Action' WHERE tab_sid = x.tab_sid;
  END LOOP;
END;
/
-- ** New package grants **

-- *** Packages ***
@..\..\..\aspen2\cms\db\tab_body

@update_tail
