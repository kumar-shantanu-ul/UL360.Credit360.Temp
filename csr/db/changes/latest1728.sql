-- Please update version too -- this keeps clean builds in sync
define version=1728
@update_header

update csr.factor_type
set parent_id =
case
  when parent_id = 15269 then 15167
  when parent_id = 15303 then 15201
  when parent_id = 15337 then 15235
  when parent_id = 15167 then 15269
  when parent_id = 15201 then 15303
  when parent_id = 15235 then 15337
  else parent_id
end;

@update_tail