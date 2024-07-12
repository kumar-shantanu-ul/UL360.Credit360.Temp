-- Please update version.sql too -- this keeps clean builds in sync
define version=1156
@update_header

DELETE FROM ct.bt_profile;
DELETE FROM ct.bt_estimate_type;

INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (1, 'Use Fuel'); 
INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (2, 'Use Distance');
INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (3, 'Use Time');
INSERT INTO ct.bt_estimate_type (bt_estimate_type_id, description) VALUES (4, 'Use Spend');

create or replace package ct.products_services_pkg as
procedure dummy;
end;
/
create or replace package body ct.products_services_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on ct.products_services_pkg to web_user;

@..\ct\business_travel_pkg
@..\ct\emp_commute_pkg
@..\ct\products_services_pkg

@..\ct\business_travel_body
@..\ct\emp_commute_body
@..\ct\products_services_body


@update_tail
