-- Please update version.sql too -- this keeps clean builds in sync
define version=3319
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.scheduled_task_stat(
	scheduled_task_stat_run_id		NUMBER(10,0) NOT NULL,
	task_group						VARCHAR2(255) NOT NULL,
	task_name						VARCHAR2(255) NOT NULL,
	ran_on							VARCHAR2(255) NOT NULL,
	run_start_dtm					DATE DEFAULT SYSDATE NOT NULL,
	run_end_dtm						DATE,
	number_of_apps					NUMBER(10,0),
	number_of_items					NUMBER(10,0),
	number_of_handled_failures		NUMBER(10,0),
	fetch_time_secs					NUMBER(10,0),
	work_time_secs					NUMBER(10,0),
	was_unhandled_failure			NUMBER(1,0),
	CONSTRAINT pk_scheduled_task_stat PRIMARY KEY (scheduled_task_stat_run_id),
	CONSTRAINT ck_scheduled_task_stat_fail CHECK (was_unhandled_failure IS NULL OR was_unhandled_failure IN (0,1))
)
PARTITION BY RANGE (run_start_dtm)
INTERVAL(NUMTOYMINTERVAL(1, 'MONTH'))
( 
	PARTITION sched_task_stat_p1 VALUES LESS THAN (TO_DATE('01-09-2020', 'DD-MM-YYYY'))
);

CREATE INDEX CSR.SCHED_TASK_STAT_IDX1 ON CSR.SCHEDULED_TASK_STAT
    (TASK_GROUP, TASK_NAME) LOCAL;

CREATE SEQUENCE csr.scheduled_task_stat_id CACHE 5;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **
create or replace package csr.scheduled_task_pkg  as end;
/
grant execute on CSR.scheduled_task_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../scheduled_task_pkg
@../scheduled_task_body

@update_tail
