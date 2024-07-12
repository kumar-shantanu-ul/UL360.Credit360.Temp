-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***

INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15784, 12561, 'Accomodation ', NULL , 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15785, 15784, 'Hotel Stay',  NULL, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15786, 15785, 'Direct',  NULL, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15787, 15786, 'Hotel Stay (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15788, 14921, 'Transmission Loss (Electric Vehicle)', NULL, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15789, 14848, 'Air Passenger Distance - International - Average Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15790, 14848, 'Air Passenger Distance - International - Average Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15791, 14848, 'Air Passenger Distance - International - Economy Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15792, 14848, 'Air Passenger Distance - International - Economy Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15793, 14848, 'Air Passenger Distance - International - Premium Economy Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15794, 14848, 'Air Passenger Distance - International - Premium Economy Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15795, 14848, 'Air Passenger Distance - International - Business Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15796, 14848, 'Air Passenger Distance - International - Business Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15797, 14848, 'Air Passenger Distance - International - First Class (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15798, 14848, 'Air Passenger Distance - International - First Class (Radiative Forcing) (+9% Uplift) (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15799, 14867, 'Air Passenger Distance - International - Average Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15800, 14867, 'Air Passenger Distance - International - Average Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15801, 14867, 'Air Passenger Distance - International - Economy Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15802, 14867, 'Air Passenger Distance - International - Economy Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15803, 14867, 'Air Passenger Distance - International - Premium Economy Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15804, 14867, 'Air Passenger Distance - International - Premium Economy Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15805, 14867, 'Air Passenger Distance - International - Business Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15806, 14867, 'Air Passenger Distance - International - Business Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15807, 14867, 'Air Passenger Distance - International - First Class (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15808, 14867, 'Air Passenger Distance - International - First Class (Radiative Forcing) (+9% Uplift) (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15809, 14922, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15810, 14922, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15811, 14922, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15812, 14922, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15813, 14922, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15814, 14922, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15815, 14922, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15816, 14922, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15817, 14922, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15818, 14922, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15819, 14922, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15820, 14922, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15821, 14922, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15822, 14922, 'Road Vehicle Distance - Car (Class A -Mini) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15823, 14922, 'Road Vehicle Distance - Car (Class B -Supermini) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15824, 14922, 'Road Vehicle Distance - Car (Class C -Lower Medium) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15825, 14922, 'Road Vehicle Distance - Car (Class D -Upper Medium) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15826, 14922, 'Road Vehicle Distance - Car (Class E -Executive) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15827, 14922, 'Road Vehicle Distance - Car (Class F -Luxury) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15828, 14922, 'Road Vehicle Distance - Car (Class G -Sports) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15829, 14922, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15830, 14922, 'Road Vehicle Distance - Car (Class I -MPV) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15831, 14922, 'Road Vehicle Distance - Car (Small Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15832, 14922, 'Road Vehicle Distance - Car (Medium Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15833, 14922, 'Road Vehicle Distance - Car (Large Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15834, 14922, 'Road Vehicle Distance - Car (Average Car) Battery Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15835, 14922, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15836, 14922, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15837, 14922, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15838, 14922, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15839, 14922, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15840, 14922, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15841, 14922, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15842, 14922, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15843, 14922, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15844, 14922, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15845, 14922, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15846, 14922, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15847, 14922, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Direct)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15848, 15788, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15849, 15788, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15850, 15788, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15851, 15788, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15852, 15788, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15853, 15788, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15854, 15788, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15855, 15788, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15856, 15788, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15857, 15788, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15858, 15788, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15859, 15788, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15860, 15788, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Transmission Loss)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15861, 14930, 'Road Vehicle Distance - Car (Class A -Mini) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15862, 14930, 'Road Vehicle Distance - Car (Class B -Supermini) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15863, 14930, 'Road Vehicle Distance - Car (Class C -Lower Medium) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15864, 14930, 'Road Vehicle Distance - Car (Class D -Upper Medium) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15865, 14930, 'Road Vehicle Distance - Car (Class E -Executive) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15866, 14930, 'Road Vehicle Distance - Car (Class F -Luxury) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15867, 14930, 'Road Vehicle Distance - Car (Class G -Sports) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15868, 14930, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15869, 14930, 'Road Vehicle Distance - Car (Class I -MPV) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15870, 14930, 'Road Vehicle Distance - Car (Small Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15871, 14930, 'Road Vehicle Distance - Car (Medium Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15872, 14930, 'Road Vehicle Distance - Car (Large Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15873, 14930, 'Road Vehicle Distance - Car (Average Car) Plug-in Hybrid Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15874, 14930, 'Road Vehicle Distance - Car (Class A -Mini) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15875, 14930, 'Road Vehicle Distance - Car (Class B -Supermini) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15876, 14930, 'Road Vehicle Distance - Car (Class C -Lower Medium) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15877, 14930, 'Road Vehicle Distance - Car (Class D -Upper Medium) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15878, 14930, 'Road Vehicle Distance - Car (Class E -Executive) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15879, 14930, 'Road Vehicle Distance - Car (Class F -Luxury) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15880, 14930, 'Road Vehicle Distance - Car (Class G -Sports) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15881, 14930, 'Road Vehicle Distance - Car (Class H -Dual purpose 4X4) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15882, 14930, 'Road Vehicle Distance - Car (Class I -MPV) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15883, 14930, 'Road Vehicle Distance - Car (Small Car) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15884, 14930, 'Road Vehicle Distance - Car (Medium Car) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15885, 14930, 'Road Vehicle Distance - Car (Large Car) Battery Electric Vehicle (Upstream)', 10, 0);
INSERT INTO csr.factor_type (factor_type_id,parent_id,name,std_measure_id,egrid) VALUES (15886, 14930, 'Road Vehicle Distance - Car (Average Car) Battery Electric Vehicle (Upstream)', 10, 0);






-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
