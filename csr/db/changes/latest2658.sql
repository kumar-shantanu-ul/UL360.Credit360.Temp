--Please update version.sql too -- this keeps clean builds in sync
define version=2658
@update_header

-- fix swapped single interval labels for year/month
update csr.period_interval set single_interval_no_year_label='{0:PL}' where period_set_id=1 and period_interval_id=1;
update csr.period_interval set single_interval_no_year_label='Year' where period_set_id=1 and period_interval_id=4;

@update_tail
