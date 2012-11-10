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

