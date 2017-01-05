function read_xml_input_generation(input_file_path::String)
	file_stream::IOStream = open(input_file_path, "r")
	file_string::String = readstring(file_stream)
	close(file_stream)
			
	Lx::Float64 = get_xml_key(file_string, "domain_size_x", Float64)
	Ly::Float64 = get_xml_key(file_string, "domain_size_y", Float64)
	Lz::Float64 = get_xml_key(file_string, "domain_size_z", Float64)
	number_of_particles::Int64 = get_xml_key(file_string, "number_of_particles", Int64)
	lbz::Float64 = get_xml_key(file_string, "lower_bound_z", Float64)
	ubz::Float64 = get_xml_key(file_string, "upper_bound_z", Float64)
	ubangle::Float64 = get_xml_key(file_string, "upper_bound_angle_to_z_axis", Float64)
	number_of_equilibration_sweeps::Int64 = get_xml_key(file_string, "number_of_equilibration_sweeps", Int64)
	output_path::String = get_xml_key(file_string, "output_path", String)
	
	return (Lx, Ly, Lz, number_of_particles, lbz, ubz, ubangle, number_of_equilibration_sweeps, output_path)
end