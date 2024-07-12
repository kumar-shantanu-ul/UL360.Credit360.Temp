-- Please update version.sql too -- this keeps clean builds in sync
define version=3488
define minor_version=9
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

--Anonymise SO name if the user is anonymised and not in the trash
MERGE INTO security.securable_object so USING(
    SELECT cu.csr_user_sid, cu.user_name
      FROM csr.csr_user cu
      LEFT JOIN csr.trash t
        ON cu.csr_user_sid = t.trash_sid
      LEFT JOIN csr.superadmin sa
        ON cu.csr_user_sid = sa.csr_user_sid
     WHERE cu.anonymised = 1
       AND t.trash_sid IS NULL
       AND sa.csr_user_sid IS NULL
) src ON (so.sid_id = src.csr_user_sid)
WHEN MATCHED THEN UPDATE SET so.name = src.user_name;

--Set the trash SO_NAME to the previous SO GUID
MERGE INTO csr.trash t USING(
    SELECT cu.user_name, so.sid_id
      FROM security.securable_object so
      JOIN csr.csr_user cu
        ON cu.csr_user_sid = so.sid_id
     WHERE cu.anonymised = 1
) src ON (t.trash_sid = src.sid_id)
WHEN MATCHED THEN UPDATE SET t.so_name = src.user_name, t.description = src.user_name;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_body

@update_tail
