-- Please update version.sql too -- this keeps clean builds in sync
define version=2755
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

DROP SEQUENCE csr.user_inactive_sys_alert_id_seq;
CREATE SEQUENCE csr.user_inactive_sys_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

DROP SEQUENCE csr.user_inactive_man_alert_id_seq;
CREATE SEQUENCE csr.user_inactive_man_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

DROP SEQUENCE csr.user_inactive_rem_alert_id_seq;
CREATE SEQUENCE csr.user_inactive_rem_alert_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***

-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
