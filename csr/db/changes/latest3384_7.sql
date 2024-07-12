-- Please update version.sql too -- this keeps clean builds in sync
define version=3384
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.sustainability_essentials_enable(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	version					VARCHAR2(100) NOT NULL,
	enabled_modules_json	CLOB,
	CONSTRAINT pk_sustainability_essentials_enable PRIMARY KEY (app_sid)
);

CREATE TABLE csr.sustainability_essentials_object_map(
	app_sid					NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	object_ref				VARCHAR2(1024) NOT NULL,
	created_object_id		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_sustainability_essentials_object_map PRIMARY KEY (app_sid, object_ref, created_object_id)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
create or replace package CSR.SUSTAIN_ESSENTIALS_PKG as
procedure dummy;
end;
/
create or replace package body CSR.SUSTAIN_ESSENTIALS_PKG as
procedure dummy
as
begin
	null;
end;
end;
/

GRANT EXECUTE ON CSR.SUSTAIN_ESSENTIALS_PKG TO WEB_USER;
GRANT EXECUTE ON CSR.SUSTAIN_ESSENTIALS_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.FACTOR_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.PORTLET_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.INDICATOR_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.CALC_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.MEASURE_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.INDICATOR_API_PKG TO TOOL_USER;
GRANT EXECUTE ON CSR.TAG_PKG TO TOOL_USER;


-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../sustain_essentials_pkg
@../image_upload_portlet_pkg
@../alert_pkg
@../indicator_api_pkg

@../enable_body
@../sustain_essentials_body
@../image_upload_portlet_body
@../alert_body
@../indicator_api_body

@update_tail
