-- Please update version.sql too -- this keeps clean builds in sync
define version=1214
@update_header

create or replace package ct.consumption_pkg as
    procedure dummy;
end;
/

create or replace package body ct.consumption_pkg as
    procedure dummy
    as
    begin
        null;
    end;
end;
/ 
grant execute on ct.consumption_pkg to web_user;

@..\ct\consumption_pkg
@..\ct\consumption_body

@update_tail