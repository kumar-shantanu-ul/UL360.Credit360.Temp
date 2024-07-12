-- Please update version.sql too -- this keeps clean builds in sync
define version=0
define minor_version=0
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

DELETE FROM csr.logistics_error_log 
 WHERE logged_dtm >= TO_DATE('2022/01/01', 'yyyy/mm/dd');

UPDATE csr.logistics_tab_mode
   SET is_dirty = 1,
   processing = 0
 WHERE tab_sid = 12332941
;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
