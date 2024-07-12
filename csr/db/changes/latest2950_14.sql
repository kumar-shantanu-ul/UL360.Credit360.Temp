-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CHAIN.SAVED_FILTER ADD (
	COLOUR_BY			  VARCHAR2(255),
	COLOUR_RANGE_ID		  NUMBER(10)
);

ALTER TABLE CSRIMP.CHAIN_SAVED_FILTER ADD (
	COLOUR_BY			  VARCHAR2(255),
	COLOUR_RANGE_ID		  NUMBER(10)
);

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
@../chain/filter_pkg

@../chain/filter_body
@../schema_body
@../csrimp/imp_body

@update_tail
