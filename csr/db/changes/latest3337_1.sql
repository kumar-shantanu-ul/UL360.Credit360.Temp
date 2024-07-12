-- Please update version.sql too -- this keeps clean builds in sync
define version=3337
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.AUTO_EXP_RETRIEVAL_DATAVIEW ADD (
   IND_SELECTION_TYPE_ID             NUMBER(10, 0)    DEFAULT 0 NOT NULL
);

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
@../csr_data_pkg
@../automated_export_pkg

@../automated_export_body

@update_tail
