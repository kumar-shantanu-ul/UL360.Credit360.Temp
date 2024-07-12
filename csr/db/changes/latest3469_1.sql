-- Please update version.sql too -- this keeps clean builds in sync
define version=3469
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_EXP_FILECREATE_DSV ADD encode_newline NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.AUTO_EXP_FILECREATE_DSV ADD CONSTRAINT CK_AUTO_EXP_FILECREATE_DSV_ENCODE_NEWLINE CHECK (ENCODE_NEWLINE IN (0, 1, 2));

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
@../automated_export_pkg
@../automated_export_body

@update_tail
