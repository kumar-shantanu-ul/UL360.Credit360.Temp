-- Please update version.sql too -- this keeps clean builds in sync
define version=1675
@update_header

ALTER TABLE actions.customer_options
ADD (DISABLE_CALCS_WHEN_SCRIPTED NUMBER(1) DEFAULT 0);

ALTER TABLE actions.customer_options
MODIFY (DISABLE_CALCS_WHEN_SCRIPTED NOT NULL);

@update_tail


