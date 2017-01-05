include("read_xml_key.jl")

function read_xml_output_generation(file_path::String)
	file_stream::IOStream = open(file_path, "r")
	file_string::String = readstring(file_stream)
	close(file_stream)
			
	Lx::Float64 = read_xml_key(file_string, "domain_size_x", Float64)
	Ly::Float64 = read_xml_key(file_string, "domain_size_y", Float64)
	Lz::Float64 = read_xml_key(file_string, "domain_size_z", Float64)
	particle_type::String = read_xml_key(file_string, "particle_type", String)
	number_of_particles::Int64 = read_xml_key(file_string, "number_of_particles", Int64)
	X::Array{Float64, 1} = read_xml_key(file_string, "X", Array{Float64, 1})
	Y::Array{Float64, 1} = read_xml_key(file_string, "Y", Array{Float64, 1})
	Z::Array{Float64, 1} = read_xml_key(file_string, "Z", Array{Float64, 1})
	THETA1::Array{Float64, 1} = read_xml_key(file_string, "THETA1", Array{Float64, 1})
	THETA2::Array{Float64, 1} = read_xml_key(file_string, "THETA2", Array{Float64, 1})
	THETA3::Array{Float64, 1} = read_xml_key(file_string, "THETA3", Array{Float64, 1})
	R1::Array{Float64, 1} = read_xml_key(file_string, "R1", Array{Float64, 1})
	R2::Array{Float64, 1} = read_xml_key(file_string, "R2", Array{Float64, 1})
	
	return (Lx, Ly, Lz, particle_type, number_of_particles, X, Y, Z, THETA1, THETA2, THETA3, R1, R2)
end

#(Lx, Ly, Lz, particle_type, number_of_particles, X, Y, Z, THETA1, THETA2, THETA3, R1, R2) = read_xml_output_generation("../io_test_files/output_generation.xml")