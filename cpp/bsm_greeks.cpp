#include <iostream>
#include <cmath>
#include <string>

// Standard normal cumulative distribution function
inline double norm_cdf(double x) {
    return 0.5 * (1.0 + std::erf(x / std::sqrt(2.0)));
}

// Standard normal probability density function
inline double norm_pdf(double x) {
    return std::exp(-0.5 * x * x) / std::sqrt(2.0 * M_PI);
}

struct BSMInputs {
    double S0;      // Spot price
    double K;       // Strike
    double T;       // Time to expiry (years)
    double sigma;   // Volatility (per annum, decimal)
    double r;       // Risk-free rate (cont. comp.)
    double q;       // Dividend yield (cont. comp.)
    std::string opt_type; // "call" or "put"
};

struct BSMOutputs {
    double price;
    double delta;
    double gamma;
    double vega_per_vol;
    double vega_per_volpt;
    double theta_per_year;
    double theta_per_day;
    double rho_per_1;
    double rho_per_bp;
    double phi_per_1;
    double phi_per_bp;
};

BSMOutputs price_and_greeks_bsm(const BSMInputs& in, int theta_basis) {
    double S0 = in.S0, K = in.K, T = in.T, sigma = in.sigma, r = in.r, q = in.q;
    std::string opt_type = in.opt_type;

    // Guards for edge cases
    if (T < 1e-6) T = 1e-6;
    if (sigma < 1e-8) sigma = 1e-8;

    double d1 = (std::log(S0 / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * std::sqrt(T));
    double d2 = d1 - sigma * std::sqrt(T);

    double exp_qT = std::exp(-q * T);
    double exp_rT = std::exp(-r * T);

    double N_d1 = norm_cdf(d1);
    double N_d2 = norm_cdf(d2);
    double N_md1 = norm_cdf(-d1);
    double N_md2 = norm_cdf(-d2);
    double n_d1 = norm_pdf(d1);

    double price, delta, gamma, vega, theta, rho, phi;

    if (opt_type == "call") {
        price = S0 * exp_qT * N_d1 - K * exp_rT * N_d2;
        delta = exp_qT * N_d1;
        theta = -S0 * exp_qT * n_d1 * sigma / (2 * std::sqrt(T)) + q * S0 * exp_qT * N_d1 - r * K * exp_rT * N_d2;
        rho = K * T * exp_rT * N_d2;
        phi = -T * S0 * exp_qT * N_d1;
    } else {
        price = K * exp_rT * N_md2 - S0 * exp_qT * N_md1;
        delta = exp_qT * N_d1 - exp_qT;
        theta = -S0 * exp_qT * n_d1 * sigma / (2 * std::sqrt(T)) - q * S0 * exp_qT * N_md1 + r * K * exp_rT * N_md2;
        rho = -K * T * exp_rT * N_md2;
        phi = T * S0 * exp_qT * N_md1;
    }

    gamma = exp_qT * n_d1 / (S0 * sigma * std::sqrt(T));
    vega = S0 * exp_qT * n_d1 * std::sqrt(T);
    double vega_per_volpt = vega * 0.01;
    double theta_per_day = theta / static_cast<double>(theta_basis);
    double rho_per_bp = rho / 10000.0;
    double phi_per_bp = phi / 10000.0;

    return BSMOutputs{
        price,
        delta,
        gamma,
        vega,
        vega_per_volpt,
        theta,
        theta_per_day,
        rho,
        rho_per_bp,
        phi,
        phi_per_bp
    };
}

int main() {
    // Example from the guide
    BSMInputs in = {100.0, 100.0, 0.5, 0.20, 0.03, 0.01, "call"};
    // Use 365 for calendar-day theta, 252 for trading-day theta
    BSMOutputs out = price_and_greeks_bsm(in, 365);

    std::cout << "Price: " << out.price << std::endl;
    std::cout << "Delta: " << out.delta << std::endl;
    std::cout << "Gamma: " << out.gamma << std::endl;
    std::cout << "Vega (per 1.00 vol): " << out.vega_per_vol << std::endl;
    std::cout << "Vega (per vol-pt): " << out.vega_per_volpt << std::endl;
    std::cout << "Theta (per year): " << out.theta_per_year << std::endl;
    std::cout << "Theta (per day): " << out.theta_per_day << std::endl;
    std::cout << "Rho (per 1.00): " << out.rho_per_1 << std::endl;
    std::cout << "Rho (per bp): " << out.rho_per_bp << std::endl;
    std::cout << "Phi (per 1.00): " << out.phi_per_1 << std::endl;
    std::cout << "Phi (per bp): " << out.phi_per_bp << std::endl;
    return 0;
}
