-- Please update version.sql too -- this keeps clean builds in sync
define version=3345
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE CSR.MANAGED_CONTENT_MAP(
    APP_SID             NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SID                 NUMBER(10, 0)    NOT NULL,
    UNIQUE_REF          VARCHAR2(1024)    NOT NULL,
    PACKAGE_REF          VARCHAR2(1024)    NOT NULL,
    CONSTRAINT PK_MANAGED_CONTENT_MAP PRIMARY KEY (APP_SID, SID, UNIQUE_REF)
)
;

CREATE TABLE CSR.MANAGED_PACKAGE (
	APP_SID                 NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	PACKAGE_REF				VARCHAR2(1024) NOT NULL,
	PACKAGE_NAME			VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_MANAGED_PACKAGE PRIMARY KEY (APP_SID)
)
;

CREATE UNIQUE INDEX CSR.IDX_PACKAGE_REF ON CSR.MANAGED_PACKAGE(PACKAGE_REF)
;


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (116, 'Managed Packaged Content', 'EnableManagedPackagedContent', 'Enables managed packaged content.');
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (116, 'in_package_name', 'Package name', 0);
	INSERT INTO csr.module_param (module_id, param_name, param_hint, pos)
	VALUES (116, 'in_package_ref', 'Package reference', 1);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

create or replace package csr.managed_content_pkg as
	procedure dummy;
end;
/
create or replace package body csr.managed_content_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

grant execute on csr.managed_content_pkg to web_user;

@../managed_content_pkg
@../managed_content_body
@../enable_pkg
@../enable_body
@../indicator_body

@update_tail
