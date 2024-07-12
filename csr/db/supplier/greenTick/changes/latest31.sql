-- Please update version.sql too -- this keeps clean builds in sync
define version=31
@update_header

ALTER TABLE SUPPLIER.QUESTIONNAIRE_GROUP
 ADD (COLOUR  VARCHAR2(6 BYTE));
 
	
UPDATE QUESTIONNAIRE_GROUP SET colour = 'ee2222' 
WHERE group_id IN
(
    select group_id from questionnaire_group WHERE app_sid in (
        SELECT app_sid FROM csr.customer 
            WHERE ((host = 'bootssupplier.credit360.com') OR (host = 'bootstest.credit360.com') OR (host = 'bs.credit360.com'))
    ) 
    AND name = 'Sustainable Sourcing'
);


UPDATE QUESTIONNAIRE_GROUP SET colour = '44cc44' 
WHERE group_id IN
(
    select group_id from questionnaire_group WHERE app_sid in (
        SELECT app_sid FROM csr.customer 
            WHERE ((host = 'bootssupplier.credit360.com') OR (host = 'bootstest.credit360.com') OR (host = 'bs.credit360.com'))
    ) 
    AND name = 'Green Tick'
);
		
@update_tail