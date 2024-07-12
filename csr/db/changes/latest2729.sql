-- Please update version.sql too -- this keeps clean builds in sync
define version=2729
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.sso_certificate_status (
  SID_ID      		NUMBER(10) NULL,
  SSO_CERT_ID 		NUMBER(10) NULL,
  HOST        		VARCHAR2(255),
  SUBJECT     		VARCHAR2(1024),
  NOT_BEFORE_DTM	DATE,
  NOT_AFTER_DTM		DATE,
  CONSTRAINT  UK_SSO_CERT_STATUS UNIQUE (SID_ID, SSO_CERT_ID)
);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.certificate_pkg AS PROCEDURE dummy; END;
/
CREATE OR REPLACE PACKAGE BODY csr.certificate_pkg AS PROCEDURE dummy AS BEGIN NULL; END; END;
/

GRANT EXECUTE ON csr.certificate_pkg TO web_user;

-- *** Packages ***
@..\certificate_pkg
@..\certificate_body

@update_tail
