workspace()

include("generate_random_unit_quaternion.jl")
include("characteristic_matrix_ellipsoid.jl")
include("characteristic_matrix_ellipse.jl")
include("relax_system.jl")
include("generate_proposal_position.jl")
include("generate_proposal_orientation.jl")
include("overlap_ellipsoid.jl")
include("overlap_ellipse.jl")
include("signed_distance_mod.jl")
include("quaternion_mult.jl")

function run()
	# Simulation domain dimensions.
	Lx::Float64 = 4.0
	Ly::Float64 = 4.0
	Lz::Float64 = 4.0
	
	# Type of particles.
	#particle_type::String = "sphere"
	particle_type::String = "ellipse"
	#particle_type::String = "ellipsoid"
	
	particle_type_index::Int64 = 0
	if particle_type == "sphere"
		particle_type_index = 1
	elseif particle_type == "ellipse"
		particle_type_index = 2
	elseif particle_type == "ellipsoid"
		particle_type_index = 3
	end
	
	# Number of particles.
	number_of_particles::Int64 = 64

	# Particle property matrix (i.e. radii).
	number_of_properties::Int64 = 0
	if particle_type == "sphere"
		number_of_properties = 1
	elseif particle_type == "ellipse"
		number_of_properties = 2
	elseif particle_type == "ellipsoid"
		number_of_properties = 3
	end
	
	R::Array{Float64, 2} = zeros(number_of_particles, number_of_properties)
	#R = 0.5 * ones(number_of_particles, number_of_properties)
	R[:, 1] = 0.5 * ones(number_of_particles, 1)
	R[:, 2] = 1.0 * ones(number_of_particles, 1)
	#R[:, 3] = 1.5 * ones(number_of_particles, 1)
	
	# Positions.
	X::Array{Float64, 1} = Lx * rand(number_of_particles)
	Y::Array{Float64, 1} = Ly * rand(number_of_particles)
	Z::Array{Float64, 1} = Lz * rand(number_of_particles)
	
	# Quaternions. Generate random orientations.
	Q0::Array{Float64, 1} = zeros(number_of_particles)
	Q1::Array{Float64, 1} = zeros(number_of_particles)
	Q2::Array{Float64, 1} = zeros(number_of_particles)
	Q3::Array{Float64, 1} = zeros(number_of_particles)
	q0::Float64 = 0.0
	q1::Float64 = 0.0
	q2::Float64 = 0.0
	q3::Float64 = 0.0
	if particle_type != "sphere"
		for current_particle = 1:number_of_particles
			(q0, q1, q2, q3) = generate_random_unit_quaternion()
			Q0[current_particle] = q0
			Q1[current_particle] = q1
			Q2[current_particle] = q2
			Q3[current_particle] = q3
		end
	end
	
	# Simulation parameters.
	sigma_translation_ub::Float64 = 0.05
	sigma_rotation_ub::Float64 = 0.1
	sigma_translation::Float64 = sigma_translation_ub
	sigma_rotation::Float64 = sigma_rotation_ub
	
	# Characteristic matrix entries.
	A11::Array{Float64, 1} = zeros(number_of_particles)
	A12::Array{Float64, 1} = zeros(number_of_particles)
	A13::Array{Float64, 1} = zeros(number_of_particles)
	A21::Array{Float64, 1} = zeros(number_of_particles)
	A22::Array{Float64, 1} = zeros(number_of_particles)
	A23::Array{Float64, 1} = zeros(number_of_particles)
	A31::Array{Float64, 1} = zeros(number_of_particles)
	A32::Array{Float64, 1} = zeros(number_of_particles)
	A33::Array{Float64, 1} = zeros(number_of_particles)
	
	a11::Float64 = 0.0
	a12::Float64 = 0.0
	a13::Float64 = 0.0
	a21::Float64 = 0.0
	a22::Float64 = 0.0
	a23::Float64 = 0.0
	a31::Float64 = 0.0
	a32::Float64 = 0.0
	a33::Float64 = 0.0
	if particle_type == "ellipse"
		for current_particle = 1:number_of_particles
			(a11, a12, a13, a21, a22, a23, a31, a32, a33) = characteristic_matrix_ellipse(Q0[current_particle], Q1[current_particle], Q2[current_particle], Q3[current_particle], R[current_particle, 1], R[current_particle, 2])
			A11[current_particle] = a11
			A12[current_particle] = a12
			A13[current_particle] = a13
			A21[current_particle] = a21
			A22[current_particle] = a22
			A23[current_particle] = a23
			A31[current_particle] = a31
			A32[current_particle] = a32
			A33[current_particle] = a33
		end
	elseif particle_type == "ellipsoid"
		for current_particle = 1:number_of_particles
			(a11, a12, a13, a21, a22, a23, a31, a32, a33) = characteristic_matrix_ellipsoid(Q0[current_particle], Q1[current_particle], Q2[current_particle], Q3[current_particle], R[current_particle, 1], R[current_particle, 2], R[current_particle, 3])
			A11[current_particle] = a11
			A12[current_particle] = a12
			A13[current_particle] = a13
			A21[current_particle] = a21
			A22[current_particle] = a22
			A23[current_particle] = a23
			A31[current_particle] = a31
			A32[current_particle] = a32
			A33[current_particle] = a33
		end
	end

	# Relax system until zero energy is reached.
	(X, Y, Z, Q0, Q1, Q2, Q3, A11, A12, A13, A21, A22, A23, A31, A32, A33, sigma_translation, sigma_rotation) = 
		relax_system(Lx, Ly, Lz, particle_type, R, X, Y, Z, Q0, Q1, Q2, Q3, A11, A12, A13, A21, A22, A23, A31, A32, A33, sigma_translation, sigma_translation_ub, sigma_rotation, sigma_rotation_ub)

	# Write result to file.
	file_name_output::String = "output.dat"
	file_stream_output::IOStream = open(file_name_output, "w")
	#writedlm(file_stream_output, particle_type_index, ",")
	writedlm(file_stream_output, [Lx Ly Lz], ",")
	writedlm(file_stream_output, [R X Y Z Q0 Q1 Q2 Q3], ",")
	close(file_stream_output)
	
	nothing
end

run()