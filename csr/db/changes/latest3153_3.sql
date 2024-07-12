-- Please update version.sql too -- this keeps clean builds in sync
define version=3153
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE SURVEYS.SHARED_RESPONSE (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	SHARE_KEY				VARCHAR2(255)	NOT NULL,
	RESPONSE_ID				NUMBER(10, 0)	NOT NULL,
	SHARED_BY_SID			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','SID') NOT NULL,
	SHARED_DTM				DATE			DEFAULT SYSDATE NOT NULL,
	EXPIRES_DTM				DATE			DEFAULT (SYSDATE + 7) NOT NULL,
	CONSTRAINT PK_SHARED_RESPONSE PRIMARY KEY (APP_SID, SHARE_KEY)
)
;

create index surveys.ix_shared_response_response on surveys.shared_response (app_sid, response_id);


-- Alter tables

ALTER TABLE SURVEYS.SHARED_RESPONSE ADD CONSTRAINT FK_SHARED_RESPONSE_RESPONSE
	FOREIGN KEY (APP_SID, RESPONSE_ID)
	REFERENCES SURVEYS.RESPONSE(APP_SID, RESPONSE_ID)
;

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
--@..\surveys\survey_pkg
--@..\surveys\survey_body

@update_tail
