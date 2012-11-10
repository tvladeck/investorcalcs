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

        //need to use slice(0) so that a new object is created. otherwise
        //unshift will affect both totalVector and revenueStream
        var totalVector = revenueStream.slice(0); // new variable to calculate IRR
        totalVector[0]  -= totalUpfront; // need to add upfront cost
        var returns = irr(totalVector);
        returns = Math.pow((1 + returns), 12) - 1; // convert monthly IRR to annual

        var result =
        {
                capex: totalUpfront,
                irr: returns,
                revenue: revenueStream,
                cashflow: totalVector,
                totalRevenue: totalRevenue,
                projects: individualResults
        };

        return result;
}

