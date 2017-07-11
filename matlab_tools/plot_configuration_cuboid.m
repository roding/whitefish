clear
clc
close all hidden

file_name = '../src/output.dat';
file_data = dlmread(file_name, ',');

Lx = file_data(1, 1);
Ly = file_data(1, 2);
Lz = file_data(1, 3);

R1 = file_data(2:end, 1);
R2 = file_data(2:end, 2);
R3 = file_data(2:end, 3);
X = file_data(2:end, 4);
Y = file_data(2:end, 5);
Z = file_data(2:end, 6);
Q0 = file_data(2:end, 7);
Q1 = file_data(2:end, 8);
Q2 = file_data(2:end, 9);
Q3 = file_data(2:end, 10);
% 
% R1 = R1([14 18]);
% R2 = R2([14 18]);
% R3 = R3([14 18]);
% X = X([14 18]);
% Y = Y([14 18]);
% Z = Z([14 18]);
% Q0 = Q0([14 18]);
% Q1 = Q1([14 18]);
% Q2 = Q2([14 18]);
% Q3 = Q3([14 18]);

number_of_particles = numel(R1);

xsi = 2 * [0 1 1 0 0 0 ; 1 1 0 0 1 1 ; 1 1 0 0 1 1 ; 0 1 1 0 0 0] - 1;
eta = 2 * [0 0 1 1 0 0 ; 0 1 1 0 0 0 ; 0 1 1 0 1 1 ; 0 0 1 1 1 1] - 1;
zeta = 2 * [0 0 0 0 0 1 ; 0 0 0 0 0 1 ; 1 1 1 1 0 1 ; 1 1 1 1 0 1] - 1;

fig = figure();

h = axes();
hold on

count = 0;
for current_particle = 1:number_of_particles
    x = X(current_particle);
    y = Y(current_particle);
    z = Z(current_particle);
    q0 = Q0(current_particle);
    q1 = Q1(current_particle);
    q2 = Q2(current_particle);
    q3 = Q3(current_particle);
    r1 = R1(current_particle);
    r2 = R2(current_particle);
    r3 = R3(current_particle);
    
    Rq = rotation_matrix(q0, q1, q2, q3);
    XSI = Rq * [r1*xsi(:)' ; r2*eta(:)' ; r3*zeta(:)'];
    
    xsi_sc_rot = reshape(XSI(1,:), [4, 6]);
    eta_sc_rot = reshape(XSI(2,:), [4, 6]);
    zeta_sc_rot = reshape(XSI(3,:), [4, 6]);
    
    rmax = max([r1, r2, r3]);
    for i = -1:1
        for j = -1:1
            for k = -1:1
                if (i*Lx + x >= - rmax) && (i*Lx + x <= Lx + rmax) && ...
                   (j*Ly + y >= - rmax) && (j*Ly + y <= Ly + rmax) && ...
                   (k*Lz + z >= - rmax) && (k*Lz + z <= Lz + rmax)
                    
                   for current_facet = 1:6
                       hp = patch(i * Lx + x + xsi_sc_rot(:, current_facet), j * Ly + y + eta_sc_rot(:, current_facet), k * Lz + z + zeta_sc_rot(:, current_facet), [.5 .5 .5]);
                   end

                    count = count + 1;
                    disp(count)
                end
            end
        end
    end
end
                    
map = repmat([.2 .2 .8],[64 1]);
colormap(map)

% h.XLim = [0 Lx];
% h.YLim = [0 Ly];
% h.ZLim = [0 Lz];

h.XTick = [];
h.YTick = [];
h.ZTick = [];

h.Box = 'on';
h.BoxStyle = 'full';

h.Projection = 'perspective';
h.View = [60, 20];
% h.View = [-70, 15];


axis vis3d tight
camlight left; 
lighting flat

axis 'equal'
% axis([0 Lx 0 Ly 0 Lz])