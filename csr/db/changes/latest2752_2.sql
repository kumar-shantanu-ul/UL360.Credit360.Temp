-- Please update version.sql too -- this keeps clean builds in sync
define version=2752
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE ASPEN2.PAGE_ERROR_LOG (
	URL					VARCHAR(1024),
	LAST_ERROR_DTM		DATE,
	CONSTRAINT PK_PAGE_ERROR PRIMARY KEY (URL)
);

CREATE TABLE ASPEN2.PAGE_ERROR_LOG_DETAIL (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	HOST				VARCHAR(1024) NOT NULL,
	URL					VARCHAR(1024) NOT NULL,
	USER_SID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
	UNIQUE_ERROR_ID		VARCHAR2(1024),
	QUERY_STRING		VARCHAR2(1024),
	EXCEPTION_TYPE		VARCHAR2(1024),
	STACK_TRACE			CLOB,
	ERROR_DTM			DATE DEFAULT SYSDATE,
	CONSTRAINT PK_PAGE_ERROR_LOG_DETAIL PRIMARY KEY (UNIQUE_ERROR_ID),
	CONSTRAINT FK_PAGE_ERROR_LOG FOREIGN KEY (URL) REFERENCES ASPEN2.PAGE_ERROR_LOG(URL)
);

CREATE INDEX ASPEN2.IDX_PAGE_ERROR_LOG_DETAIL ON ASPEN2.PAGE_ERROR_LOG_DETAIL(APP_SID);

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@..\..\..\aspen2\db\error_pkg
@..\..\..\aspen2\db\error_body

@update_tail
