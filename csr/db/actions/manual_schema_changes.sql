-- This file contains schema changes waiting to be entered into actions.dm1

-- latest1675.sql

ALTER TABLE actions.customer_options
ADD (DISABLE_CALCS_WHEN_SCRIPTED NUMBER(1) DEFAULT 0);

ALTER TABLE actions.customer_options
MODIFY (DISABLE_CALCS_WHEN_SCRIPTED NOT NULL);

-- end latest1675.sql

alter table actions.ind_template rename column divisible to divisibility;
