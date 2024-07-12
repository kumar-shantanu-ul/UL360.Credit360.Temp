-- Please update version.sql too -- this keeps clean builds in sync
define version=3001
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.PERIOD_SPAN_PATTERN
ADD PERIOD_IN_YEAR_2 NUMBER(2) DEFAULT 0 NOT NULL;

ALTER TABLE CSR.PERIOD_SPAN_PATTERN
ADD YEAR_OFFSET_2 NUMBER(2) DEFAULT 0 NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.PERIOD_SPAN_PATTERN_TYPE (PERIOD_SPAN_PATTERN_TYPE_ID, LABEL)
VALUES (4, 'Offset to Offset');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_export_body


@update_tail
