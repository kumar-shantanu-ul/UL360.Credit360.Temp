-- Please update version.sql too -- this keeps clean builds in sync
define version=1477
@update_header

-- menus have moved
update csr.std_alert_type set send_trigger = replace(send_trigger, ' is is ', ' it is ')
 where send_trigger like 'A sheet has not been submitted, but is is past the%';
 
@update_tail
