define version=93
@update_header

ALTER TABLE chain.customer_options ADD (dashboard_task_scheme_id NUMBER(10));

@update_tail