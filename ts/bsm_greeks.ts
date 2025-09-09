// Black-Scholes Greeks & Pricing Calculator in TypeScript

// Standard normal cumulative distribution function
function normCDF(x: number): number {
    return 0.5 * (1 + erf(x / Math.SQRT2));
}

// Standard normal probability density function
function normPDF(x: number): number {
    return Math.exp(-0.5 * x * x) / Math.sqrt(2 * Math.PI);
}

// Error function approximation (Abramowitz & Stegun, 7.1.26)
function erf(x: number): number {
    // Save the sign of x
    const sign = x >= 0 ? 1 : -1;
    x = Math.abs(x);
    // Constants
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;
    const p = 0.3275911;
    // Abramowitz & Stegun formula 7.1.26
    const t = 1.0 / (1.0 + p * x);
    const y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Math.exp(-x * x);
    return sign * y;
}

export type BSMInputs = {
    S0: number;      // Spot price
    K: number;       // Strike
    T: number;       // Time to expiry (years)
    sigma: number;   // Volatility (per annum, decimal)
    r: number;       // Risk-free rate (cont. comp.)
    q: number;       // Dividend yield (cont. comp.)
    optType: 'call' | 'put';
};

export type BSMOutputs = {
    price: number;
    delta: number;
    gamma: number;
    vegaPerVol: number;
    vegaPerVolPt: number;
    thetaPerYear: number;
    thetaPerDay: number;
    rhoPer1: number;
    rhoPerBp: number;
    phiPer1: number;
    phiPerBp: number;
};

export function priceAndGreeksBSM(inputs: BSMInputs, thetaBasis: number): BSMOutputs {
    let { S0, K, T, sigma, r, q, optType } = inputs;
    // Guards for edge cases
    if (T < 1e-6) T = 1e-6;
    if (sigma < 1e-8) sigma = 1e-8;

    const d1 = (Math.log(S0 / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * Math.sqrt(T));
    const d2 = d1 - sigma * Math.sqrt(T);

    const expQT = Math.exp(-q * T);
    const expRT = Math.exp(-r * T);

    const N_d1 = normCDF(d1);
    const N_d2 = normCDF(d2);
    const N_md1 = normCDF(-d1);
    const N_md2 = normCDF(-d2);
    const n_d1 = normPDF(d1);

    let price: number, delta: number, gamma: number, vega: number, theta: number, rho: number, phi: number;

    if (optType === 'call') {
        price = S0 * expQT * N_d1 - K * expRT * N_d2;
        delta = expQT * N_d1;
        theta = -S0 * expQT * n_d1 * sigma / (2 * Math.sqrt(T)) + q * S0 * expQT * N_d1 - r * K * expRT * N_d2;
        rho = K * T * expRT * N_d2;
        phi = -T * S0 * expQT * N_d1;
    } else {
        price = K * expRT * N_md2 - S0 * expQT * N_md1;
        delta = expQT * N_d1 - expQT;
        theta = -S0 * expQT * n_d1 * sigma / (2 * Math.sqrt(T)) - q * S0 * expQT * N_md1 + r * K * expRT * N_md2;
        rho = -K * T * expRT * N_md2;
        phi = T * S0 * expQT * N_md1;
    }

    gamma = expQT * n_d1 / (S0 * sigma * Math.sqrt(T));
    vega = S0 * expQT * n_d1 * Math.sqrt(T);
    const vegaPerVolPt = vega * 0.01;
    const thetaPerDay = theta / thetaBasis;
    const rhoPerBp = rho / 10000.0;
    const phiPerBp = phi / 10000.0;

    return {
        price,
        delta,
        gamma,
        vegaPerVol: vega,
        vegaPerVolPt,
        thetaPerYear: theta,
        thetaPerDay,
        rhoPer1: rho,
        rhoPerBp,
        phiPer1: phi,
        phiPerBp
    };
}

// Example usage
if (require.main === module) {
    const inputs: BSMInputs = {
        S0: 100.0,
        K: 100.0,
        T: 0.5,
        sigma: 0.20,
        r: 0.03,
        q: 0.01,
        optType: 'call', // or 'put'
    };
    // Use 365 for calendar-day theta, 252 for trading-day theta
    const outputs = priceAndGreeksBSM(inputs, 365);
    console.log(`Price: ${outputs.price.toFixed(6)}`);
    console.log(`Delta: ${outputs.delta.toFixed(6)}`);
    console.log(`Gamma: ${outputs.gamma.toFixed(6)}`);
    console.log(`Vega (per 1.00 vol): ${outputs.vegaPerVol.toFixed(6)}`);
    console.log(`Vega (per vol-pt): ${outputs.vegaPerVolPt.toFixed(6)}`);
    console.log(`Theta (per year): ${outputs.thetaPerYear.toFixed(6)}`);
    console.log(`Theta (per day): ${outputs.thetaPerDay.toFixed(6)}`);
    console.log(`Rho (per 1.00): ${outputs.rhoPer1.toFixed(6)}`);
    console.log(`Rho (per bp): ${outputs.rhoPerBp.toFixed(6)}`);
    console.log(`Phi (per 1.00): ${outputs.phiPer1.toFixed(6)}`);
    console.log(`Phi (per bp): ${outputs.phiPerBp.toFixed(6)}`);
}
