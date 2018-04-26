************* WWS508c PS3 *************
*  Spring 2018			              *
*  Author : Chris Austin              *
*  Email: chris.austin@princeton.edu  *
***************************************

/* Credit: Somya Bajaj, Joelle Gamble, Anastasia Korolkova, Luke Strathmann, Chris Austin
Last modified by: Chris Austin
Last modified on: 4/25/18 */

clear all

*Set directory, dta file, etc.
*cd "C:\Users\TerryMoon\Dropbox\Teaching Princeton\wws508c 2018S\ps\ps5"
cd "C:\Users\Chris\Documents\Princeton\WWS Spring 2018\WWS 508c\PS5\pS5"
use wws508c_crime_ps5

set more off
set matsize 10000
capture log close
pause on
*log using PS5.log, replace

*Download outreg2
ssc install outreg2
ssc install mdesc

**Housekeeping
label variable birthyr "Birth year"
label variable draftnumber "Draft number (1-1000)"
label variable conscripted "Fraction conscripted"
label variable crimerate "Fraction with criminal record by 2005"
label variable property "Fraction with property crime conviction in 2000-2005"
label variable murder "Fraction with murder conviciton in 2000-2005"
label variable drug "Fraction with drug conviction in 2000-2005"
label variable sexual "Fraction with sex crime conviction in 2000-2005"
label variable threat "Fraction with threat conviction in 200-2005"
label variable arms "Fraction with weapons-related conviction in 2000-2005"
label variable whitecollar "Fraction with white collar crime conviction in 2000-2005"
label variable argentine "Fraction non-indigenous Argentinean"
label variable indigenous "Fraction indigenous Argentinean"
label variable naturalized "Fraction naturalized citizens"



********************************************************************************
**                                   P1                                       **
********************************************************************************
// Describe the data. Are there differences in conscription rates or crime rates 
// across birth years?

mdesc

su

foreach i in 1958 1959 1960 1961 1962 {
	di "Concripted rate and Crime Rate for birth cohort `i'"
	su conscripted if birthyr == `i'
	su crimerate if birthyr == `i'	
	di ""
}

graph bar conscripted, over(birthyr)

pause

graph bar crimerate, over(birthyr)

**Conscription rates were highest in 1958 and tapered by 1962. 
**Crime rates gradually increased from 1958 to 1962. There appears to be a 
**negative relationship between conscription and crime rate.

pause

********************************************************************************
**                                   P2                                      **
********************************************************************************
//Use OLS to estimate the relationship between conscription rates and crime rates, 
//controlling for observable covariates. Run 8 regressions, one for crimerate and 
//one for each of the crime types. Do these results reflect causal effects of 
//conscription? Describe possible biases. Are there any biases arising from the 
//fact that data on crime type only become available starting in 2000?

**OLS with background characteristics and birthyear fixed effects.

foreach i of varlist crimerate-whitecollar {
	reg `i' conscripted argentine indigenous naturalized i.birthyr, r
	pause 
	}

**Significant positive effects for crimerate, property, threat, white collar.
**No significant effects for arms, sexual, murder, and drug.

**But OLS estimates are likely biased. We are ignoring confounding variables that
**are correlated with conscription and crimerates. As a result, we are likely 
**biasing our results. Such omitted variables may be: whether the conscriptee
**are more agressive, or being conscripted is correlated with shorter life-spans.

**If conscription is correlated with shorter lifespans, this may bias our results.
**Because crime rates don't start until 2000, and assuming the men had to be 18
**years of age before they were eligible to conscript, then crime rates were only
**observed started when those conscriptees were 56 years old at the youngest. If
**being conscripted is correlated with shorter life-spans, which may bias our results
**as we are not looking at a representative sample.

pause

********************************************************************************
**                                   P3                                      **
********************************************************************************
//The lottery assigned a draft number to each last three ID digit combination, 
//and the military then set a cutoff based on the needs of the military, such that 
//all draft numbers at or above the cutoff were eligible for conscription. Based
//on the following cutoffs, code a variable that equals 1 if eligible, 0 if not.

gen cohort_1958 = birthyr == 1958 & draftnumber >= 175

gen cohort_1959 = birthyr == 1959 & draftnumber >= 320

gen cohort_1960 = birthyr == 1960 & draftnumber >= 341

gen cohort_1961 = birthyr == 1961 & draftnumber >= 350

gen cohort_1962 = birthyr == 1962 & draftnumber >= 320

gen cutoff = cohort_1958 == 1 | cohort_1959 == 1 | cohort_1960 == 1 | cohort_1961 == 1 | cohort_1962 == 1

pause

********************************************************************************
**                                   P4                                      **
********************************************************************************
//Estimate the “first stage” effect of eligibility on conscription. Think carefully 
//about the regression specification. Do you need to control for birth year fixed 
//effects? Do you need to control for ethnic composition?

**Initial regression with birth year fixed effects.
reg conscripted cutoff argentine indigenous naturalized i.birthyr, r

**The results show that you are 65.8 percentage points more likely to conscript 
**if you were eligible at the 99% CI. This satisfies the relevance assumption; 
**eligibility correlates with conscription. cov(zi, xi) != 0. 

**Yes, you should include birth year fixed effects if we decide to include it in
**our second stage regression (I did). If there is regression to the mean as you 
**get older, we will want to look at how specific crime rate changes within each 
**age cohort.

**Alternatively, there may have been country-wide shocks that only affected one
**cohort and not others, like a new abortion law, increase in access to prenatal
**services, a war that only a subset of birth cohorts faught in.

**Yes, you should look at ethnic composition as well, in case certain groups are
**more or less likely to conscribe than others. Citizenship should also be included,
**assuming you could not be draft eligible if you were not a citizen, i.e., we are
**sure citizenship status was assigned before the lottery and not after; and if
*the latter, you were not more likely to become naturalized after conscription.

pause

********************************************************************************
**                                   P5                                       **
********************************************************************************
//Estimate the “reduced form” effect of eligibility on crime rates. As before, 
//estimate 8 regressions, one for crimerate and one for each of the crime types. 
//Do these results reflect causal effects of conscription?

foreach i of varlist crimerate-whitecollar {
	qui reg conscripted cutoff argentine indigenous naturalized i.birthyr 
	estimates store first_stage
	qui reg `i' cutoff argentine indigenous naturalized i.birthyr 
	estimates store reduced_form
	suest first_stage reduced_form, r
	nlcom [reduced_form_mean]cutoff/[first_stage_mean]cutoff
	pause
}

