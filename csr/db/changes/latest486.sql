-- Please update version.sql too -- this keeps clean builds in sync
define version=486
@update_header

ALTER TABLE snapshot
	ADD REFRESH_XML SYS.XMLType;

UPDATE snapshot
   SET refresh_xml = '<recurrence><daily every-n="1"></daily></recurrence>'
 WHERE refresh_freq = 0;

UPDATE snapshot
   SET refresh_xml = '<recurrence><weekly every-n="1"><sunday></sunday></weekly></recurrence>'
 WHERE refresh_freq = 7;

ALTER TABLE snapshot
	MODIFY refresh_xml NOT NULL;

ALTER TABLE snapshot
	DROP column refresh_freq;

@update_tail
