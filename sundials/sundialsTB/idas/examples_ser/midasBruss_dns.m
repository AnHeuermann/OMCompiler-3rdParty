function midasBruss_dns
%midasBruss_dns Brusselator example
%  This example solves the 2D Brusselator example on an (mx)x(my)
%  grid of the square with side L, using the MOL with central 
%  finite-differences for the semidiscretization in space.
%  Homogeneous BC on all sides are incorporated as algebraic
%  constraints.

% Radu Serban <radu@llnl.gov>
% LLNS Copyright Start
% Copyright (c) 2014, Lawrence Livermore National Security
% This work was performed under the auspices of the U.S. Department 
% of Energy by Lawrence Livermore National Laboratory in part under 
% Contract W-7405-Eng-48 and in part under Contract DE-AC52-07NA27344.
% Produced at the Lawrence Livermore National Laboratory.
% All rights reserved.
% For details, see the LICENSE file.
% LLNS Copyright End
% $Revision: 4075 $Date: 2007/08/21 23:09:18 $

%--------------
% Problem data
%--------------

eps = 2.0e-3; % diffusion param
A = 1.0;
B = 3.4;

% Spatial length 0 <= x,y, <= L
L = 1.0;

% grid size
mx = 20;
my = 20;
dx = L/mx;
dy = L/my;

% coefficients in central FD
hdif = eps/dx^2;
vdif = eps/dy^2;

% problem dimension
nx = mx+1;
ny = my+1;
n = 2*nx*ny;

x = linspace(0,L,nx);
y = linspace(0,L,ny);

data.eps = eps;
data.A = A;
data.B = B;
data.L = L;
data.dx = dx;
data.dy = dy;
data.nx = nx;
data.ny = ny;
data.x = x;
data.y = y;
data.hdif = hdif;
data.vdif = vdif;

%-------------------
% Initial conditions
%-------------------

[u0, v0] = BRUSic(data);
Y0 = UV2Y(u0, v0, data);
Yp0 = zeros(n,1);

% ---------------------
% Initialize integrator
% ---------------------

% Integration limits

t0 = 0.0;
tf = 1.0;

% Specify algebraic variables

u_id = ones(ny,nx);
u_id(1,:) = 0;
u_id(ny,:) = 0;
u_id(:,1) = 0;
u_id(:,nx) = 0;

v_id = ones(ny,nx);
v_id(1,:) = 0;
v_id(ny,:) = 0;
v_id(:,1) = 0;
v_id(:,nx) = 0;

id = UV2Y(u_id, v_id, data);

options = IDASetOptions('UserData',data,...
                        'RelTol',1.e-5,...
                        'AbsTol',1.e-5,...
                        'VariableTypes',id,...
                        'suppressAlgVars','on',...
                        'MaxNumSteps', 1000,...
                        'LinearSolver','Dense');

% Initialize IDAS

IDAInit(@BRUSres,t0,Y0,Yp0,options);

% Compute consistent I.C.

[status, Y0, Yp0] = IDACalcIC(tf, 'FindAlgebraic');

% ---------------
% Integrate to tf
% ---------------

plotSol(t0,Y0,data);

[status, t, Y] = IDASolve(tf, 'Normal');

plotSol(t,Y,data);

% -----------
% Free memory
% -----------

IDAFree;


%%save foo.mat t Y data

return


% ====================================================================================
% Initial conditions
% ====================================================================================

function [u0, v0] = BRUSic(data)

dx = data.dx;
dy = data.dy;
nx = data.nx;
ny = data.ny;
L  = data.L;
x  = data.x;
y  = data.y;

n = 2*nx*ny;

[x2D , y2D] = meshgrid(x,y);

u0 = 1.0 - 0.5 * cos(pi*y2D/L);
u0(1,:) = u0(2,:);
u0(ny,:) = u0(ny-1,:);
u0(:,1) = u0(:,2);
u0(:,nx) = u0(:,nx-1);

v0 = 3.5 - 2.5*cos(pi*x2D/L);
v0(1,:) = v0(2,:);
v0(ny,:) = v0(ny-1,:);
v0(:,1) = v0(:,2);
v0(:,nx) = v0(:,nx-1);

return


% ====================================================================================
% 1D <-> 2D conversion functions
% ====================================================================================

function y = UV2Y(u, v, data)

nx = data.nx;
ny = data.ny;

u1 = reshape(u, 1, nx*ny);
v1 = reshape(v, 1, nx*ny);

y = reshape([u1;v1], 2*nx*ny,1);

return


function [u,v] = Y2UV(y, data)

nx = data.nx;
ny = data.ny;

y2 = reshape(y, 2, nx*ny);

u = reshape(y2(1,:), ny, nx);
v = reshape(y2(2,:), ny, nx);

return

% ====================================================================================
% Residual function
% ====================================================================================

function [res, flag, new_data] = BRUSres(t,Y,Yp,data)

dx = data.dx;
dy = data.dy;
nx = data.nx;
ny = data.ny;

eps = data.eps;
A = data.A;
B = data.B;
L = data.L;

hdif = data.hdif;
vdif = data.vdif;

% Convert Y and Yp to (u,v) and (up, vp)

[u,v] = Y2UV(Y,data);
[up,vp] = Y2UV(Yp,data);

% 2D residuals

ru = zeros(ny,nx);
rv = zeros(ny,nx);

% Inside the domain

for iy = 2:ny-1

  for ix = 2:nx-1
    
    uu = u(iy,ix);
    vv = v(iy,ix);
    
    ru(iy,ix) = up(iy,ix) - ...
        hdif * ( u(iy,ix+1) - 2*uu + u(iy,ix-1) ) - ...
        vdif * ( u(iy+1,ix) - 2*uu + u(iy-1,ix) ) - ...
        A + (B+1)*uu - uu^2 * vv;

    rv(iy,ix) = vp(iy,ix) - ...
        hdif * ( v(iy,ix+1) - 2*vv + v(iy,ix-1) ) - ...
        vdif * ( v(iy+1,ix) - 2*vv + v(iy-1,ix) ) - ...
        B*uu + uu^2 * vv;
    
  end
  
end
    
% Boundary conditions

ru(1,:) = u(1,:) - u(2,:);
ru(ny,:) = u(ny,:) - u(ny-1,:);
ru(:,1) = u(:,1) - u(:,2);
ru(:,nx) = u(:,nx) - u(:,nx-1);

rv(1,:) = v(1,:) - v(2,:);
rv(ny,:) = v(ny,:) - v(ny-1,:);
rv(:,1) = v(:,1) - v(:,2);
rv(:,nx) = v(:,nx) - v(:,nx-1);

% Convert (ru,rv) to res

res = UV2Y(ru,rv,data);

% Return flag and pb. data

flag = 0;
new_data = [];

% ====================================================================================
% Plot (u,v)
% ====================================================================================

function plotSol(t,Y,data)

x = data.x;
y = data.y;

[u,v] = Y2UV(Y, data);

figure;
set(gcf,'position',[600 600 650 300])

subplot(1,2,1)
surfc(x,y,u);
shading interp
%view(0,90)
view(-15,35)
axis tight
box on
grid off
xlabel('x');
ylabel('y');
title(sprintf('u(x,y,%g)',t))
%colorbar('horiz');

subplot(1,2,2)
surfc(x,y,v);
shading interp
%view(0,90)
view(-15,35)
axis tight
box on
grid off
xlabel('x');
ylabel('y');
title(sprintf('v(x,y,%g)',t))
%colorbar('horiz');

return
