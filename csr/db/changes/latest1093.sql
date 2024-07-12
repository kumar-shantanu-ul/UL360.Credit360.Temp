-- Please update version.sql too -- this keeps clean builds in sync
define version=1093
@update_header 

UPDATE chain.card SET js_class_type='CarbonTrust.Cards.WalkBusinessTravel' WHERE js_class_type='CarbonTrust.Cards.walkBusinessTravel';
UPDATE chain.card SET js_class_type='CarbonTrust.Cards.EmployeeCommute' WHERE js_class_type='CarbonTrust.Cards.employeeCommute';

@update_tail
