-- Please update version.sql too -- this keeps clean builds in sync
define version=3316
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE CSR.INITIATIVES_OPTIONS MODIFY (
    METRICS_END_YEAR              NUMBER(10, 0)     DEFAULT 2030
);

-- *** Grants ***
GRANT EXECUTE ON actions.file_upload_pkg TO CSR;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (46, 'Metrics End Year', 1, '(e.g. 2030)');


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../initiative_pkg

@../enable_body
@../initiative_body

@update_tail
