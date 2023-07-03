function [U, V] = UV_Init(X, k)
    rng('default');
    % �����ʼ�����е�U��V
    m = size(X, 1);
    n = size(X, 2);
    U = abs(rand(m, k));
    V = abs(rand(k, n));
    [U, V] = NormalizeUV(U, V, 1, 2);
end