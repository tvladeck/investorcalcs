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
        var interval = [0, 1];
        var result = 1;
        while (Math.abs(result) > 0.1)
        {
                var middle = (interval[0] + interval[1]) / 2;
                result = npv(middle, payments);
                if(result < 0) interval = [interval[0], middle];
                if(result > 0) interval = [middle, interval[1]];
        }
        return middle;
}

