// Black-Scholes Greeks & Pricing Calculator in Rust

use std::f64::consts::PI;

// Standard normal cumulative distribution function
fn norm_cdf(x: f64) -> f64 {
    0.5 * (1.0 + erf(x / (2.0_f64).sqrt()))
}

// Standard normal probability density function
fn norm_pdf(x: f64) -> f64 {
    (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

// Error function approximation (Abramowitz & Stegun, 7.1.26)
fn erf(x: f64) -> f64 {
    let sign = if x >= 0.0 { 1.0 } else { -1.0 };
    let x = x.abs();
    let a1 = 0.254829592;
    let a2 = -0.284496736;
    let a3 = 1.421413741;
    let a4 = -1.453152027;
    let a5 = 1.061405429;
    let p = 0.3275911;
    let t = 1.0 / (1.0 + p * x);
    let y = 1.0 - (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * (-x * x).exp());
    sign * y
}

struct BSMInputs {
    s0: f64,
    k: f64,
    t: f64,
    sigma: f64,
    r: f64,
    q: f64,
    opt_type: String, // "call" or "put"
}

struct BSMOutputs {
    price: f64,
    delta: f64,
    gamma: f64,
    vega_per_vol: f64,
    vega_per_volpt: f64,
    theta_per_year: f64,
    theta_per_day: f64,
    rho_per_1: f64,
    rho_per_bp: f64,
    phi_per_1: f64,
    phi_per_bp: f64,
}

fn price_and_greeks_bsm(inputs: &BSMInputs, theta_basis: f64) -> BSMOutputs {
    let mut t = inputs.t;
    let mut sigma = inputs.sigma;
    if t < 1e-6 { t = 1e-6; }
    if sigma < 1e-8 { sigma = 1e-8; }
    let s0 = inputs.s0;
    let k = inputs.k;
    let r = inputs.r;
    let q = inputs.q;
    let opt_type = &inputs.opt_type;
    let sqrt_t = t.sqrt();
    let d1 = (s0 / k).ln() + (r - q + 0.5 * sigma * sigma) * t;
    let d1 = d1 / (sigma * sqrt_t);
    let d2 = d1 - sigma * sqrt_t;
    let exp_qt = (-q * t).exp();
    let exp_rt = (-r * t).exp();
    let n_d1 = norm_pdf(d1);
    let _n_d2 = norm_pdf(d2);
    let n_md1 = norm_cdf(-d1);
    let n_md2 = norm_cdf(-d2);
    let n_d1_cdf = norm_cdf(d1);
    let n_d2_cdf = norm_cdf(d2);
    let price;
    let delta;
    let theta;
    let rho;
    let phi;
    if opt_type == "call" {
        price = s0 * exp_qt * n_d1_cdf - k * exp_rt * n_d2_cdf;
        delta = exp_qt * n_d1_cdf;
        theta = -s0 * exp_qt * n_d1 * sigma / (2.0 * sqrt_t) + q * s0 * exp_qt * n_d1_cdf - r * k * exp_rt * n_d2_cdf;
        rho = k * t * exp_rt * n_d2_cdf;
        phi = -t * s0 * exp_qt * n_d1_cdf;
    } else {
        price = k * exp_rt * n_md2 - s0 * exp_qt * n_md1;
        delta = exp_qt * n_d1_cdf - exp_qt;
        theta = -s0 * exp_qt * n_d1 * sigma / (2.0 * sqrt_t) - q * s0 * exp_qt * n_md1 + r * k * exp_rt * n_md2;
        rho = -k * t * exp_rt * n_md2;
        phi = t * s0 * exp_qt * n_md1;
    }
    let gamma = exp_qt * n_d1 / (s0 * sigma * sqrt_t);
    let vega = s0 * exp_qt * n_d1 * sqrt_t;
    let vega_per_volpt = vega * 0.01;
    let theta_per_day = theta / theta_basis;
    let rho_per_bp = rho / 10000.0;
    let phi_per_bp = phi / 10000.0;
    BSMOutputs {
        price,
        delta,
        gamma,
        vega_per_vol: vega,
        vega_per_volpt,
        theta_per_year: theta,
        theta_per_day,
        rho_per_1: rho,
        rho_per_bp,
        phi_per_1: phi,
        phi_per_bp,
    }
}

fn main() {
    let inputs = BSMInputs {
        s0: 100.0,
        k: 100.0,
        t: 0.5,
        sigma: 0.20,
        r: 0.03,
        q: 0.01,
        opt_type: "call".to_string(),
    };
    // Use 365.0 for calendar-day theta, 252.0 for trading-day theta
    let outputs = price_and_greeks_bsm(&inputs, 365.0);
    println!("Price: {:.6}", outputs.price);
    println!("Delta: {:.6}", outputs.delta);
    println!("Gamma: {:.6}", outputs.gamma);
    println!("Vega (per 1.00 vol): {:.6}", outputs.vega_per_vol);
    println!("Vega (per vol-pt): {:.6}", outputs.vega_per_volpt);
    println!("Theta (per year): {:.6}", outputs.theta_per_year);
    println!("Theta (per day): {:.6}", outputs.theta_per_day);
    println!("Rho (per 1.00): {:.6}", outputs.rho_per_1);
    println!("Rho (per bp): {:.6}", outputs.rho_per_bp);
    println!("Phi (per 1.00): {:.6}", outputs.phi_per_1);
    println!("Phi (per bp): {:.6}", outputs.phi_per_bp);
}
