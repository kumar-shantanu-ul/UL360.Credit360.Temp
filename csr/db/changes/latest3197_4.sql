-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
-- Reverse
/*
ALTER TABLE chain.saved_filter DROP CONSTRAINT chk_hide_empty;
ALTER TABLE chain.saved_filter DROP COLUMN hide_empty;
ALTER TABLE csrimp.chain_saved_filter DROP COLUMN hide_empty;
*/

ALTER TABLE chain.saved_filter ADD (
	HIDE_EMPTY NUMBER(1,0) DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_HIDE_EMPTY CHECK (HIDE_EMPTY IN (0, 1))
);

ALTER TABLE csrimp.chain_saved_filter ADD (
	HIDE_EMPTY NUMBER(1,0) NULL
);

UPDATE csrimp.chain_saved_filter SET hide_empty = 0;
ALTER TABLE csrimp.chain_saved_filter MODIFY (hide_empty NUMBER(1,0) NOT NULL);

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
@../chain/filter_pkg

@../schema_body
@../chain/filter_body
@../csrimp/imp_body


@update_tail
