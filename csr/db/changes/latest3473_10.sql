-- Please update version.sql too -- this keeps clean builds in sync
define version=3473
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.failed_notification_archive (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	failed_notification_id			NUMBER(10, 0)	NOT NULL,
	create_dtm						DATE			DEFAULT SYSDATE NOT NULL,
	archive_reason					NUMBER(1)		NOT NULL,
	notification_type_id			VARCHAR2(36)	NOT NULL,
	to_user							VARCHAR2(36)	NOT NULL,
	channel							VARCHAR2(255)	NOT NULL,
	failure_code					VARCHAR2(255)	NOT NULL,
	failure_exception				VARCHAR2(1024),
	failure_detail					VARCHAR2(1024),
	from_user						VARCHAR2(36),
	merge_fields					CLOB,
	repeating_merge_fields			CLOB,
	CONSTRAINT pk_failed_notification_archive PRIMARY KEY (app_sid, failed_notification_id),
	CONSTRAINT ck_archive_reason CHECK (archive_reason IN (0, 1, 2))
);

-- Alter tables

-- action 0 = none, 1 = retry, 2 = delete
ALTER TABLE csr.failed_notification ADD (
	create_dtm						DATE			DEFAULT SYSDATE NOT NULL,
	action							NUMBER(1)		DEFAULT 0 NOT NULL,
	failure_exception				VARCHAR2(1024),
	failure_detail					VARCHAR2(1024),
	CONSTRAINT ck_action_valid CHECK (action IN (0, 1, 2))
);


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
@../notification_pkg
@../notification_body

@update_tail
