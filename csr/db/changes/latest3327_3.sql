-- Please update version.sql too -- this keeps clean builds in sync
define version=3327
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.integration_request
DROP CONSTRAINT PK_INTEGRATION_REQUEST;

ALTER TABLE chain.integration_request
ADD CONSTRAINT PK_INTEGRATION_REQUEST PRIMARY KEY (app_sid, data_type, request_url);

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
@../chain/integration_pkg
@../chain/integration_body

@update_tail
