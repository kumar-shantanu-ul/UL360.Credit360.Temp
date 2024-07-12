-- Please update version.sql too -- this keeps clean builds in sync
define version=3021
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
 
-- *** Grants ***
begin
	dbms_java.grant_permission( 'CSR', 'SYS:java.net.SocketPermission', 'localhost:1024-', 'listen,resolve');
end;
/


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
