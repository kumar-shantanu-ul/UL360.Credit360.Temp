-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.FILTER_VALUE DROP CONSTRAINT FK_FLT_VAL_FLD;

ALTER TABLE CHAIN.FILTER_VALUE ADD CONSTRAINT FK_FLT_VAL_FLD 
	FOREIGN KEY (APP_SID, FILTER_FIELD_ID)
	REFERENCES CHAIN.FILTER_FIELD(APP_SID, FILTER_FIELD_ID)
	ON DELETE CASCADE
;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/filter_body

@update_tail
