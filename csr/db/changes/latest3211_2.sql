-- Please update version.sql too -- this keeps clean builds in sync
define version=3211
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.axis DROP CONSTRAINT FK_AXIS_REL_AXIS_LEFT;
ALTER TABLE csr.axis DROP CONSTRAINT FK_AXIS_REL_AXIS_RIGHT;
DROP TABLE csr.related_axis_member;
DROP TABLE csr.related_axis;
DROP TABLE csr.selected_axis_task;
DROP TABLE csr.axis_member;
DROP TABLE csr.axis;


DROP SEQUENCE CSR.AXIS_ID_SEQ;
DROP SEQUENCE CSR.AXIS_MEMBER_ID_SEQ;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM csr.capability WHERE NAME = 'Configure strategy dashboard';
DELETE FROM csr.capability WHERE NAME = 'View strategy dashboard';

DROP PACKAGE csr.strategy_pkg;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\..\..\aspen2\cms\db\web_publication_body
@..\csr_app_body
@..\actions\task_body
@..\actions\initiative_body

@update_tail
