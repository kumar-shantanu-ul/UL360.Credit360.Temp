-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=17
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

create index csr.ix_model_instance_map_to_ind on csr.model_instance_map (app_sid, map_to_indicator_sid);
update csr.model_instance_map set map_to_indicator_sid = null where map_to_indicator_sid = -1;

begin
	for r in (select * from all_constraints where owner='CSR' and constraint_name='REFIND1573') loop
		execute immediate 'alter table csr.model_instance_map drop constraint REFIND1573';
	end loop;
end;
/

alter table csr.model_instance_map add constraint fk_model_instance_map_to_ind 
foreign key (app_sid, map_to_indicator_sid) references csr.ind (app_sid, ind_sid);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
