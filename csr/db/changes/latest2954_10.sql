-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DELETE FROM csr.flow_state_role_capability fsrc
 WHERE NOT EXISTS (
  SELECT *
    FROM csr.flow_state_role fsr
   WHERE fsr.flow_state_id = fsrc.flow_state_id AND fsr.role_sid = fsrc.role_sid
) AND fsrc.role_sid IS NOT NULL;

ALTER TABLE csr.flow_state_role_capability ADD CONSTRAINT FK_FLOW_STATE_ROLE_CAP_ROLE FOREIGN KEY (app_sid, role_sid) REFERENCES csr.role (app_sid, role_sid);

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
@..\role_body

@update_tail
