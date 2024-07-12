-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

alter table aspen2.application add cdn_server varchar2(512);
alter table csrimp.aspen2_application add cdn_server varchar2(512);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (19,'Set CDN Server','Sets the domain of the CDN server. A CDN provides static content to users from a server closer to their location. Dynamic content such as data will still come from our servers.','SetCDNServer',null);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID, PARAM_NAME, PARAM_HINT, POS) VALUES (19, 'CDN Server name','Domain of the CDN server',0);

	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (20,'Remove CDN Server','Removes the CDN server so that all content comes from the site directly','RemoveCDNServer',null);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../customer_pkg
@../util_script_pkg

@../../../aspen2/db/aspenapp_body
@../csrimp/imp_body
@../customer_body
@../util_script_body

@update_tail
