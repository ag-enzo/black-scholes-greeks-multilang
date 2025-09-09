import math
from dataclasses import dataclass

# Standard normal cumulative distribution function
def norm_cdf(x):
    return 0.5 * (1.0 + math.erf(x / math.sqrt(2)))

# Standard normal probability density function
def norm_pdf(x):
    return math.exp(-0.5 * x * x) / math.sqrt(2 * math.pi)

@dataclass
class BSMInputs:
    S0: float      # Spot price
    K: float       # Strike
    T: float       # Time to expiry (years)
    sigma: float   # Volatility (per annum, decimal)
    r: float       # Risk-free rate (cont. comp.)
    q: float       # Dividend yield (cont. comp.)
    opt_type: str  # "call" or "put"

@dataclass
class BSMOutputs:
    price: float
    delta: float
    gamma: float
    vega_per_vol: float
    vega_per_volpt: float
    theta_per_year: float
    theta_per_day: float
    rho_per_1: float
    rho_per_bp: float
    phi_per_1: float
    phi_per_bp: float

def price_and_greeks_bsm(inputs: BSMInputs, theta_basis: int) -> BSMOutputs:
    S0, K, T, sigma, r, q = inputs.S0, inputs.K, inputs.T, inputs.sigma, inputs.r, inputs.q
    opt_type = inputs.opt_type

    # Guards for edge cases
    if T < 1e-6:
        T = 1e-6
    if sigma < 1e-8:
        sigma = 1e-8

    d1 = (math.log(S0 / K) + (r - q + 0.5 * sigma ** 2) * T) / (sigma * math.sqrt(T))
    d2 = d1 - sigma * math.sqrt(T)

    exp_qT = math.exp(-q * T)
    exp_rT = math.exp(-r * T)

    N_d1 = norm_cdf(d1)
    N_d2 = norm_cdf(d2)
    N_md1 = norm_cdf(-d1)
    N_md2 = norm_cdf(-d2)
    n_d1 = norm_pdf(d1)

    if opt_type == "call":
        price = S0 * exp_qT * N_d1 - K * exp_rT * N_d2
        delta = exp_qT * N_d1
        theta = -S0 * exp_qT * n_d1 * sigma / (2 * math.sqrt(T)) + q * S0 * exp_qT * N_d1 - r * K * exp_rT * N_d2
        rho = K * T * exp_rT * N_d2
        phi = -T * S0 * exp_qT * N_d1
    else:
        price = K * exp_rT * N_md2 - S0 * exp_qT * N_md1
        delta = exp_qT * N_d1 - exp_qT
        theta = -S0 * exp_qT * n_d1 * sigma / (2 * math.sqrt(T)) - q * S0 * exp_qT * N_md1 + r * K * exp_rT * N_md2
        rho = -K * T * exp_rT * N_md2
        phi = T * S0 * exp_qT * N_md1

    gamma = exp_qT * n_d1 / (S0 * sigma * math.sqrt(T))
    vega = S0 * exp_qT * n_d1 * math.sqrt(T)
    vega_per_volpt = vega * 0.01
    theta_per_day = theta / theta_basis
    rho_per_bp = rho / 10000.0
    phi_per_bp = phi / 10000.0

    return BSMOutputs(
        price=price,
        delta=delta,
        gamma=gamma,
        vega_per_vol=vega,
        vega_per_volpt=vega_per_volpt,
        theta_per_year=theta,
        theta_per_day=theta_per_day,
        rho_per_1=rho,
        rho_per_bp=rho_per_bp,
        phi_per_1=phi,
        phi_per_bp=phi_per_bp
    )

if __name__ == "__main__":
    # Example from the guide
    inputs = BSMInputs(
        S0=100.0,
        K=100.0,
        T=0.5,
        sigma=0.20,
        r=0.03,
        q=0.01,
        opt_type="call"  # or "put"
    )
    # Use 365 for calendar-day theta, 252 for trading-day theta
    outputs = price_and_greeks_bsm(inputs, 365)

    print(f"Price: {outputs.price:.6f}")
    print(f"Delta: {outputs.delta:.6f}")
    print(f"Gamma: {outputs.gamma:.6f}")
    print(f"Vega (per 1.00 vol): {outputs.vega_per_vol:.6f}")
    print(f"Vega (per vol-pt): {outputs.vega_per_volpt:.6f}")
    print(f"Theta (per year): {outputs.theta_per_year:.6f}")
    print(f"Theta (per day): {outputs.theta_per_day:.6f}")
    print(f"Rho (per 1.00): {outputs.rho_per_1:.6f}")
    print(f"Rho (per bp): {outputs.rho_per_bp:.6f}")
    print(f"Phi (per 1.00): {outputs.phi_per_1:.6f}")
    print(f"Phi (per bp): {outputs.phi_per_bp:.6f}")
