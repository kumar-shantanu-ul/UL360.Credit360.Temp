-- Please update version.sql too -- this keeps clean builds in sync
define version=665
@update_header

ALTER TABLE csr.deleg_plan
	ADD SCHEDULE_XML CLOB;

UPDATE csr.deleg_plan
   SET schedule_xml = '<recurrence><yearly><day number="1" month="' || to_char(end_dtm, 'MON') || '"/></yearly></recurrence>'
 WHERE interval = 'y';

UPDATE csr.deleg_plan
   SET schedule_xml = '<recurrence><monthly every-n="6"><day number="1"></day></monthly></recurrence>'
 WHERE interval = 'h';

UPDATE csr.deleg_plan
   SET schedule_xml = '<recurrence><monthly every-n="3"><day number="1"></day></monthly></recurrence>'
 WHERE interval = 'q';

UPDATE csr.deleg_plan
   SET schedule_xml = '<recurrence><monthly every-n="1"><day number="1"></day></monthly></recurrence>'
 WHERE interval = 'm';

ALTER TABLE csr.deleg_plan
	MODIFY schedule_xml NOT NULL;

@update_tail
