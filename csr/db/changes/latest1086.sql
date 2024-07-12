define version=1086
@update_header

update csr.calc_job_phase set description='Awaiting processing' where phase=0;

@update_tail
