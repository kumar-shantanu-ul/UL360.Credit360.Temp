-- Please update version.sql too -- this keeps clean builds in sync
define version=3323
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.service_user_map(
	service_identifier		VARCHAR2(255)				NOT NULL,
	user_sid				NUMBER(10)					NOT NULL,
	full_name				VARCHAR2(256)				NOT NULL,
	can_impersonate			NUMBER(1)		DEFAULT 0	NOT NULL,
	CONSTRAINT pk_service_user_map PRIMARY KEY (service_identifier),
	CONSTRAINT ck_service_user_map_impersonate CHECK (can_impersonate IN (0,1))
)
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
	INSERT INTO csr.service_user_map
		(service_identifier, user_sid, full_name, can_impersonate)
	VALUES
		('scheduler', 3, 'Scheduler service user', 1);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_user_pkg
@../csr_user_body

@update_tail
