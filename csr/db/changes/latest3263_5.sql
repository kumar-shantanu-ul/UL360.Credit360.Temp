-- Please update version.sql too -- this keeps clean builds in sync
define version=3263
define minor_version=5
@update_header

-- Ensure security changes have been applied.

declare
	v_ver number;
begin
	select db_version into v_ver from security.version;
	if v_ver < 79 then
		raise_application_error(-20001, 'Security schema must be at least version 79');
	end if;
end;
/

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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body

@update_tail
