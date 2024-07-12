-- Please update version.sql too -- this keeps clean builds in sync
define version=2394
@update_header

-- New factor types [https://fogbugz.credit360.com/default.asp?52920]
declare 
  parent_id csr.factor_type.factor_type_id%TYPE;
begin
	parent_id := 11158; -- "Fugitive Gases"

	insert into csr.factor_type(factor_type_id, parent_id, name, std_measure_id, egrid) VALUES (15630, parent_id, 'Fugitive Gas - R-401b', 1, 0);
	insert into csr.factor_type(factor_type_id, parent_id, name, std_measure_id, egrid) VALUES (15631, parent_id, 'Fugitive Gas - R-407b', 1, 0);
	insert into csr.factor_type(factor_type_id, parent_id, name, std_measure_id, egrid) VALUES (15632, parent_id, 'Fugitive Gas - R-412a', 1, 0);
	insert into csr.factor_type(factor_type_id, parent_id, name, std_measure_id, egrid) VALUES (15633, parent_id, 'Fugitive Gas - R-420a', 1, 0);
end;
/

@update_tail
