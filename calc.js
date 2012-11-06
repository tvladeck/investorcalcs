function npv (discount, payments) 
 {
        var sum = 0;
        for(var i = 0; i < payments.length; i++) 
        {
                sum += payments[i]/Math.pow((1+discount), i);
        }
        return sum;
}

function irr (payments) 
{
        if (npv(1, payments) > 0) return 1; // ensure that irr calc returns a val
        var interval = [0, 1];
        var result = 1;
        // uses the bisection method to find the root
        while (Math.abs(result) > 0.1)
        {
                var middle = (interval[0] + interval[1]) / 2;
                result = npv(middle, payments);
                if(result < 0) interval = [interval[0], middle];
                if(result > 0) interval = [middle, interval[1]];
        }
        return middle;
}

var upfrontCost,    // the amount we pay for lights upfront
    paybackMonths,  // the # of months it takes to get paid back (param for how much we charge customer)
    attritionRate,  // probability that any given customer defaults on contract w/in a year
    renewalRate,    // probability that a customer will renew after expiration of contract
    failureRate,    // percentage of lamps that fail every year (outside of normal fail rate)
    lampLife,       // number of years that lamps last (on average)
    numSimulations, // number of simulations to run the MC analysis
    months;         // number of months to run analysis for

function contractStream (fee, attritionRate, renewalRate, contractLength, months)
// Args:
//  fee: monthly fee from the customer
//  attritionRate: probability in a given month that the customer will default
//  renewalRate: probability that the customer will renew her contract
//  conractLength: length of contract in months
//  months: number of months to consider
// Returns:
//  a vector of fees. important to note that this is probablistic, so that when
//  called multiple times will return multiple answers
{
        var feeVector = [];
        var cancelRate = 1 - renewalRate;
        for(var i = 0; i < months; i++)
        {
                if(i % contractLength == 0 && i != 0 && Math.random() < cancelRate)
                // i % contractLength == 0 means that the month is a renewal month
                // i != 0 just means that the zeroth month is not considered a
                // renewal month
                // Math.random() < cancelRate means that the customer canceled
                {
                        break; // customer stops paying 
                }
                else if(Math.random() < attritionRate)
                // Math.random() < attritionRate means the customer has
                // defaulted on us
                {
                        break; // customer stops paying
                }
                else
                {
                        feeVector.push(fee); // implies customer pays another month
                }
        }

        for(var i = feeVector.length; i < months; i++)
        // all this does is add zeroes s.t. the feeVector is the right length
        {
                feeVector.push(0);
        }

        return feeVector;
}

function simulateDeals (N, upfrontCost, paybackMonths, attritionRate, 
                        renewalRate, contractLength, months)
{
        var totalUpfront = N * upfrontCost;
        var fee = upfrontCost / paybackMonths;
        var revenueStream = [];
        for (var i = 0; i < months; i++) { revenueStream.push(0); }

        var individualResults = [];
        for (var i = 0; i < N; i++)
        {
                var feeVector = contractStream(fee, attritionRate, renewalRate, contractLength, months);
                individualResults.push(feeVector);
                for (var j = 0; j < months; j++)
                {
                        revenueStream[j] += feeVector[j];
                }
        }

        var totalRevenue = 0;
        for (var i = 0; i < months; i++)
        {
                totalRevenue += revenueStream[i];
        }

        var totalVector = revenueStream; // new variable to calculate IRR
        totalVector.unshift(-totalUpfront); // need to add upfront cost
        var returns = irr(totalVector);
        returns = Math.pow((1 + returns), 12) - 1; // convert monthly IRR to annual

        var result =
        {
                capex: totalUpfront,
                irr: returns,
                stream: revenueStream,
                totalRevenue: totalRevenue,
                projects: individualResults
        };

        return result;
}

function simulateBusiness (upfrontCost, paybackMonths, attritionRate,
                           renewalRate, contractLength, stopMonths,
                           padMonths, initialSalespeople, salesAddTiming,
                           salesAddNumber, dealsPerSalesperson,
                           salesSalary, salesToOps, opsSalary)
// Args:
//  upfrontCost: the upfront cost of a single deal
//  paybackMonths: the number of months it takes for BH to get paid back under
//  our price
//  attritionRate: the annual probability of a customer defaulting and going
//  away
//  renewalRate: the probability of a customer renewing their deal with BH
//  contractLength: the length of our contracts
//  stopMonths: the number of months that salespeople are adding deals
//  padMonths: the number after stopmonths to keep considering the existing
//  deals
//  initialSalespeople: the number of salespeople we start with
//  salesAddTiming: the N in "every N months we add salespeople"
//  salesAddNumber: the number of salespeople we add when we add salespeople
//  dealsPerSalesperson: the number of deals per month per salesperson
//  salesSalary: salary of a salesperson
//  salesToOps: ratio of sales to operations people
//  opsSalary: salary of ops people
{
        var revenues = [];
        var capex    = [];
        var salaries = [];
        var projects = [];
        var salespeople = initialSalespeople;
        var opspeople   = Math.floor(initialSalespeople / salesToOps);
        var totalMonths = stopMonths + padMonths;
        for(var i = 0; i < totalMonths; i++) { revenues.push(0); }

        for(var i = 0; i < stopMonths; i++)
        {
                if(i % salesAddTiming == 0 && i != 0) 
                // i % salesAddTiming means that it is a month where we add
                // salespeople
                // i != 0 means that we don't add in the zeroth month
                {
                        salespeople += salesAddNumber;
                        opspeople    = Math.floor(salespeople / salesToOps);
                }

                var salary = salespeople * salesSalary + opspeople * opsSalary;
                salaries.push(salary);

                var numDeals = dealsPerSalesperson * salespeople;

                var monthsAhead = totalMonths - i; // this is the number of months that each set of deals will last for
                var simulation = simulateDeals(numdeals, upfrontCost, paybackMonths, attritionRate,
                                               renewalRate, contractLength, monthsAhead);

                capex.push(simulation.capex);

                var revs = simulation.stream;
                for(var j = 0; j < i; j++)
                // this just adds zeroes to the front of the revenue stream so
                // that they are all the same length
                {
                        revs.unshift(0);
                }
                for(var j = 0; j < totalMonths; j++)
                {
                        revenues[j] += revs[j];
                }
        }

        var result =
        {
                capex: capex,
                revenues: revenues,
                salaries: salaies
        };

        return result;
}

