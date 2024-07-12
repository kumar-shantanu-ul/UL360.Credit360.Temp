define version=10
@update_header

ALTER TABLE CUSTOMER_OPTIONS ADD  (DEFAULT_RECEIVE_SCHED_ALERTS     NUMBER(1, 0)     DEFAULT 1 NOT NULL);

@..\company_user_body


@update_tail


