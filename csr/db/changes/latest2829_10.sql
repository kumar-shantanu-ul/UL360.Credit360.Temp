-- Please update version.sql too -- this keeps clean builds in sync
define version=2829
define minor_version=10
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
    FOR r IN (
       	SELECT distinct c.host
		FROM security.menu m
		JOIN security.securable_object so on so.sid_id = m.SID_ID
		JOIN csr.customer c on so.APPLICATION_SID_ID = c.APP_SID
		where action = '/csr/site/audit/browse.acds'
    )
    LOOP
        security.user_pkg.logonadmin(r.host);
        BEGIN
            CSR.ENABLE_PKG.ENABLEAUDITFILTERING();
            dbms_output.put_line( r.host || ' updated to new audits.');
        EXCEPTION
            WHEN security.security_pkg.object_not_found THEN
                 dbms_output.put_line('Error ' || r.host || ' already has new audits enabled.');
        END;
    END LOOP;
 END;
 /
 
-- ** New package grants **

-- *** Packages ***

@update_tail
