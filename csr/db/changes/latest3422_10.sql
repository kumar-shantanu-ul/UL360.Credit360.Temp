-- Please update version.sql too -- this keeps clean builds in sync
define version=3422
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.site_audit_details (
	app_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	original_sitename	VARCHAR2(255)	NOT NULL,
	created_by			VARCHAR2(255)	NOT NULL,
	created_dtm			DATE,
	original_expiry_dtm	DATE			DEFAULT SYSDATE+365 NOT NULL,
	active_expiry_dtm	DATE			NOT NULL,
	enabled_modules		CLOB			NOT NULL,
	added_to_existing	NUMBER(1)		DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SITE_AUDIT_DETAILS PRIMARY KEY (APP_SID),
	CONSTRAINT CK_SITE_AUDIT_DETAILS_EXISTING CHECK (added_to_existing IN (0, 1))
);

CREATE TABLE csr.site_audit_details_expiry (
	app_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	expiry_dtm			DATE			NOT NULL,
	entered_by_sid		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
	entered_at_dtm		DATE			DEFAULT SYSDATE,
	reason				CLOB			NOT NULL
);
ALTER TABLE csr.site_audit_details_expiry ADD CONSTRAINT FK_site_audit_details_expiry_entered_by
	FOREIGN KEY (app_sid, entered_by_sid) 
	REFERENCES csr.csr_user(app_sid, csr_user_sid);

CREATE TABLE csr.site_audit_details_client_name (
	app_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	client_name			VARCHAR2(1024)	NOT NULL,
	entered_by_sid		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	entered_at_dtm		DATE			DEFAULT SYSDATE,
	CONSTRAINT PK_SITE_AUDIT_DETAILS_CLIENT_NAME PRIMARY KEY (APP_SID, CLIENT_NAME)
);
ALTER TABLE csr.site_audit_details_client_name ADD CONSTRAINT FK_site_audit_details_client_name_entered_by
	FOREIGN KEY (app_sid, entered_by_sid) 
	REFERENCES csr.csr_user(app_sid, csr_user_sid);

CREATE TABLE csr.site_audit_details_reason (
	app_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	reason				CLOB			NOT NULL,
	entered_by_sid		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	entered_at_dtm		DATE			DEFAULT SYSDATE
);
ALTER TABLE csr.site_audit_details_reason ADD CONSTRAINT FK_site_audit_details_reason_entered_by
	FOREIGN KEY (app_sid, entered_by_sid) 
	REFERENCES csr.csr_user(app_sid, csr_user_sid);

CREATE TABLE csr.site_audit_details_contract_ref (
	app_sid				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	contract_reference	VARCHAR2(1024)	NOT NULL,
	entered_by_sid		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','SID'),
	entered_at_dtm		DATE			DEFAULT SYSDATE
);
ALTER TABLE csr.site_audit_details_contract_ref ADD CONSTRAINT FK_site_audit_details_contract_ref_entered_by
	FOREIGN KEY (app_sid, entered_by_sid) 
	REFERENCES csr.csr_user(app_sid, csr_user_sid);

create index csr.ix_site_audit_de_cn_entered_by on csr.site_audit_details_client_name (app_sid, entered_by_sid);
create index csr.ix_site_audit_de_cr_entered_by on csr.site_audit_details_contract_ref (app_sid, entered_by_sid);
create index csr.ix_site_audit_de_exp_entered_by on csr.site_audit_details_expiry (app_sid, entered_by_sid);
create index csr.ix_site_audit_de_rea_entered_by on csr.site_audit_details_reason (app_sid, entered_by_sid);

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
@../csr_app_pkg
@../csr_app_body

@update_tail
