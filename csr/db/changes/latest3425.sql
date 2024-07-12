-- Please update version.sql too -- this keeps clean builds in sync
define version=3425
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

-- Insert capability where missing
MERGE INTO csr.capability c
USING (
	SELECT 'Manage meter readings' name, 1 allow_by_default
	  FROM DUAL
	) d
   ON (c.name = d.name)
 WHEN NOT MATCHED THEN
 	INSERT (c.name, c.allow_by_default)
	VALUES (d.name, d.allow_by_default);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
