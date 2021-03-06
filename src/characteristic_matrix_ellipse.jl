function characteristic_matrix_ellipse(q0::Float64, q1::Float64, q2::Float64, q3::Float64, r1::Float64, r2::Float64)

	a11::Float64 = 4.0 * r2^2 * (q0 * q3 + q1 * q2)^2 + r1^2 * (q0^2 + q1^2 - q2^2 - q3^2)^2
	a12::Float64 = r2^2 * (2.0 * q0 * q3 + 2.0 * q1 * q2) * (q0^2 - q1^2 + q2^2 - q3^2) - r1^2 * (2.0 * q0 * q3 - 2.0 * q1 * q2) * (q0^2 + q1^2 - q2^2 - q3^2)
	a13::Float64 = r1^2 * (2.0 * q0 * q2 + 2.0 * q1 * q3) * (q0^2 + q1^2 - q2^2 - q3^2) - r2^2 * (2.0 * q0 * q1 - 2.0 * q2 * q3) * (2.0 * q0 * q3 + 2.0 * q1 * q2)
	a21::Float64 = a12	
	a22::Float64 = 4.0 * r1^2 * (q0 * q3 - q1 * q2)^2 + r2^2 * (q0^2 - q1^2 + q2^2 - q3^2)^2
	a23::Float64 = - r2^2 * (2.0 * q0 * q1 - 2.0 * q2 * q3) * (q0^2 - q1^2 + q2^2 - q3^2) - r1^2 * (2.0 * q0 * q2 + 2.0 * q1 * q3) * (2.0 * q0 * q3 - 2.0 * q1 * q2)
	a31::Float64 = a13
	a32::Float64 = a23
	a33::Float64 = 4.0 * r1^2 * (q0 * q2 + q1 * q3)^2 + 4.0 * r2^2 * (q0 * q1 - q2 * q3)^2
	
	return (a11, a12, a13, a21, a22, a23, a31, a32, a33)
end