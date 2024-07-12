define version=110
@update_header

ALTER TABLE chain.customer_options DROP COLUMN DASHBOARD_TASK_SCHEME_ID;

@..\task_body

@update_tail