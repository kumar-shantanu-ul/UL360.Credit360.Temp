-- Please update version.sql too -- this keeps clean builds in sync
define version=478
@update_header

begin
update measure_conversion set c=0 where a is not null ;
update measure_conversion set b=null,c=null where a is null ;
update measure_conversion_period set c=0 where a is not null and (b is null or c is null);
update measure_conversion_period set b=null,c=null where a is null ;
update imp_val set c=0 where a is not null and (b is null or c is null);
update imp_val set b=null,c=null where a is null;
commit;
end;
/
alter table measure_conversion add constraint ck_mconv_completed check ( (a is null and b is null and c is null) or (a is not null and b is not null and c is not null) );
alter table measure_conversion_period add constraint ck_mconv_period_completed check ( (a is null and b is null and c is null) or (a is not null and b is not null and c is not null) );
alter table imp_val add constraint ck_imp_val_conv_completed check ( (a is null and b is null and c is null) or (a is not null and b is not null and c is not null) );

@update_tail
