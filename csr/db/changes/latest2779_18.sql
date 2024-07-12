-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=18
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin();
END;
/

BEGIN
  FOR r IN (
    SELECT UNIQUE so.application_sid_id, c.name customername, so.sid_id, so.name, m.action, host
      FROM SECURITY.SECURABLE_OBJECT  so
      JOIN security.menu m on m.sid_id=so.sid_id
      JOIN csr.customer c on c.app_sid=so.application_sid_id
     WHERE class_id= (SELECT class_id FROM security.securable_object_class WHERE class_name='Menu')
       AND m.action LIKE '%text/admin/list.%'
       AND so.name LIKE 'csr_%'
     ORDER BY c.name)
  LOOP
    --dbms_output.put_line(r.host||': SO '||r.name);
    security.securableobject_pkg.RenameSO(security.security_pkg.getACT, r.sid_id, 'csr_text_admin_list');
  END LOOP;
END;
/

BEGIN
  FOR r IN (
    SELECT UNIQUE so.application_sid_id, c.name customername, so.sid_id, so.name, m.action, host
      FROM SECURITY.SECURABLE_OBJECT  so
      JOIN security.menu m on m.sid_id=so.sid_id
      JOIN csr.customer c on c.app_sid=so.application_sid_id
     WHERE class_id= (SELECT class_id FROM security.securable_object_class WHERE class_name='Menu')
       AND m.action LIKE '%text/admin/list2.%'
       AND so.name LIKE 'csr_%'
     ORDER BY c.name)
  LOOP
    --dbms_output.put_line(r.host||': SO '||r.name);
    security.securableobject_pkg.RenameSO(security.security_pkg.getACT, r.sid_id, 'csr_text_admin_list2');
  END LOOP;
END;
/

-- ** New package grants **

-- *** Packages ***
@..\enable_body

@update_tail
