-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS ADD (
	INCLUDE_FIRST_ROW NUMBER(1) DEFAULT 0 NOT NULL
);
UPDATE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS SET INCLUDE_FIRST_ROW = 1 WHERE CONVERT_TO_DSV = 1;

ALTER TABLE CSR.AUTO_EXP_BATCHED_EXP_SETTINGS
ADD CONSTRAINT CK_AUTO_EXP_BATCH_EXP_INC_F_R CHECK (INCLUDE_FIRST_ROW IN (0, 1));

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

@../batch_exporter_pkg
@../batch_exporter_body
@../automated_export_pkg
@../automated_export_body


@update_tail