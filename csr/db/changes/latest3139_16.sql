-- Please update version.sql too -- this keeps clean builds in sync
define version=3139
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables 


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***

UPDATE surveys.answer 
   SET hidden = 0
 WHERE hidden IS NULL;

-- Alter tables
ALTER TABLE surveys.answer 
	 MODIFY hidden NUMBER(1) DEFAULT 0 NOT NULL ;


-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
