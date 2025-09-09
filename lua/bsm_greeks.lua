-- Black-Scholes Greeks & Pricing Calculator in Lua

-- Error function (erf) approximation (Abramowitz & Stegun, 7.1.26)
local function erf(x)
    local sign = x >= 0 and 1 or -1
    x = math.abs(x)
    local t = 1.0 / (1.0 + 0.3275911 * x)
    local a1, a2, a3, a4, a5 = 0.254829592, -0.284496736, 1.421413741, -1.453152027, 1.061405429
    local y = 1.0 - (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * math.exp(-x * x))
    return sign * y
end

-- Standard normal cumulative distribution function
local function norm_cdf(x)
    if math.erf then
        return 0.5 * (1 + math.erf(x / math.sqrt(2)))
    else
        return 0.5 * (1 + erf(x / math.sqrt(2)))
    end
end

-- Standard normal probability density function
local function norm_pdf(x)
    return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)
end

-- Main calculator function
local function price_and_greeks_bsm(inputs, theta_basis)
    local S0, K, T, sigma, r, q, opt_type = inputs.S0, inputs.K, inputs.T, inputs.sigma, inputs.r, inputs.q, inputs.opt_type
    -- Guards for edge cases
    if T < 1e-6 then T = 1e-6 end
    if sigma < 1e-8 then sigma = 1e-8 end

    local sqrtT = math.sqrt(T)
    local d1 = (math.log(S0 / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * sqrtT)
    local d2 = d1 - sigma * sqrtT

    local exp_qT = math.exp(-q * T)
    local exp_rT = math.exp(-r * T)

    local N_d1 = norm_cdf(d1)
    local N_d2 = norm_cdf(d2)
    local N_md1 = norm_cdf(-d1)
    local N_md2 = norm_cdf(-d2)
    local n_d1 = norm_pdf(d1)

    local price, delta, gamma, vega, theta, rho, phi

    if opt_type == "call" then
        price = S0 * exp_qT * N_d1 - K * exp_rT * N_d2
        delta = exp_qT * N_d1
        theta = -S0 * exp_qT * n_d1 * sigma / (2 * sqrtT) + q * S0 * exp_qT * N_d1 - r * K * exp_rT * N_d2
        rho = K * T * exp_rT * N_d2
        phi = -T * S0 * exp_qT * N_d1
    else
        price = K * exp_rT * N_md2 - S0 * exp_qT * N_md1
        delta = exp_qT * N_d1 - exp_qT
        theta = -S0 * exp_qT * n_d1 * sigma / (2 * sqrtT) - q * S0 * exp_qT * N_md1 + r * K * exp_rT * N_md2
        rho = -K * T * exp_rT * N_md2
        phi = T * S0 * exp_qT * N_md1
    end

    gamma = exp_qT * n_d1 / (S0 * sigma * sqrtT)
    vega = S0 * exp_qT * n_d1 * sqrtT
    local vega_per_volpt = vega * 0.01
    local theta_per_day = theta / theta_basis
    local rho_per_bp = rho / 10000.0
    local phi_per_bp = phi / 10000.0

    return {
        price = price,
        delta = delta,
        gamma = gamma,
        vega_per_vol = vega,
        vega_per_volpt = vega_per_volpt,
        theta_per_year = theta,
        theta_per_day = theta_per_day,
        rho_per_1 = rho,
        rho_per_bp = rho_per_bp,
        phi_per_1 = phi,
        phi_per_bp = phi_per_bp
    }
end

-- Example usage
do
    local inputs = {
        S0 = 100.0,
        K = 100.0,
        T = 0.5,
        sigma = 0.20,
        r = 0.03,
        q = 0.01,
        opt_type = "call" -- or "put"
    }
    -- Use 365 for calendar-day theta, 252 for trading-day theta
    local outputs = price_and_greeks_bsm(inputs, 365)
    print(string.format("Price: %.6f", outputs.price))
    print(string.format("Delta: %.6f", outputs.delta))
    print(string.format("Gamma: %.6f", outputs.gamma))
    print(string.format("Vega (per 1.00 vol): %.6f", outputs.vega_per_vol))
    print(string.format("Vega (per vol-pt): %.6f", outputs.vega_per_volpt))
    print(string.format("Theta (per year): %.6f", outputs.theta_per_year))
    print(string.format("Theta (per day): %.6f", outputs.theta_per_day))
    print(string.format("Rho (per 1.00): %.6f", outputs.rho_per_1))
    print(string.format("Rho (per bp): %.6f", outputs.rho_per_bp))
    print(string.format("Phi (per 1.00): %.6f", outputs.phi_per_1))
    print(string.format("Phi (per bp): %.6f", outputs.phi_per_bp))
end
