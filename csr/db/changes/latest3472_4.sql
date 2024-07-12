-- Please update version.sql too -- this keeps clean builds in sync
define version=3472
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.failed_notification (
    app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	failed_notification_id			NUMBER(10, 0)	NOT NULL,
	notification_type_id			VARCHAR2(36)	NOT NULL,
	to_user							VARCHAR2(36)	NOT NULL,
	channel							VARCHAR2(255)	NOT NULL,
	failure_code					VARCHAR2(255)	NOT NULL,
	from_user						VARCHAR2(36),
	merge_fields					CLOB,
	repeating_merge_fields			CLOB,
	CONSTRAINT pk_failed_notification PRIMARY KEY (app_sid, failed_notification_id)
);

ALTER TABLE csr.failed_notification ADD CONSTRAINT fk_failed_notification_notif_type_id
    FOREIGN KEY (app_sid, notification_type_id)
    REFERENCES csr.notification_type(app_sid, notification_type_id);

CREATE SEQUENCE csr.failed_notification_id_seq CACHE 5;

create index csr.ix_failed_notifi_notification_ on csr.failed_notification (app_sid, notification_type_id);

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
@../notification_pkg
@../notification_body

@update_tail
