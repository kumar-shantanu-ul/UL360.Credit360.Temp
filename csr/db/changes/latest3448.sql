-- Please update version.sql too -- this keeps clean builds in sync
define version=3448
define minor_version=0
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
UPDATE csr.flow_state_role_capability fsrc
   SET permission_set = 3 -- Read/Write
 WHERE permission_set = 2 -- Write Only
   AND EXISTS (
        SELECT cfc2.flow_capability_id
          FROM csr.customer_flow_capability cfc2
          JOIN csr.non_compliance_type_flow_cap nfc ON cfc2.flow_capability_id = nfc.flow_capability_id
         WHERE nfc.base_flow_capability_id = 23 -- Non-compliance tags
           AND cfc2.perm_type = 1 -- Boolean
           AND cfc2.flow_capability_id = fsrc.flow_capability_id
   );
   
UPDATE csr.customer_flow_capability cfc
   SET perm_type = 0 -- Specific ("None"/"Read only"/"Read/Write")
 WHERE EXISTS (
        SELECT cfc2.flow_capability_id
          FROM csr.customer_flow_capability cfc2
          JOIN csr.non_compliance_type_flow_cap nfc ON cfc2.flow_capability_id = nfc.flow_capability_id
         WHERE nfc.base_flow_capability_id = 23 -- Non-compliance tags
           AND cfc2.perm_type = 1 -- Boolean
           AND cfc2.flow_capability_id = cfc.flow_capability_id
   );

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
