-- Please update version.sql too -- this keeps clean builds in sync
define version=3253
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.T_FLOW_STATE ADD MOVE_TO_FLOW_STATE_ID	NUMBER(10);
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.flow_state
   SET move_to_flow_state_id = NULL
 WHERE move_to_flow_state_id IS NOT NULL
   AND is_deleted = 0;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_pkg
@../flow_body

@update_tail
