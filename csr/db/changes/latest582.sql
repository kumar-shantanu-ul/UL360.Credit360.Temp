-- Please update version.sql too -- this keeps clean builds in sync
define version=582
@update_header

INSERT INTO customer_portlet (app_sid, portlet_id)			
	SELECT app_sid, portlet_id 
	  FROM customer, portlet 
	 where editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
	   and type IN (
		'Credit360.Portlets.Issue'
	 ) AND (app_sid, portlet_Id) NOT IN (
		select app_sid, portlet_id from customer_portlet
	 );

	

insert into customer_alert_type (app_sid, alert_Type_id)
	select app_sid, alert_type_id
	  from customer, alert_type
	 where editing_url = '/csr/site/delegation/sheet2/sheet.acds?'
	   and alert_Type_id in (17,18)
	   and (app_sid, alert_type_id) NOT IN (
		select app_sid, alert_type_id from customer_alert_type 
	);


@update_tail
