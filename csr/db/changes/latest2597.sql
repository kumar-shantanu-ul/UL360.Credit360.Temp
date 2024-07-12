-- Please update version.sql too -- this keeps clean builds in sync
define version=2597
@update_header

GRANT SELECT,REFERENCES ON security.application TO CHEM;

@update_tail
