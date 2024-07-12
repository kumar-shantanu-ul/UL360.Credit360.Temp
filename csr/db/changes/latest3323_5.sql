-- Please update version.sql too -- this keeps clean builds in sync
define version=3323
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.integration_request (
	app_sid					NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	data_type				VARCHAR2(64)	NOT NULL,
	tenant_id				VARCHAR2(64)	NOT NULL,
	request_url				VARCHAR2(2048)	NOT NULL,
	request_verb			VARCHAR2(100)	NOT NULL,
	last_updated_dtm		DATE			NOT NULL,
	last_updated_message	VARCHAR2(1024)	NOT NULL,
	request_json			CLOB,
	CONSTRAINT pk_integration_request	PRIMARY KEY (app_sid, data_type)
);


-- Alter tables

-- *** Grants ***
create or replace package chain.integration_pkg as end;
/

GRANT EXECUTE ON chain.integration_pkg TO csr;
GRANT EXECUTE ON chain.integration_pkg TO web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
insert into csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
values (csr.plugin_id_seq.nextval, 10, 'Integration supplier details', '/csr/site/chain/manageCompany/controls/IntegrationSupplierDetailsTab.js', 'Chain.ManageCompany.IntegrationSupplierDetailsTab', 'Credit360.Chain.Plugins.IntegrationSupplierDetailsDto', 'This tab shows the Integration details for a supplier.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../chain/integration_pkg

@../chain/chain_body
@../chain/integration_body

@update_tail
