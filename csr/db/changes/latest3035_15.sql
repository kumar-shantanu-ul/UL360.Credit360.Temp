-- Please update version.sql too -- this keeps clean builds in sync
define version=3035
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables
drop package aspen2.fp_user_pkg;
drop package aspen2.job_pkg;
drop package aspen2.poll_pkg;
drop package aspen2.scheduledtask_pkg;
drop package aspen2.mdcomment_pkg;
drop package aspen2.supportTicket_pkg;
drop package aspen2.print_pkg;
drop package aspen2.trash_pkg;

DROP SEQUENCE ASPEN2.JOB_RUN_ID_SEQ;
DROP SEQUENCE ASPEN2.MDCOMMENT_ID_SEQ;
DROP SEQUENCE ASPEN2.MDCOMMENT_OFFENCE_ID_SEQ;
DROP SEQUENCE ASPEN2.POLL_OPTION_ID_SEQ;
DROP SEQUENCE ASPEN2.PRINT_REQUEST_ID_SEQ;
DROP SEQUENCE ASPEN2.SUPPORT_TICKET_ID_SEQ;
DROP TABLE ASPEN2.MDCOMMENT_OFFENCE;
DROP TABLE ASPEN2.MDCOMMENT;
DROP TABLE ASPEN2.MDCOMMENT_STATUS;
DROP TABLE ASPEN2.FP_USER;
DROP TABLE ASPEN2.POLL_VOTE;
DROP TABLE ASPEN2.POLL_OPTION;
DROP TABLE ASPEN2.POLL;
DROP TABLE ASPEN2.JOB_RUN;
DROP TABLE ASPEN2.JOB;
DROP TABLE ASPEN2.PRINT_RESULT;
DROP TABLE ASPEN2.PRINT_REQUEST_COOKIE;
DROP TABLE ASPEN2.PRINT_REQUEST_HEADER;
DROP TABLE ASPEN2.PRINT_REQUEST;
DROP TABLE ASPEN2.SUPPORT_ADMIN;
DROP TABLE ASPEN2.SUPPORT_TICKET;
DROP TABLE ASPEN2.SUPPORT_TYPE;
DROP TABLE ASPEN2.SUPPORT_STATUS;
DROP TABLE ASPEN2.TASKSCHEDULE;
drop table aspen2.trash;

DROP USER COMMERCE2 CASCADE;


-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- cvs/csr/db/chain/create_views.sql

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
