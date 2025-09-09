# Options Greeks & Black–Scholes Calculator — Inputs & Implementation Guide


---

## 1) Scope & Model

- **Products**: European **calls/puts** on equities/indices/ETFs, FX (quanto omitted), and commodity forwards.
- **Base model**: Black–Scholes–Merton (BSM) with **continuous dividend yield** \(q\).  
- **Valuation measure**: risk-neutral under domestic rate \(r\).
- **Output**: price + Greeks \(\Delta, \Gamma, \text{Vega}, \Theta, \rho\) (+ dividend rho/“phi”), and optional higher-order Greeks (Vanna, Vomma/Volga).

---

## 2) Core Inputs (minimal set to compute all Greeks)

| Name | Symbol | Type | Units / Convention | Why it’s needed |
|---|---|---|---|---|
| Underlying spot | \($S_0$\) | float \> 0 | price in underlying currency | Enters \(d_1,d_2\), all Greeks depend on it |
| Strike | \(K\) | float \> 0 | price | Payoff anchor; in \(d_1,d_2\) |
| Time to expiry | \(T\) | float \> 0 | **years** (see §3) | Scales vol; appears in discounting and \(d_1,d_2\) |
| Volatility (implied) | \(\sigma\) | float \> 0 | **per annum**, decimal (e.g., 0.20 = 20%) | Drives price curvature and vega |
| Risk-free rate (domestic) | \(r\) | float (±) | **cont. comp.** per annum | Discount factor \(e^{-rT}\), rho |
| Dividend/foreign yield | \(q\) | float (±) | **cont. comp.** per annum | Carry term; delta/vega/price weighting |
| Option type | — | enum {call, put} | — | Chooses payoff branch |
| Exercise style | — | enum {European} | — | Confirms BSM closed form applies |
| Valuation date & expiry date | — | date | ISO-8601 | Used to compute precise \(T\) per day-count |

**Alternative parametrization (recommended for FX/commodities/rates):**
- **Forward** \(F_0\) and **discount factor** \(P(0,T)\) instead of \((S_0,r,q)\):
  - \(F_0 = S_0 e^{(r-q)T}\), \(P(0,T) = e^{-rT}\)  
  - **Inputs**: \((F_0, P(0,T), K, T, \sigma, \text{type})\).  
  - Benefits: numerical stability, easier multi-curve/rates integration.

---

## 3) Time & Calendar Conventions (how to compute \(T\))

