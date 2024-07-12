-- Please update version.sql too -- this keeps clean builds in sync
define version=3165
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.ENHESA_SITE_TYPE
  MODIFY (LABEL			VARCHAR2(256) NOT NULL);

ALTER TABLE CSR.ENHESA_SITE_TYPE_HEADING
  MODIFY (HEADING_CODE	VARCHAR2(256) NOT NULL);
		  
ALTER TABLE CSRIMP.ENHESA_SITE_TYPE
  MODIFY (LABEL			VARCHAR2(256) NOT NULL);
		  
ALTER TABLE CSRIMP.ENHESA_SITE_TYPE_HEADING
  MODIFY (HEADING_CODE	VARCHAR2(256) NOT NULL);

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
