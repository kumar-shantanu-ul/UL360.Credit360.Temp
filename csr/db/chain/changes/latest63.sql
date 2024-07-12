define version=63
@update_header


ALTER TABLE chain.invitation_status
  ADD (filter_description VARCHAR2(100));

UPDATE chain.invitation_status
   SET filter_description = description
 WHERE invitation_status_id IN (1,2,3,5);

UPDATE chain.invitation_status
   SET filter_description = 'Rejected'
 WHERE invitation_status_id = 6;
 
@..\invitation_pkg
@..\invitation_body

@update_tail