- **Day-count**: pick one and be consistent:
  - *Equities/FX (common)*: ACT/365 or ACT/365F.
  - *Trading-day flavor*: ACT/**252** (Brazil) or ACT/260 (EU) if you want Theta in trading days.  
- **Business-day vs calendar-day Theta**: decide and **document** (most shops use calendar Theta).
- **Leap years**: ACT/365 naturally handles it.
- **Precision**: compute \(T = \frac{\text{days between valuation and expiry}}{\text{denominator}}\) as a double.

---

## 4) Optional Inputs (realistic markets)

- **Discrete cash dividends** \(\{($t_i, D_i$)\}\)  
  - Handle either via spot adjustment \($S_0' = S_0 - \sum_i D_i e^{-r t_i}$\) or forward adjustment. Use with care near ex-dates.
- **Borrow/repo (equities)** or **convenience yield (commodities)**  
  - Fold into \(q\) (effective dividend yield).
- **FX**: treat \($q = r_f$\) (foreign short rate); still use same BSM form.
- **Negative rates**: allowed; use continuous-compounding consistently.

---

## 5) Outputs (with units)

| Output | Units / Notes |
|---|---|
| Price | Currency of underlying |
| Delta | **Per \$1 of spot** (dimensionless). Equity: \(\Delta \in [0,1]\) call; \([-1,0]\) put |
| Gamma | **Per \$1² of spot** |
| Vega | **Per absolute vol (1.00 = 100 vol pts)**. Also report **per vol-pt** (= Vega × 0.01) |
| Theta | **Per year** (then show **per day** = Theta/365 or /252) |
| Rho | **Per 1.00 change in \(r\)** (also show per 1 bp = /10,000) |
| Dividend Rho (“Phi”) | **Per 1.00 change in \(q\)** |

---

## 6) Base Equations (BSM with continuous yield \(q\))

\[
$d_1=\frac{\ln(S_0/K)+(r-q+\tfrac12\sigma^2)T}{\sigma\sqrt{T}}$,
\

$d_2=d_1-\sigma\sqrt{T}$
\]

Prices:
\[
$C=S_0 e^{-qT} N(d_1)-K e^{-rT} N(d_2)$,


$P=K e^{-rT} N(-d_2)-S_0 e^{-qT} N(-d_1)$
\]

Greeks:
- **Delta**: \( \Delta_$c=e^{-qT}N(d_1)$,\ \Delta_p=\Delta_c- e^{-qT}\)
- **Gamma**: \( \Gamma=\dfrac{e^{-qT} n(d_1)}{S_0 \sigma \sqrt{T}} \)
- **Vega**: \( \text{Vega}= S_0 e^{-qT} n(d_1)\sqrt{T} \) (per 1.00 vol)
- **Theta (per year)**:
  - Call: \( \Theta_c=-\dfrac{S_0 e^{-qT} n(d_1)\sigma}{2\sqrt{T}}+q S_0 e^{-qT}N(d_1)-r K e^{-rT} N(d_2) \)
  - Put:  \( \Theta_p=-\dfrac{S_0 e^{-qT} n(d_1)\sigma}{2\sqrt{T}}-q S_0 e^{-qT}N(-d_1)+r K e^{-rT} N(-d_2) \)
- **Rho**: \( \rho_c=K T e^{-rT} N(d_2),\ \rho_p=-K T e^{-rT} N(-d_2) \)
- **Dividend Rho (Phi)**: \( \phi_c=-T S_0 e^{-qT} N(d_1),\ \phi_p=T S_0 e^{-qT} N(-d_1) \)

**Forward form (numerically robust):**
- Replace \(S_0 e^{-qT}\) by **forward-PV**: \(F_0 P(0,T)\) where \(F_0=S_0 e^{(r-q)T}\), \(P(0,T)=e^{-rT}\).
- Then \(C = P(0,T)\{F_0 N(d_1) - K N(d_2)\}\) with \(d_1=\frac{\ln(F_0/K)+\tfrac12\sigma^2 T}{\sigma\sqrt{T}}\).

---

## 7) “Inputs Map” — exactly what each output depends on

| Output | Needs (minimum) |
|---|---|
| Price | \((S_0,K,T,\sigma,r,q,\text{type})\) *or* \((F_0,P(0,T),K,T,\sigma,\text{type})\) |
| Delta, Gamma | Above + \(S_0\) explicitly (or transform from forward delta) |
| Vega | Above + \(T\) (via \(\sqrt{T}\)) |
| Theta | Above + **chosen day-count** (controls per-day convention) |
| Rho | Above + \(r\) (or \(P(0,T)\)) |
| Phi | Above + \(q\) (or carry embedded in \(F_0\)) |

---

## 8) Numerical Settings (do this once, then reuse everywhere)

- **Normal PDF/CDF**: high-accuracy `erf/erfc` implementation; stable tails for \(|d|\gtrsim 8\).
- **Log terms**: prefer `log1p(x)` when applicable; guard `ln(S/K)` for extreme ratios.
- **d1,d2 stability** (forward form helps when \(F_0/K\) is extreme).
- **Theta convention**: compute **per year** then expose “per calendar day” = /365 (or your chosen denominator) to avoid inconsistency.
- **Units**: store **Vega_per_vol** and also compute **Vega_per_volpt = Vega_per_vol × 0.01**.
- **Finite differences** (if you need cross-checks or exotics):  
  - Spot bump: \(\epsilon_S \approx 0.5\%-1.0\%\) of \(S_0\)  
  - Vol bump: \(\epsilon_\sigma \approx 0.01\) (1 vol point)  
  - Rate/yield bump: \(\epsilon_r,\epsilon_q \approx 1\text{ bp}=10^{-4}\)  
  - Use **central differences** and **common random numbers** (if MC).

---

## 9) Edge Cases & Domain Guards

- **Near expiry** \(T \to 0\): clamp \(T \ge \varepsilon_T\) (e.g., \(10^{-6}\)). For \(T=0\), **price = intrinsic**, Greeks → distributional limits (report 0/NA except Delta = sign of intrinsic where sensible).
- **Deep ITM/OTM**: avoid catastrophic cancellation (`1 - N(x)` for large positive x → use tail function).
- **Zero/negative rates or yields**: allowed; continuous-comp math is robust.
- **Very small \(\sigma\)**: clamp \(\sigma \ge \varepsilon_\sigma\) (e.g., \(10^{-8}\)); price → discounted intrinsic.
- **Discrete dividends** near ex-date: BSM with continuous \(q\) can misstate Delta/Vega; if you allow discrete divs, add the **div schedule** input and adjust \(S_0\)/\(F_0\).

---

## 10) Validation & Sanity Checks (must implement)

1. **Put–call parity**: \(C - P \stackrel{?}{=} S_0 e^{-qT} - K e^{-rT}\) (tolerance \(< 10^{-10}\) typical).
2. **BS PDE identity**:  
   \[
   \Theta + \tfrac12 \sigma^2 S_0^2 \Gamma + (r-q)S_0\Delta - rV \approx 0
   \]
3. **Symmetries**: \(\Gamma_c=\Gamma_p\), \(\text{Vega}_c=\text{Vega}_p\).
4. **Monotonicities**: Call price ↑ in \(S_0,\sigma,T,r\); ↓ in \(q\). Put has opposite signs for some.
5. **Finite-diff cross-check**: numerical Greeks ≈ analytic within tolerance.

---

## 11) API Sketch (clean, testable)

```python
# Pseudocode signatures (language-agnostic intent)

struct BSMInputs:
    S0: float            # or supply F0 + DF instead
    K: float
    T: float             # years (ACT/365 or as chosen)
    sigma: float         # per annum, decimal
    r: float             # cont. comp.
    q: float             # cont. comp.
    opt_type: str        # "call" | "put"

struct CalendarConv:
    day_count: str       # "ACT/365", "ACT/252", etc.
    theta_basis: str     # "calendar" or "trading"

struct BSMOutputs:
    price: float
    delta: float
    gamma: float
    vega_per_vol: float
    vega_per_volpt: float
    theta_per_year: float
    theta_per_day: float
    rho_per_1: float
    rho_per_bp: float
    phi_per_1: float     # dividend rho
    phi_per_bp: float

function price_and_greeks_bsm(in: BSMInputs, cal: CalendarConv) -> BSMOutputs

### 11) Forward-param API (preferred for FX/commodities)

**Why**: Using forward \(F_0\) and discount factor \(DF=P(0,T)\) is numerically robust (especially for FX/commodities and multi-curve setups). It removes explicit dependence on \(r\) and \(q\) in the pricing formula.

**Inputs (forward parametrization)**

    struct FwdInputs:
        F0: float            # forward price to T (in underlying units)
        DF: float            # discount factor P(0,T) under domestic curve
        K: float             # strike
        T: float             # time to expiry in years (per chosen day-count)
        sigma: float         # implied vol (per annum, decimal)
        opt_type: "call" | "put"

**Pricing (forward form)**

- Define  
  \( d_1=\dfrac{\ln(F_0/K)+\tfrac12\sigma^2 T}{\sigma\sqrt{T}},\quad d_2=d_1-\sigma\sqrt{T}\).
- Prices (European):
  - Call: \( C = DF\,\big[F_0\,N(d_1)-K\,N(d_2)\big] \)
  - Put:  \( P = DF\,\big[K\,N(-d_2)-F_0\,N(-d_1)\big] \)

**Greeks (reported in spot terms unless noted)**

- **Delta (spot)** requires a carry assumption to map forward delta to spot delta:
  - If spot \(S_0\) and effective yield \(q\) are known (e.g., FX \(q=r_f\)):  
    \( \Delta_\text{call} = e^{-qT}N(d_1),\quad \Delta_\text{put}=\Delta_\text{call}-e^{-qT}\).
  - **Forward delta** (per unit change in \(F_0\)) without carry info:  
    \( \Delta^{(F)}_\text{call} = DF\,N(d_1),\quad \Delta^{(F)}_\text{put} = -DF\,N(-d_1)\).
  - Convert forward-delta to spot-delta if \(S_0\) and \(q\) (or repo/convenience yield) are available via \(F_0=S_0 e^{(r-q)T}\Rightarrow e^{-qT}=\dfrac{DF\,F_0}{S_0}\).

- **Gamma (spot)**  
  \( \Gamma = \dfrac{e^{-qT}\,n(d_1)}{S_0\,\sigma\sqrt{T}} \) (same as standard BSM; needs \(S_0,q\)).

- **Vega (per 1.00 vol)**  
  \( \text{Vega} = DF\,F_0\,n(d_1)\sqrt{T} \).  
  Report also **per vol-pt**: \( \text{Vega}_{1\text{vol-pt}} = 0.01 \times \text{Vega} \).

- **Theta (per year)**  
  Use the standard BSM expressions with \(S_0,r,q\) if you want calendar/trading-day Theta; or differentiate the forward-form price holding \(F_0\) fixed under your surface convention (document your choice: sticky-strike vs sticky-delta).

- **Rho / Dividend-Rho (Phi)**  
  In forward parametrization, sensitivity to \(r\) and \(q\) is embedded via \(DF\) and \(F_0\). If you need explicit **Rho** and **Phi**, map back to \(r,q\) using \(DF=e^{-rT}\) and \(F_0=S_0 e^{(r-q)T}\) and apply the closed-form BSM rho/phi.

**Notes**
- Forward form is ideal when you price off **observable forwards** (futures, FX forwards) and a **discount curve**.  
- For FX, set \(F_0=S_0\,e^{(r_d-r_f)T}\) and usually report *delta in premium-included delta conventions* only if required by desk standards.

---

### 12) Higher-Order Greeks (optional, same inputs)

- **Vanna**  
  \( \displaystyle \text{Vanna}=\frac{\partial^2 V}{\partial S\,\partial \sigma}
     = -\,e^{-qT}\,n(d_1)\,\frac{d_2}{\sigma} \)
- **Vomma / Volga**  
  \( \displaystyle \text{Vomma}=\frac{\partial^2 V}{\partial \sigma^2}
     = \text{Vega}\cdot\frac{d_1 d_2}{\sigma} \)
- **Charm / Color / Speed / Veta**  
  Time- and spot-derivatives of \(\Delta,\Gamma,\text{Vega}\). Same input set; ensure consistent **surface dynamics** (sticky-strike vs sticky-delta) when interpreting these.

---

### 13) Extension Hooks (if you later go beyond BSM)

Going beyond lognormal requires **additional model parameters** and usually different numerical engines (PDE/Fourier/MC/AAD):

- **Local Vol (Dupire)**: calibrated \(\sigma_\text{loc}(S,t)\) surface + partials; Greeks depend on state \((S,t)\).
- **Heston (stochastic vol)**: \(\kappa,\theta,\xi,\rho,v_0\); Greeks reflect vol-of-vol and spot-vol correlation.
- **SABR (rates/FX)**: \(\alpha,\beta,\rho,\nu\) (+ Hagan formula choice/backbone); quote-level greeks (sabr-vega, vanna, volga).
- **Jump-Diffusion (Merton/Kou)**: jump intensity and distribution params \((\lambda,\mu_J,\sigma_J)\); wings and gamma differ materially.

---

### 14) Example (canonical, to test your implementation)

Assume:
- \(S_0=100,\ K=100,\ T=0.5,\ \sigma=0.20,\ r=0.03,\ q=0.01\), call.
- Compute \(F_0=S_0 e^{(r-q)T}\), \(DF=e^{-rT}\).
- Then \(d_1=\dfrac{\ln(F_0/K)+\tfrac12\sigma^2 T}{\sigma\sqrt{T}},\ d_2=d_1-\sigma\sqrt{T}\).
- Price: \(C=DF\,[F_0 N(d_1)-K N(d_2)]\).
- Greeks:  
  - \( \Delta = e^{-qT}N(d_1) \), \( \Gamma = \dfrac{e^{-qT}n(d_1)}{S_0\sigma\sqrt{T}} \),  
  - \( \text{Vega} = DF\,F_0\,n(d_1)\sqrt{T} \) (also report per vol-pt = ×0.01),  
  - \( \Theta \) per chosen calendar basis,  
  - \( \rho,\phi \) via mapping back to \(r,q\) if desired.

---

### 15) Build Checklist (TL;DR)

1. Normalize dates → \(T\) with a documented day-count; pick **calendar vs trading-day Theta**.
2. Choose parameterization: **(S0,r,q)** or **(F0,DF)**. Prefer forward form when forwards/curves are primary inputs.
3. Implement **stable** \(N(\cdot), n(\cdot), d_1, d_2\) (handle extreme moneyness and tiny \(T,\sigma\)).
4. Compute price + Greeks **in one pass**; reuse \(d\)’s and normal densities/CDFs.
5. Present units clearly: Vega per 1.00 and per vol-pt; Rho/Phi per 1.00 and per bp; Theta per year and per day.
6. Validate with **put–call parity** and the **BS PDE identity**; cross-check with finite differences.
7. Guard edge cases (deep wings, \(T\to 0\), \(\sigma\to 0\), negative rates/yields).
8. Document your **surface dynamics** assumption (sticky-strike vs sticky-delta) when interpreting higher-order greeks.