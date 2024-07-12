-- Please update version.sql too -- this keeps clean builds in sync
define version=3272
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
UPDATE aspen2.application
   SET default_stylesheet = '/csr/shared/branding/generic.xsl'
 WHERE default_stylesheet = '/standardbranding/shared/branding/generic.xsl';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../branding_pkg
@../branding_body

@update_tail
