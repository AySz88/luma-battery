function [ stepDown, stepUp, thresh ] = CalcGarciaPerezStaircase( M )
%CALCGARCIAPEREZSTAIRCASE Derives step sizes from values in M
%   as per Garcia-Perez (1998), but using QUEST's psychometric function
%
%   Requires: M.beta, M.gamma, M.delta, M.downCount (see Parameters.m)
%
%   stepDown: suggested step size down (already negative)
%   stepUp: suggested step size up
%   thresh: claimed correctness level at threshold
    
    % For 1Down1Up, 2Down1Up, 3Down1Up, and 4Down1Up respectively...
    stepRatios = ... % step down = stepRatio * step up
        [0.2845, 0.5488, 0.7393, 0.8415];
    targets = ... % claimed convergence target (percent correctness)
        [0.7785, 0.8035, 0.8315, 0.8584];
    %Sanity check: expected next step is 0 at target; example for 3down1up:
    % (1-.8315^3)/(.8315^3) = 0.7395 (approximately stepRatio)
    % so p(stepdown)*stepDown + p(step up)*stepUp = 0

    % Garcia-Perez's "p_g" is gamma, and "p_l" is (1-gamma)*delta
    spreadProbs = [M.gamma+0.01, 1-(1-M.gamma)*M.delta-0.01];
    % Rederive Garcia-Parez's 'spread' using QUEST's psychometric func
    spreadPoints = 1/M.beta * log10( log( ...
        (1-M.delta)*(1-M.gamma) ...
        ./ (M.delta*M.gamma + 1 - M.delta - spreadProbs)));
    spread = spreadPoints(2) - spreadPoints(1);
    
    stepUp = 0.75 * spread; % between 0.5*spread and 1*spread ok
    stepDown = -1 * stepRatios(M.downCount) * stepUp;
    thresh = targets(M.downCount);
end

