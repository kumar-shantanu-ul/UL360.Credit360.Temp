-- Please update version.sql too -- this keeps clean builds in sync
define version=1087
@update_header

UPDATE security.menu SET description = 'Business structure manager' WHERE description = 'Breakdown manager' AND action = '/csr/site/ct/hotspotter/breakdownmanager.acds';

@update_tail
