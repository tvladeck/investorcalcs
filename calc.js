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

        console.log('check 1');
        for (var i = 0; i < N; i++)
        {
                var feeVector = contractStream(fee, attritionRate, renewalRate, contractLength, months);
                for (var j = 0; j < months; j++)
                {
                        revenueStream[j] += feeVector[j];
                }
        }

        console.log('check 2');
        var totalRevenue = 0;
        for (var i = 0; i < months; i++)
        {
                totalRevenue += revenueStream[i];
        }

        console.log('check 3');
        var totalVector = revenueStream;
        totalVector.unshift(-totalUpfront);
        var returns = irr(totalVector);

        var result =
        {
                capex: totalUpfront,
                irr: returns,
                stream: revenueStream,
                totalRevenue: totalRevenue
        };

        return result;
}
