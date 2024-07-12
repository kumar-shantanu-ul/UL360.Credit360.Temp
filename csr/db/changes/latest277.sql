-- Please update version.sql too -- this keeps clean builds in sync
define version=277
@update_header

ALTER TABLE event ADD (event_dtm date);

UPDATE event SET event_dtm = raised_dtm;

ALTER TABLE event MODIFY (event_dtm date not null);
		
@update_tail
