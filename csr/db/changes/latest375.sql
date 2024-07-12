-- Please update version.sql too -- this keeps clean builds in sync
define version=375
@update_header

-- missed out from earlier script and needed by new metering rls security functions
INSERT INTO CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Access all contracts', 0);

@..\security_functions

@update_tail
