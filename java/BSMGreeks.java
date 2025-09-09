import java.util.function.Function;

public class BSMGreeks {
    // Standard normal cumulative distribution function
    public static double normCDF(double x) {
        return 0.5 * (1.0 + erf(x / Math.sqrt(2.0)));
    }

    // Standard normal probability density function
    public static double normPDF(double x) {
        return Math.exp(-0.5 * x * x) / Math.sqrt(2.0 * Math.PI);
    }

    // Error function approximation (Abramowitz & Stegun, 7.1.26)
    public static double erf(double x) {
        // Save the sign of x
        int sign = (x >= 0) ? 1 : -1;
        x = Math.abs(x);
        // Constants
        double a1 = 0.254829592;
        double a2 = -0.284496736;
        double a3 = 1.421413741;
        double a4 = -1.453152027;
        double a5 = 1.061405429;
        double p = 0.3275911;
        // Abramowitz & Stegun formula 7.1.26
        double t = 1.0 / (1.0 + p * x);
        double y = 1.0 - (((((a5 * t + a4) * t + a3) * t + a2) * t + a1) * t * Math.exp(-x * x));
        return sign * y;
    }

    public static class BSMInputs {
        public double S0, K, T, sigma, r, q;
        public String optType; // "call" or "put"
        public BSMInputs(double S0, double K, double T, double sigma, double r, double q, String optType) {
            this.S0 = S0; this.K = K; this.T = T; this.sigma = sigma; this.r = r; this.q = q; this.optType = optType;
        }
    }

    public static class BSMOutputs {
        public double price, delta, gamma, vegaPerVol, vegaPerVolPt, thetaPerYear, thetaPerDay, rhoPer1, rhoPerBp, phiPer1, phiPerBp;
        public BSMOutputs(double price, double delta, double gamma, double vegaPerVol, double vegaPerVolPt, double thetaPerYear, double thetaPerDay, double rhoPer1, double rhoPerBp, double phiPer1, double phiPerBp) {
            this.price = price; this.delta = delta; this.gamma = gamma; this.vegaPerVol = vegaPerVol; this.vegaPerVolPt = vegaPerVolPt;
            this.thetaPerYear = thetaPerYear; this.thetaPerDay = thetaPerDay; this.rhoPer1 = rhoPer1; this.rhoPerBp = rhoPerBp;
            this.phiPer1 = phiPer1; this.phiPerBp = phiPerBp;
        }
    }

    public static BSMOutputs priceAndGreeksBSM(BSMInputs in, int thetaBasis) {
        double S0 = in.S0, K = in.K, T = in.T, sigma = in.sigma, r = in.r, q = in.q;
        String optType = in.optType;
        // Guards for edge cases
        if (T < 1e-6) T = 1e-6;
        if (sigma < 1e-8) sigma = 1e-8;
        double sqrtT = Math.sqrt(T);
        double d1 = (Math.log(S0 / K) + (r - q + 0.5 * sigma * sigma) * T) / (sigma * sqrtT);
        double d2 = d1 - sigma * sqrtT;
        double exp_qT = Math.exp(-q * T);
        double exp_rT = Math.exp(-r * T);
        double N_d1 = normCDF(d1);
        double N_d2 = normCDF(d2);
        double N_md1 = normCDF(-d1);
        double N_md2 = normCDF(-d2);
        double n_d1 = normPDF(d1);
        double price, delta, gamma, vega, theta, rho, phi;
        if (optType.equals("call")) {
            price = S0 * exp_qT * N_d1 - K * exp_rT * N_d2;
            delta = exp_qT * N_d1;
            theta = -S0 * exp_qT * n_d1 * sigma / (2 * sqrtT) + q * S0 * exp_qT * N_d1 - r * K * exp_rT * N_d2;
            rho = K * T * exp_rT * N_d2;
            phi = -T * S0 * exp_qT * N_d1;
        } else {
            price = K * exp_rT * N_md2 - S0 * exp_qT * N_md1;
            delta = exp_qT * N_d1 - exp_qT;
            theta = -S0 * exp_qT * n_d1 * sigma / (2 * sqrtT) - q * S0 * exp_qT * N_md1 + r * K * exp_rT * N_md2;
            rho = -K * T * exp_rT * N_md2;
            phi = T * S0 * exp_qT * N_md1;
        }
        gamma = exp_qT * n_d1 / (S0 * sigma * sqrtT);
        vega = S0 * exp_qT * n_d1 * sqrtT;
        double vegaPerVolPt = vega * 0.01;
        double thetaPerDay = theta / thetaBasis;
        double rhoPerBp = rho / 10000.0;
        double phiPerBp = phi / 10000.0;
        return new BSMOutputs(price, delta, gamma, vega, vegaPerVolPt, theta, thetaPerDay, rho, rhoPerBp, phi, phiPerBp);
    }

    public static void main(String[] args) {
        // Example from the guide
        BSMInputs in = new BSMInputs(100.0, 100.0, 0.5, 0.20, 0.03, 0.01, "call");
        // Use 365 for calendar-day theta, 252 for trading-day theta
        BSMOutputs out = priceAndGreeksBSM(in, 365);
        System.out.printf("Price: %.6f\n", out.price);
        System.out.printf("Delta: %.6f\n", out.delta);
        System.out.printf("Gamma: %.6f\n", out.gamma);
        System.out.printf("Vega (per 1.00 vol): %.6f\n", out.vegaPerVol);
        System.out.printf("Vega (per vol-pt): %.6f\n", out.vegaPerVolPt);
        System.out.printf("Theta (per year): %.6f\n", out.thetaPerYear);
        System.out.printf("Theta (per day): %.6f\n", out.thetaPerDay);
        System.out.printf("Rho (per 1.00): %.6f\n", out.rhoPer1);
        System.out.printf("Rho (per bp): %.6f\n", out.rhoPerBp);
        System.out.printf("Phi (per 1.00): %.6f\n", out.phiPer1);
        System.out.printf("Phi (per bp): %.6f\n", out.phiPerBp);
    }
}
