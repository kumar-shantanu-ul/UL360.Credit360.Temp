select
	owner || '.' || table_name "Owning table"
,	(
		select
			owner || '.' || table_name
		from
			all_constraints referenced_constraint
		where
			owner = all_constraints.r_owner
		and	constraint_name = all_constraints.r_constraint_name
	) "Referenced table"
,	r_owner || '.' || r_constraint_name "Constraint name"
from
	all_constraints
where
	upper(constraint_name) = upper('&1')
;