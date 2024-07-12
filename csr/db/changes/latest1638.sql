-- Please update version.sql too -- this keeps clean builds in sync
define version=1638
@update_header

ALTER TABLE csrimp.issue
ADD (
    IS_PENDING_ASSIGNMENT	NUMBER(1)
);

UPDATE csrimp.issue
   SET is_pending_assignment = 0;

ALTER TABLE csrimp.issue MODIFY is_pending_assignment NOT NULL;

ALTER TABLE csrimp.issue_type
ADD (
  ALLOW_PENDING_ASSIGNMENT	NUMBER(1)
);

UPDATE csrimp.issue_type
   SET allow_pending_assignment = 0;

ALTER TABLE csrimp.issue_type MODIFY allow_pending_assignment NOT NULL;

@../csrimp/imp_body.sql

@update_tail
