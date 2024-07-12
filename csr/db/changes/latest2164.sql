-- Please update version.sql too -- this keeps clean builds in sync
define version=2164
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS
-- Data
--INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Can edit transition comment', 0);

DECLARE
	v_corpreport_sid				security.security_pkg.T_SID_ID;
   CURSOR cur IS
      SELECT website_name FROM security.website;
BEGIN
   FOR r IN cur LOOP
    BEGIN
      security.user_pkg.logonadmin(r.website_name);
	  v_corpreport_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.getAct, security.security_pkg.getApp, 'Indexes');
      dbms_output.put_line(security.security_pkg.getApp);
      csr.csr_data_pkg.EnableCapability('Can edit transition comment', 1);
      EXCEPTION WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
        NULL;
        END;
   END LOOP;
END;
/

-- *** Packages ***
@..\section_body
@..\enable_body
@update_tail