**Yes, the reduced form represents causal average treatment effect that conscription 
**has on crime rate. In Question 6, we will scale RF by the first stage results 
**to get the LATE.


********************************************************************************
**                                   P6                                       **
********************************************************************************
//Based on your results for questions (4) and (5), calculate instrumental variables 
//estimates for the effect of conscription on crime (both crimerate and crime types). 
//You need only calculate point estimates, not standard errors.

**See nlcom results above for IV estimates. 

pause 

********************************************************************************
**                                   P7                                       **
********************************************************************************
// Confirm your calculations by running two-stage least squares regressions. Are 
//there differences between the 2SLS (question 7) and OLS (question 2) results? 
//Why or why not?

foreach i of varlist crimerate-whitecollar {
	ivregress 2sls `i' (conscripted=cutoff) argentine indigenous naturalized i.birthyr, r first
	pause
}

**Estimates for manual calculation (RF/FS) and IV are the same as.

**The IV LATE estimate (.00267) is roughly the same as the OLS estimate (.00226).
**This is likely because eligibility is such a good predictor of conscription.
**Because the FS estimate is so close to 1, the scaled IV estimate are close to 
**original OLS estimate.

********************************************************************************
**                                   P8                                       **
********************************************************************************
//Given your knowledge of the Argentine draft (from the paragraph on page 1), 
//assess the validity of eligibility as an instrument for conscription. Does it 
//satisfy all the criteria for a valid instrument?

**Assumptions: 
*1. Relevance: Eligibility must correlate with conscription. cov(zi, xi) != 0
*2. Exogeneity: Eligibility is uncorrelated with ei; it only affects y_i through 
*conscription cov(zi, ei) = 0.

**1. We have already confirmed the relevance assumption in Question 4.

**2. For an unbiased IV estimation, the instrument must be exogenous. Eligibility
**can only affect the outcome through treatment. Although this is not testable,
**we can at least show that draft eligibility is not correlated with background 
**characteristics. If they are, then eligibility was not randomly assigned and 
**therefore there may still be OVB.

*Individual t-tests on background characteristics
foreach i in argentine indigenous naturalized {
	ttest `i', by(cutoff)
	pause
}

*Joint F-test in case eligibility is jointly correlated with background characteristics.
reg conscripted cutoff argentine indigenous naturalized i.birthyr, r
test argentine indigenous naturalized

**We cannot reject any t-tests or joint F-test, so it is likely that eligibility
**is exogenous.

**Because we meet both assumptions, we can reasonably conclude that eligibility 
**is a valid instrument.

pause

********************************************************************************
**                                   P9                                       **
********************************************************************************
//Interpret the 2SLS result for crimerate. Which population’s average treatment 
//effect does it estimate? Is it reasonable to call it a local average treatment 
//effect? Is it reasonable to call it a treatment-on-thetreated effect?

**The treatment looks at the average effect of those eligible for conscription in 
**Argentina. We cannot conclude that that this is the ATE if there is heterogeneous 
**effects; or rather, if the effect is not uniform across all enrolees. 

**That said, LATE is the average effect among individuals who were induced to 
**conscribe as a result of being draft eligible due to their specific randomly
**assigned lottery outcome and cutoff point.

**It is reasonable to call our effect the LATE; RF scaled by FS estimate (prediction 
**conscription conditional on mandatory enrollment). It is not reasonable to 
**call it TOT, unless you assume no always takers. Because we know that others 
**who did not have their number drawn still enrolled, then we know that there is
**the possibility of always takers and think it would be more reasonable to 
**conclude the IV effect as the LATE.

pause 

********************************************************************************
**                                   P10                                       **
********************************************************************************
// Israel also has a military draft. Suppose we wanted to use the results from 
//Argentina to project what would happen to Israeli crime rates if Israel switched 
//from mandatory to voluntary military service. An important distinction between 
//Argentina and Israel is that most Argentines were not eager participants in the 
//military, whereas many Israelis claim that they would enlist in the military 
//even in the absence of a draft, out of a sense of patriotism. (This statement 
//is a gross generalization, but please take it as given in your answer.) Does 
//this distinction affect whether we can use the estimate from Argentina to predict 
//the effect of the repeal of the draft in Israel?

**No. If we are assuming that in all other aspects that Israel is similar to the
**cohort studied in Argentina (faught in as many similar wars as Arganinian vets,
**trained in a similar manner, etc.), AND we assume eligibility is still randomly
**assigned, then we would not expect to see a difference among eligibles.

**That said, if this study were done in Israel instead, and again all else equal,
**we would expect there to be more always takers. In which case eligibility would
**be a poorer predicter of conscription. This would increase the scaled RF effect
**of eligibility on crime rate. Which would mean that crime rate in Israel, would
**be higher among eligibles compared to Argentina eligibles, all else constant.
