-- Please update version.sql too -- this keeps clean builds in sync
define version=1821
@update_header

@@latest1821_packages

-- FB33767 Delete factors with overlapping dates
begin
	security.user_pkg.logonadmin;

	begin csr.temp_factor_pkg.StdFactorDelValue(184324203);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324205);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324207);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324209);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324211);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324212);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324214);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324216);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324219);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324221);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324495);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324497);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324499);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324501);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324503);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324504);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324506);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324508);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324511);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324513);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324787);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324789);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324791);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324793);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324795);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324796);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324798);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324800);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324803);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184324805);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325079);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325081);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325083);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325085);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325087);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325088);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325090);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325092);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325095);
		exception when no_data_found then null; end;
	begin csr.temp_factor_pkg.StdFactorDelValue(184325097);
		exception when no_data_found then null; end;

end;
/

drop package csr.temp_factor_pkg;
drop package actions.temp_dependency_pkg;

@update_tail