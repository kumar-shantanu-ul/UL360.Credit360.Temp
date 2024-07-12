-- Please update version.sql too -- this keeps clean builds in sync
define version=3486
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) VALUES (29,'Anonymised',1);

UPDATE csr.audit_log
   SET audit_type_id = 29
 WHERE audit_type_id = 5
   AND description = 'Anonymised';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../csr_user_pkg
@../csr_user_body


@update_tail
