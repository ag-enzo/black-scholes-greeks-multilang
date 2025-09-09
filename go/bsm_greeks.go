package main

import (
	"fmt"
	"math"
)

// Standard normal cumulative distribution function
func normCDF(x float64) float64 {
	return 0.5 * (1.0 + math.Erf(x/math.Sqrt2))
}

// Standard normal probability density function
func normPDF(x float64) float64 {
	return math.Exp(-0.5*x*x) / math.Sqrt(2*math.Pi)
}

// OptionType is either Call or Put
const (
	Call = "call"
	Put  = "put"
)

type BSMInputs struct {
	S0      float64 // Spot price
	K       float64 // Strike
	T       float64 // Time to expiry (years)
	Sigma   float64 // Volatility (per annum, decimal)
	R       float64 // Risk-free rate (cont. comp.)
	Q       float64 // Dividend yield (cont. comp.)
	OptType string  // "call" or "put"
}

type BSMOutputs struct {
	Price        float64
	Delta        float64
	Gamma        float64
	VegaPerVol   float64
	VegaPerVolPt float64
	ThetaPerYear float64
	ThetaPerDay  float64
	RhoPer1      float64
	RhoPerBp     float64
	PhiPer1      float64
	PhiPerBp     float64
}

func priceAndGreeksBSM(inputs BSMInputs, thetaBasis int) BSMOutputs {
	S0, K, T, sigma, r, q := inputs.S0, inputs.K, inputs.T, inputs.Sigma, inputs.R, inputs.Q
	optType := inputs.OptType

	// Guards for edge cases
	if T < 1e-6 {
		T = 1e-6
	}
	if sigma < 1e-8 {
		sigma = 1e-8
	}

	// d1, d2
	d1 := (math.Log(S0/K) + (r-q+0.5*sigma*sigma)*T) / (sigma * math.Sqrt(T))
	d2 := d1 - sigma*math.Sqrt(T)

	expQT := math.Exp(-q * T)
	expRT := math.Exp(-r * T)

	N_d1 := normCDF(d1)
	N_d2 := normCDF(d2)
	N_md1 := normCDF(-d1)
	N_md2 := normCDF(-d2)
	n_d1 := normPDF(d1)

	var price, delta, gamma, vega, theta, rho, phi float64

	if optType == Call {
		price = S0*expQT*N_d1 - K*expRT*N_d2
		delta = expQT * N_d1
		theta = -S0*expQT*n_d1*sigma/(2*math.Sqrt(T)) + q*S0*expQT*N_d1 - r*K*expRT*N_d2
		rho = K * T * expRT * N_d2
		phi = -T * S0 * expQT * N_d1
	} else {
		price = K*expRT*N_md2 - S0*expQT*N_md1
		delta = expQT*N_d1 - expQT
		theta = -S0*expQT*n_d1*sigma/(2*math.Sqrt(T)) - q*S0*expQT*N_md1 + r*K*expRT*N_md2
		rho = -K * T * expRT * N_md2
		phi = T * S0 * expQT * N_md1
	}

	gamma = expQT * n_d1 / (S0 * sigma * math.Sqrt(T))
	vega = S0 * expQT * n_d1 * math.Sqrt(T)
	vegaPerVolPt := vega * 0.01
	thetaPerDay := theta / float64(thetaBasis)
	rhoPerBp := rho / 10000.0
	phiPerBp := phi / 10000.0

	return BSMOutputs{
		Price:        price,
		Delta:        delta,
		Gamma:        gamma,
		VegaPerVol:   vega,
		VegaPerVolPt: vegaPerVolPt,
		ThetaPerYear: theta,
		ThetaPerDay:  thetaPerDay,
		RhoPer1:      rho,
		RhoPerBp:     rhoPerBp,
		PhiPer1:      phi,
		PhiPerBp:     phiPerBp,
	}
}

func main() {
	// Example from the guide
	inputs := BSMInputs{
		S0:      100.0,
		K:       100.0,
		T:       0.5,
		Sigma:   0.20,
		R:       0.03,
		Q:       0.01,
		OptType: Call, // or Put
	}
	// Use 365 for calendar-day theta, 252 for trading-day theta
	outputs := priceAndGreeksBSM(inputs, 365)

	fmt.Printf("Price: %.6f\n", outputs.Price)
	fmt.Printf("Delta: %.6f\n", outputs.Delta)
	fmt.Printf("Gamma: %.6f\n", outputs.Gamma)
	fmt.Printf("Vega (per 1.00 vol): %.6f\n", outputs.VegaPerVol)
	fmt.Printf("Vega (per vol-pt): %.6f\n", outputs.VegaPerVolPt)
	fmt.Printf("Theta (per year): %.6f\n", outputs.ThetaPerYear)
	fmt.Printf("Theta (per day): %.6f\n", outputs.ThetaPerDay)
	fmt.Printf("Rho (per 1.00): %.6f\n", outputs.RhoPer1)
	fmt.Printf("Rho (per bp): %.6f\n", outputs.RhoPerBp)
	fmt.Printf("Phi (per 1.00): %.6f\n", outputs.PhiPer1)
	fmt.Printf("Phi (per bp): %.6f\n", outputs.PhiPerBp)
}
