-- Please update version.sql too -- this keeps clean builds in sync
define version=1184
@update_header

ALTER TABLE CT.SUPPLIER MODIFY (APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP'));
ALTER TABLE CSR.WORKSHEET_VALUE_MAP_VALUE MODIFY (VALUE NULL);

create or replace package ct.supplier_pkg as
procedure dummy;
end;
/
create or replace package body ct.supplier_pkg as
procedure dummy
as
begin
	null;
end;
end;
/

grant execute on ct.supplier_pkg to web_user;

@..\excel_pkg
@..\excel_body

@..\ct\util_pkg
@..\ct\excel_pkg
@..\ct\supplier_pkg
@..\ct\products_services_pkg

@..\ct\util_body
@..\ct\excel_body
@..\ct\supplier_body
@..\ct\products_services_body

@update_tail
