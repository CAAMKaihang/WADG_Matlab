clear
kd=[4 8 16 32];
h = 2./kd;
for i=1:length(kd)

Globals2D
N=4;
%K1D = 16;
K1D = kd(i);
c_flag = 0;
FinalTime = 0.5;
%cfun = @(x,y) ones(size(x));
cfun = @(x,y) 1+0.5*sin(pi*x).*cos(pi*y); % smooth velocity
%cfun = @(x,y) (1 + .5*sin(2*pi*x).*sin(2*pi*y) + (y > 0)); % piecewise smooth velocity

[Nv, VX, VY, K, EToV] = unif_tri_mesh(K1D);

StartUp2D;

%% for the plotting
[rp sp] = EquiNodes2D(50); [rp sp] = xytors(rp,sp);
Vp = Vandermonde2D(N,rp,sp)/V;
xp = Vp*x; yp = Vp*y; % get quadrature points on each element

%% generate the quadrature point 
Nq = 2*N+1;
[rq sq wq] = Cubature2D(Nq); % integrate u*v*c
Vq = Vandermonde2D(N,rq,sq)/V; 
xq = Vq*x; yq = Vq*y;


%% construct Pq, the projection to degree N
Pq=V*V'*Vq'*diag(wq);

%% construct projection matrices for degree 1
V1 = Vandermonde2D(1,rq,sq);

Pq1 = V1 * V1' *diag(wq); %Pq1 * Cq will give the projected function values at quadrature points

%% construct the matrix C, function values at quadrature points
Cq = cfun(xq,yq);
Cq1 = Pq1*Cq;

%% initial condition

x0 = 0; y0 = .1;
p = exp(-25*((x-x0).^2 + (y-y0).^2));
u = zeros(Np, K);
v=zeros(Np,K);


%% construct the comparison
p1 = p;
u1 = u;
v1 = v;

time = 0;

% Runge-Kutta residual storage
resu = zeros(Np,K); resv = zeros(Np,K); resp = zeros(Np,K);

resu1 = resu; resv1 = resv; resp1 = resp;

% compute time step size
CN = (N+1)*(N+2)/2; % trace inequality constant
CNh = max(CN*max(Fscale(:)));
dt = 2/CNh;

%% outer time step loop
tstep = 0;

while (time<FinalTime)
    if(time+dt>FinalTime), dt = FinalTime-time; end
    
    for INTRK = 1:5
        
        timelocal = time + rk4c(INTRK)*dt;E = invV * (p-p1);
        
        [rhsp, rhsu, rhsv] = acousticsRHS2D_WADG(p,u,v);
        [rhsp1, rhsu1,rhsv1] = acousticsRHS2D_WADG1(p1,u1,v1);
        
        % initiate and increment xlabel('K1D')
ylabel('difference')Runge-Kutta residuals
        resp = rk4a(INTRK)*resp + dt*rhsp;
        resu = rk4a(INTRK)*resu + dt*rhsu;
        resv = rk4a(INTRK)*resv + dt*rhsv;
        
        resp1 = rk4a(INTRK)*resp1 + dt*rhsp1;
        resu1 = rk4a(INTRK)*resu1 + dt*rhsu1;
        resv1 = rk4a(INTRK)*resv1 + dt*rhsv1;
        
        % update fields
        u = u+rk4b(INTRK)*resu;
        v = v+rk4b(INTRK)*resv;
        p = p+rk4b(INTRK)*resp;
        
        u1 = u1+rk4b(INTRK)*resu1;
        v1 = v1+rk4b(INTRK)*resv1;
        p1 = p1+rk4b(INTRK)*resp1;
    end
    time = time+dt; tstep = tstep+1;
end
    E = invV * (p-p1);
    ae(i) = norm(E.*J,'fro');
end 
l = [1:5];
loglog(h,ae)
title('Plot of difference as mesh varies ')
xlabel('K1D')
ylabel('difference')