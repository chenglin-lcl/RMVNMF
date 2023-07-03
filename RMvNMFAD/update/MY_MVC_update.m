function [V_star, obj] = MY_MVC_update( X, MY_MVC_option)
% X: ���ݾ��� m*n
% V_star: ���յı�����
% obj: Ŀ�꺯��ֵ���� 

%% ������ֵ
maxIter = MY_MVC_option.maxIter;
k = MY_MVC_option.k;
view_num  = MY_MVC_option.view_num;
m = zeros(1, view_num); 
n = size(X{1}, 2);

%% ���ݾ���X��һ��
for i = 1: view_num
    [X{i}, ~] = data_normalization(X{i}, [], 'std');
end

%% �������
V_all = cell(1, view_num); 
U_all = cell(1, view_num); 
S = cell(1, view_num);
W = cell(1, view_num); 
W1 = cell(1, view_num);

%% ��ʼ������
for i = 1: view_num
    m(i) = size(X{i}, 1);
    [U_all{i}, V_all{i}] = UV_Init(X{i}, k);
    [W{i}, W1{i}, S{i}] = update_S(V_all{i}, MY_MVC_option);
end

%% ����һ��
for i = 1: view_num
    % ��ÿ����������һ��
    V_all{i}  = update_V(X{i}, U_all{i}, V_all, W{i}, W1{i}, MY_MVC_option, i);
    U_all{i} = update_U(X{i}, U_all{i}, V_all{i});
    [W{i}, W1{i}, S{i}] = update_S(V_all{i}, MY_MVC_option);
end

%% ��������
iter = 0;
obj = zeros(1, 1);
while iter < maxIter
    for i = 1: view_num
        
        %����ÿһ������
        V_all{i}  = update_V(X{i}, U_all{i}, V_all, W{i}, W1{i}, MY_MVC_option, i);
        U_all{i} = update_U(X{i}, U_all{i}, V_all{i});
        [W{i}, W1{i}, S{i}] = update_S(V_all{i}, MY_MVC_option);
        
        % ����Ŀ�꺯��ֵ
        iter = iter + 1;
        obj_value = calculate_obj(X, U_all, V_all, S, W, W1, MY_MVC_option);
        obj(iter) = obj_value;

        % ÿ����100�Σ����Ŀ�꺯��ֵ�͵�������
        if ~mod(iter, 100)
           fprintf("obj_value = %f, iter_num = %d\n", obj_value, iter);    
        end
    end
end

%% ����һ�¾���V*
V_star = zeros(k, n);
for i = 1: view_num
    V_star  = V_star + V_all{i};
end
V_star = V_star / view_num;
[V_star, ~] = data_normalization(V_star, [], 'std');

end


function [ V_next ] = update_V(X, U, V_all, W, W1, MY_MVC_option, p)
% X: nDim*nSmp,single view 
% U: U(t),single view 
% V_all: V_all(t),all view 
% W: Similar matrix
% W1: Diagonal matrix
% MY_MVC_option: parameter options
% p: Current View Number
% V_next: V(t+1),single view 

%����
V = V_all;
alpha = MY_MVC_option.alpha;
gamma = MY_MVC_option.gamma;
view_num = MY_MVC_option.view_num;
e = 1e-10;

% ����D
E = X-U*V{p};
D = diag(1./(2*max(sqrt(sum(E.^2, 1)), e)));
% ����V
UX = ((U') * X) * D + gamma * V{p} * W;

V_sum = zeros(size(V{1}));
for i = 1: view_num
    if i ~= p
        V_sum = V_sum + V{i};
    end
end

UUV = ((U') * U) * (V{p} * D) + alpha * V_sum + gamma * V{p} * W1 + 2 * alpha * V{p};

V_next = V{p} .* (UX ./ max(UUV, e));

end

function [ U_next ] = update_U( X, U, V)
% X: nDim*nSmp,single view 
% U: U(t),single view 
% V: V(t),single view 
% U_next: U(t+1)

% ����
e = 1e-10;

% ����D
E = X-U*V;
D = diag(1./(2*max(sqrt(sum(E.^2, 1)), e)));

% ����U
XV = X * (D * V');
UVV = U * (V  * D * (V'));
U_next = U .* (XV ./ max(UVV, e));

end

function [W, W1, S] = update_S(V, MY_MVC_option)

% ����
lambda = MY_MVC_option.lambda;
e = 1e-10;

% ����S
Dist = L2_distance_1(V, V);
eDist = exp(-1*Dist/(2*lambda));
Q = diag(1./sum(eDist, 2));
S = max(Q*eDist, e);

% ���W��W1
W = ((S')+S)/2; % Ȩ�ؾ���S�ǷǶԳ�
W1 = diag(sum(W, 1)); % �Ⱦ���

end

function [ obj_value ] = calculate_obj( X, U, V, S, W, W1, MY_MVC_option)
% X: data set
% colum: number of sample
% row: numbeor of feature
% obj_value: object function value
obj_value = 0;
view_num = MY_MVC_option.view_num;
alpha = MY_MVC_option.alpha;
gamma = MY_MVC_option.gamma;
lambda = MY_MVC_option.lambda;

for p = 1: view_num 
    obj_value = obj_value...
        + sum(sqrt(sum((X{p}-U{p}*V{p}).^2, 1)))...
        + 2*alpha*calc_traceVV(V, view_num, p)...
        + gamma*(trace(V{p}*(W1{p}-W{p})*(V{p}'))+lambda*sum(sum(S{p}.*log(S{p}))));
end

end

function [trace_VV] = calc_traceVV(V, view_num, p)
trace_VV = 0;
for i = 1: view_num
    trace_VV = trace_VV + trace(V{p}*(V{i}'));
end
end
