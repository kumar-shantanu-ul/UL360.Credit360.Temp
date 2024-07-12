-- Please update version.sql too -- this keeps clean builds in sync
define version=3484
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.
CREATE OR REPLACE FORCE EDITIONABLE VIEW "CHAIN"."V$COMPANY_REFERENCE" ("APP_SID", "COMPANY_REFERENCE_ID", "COMPANY_SID", "VALUE", "REFERENCE_ID", "LOOKUP_KEY", "LABEL") AS 
  SELECT cr.app_sid, cr.company_reference_id, cr.company_sid, cr.value, cr.reference_id, r.lookup_key, r.label
	  FROM chain.company_reference cr
	  JOIN chain.reference r ON r.app_sid = cr.app_sid AND r.reference_id = cr.reference_id;
-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\company_body

@update_tail
