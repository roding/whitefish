function evolve_system(	particle_type::String,
						R::Array{Float64, 2},
						Lx::Float64,
						Ly::Float64,
						Lz::Float64,
						X::Array{Float64, 1},
						Y::Array{Float64, 1},
						Z::Array{Float64, 1},
						Q0::Array{Float64, 1},
						Q1::Array{Float64, 1},
						Q2::Array{Float64, 1},
						Q3::Array{Float64, 1},
						A11::Array{Float64, 1},
						A12::Array{Float64, 1},
						A13::Array{Float64, 1},
						A21::Array{Float64, 1},
						A22::Array{Float64, 1},
						A23::Array{Float64, 1},
						A31::Array{Float64, 1},
						A32::Array{Float64, 1},
						A33::Array{Float64, 1},
						position_constraint_axis::String,
						position_constraint_lower::Float64,
						position_constraint_upper::Float64,
						orientation_axis::Array{Float64, 1},
						orientation_constraint_axis::Array{Float64, 1},
						orientation_constraint_lower::Float64,
						orientation_constraint_upper::Float64,
						sigma_translation::Float64,
						sigma_translation_max::Float64,
						sigma_rotation::Float64,
						sigma_rotation_max::Float64,
						sigma_ratio::Float64,
						number_of_relaxation_sweeps_max::Int64,
						number_of_equilibration_sweeps::Int64)

	is_relaxed::Bool = false

	number_of_particles::Int64 = size(R, 1)

	acceptance_probability_target::Float64 = 0.25

	# Pre-computed max radii (i.e. radius of bounding sphere).
	RMAX::Array{Float64, 1} = zeros(number_of_particles)
	if particle_type == "sphere"
		for current_particle = 1:number_of_particles
			RMAX[current_particle] = R[current_particle, 1]
		end
	elseif particle_type == "ellipse"
		for current_particle = 1:number_of_particles
			RMAX[current_particle] = maximum( R[current_particle, 1:2] )
		end
	elseif particle_type == "ellipsoid"
		for current_particle = 1:number_of_particles
			RMAX[current_particle] = maximum( R[current_particle, 1:3] )
		end
	elseif particle_type == "cuboid"
		for current_particle = 1:number_of_particles
			RMAX[current_particle] = sqrt(R[current_particle, 1]^2 + R[current_particle, 2]^2 + R[current_particle, 3]^2)
		end
	end

	# Preallocation.
	x_star::Float64 = 0.0
	y_star::Float64 = 0.0
	z_star::Float64 = 0.0
	q0_star::Float64 = 0.0
	q1_star::Float64 = 0.0
	q2_star::Float64 = 0.0
	q3_star::Float64 = 0.0
	a11_star::Float64 = 0.0
	a12_star::Float64 = 0.0
	a13_star::Float64 = 0.0
	a21_star::Float64 = 0.0
	a22_star::Float64 = 0.0
	a23_star::Float64 = 0.0
	a31_star::Float64 = 0.0
	a32_star::Float64 = 0.0
	a33_star::Float64 = 0.0

	energy_system::Float64 = 0.0
	energy_particle::Float64 = 0.0
	energy_particle_star::Float64 = 0.0
	current_relaxation_sweep::Int64 = 0
	current_equilibration_sweep::Int64 = 0
	acceptance_probability_translation::Float64 = 0.0
	acceptance_probability_rotation::Float64 = 0.0
	acceptance_probability_combined::Float64 = 0.0
	xAB::Float64 = 0.0
	yAB::Float64 = 0.0
	zAB::Float64 = 0.0
	overlapfun::Float64 = 0.0

	is_position_ok::Bool = false

	orientation_axis_rotated::Array{Float64, 1} = zeros(3)
	angle_to_orientation_constraint_axis::Float64 = 0.0
	is_orientation_ok::Bool = false

	energy_system = 1.0
	while (energy_system > 0.0 && current_relaxation_sweep < number_of_relaxation_sweeps_max) || current_equilibration_sweep < number_of_equilibration_sweeps
		if energy_system > 0.0
			current_relaxation_sweep += 1
			#println(join(("Relaxation sweep ", string(current_relaxation_sweep))))
		else
			current_equilibration_sweep += 1
			#println(join(("Equlibration sweep ", string(current_equilibration_sweep), " out of ", string(number_of_equilibration_sweeps))))
		end

		acceptance_probability_translation = 0.0
		acceptance_probability_rotation = 0.0

		energy_system = 0.0

		for currentA = 1:number_of_particles
			# Compute current local energy.
			energy_particle = 0.0
			for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
				xAB = signed_distance_mod(X[currentA], X[currentB], Lx)
				yAB = signed_distance_mod(Y[currentA], Y[currentB], Ly)
				zAB = signed_distance_mod(Z[currentA], Z[currentB], Lz)

				if xAB^2 + yAB^2 + zAB^2 < (RMAX[currentA] + RMAX[currentB])^2
					if particle_type == "sphere"
						overlapfun = (RMAX[currentA] + RMAX[currentB])^2 - (xAB^2 + yAB^2 + zAB^2)
						energy_particle += overlapfun
					elseif particle_type == "ellipse"
						overlapfun = overlap_ellipse(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB])

						if overlapfun < 1.0
							energy_particle += (1.0 - overlapfun)^2
						end
					elseif particle_type == "ellipsoid"
						overlapfun = overlap_ellipsoid(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1]^2 * R[currentA, 2]^2 * R[currentA, 3]^2)

						if overlapfun < 1.0
							energy_particle += (1.0 - overlapfun)^2
						end
					elseif particle_type == "cuboid"
						overlapfun = overlap_cuboid(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1], R[currentA, 2], R[currentA, 3], R[currentB, 1], R[currentB, 2], R[currentB, 3])

						energy_particle += overlapfun
					end

				end
			end

			# Generate random proposal position and compute new local energy with translation.
			is_position_ok = false
			while !is_position_ok
				(x_star, y_star, z_star) = generate_proposal_position(X[currentA], Y[currentA], Z[currentA], Lx, Ly, Lz, sigma_translation)
				if position_constraint_axis == "x"
					if position_constraint_lower * Lx <= x_star <= position_constraint_upper * Lx
						is_position_ok = true
					end
				elseif position_constraint_axis == "y"
					if position_constraint_lower * Ly <= y_star <= position_constraint_upper * Ly
						is_position_ok = true
					end
				elseif position_constraint_axis == "z"
					if position_constraint_lower * Lz <= z_star <= position_constraint_upper * Lz
						is_position_ok = true
					end
				end
			end

			energy_particle_star = 0.0
			for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
				xAB = signed_distance_mod(x_star, X[currentB], Lx)
				yAB = signed_distance_mod(y_star, Y[currentB], Ly)
				zAB = signed_distance_mod(z_star, Z[currentB], Lz)

				if xAB^2 + yAB^2 + zAB^2 < (RMAX[currentA] + RMAX[currentB])^2
					if particle_type == "sphere"
						overlapfun = (RMAX[currentA] + RMAX[currentB])^2 - (xAB^2 + yAB^2 + zAB^2)
						energy_particle_star += overlapfun
					elseif particle_type == "ellipse"
						overlapfun = overlap_ellipse(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB])

						if overlapfun < 1.0
							energy_particle_star += (1.0 - overlapfun)^2
						end
					elseif particle_type == "ellipsoid"
						overlapfun = overlap_ellipsoid(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1]^2 * R[currentA, 2]^2 * R[currentA, 3]^2)

						if overlapfun < 1.0
							energy_particle_star += (1.0 - overlapfun)^2
						end
					elseif particle_type == "cuboid"
						overlapfun = overlap_cuboid(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1], R[currentA, 2], R[currentA, 3], R[currentB, 1], R[currentB, 2], R[currentB, 3])

						energy_particle_star += overlapfun
					end

				end
			end

			if energy_particle_star <= energy_particle
				X[currentA] = x_star
				Y[currentA] = y_star
				Z[currentA] = z_star

				acceptance_probability_translation += 1.0
				energy_particle = energy_particle_star
			end

			# Generate random proposal orientation and compute new local energy with rotation.
			if particle_type != "sphere"
				is_orientation_ok = false
				while !is_orientation_ok
					(q0_star, q1_star, q2_star, q3_star) = generate_proposal_orientation(Q0[currentA], Q1[currentA], Q2[currentA], Q3[currentA], sigma_rotation)
					(a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star) = rotation_matrix(q0_star, q1_star, q2_star, q3_star)
					orientation_axis_rotated[1] = a11_star * orientation_axis[1] + a12_star * orientation_axis[2] + a13_star * orientation_axis[3]
					orientation_axis_rotated[2] = a21_star * orientation_axis[1] + a22_star * orientation_axis[2] + a23_star * orientation_axis[3]
					orientation_axis_rotated[3] = a31_star * orientation_axis[1] + a32_star * orientation_axis[2] + a33_star * orientation_axis[3]
					angle_to_orientation_constraint_axis = acos(orientation_axis_rotated[1] * orientation_constraint_axis[1] + orientation_axis_rotated[2] * orientation_constraint_axis[2] + orientation_axis_rotated[3] * orientation_constraint_axis[3])
					if orientation_constraint_lower <= angle_to_orientation_constraint_axis <= orientation_constraint_upper
						is_orientation_ok = true
					end
				end

				if particle_type == "ellipse"
					(a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star) = characteristic_matrix_ellipse(q0_star, q1_star, q2_star, q3_star, R[currentA, 1], R[currentA, 2])
				elseif particle_type == "ellipsoid"
					(a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star) = characteristic_matrix_ellipsoid(q0_star, q1_star, q2_star, q3_star, R[currentA, 1], R[currentA, 2], R[currentA, 3])
				elseif particle_type == "cuboid"
					(a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star) = rotation_matrix(q0_star, q1_star, q2_star, q3_star)
				end

				energy_particle_star = 0.0
				for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
					xAB = signed_distance_mod(X[currentA], X[currentB], Lx)
					yAB = signed_distance_mod(Y[currentA], Y[currentB], Ly)
					zAB = signed_distance_mod(Z[currentA], Z[currentB], Lz)

					if xAB^2 + yAB^2 + zAB^2 < (RMAX[currentA] + RMAX[currentB])^2
						if particle_type == "ellipse"
							overlapfun = overlap_ellipse(xAB, yAB, zAB, a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star, A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB])

							if overlapfun < 1.0
								energy_particle_star += (1.0 - overlapfun)^2
							end
						elseif particle_type == "ellipsoid"
							overlapfun = overlap_ellipsoid(xAB, yAB, zAB, a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star, A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1]^2 * R[currentA, 2]^2 * R[currentA, 3]^2)

							if overlapfun < 1.0
								energy_particle_star += (1.0 - overlapfun)^2
							end
						elseif particle_type == "cuboid"
							overlapfun = overlap_cuboid(xAB, yAB, zAB, a11_star, a12_star, a13_star, a21_star, a22_star, a23_star, a31_star, a32_star, a33_star, A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1], R[currentA, 2], R[currentA, 3], R[currentB, 1], R[currentB, 2], R[currentB, 3])

							energy_particle_star += overlapfun
						end
					end
				end

				if energy_particle_star <= energy_particle
					Q0[currentA] = q0_star
					Q1[currentA] = q1_star
					Q2[currentA] = q2_star
					Q3[currentA] = q3_star

					A11[currentA] = a11_star
					A12[currentA] = a12_star
					A13[currentA] = a13_star
					A21[currentA] = a21_star
					A22[currentA] = a22_star
					A23[currentA] = a23_star
					A31[currentA] = a31_star
					A32[currentA] = a32_star
					A33[currentA] = a33_star

					acceptance_probability_rotation += 1.0
					energy_particle = energy_particle_star
				end
			end

			energy_system += energy_particle
		end

		# Update sigma_translation and sigma_rotation based on acceptance probabilities.
		if particle_type == "sphere"
			acceptance_probability_translation /= number_of_particles
			if acceptance_probability_translation <= acceptance_probability_target
				sigma_translation *= 0.95
			else
				sigma_translation = min(1.05 * sigma_translation, sigma_translation_max)
			end
		else
			acceptance_probability_translation /= number_of_particles
			if acceptance_probability_translation <= acceptance_probability_target
				sigma_translation *= 0.95
			else
				sigma_translation = min(1.05 * sigma_translation, sigma_translation_max)
			end

			acceptance_probability_rotation /= number_of_particles
			if acceptance_probability_rotation <= acceptance_probability_target
				sigma_rotation *= 0.95
			else
				sigma_rotation = min(1.05 * sigma_rotation, sigma_rotation_max, sigma_ratio * sigma_translation)
			end

		#	if sigma_ratio >= 0.0
		#		acceptance_probability_combined = (acceptance_probability_translation + acceptance_probability_rotation) / (2.0 * number_of_particles)
		#		if acceptance_probability_combined <= acceptance_probability_target
		#			sigma_translation *= 0.95
		#		else
		#			sigma_translation = min(1.05 * sigma_translation, sigma_translation_max)
		#		end

		#		sigma_rotation = sigma_ratio * sigma_translation
		#	else
		#		acceptance_probability_translation /= number_of_particles
		#		if acceptance_probability_translation <= acceptance_probability_target
		#			sigma_translation *= 0.95
		#		else
		#			sigma_translation = min(1.05 * sigma_translation, sigma_translation_max)
		#		end

		#		acceptance_probability_rotation /= number_of_particles
		#		if acceptance_probability_rotation <= acceptance_probability_target
		#			sigma_rotation *= 0.95
		#		else
		#			sigma_rotation = min(1.05 * sigma_rotation, sigma_rotation_max)
		#		end
		#	end
		end

