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

