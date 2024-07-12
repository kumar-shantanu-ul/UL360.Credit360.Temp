-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.DATAVIEW ADD (
    SHOW_ABS_VARIANCE                NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CONSTRAINT CK_DATAVIEW_SHOW_ABS_VARIANCE CHECK (SHOW_ABS_VARIANCE IN (0,1))
);

ALTER TABLE CSR.DATAVIEW_HISTORY ADD (
    SHOW_ABS_VARIANCE                NUMBER(1, 0)      DEFAULT 0 NOT NULL
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
@../dataview_pkg
@../dataview_body

@update_tail