#		# Final computation of system energy after finishing the sweep. This needs to be performed because only local optimization is performed when the particles translate and rotate.
#		energy_system = 0.0
#		if particle_type == "sphere"
#			for currentA = 1:number_of_particles
#				for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
#					xAB = signed_distance_mod(X[currentA], X[currentB], Lx)
#					yAB = signed_distance_mod(Y[currentA], Y[currentB], Ly)
#					zAB = signed_distance_mod(Z[currentA], Z[currentB], Lz)
#					overlapfun = (RMAX[currentA] + RMAX[currentB])^2 - (xAB^2 + yAB^2 + zAB^2)
#					if xAB^2 + yAB^2 + zAB^2 <= (RMAX[currentA] + RMAX[currentB])^2
#						energy_system += overlapfun
#					end
#				end
#			end
#		elseif particle_type == "ellipse"
#			for currentA = 1:number_of_particles
#				for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
#					xAB = signed_distance_mod(X[currentA], X[currentB], Lx)
#					yAB = signed_distance_mod(Y[currentA], Y[currentB], Ly)
#					zAB = signed_distance_mod(Z[currentA], Z[currentB], Lz)
#					overlapfun = overlap_ellipse(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB])
#					if overlapfun < 1.0
#						energy_system += (1.0 - overlapfun)^2
#					end
#				end
#			end
#		elseif particle_type == "ellipsoid"
#			for currentA = 1:number_of_particles
#				for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
#					xAB = signed_distance_mod(X[currentA], X[currentB], Lx)
#					yAB = signed_distance_mod(Y[currentA], Y[currentB], Ly)
#					zAB = signed_distance_mod(Z[currentA], Z[currentB], Lz)
#					overlapfun = overlap_ellipsoid(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1]^2 * R[currentA, 2]^2 * R[currentA, 3]^2)
#					if overlapfun < 1.0
#						energy_system += (1.0 - overlapfun)^2
#					end
#				end
#			end
#		elseif particle_type == "cuboid"
#			for currentA = 1:number_of_particles
#				for currentB = [1:currentA-1 ; currentA+1:number_of_particles]
#					xAB = signed_distance_mod(X[currentA], X[currentB], Lx)
#					yAB = signed_distance_mod(Y[currentA], Y[currentB], Ly)
#					zAB = signed_distance_mod(Z[currentA], Z[currentB], Lz)
#					overlapfun = overlap_cuboid(xAB, yAB, zAB, A11[currentA], A12[currentA], A13[currentA], A21[currentA], A22[currentA], A23[currentA], A31[currentA], A32[currentA], A33[currentA], A11[currentB], A12[currentB], A13[currentB], A21[currentB], A22[currentB], A23[currentB], A31[currentB], A32[currentB], A33[currentB], R[currentA, 1], R[currentA, 2], R[currentA, 3], R[currentB, 1], R[currentB, 2], R[currentB, 3])
#					energy_system += overlapfun
#				end
#			end
#		end

	end

	#println((energy_system, sigma_translation, sigma_rotation))

	if energy_system == 0.0
		is_relaxed = true
	end

	return (X, Y, Z, Q0, Q1, Q2, Q3, A11, A12, A13, A21, A22, A23, A31, A32, A33, sigma_translation, sigma_rotation, is_relaxed)
end
